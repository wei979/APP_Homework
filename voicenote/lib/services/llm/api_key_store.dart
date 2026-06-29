import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Gemini API 金鑰存取。
///
/// 優先讀取編譯期注入的 `--dart-define=GEMINI_API_KEY=...`；
/// 否則讀取使用者於 App 內輸入、存於 App 私有目錄的金鑰。
/// 金鑰由使用者自行提供（Google AI Studio 免費取得），App 不內建任何金鑰。
class ApiKeyStore {
  static const String _envKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'gemini_api_key.txt'));
  }

  Future<String?> read() async {
    if (_envKey.trim().isNotEmpty) return _envKey.trim();
    final f = await _file();
    if (await f.exists()) {
      final v = (await f.readAsString()).trim();
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  Future<void> save(String key) async {
    final f = await _file();
    await f.writeAsString(key.trim());
  }

  Future<void> clear() async {
    final f = await _file();
    if (await f.exists()) await f.delete();
  }
}