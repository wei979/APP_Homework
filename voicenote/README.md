# VoiceNote — 智慧離線語音筆記 App

> 114 學年第二學期 ・ APP 程式設計期末專案
> 完全離線的語音辨識 + 自動章節摘要。錄音結束即自動產出「分章節的條列重點」，
> 點任一重點可跳回原始錄音時間點。以 **Flutter / Dart** 實作，UI 1:1 對應
> 設計稿《VoiceNote 操作流程概念圖》的 Material 3 墨綠主題。

---

## 1. 與企劃書的對應

企劃書原以 Kotlin + Jetpack Compose 規劃，本專案依需求改用 **Flutter / Dart**，
三層式架構與離線理念完全保留：

| 企劃書（Android 原生） | 本專案（Flutter） |
| --- | --- |
| 表現層 Jetpack Compose | `lib/screens/**`（Material 3 widget） |
| 邏輯層 Vosk + TextRank + Coroutines | `lib/services/**`（辨識抽象 / 純 Dart TextRank / 章節切分） |
| 資料層 Room (SQLite) | `lib/data/**`（`sqflite`） |
| 音訊 WAV 私有目錄 | `record` 以 16kHz mono WAV 存於 App 私有目錄 |
| 匯出 Markdown | `lib/services/export/markdown_exporter.dart` + `share_plus` |

四步驟操作流程（筆記列表 → 錄音 → 處理中 → 筆記詳情 → 跳轉播放 → 匯出）皆已實作。

## 2. 架構（三層 + 手動 DI）

```
lib/
├── theme/         墨綠 Material 3 主題（色票/圓角 1:1 對應設計稿 token）
├── models/        Note / Chapter / Bullet / TranscriptSegment
├── data/          AppDatabase(sqflite) · NoteDao · NoteRepository · SeedData
├── services/
│   ├── speech/        SpeechRecognizer 抽象 + Sherpa(sherpa-onnx Paraformer，真實離線預設) + Demo(後備)
│   ├── processing/    Tokenizer · TextRankSummarizer · ChapterSplitter · NoteProcessor
│   ├── audio/         AudioRecorderService(record) · AudioPlayerService(just_audio)
│   ├── export/        MarkdownExporter
│   ├── llm/           GeminiClient · MindMapService · ApiKeyStore（雲端心智圖，Gemini）
│   └── app_services.dart   服務容器（手動依賴注入）
├── providers/     NoteList · Recording · ProcessingController · Player（Provider 狀態）
└── screens/       note_list / record / processing / note_detail / mind_map
```

- **狀態管理**：`provider`。全域提供 `AppServices` 與 `NoteListProvider`；
  錄音 / 處理 / 播放等畫面各自建立 scope 內的 `ChangeNotifier`。
- **離線理念**：所有辨識、摘要、儲存皆於本機完成，不連任何雲端。

## 3. 核心演算法（純 Dart，無需訓練資料）

- **章節切分** `ChapterSplitter`：相鄰辨識段落間隔 ≥ 3 秒即切新章節（對應企劃書）。
- **重點摘要** `TextRankSummarizer`：以句子 token 重疊度建圖、跑 PageRank 迭代，
  每章節取重要性最高的 3–5 句作為重點。計算量小，可於中低階手機即時運算。
- **關鍵字標題** `KeywordExtractor`：取章節內最高頻詞作章節標題。

以上皆有單元測試（見 `test/`）。

## 4. 執行方式

> 本倉庫只含 `lib/`、`test/`、`pubspec.yaml` 等跨平台原始碼，未含各平台殼層。
> 首次取得後請先產生平台專案：

```bash
cd voicenote
flutter create .          # 產生 android/ios/web 等平台資料夾（不會覆蓋既有 lib/ 與 pubspec）
flutter pub get
flutter run               # 連上裝置或模擬器
```

開箱即用：首次啟動會自動注入示範資料（含「資料結構 第 3 章」5 章節 18 重點），
可直接瀏覽列表、開啟詳情、點重點跳轉、匯出 Markdown。

### 權限設定

錄音需要麥克風權限，`flutter create` 後請補上：

- **Android** `android/app/src/main/AndroidManifest.xml`（`<manifest>` 內）：
  ```xml
  <uses-permission android:name="android.permission.RECORD_AUDIO"/>
  ```
  並確認 `android/app/build.gradle` 的 `minSdkVersion` ≥ 23。
- **iOS** `ios/Runner/Info.plist`：
  ```xml
  <key>NSMicrophoneUsageDescription</key>
  <string>需要麥克風以進行課堂錄音與離線辨識</string>
  ```

## 5. 離線語音辨識（sherpa-onnx，預設）

預設即為真實離線辨識：**sherpa-onnx + Paraformer 中文 int8**（純 Dart FFI），
模型於首次辨識時自動從 HuggingFace 下載到 App 私有目錄，再以 OpenCC 簡→繁。
初始化失敗（如非 Android 平台）會自動退回 `DemoSpeechRecognizer`，確保流程仍可跑。

- 實作：`lib/services/speech/sherpa_speech_recognizer.dart`
- 介面抽象：`lib/services/speech/speech_recognizer.dart`（可替換不同辨識引擎）
- 全程在本機完成，**不上傳任何錄音內容**。

## 6. 雲端心智圖（重點樹狀圖）與 Gemini 金鑰設定

> ⚠️ 此功能會將逐字稿上傳到雲端 LLM（Google Gemini）做語意分析，**需連網**。
> 語音辨識本身仍完全離線；心智圖是額外的「選用」功能，與辨識分開。

在筆記詳情頁右上角點 🌳 →「產生心智圖」，App 會把章節重點與逐字稿送到 Gemini，
整理成「主題 → 子主題 → 重點」的節點連線心智圖（可雙指縮放、拖曳，點節點跳轉播放）。
結果會快取在本機，下次開啟直接顯示。

### 取得免費 Gemini 金鑰
1. 前往 **https://aistudio.google.com/apikey**（用 Google 帳號登入）。
2. 點 **Create API key** → 建立 → 複製金鑰（`AIza...` 開頭）。免費、免信用卡，免費層額度足夠課堂作業使用。

### 提供金鑰給 App（兩種方式擇一）
- **App 內輸入（最簡單）**：第一次按「產生心智圖」會跳出輸入框，貼上金鑰即可。
  金鑰只存在本機（App 私有目錄 `gemini_api_key.txt`），不內建於 App、也不進版控。
- **編譯期注入**（適合 demo / CI，不想在 UI 輸入時）：
  ```bash
  flutter run --dart-define=GEMINI_API_KEY=你的金鑰
  ```
  此方式優先於 App 內輸入的金鑰。

### 安全須知
- 金鑰**絕不**寫死在原始碼，也不提交到 Git。
- 模型預設 `gemini-2.5-flash`（免費層）；若帳號無此模型，改
  `lib/services/llm/gemini_client.dart` 的 `_model` 常數即可。

## 7. 測試

```bash
flutter test
```

涵蓋：TextRank 摘要、章節切分、整體處理流程、Markdown 匯出。

## 8. 已知限制

- 預設為 sherpa-onnx 真實離線辨識；非 Android 或初始化失敗時自動退回示範辨識器。
- 重點心智圖需連網（會上傳逐字稿到 Gemini），屬選用功能，與離線辨識分開。
- 示範資料（seed）無真實音檔，播放器以「虛擬時間軸」示範跳轉與進度；
  使用者自行錄製的筆記則播放真實 WAV。