# APP_Homework — VoiceNote 智慧離線語音筆記 App

114 學年第二學期 ・ APP 程式設計期末專案。

完全離線的語音辨識 + 自動章節摘要：錄音結束即自動產出「分章節的條列重點」，
點任一重點可跳回原始錄音時間點。以 **Flutter / Dart** 實作，UI 對應設計稿
《VoiceNote 操作流程概念圖》的 Material 3 墨綠主題。

## 倉庫結構

| 路徑 | 說明 |
| --- | --- |
| `voicenote/` | Flutter 應用程式原始碼（見 `voicenote/README.md`） |
| `1142 NKUST APP Final Project Proposal (1).docx` | 專案構想企劃書 |

## 快速開始

```bash
cd voicenote
flutter create .       # 產生 android/ios/web 等平台殼層（不覆蓋既有 lib/ 與 pubspec）
flutter pub get
flutter run
flutter test           # 執行 TextRank / 章節切分 / 處理流程 / Markdown 匯出 單元測試
```

詳細架構、權限設定與離線辨識（Vosk）啟用方式見 `voicenote/README.md`。