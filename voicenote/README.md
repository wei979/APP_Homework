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
│   ├── speech/        SpeechRecognizer 抽象 + Demo(離線示範) + Vosk(接線骨架)
│   ├── processing/    Tokenizer · TextRankSummarizer · ChapterSplitter · NoteProcessor
│   ├── audio/         AudioRecorderService(record) · AudioPlayerService(just_audio)
│   ├── export/        MarkdownExporter
│   └── app_services.dart   服務容器（手動依賴注入）
├── providers/     NoteList · Recording · ProcessingController · Player（Provider 狀態）
└── screens/       note_list / record / processing / note_detail
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

## 5. 切換到真實離線辨識（Vosk）

預設使用 `DemoSpeechRecognizer`（逐字吐出講稿 + 回傳預設講稿，讓流程端到端可跑，
不需下載模型）。要換成真實離線辨識：

1. `pubspec.yaml` 加入 `vosk_flutter`。
2. 下載繁體中文模型放入 assets 或 App 私有目錄。
3. 依 `lib/services/speech/vosk_speech_recognizer.dart` 檔頭說明完成接線。
4. 在 `lib/services/app_services.dart` 把 `DemoSpeechRecognizer()` 換成
   `VoskSpeechRecognizer(modelPath: ...)`。

介面一致，UI 與處理流程不需改動。

## 6. 測試

```bash
flutter test
```

涵蓋：TextRank 摘要、章節切分、整體處理流程、Markdown 匯出。

## 7. 已知限制

- 示範辨識器使用內建講稿；真實逐字稿請啟用 Vosk。
- 示範資料（seed）無真實音檔，播放器以「虛擬時間軸」示範跳轉與進度；
  使用者自行錄製的筆記則播放真實 WAV。