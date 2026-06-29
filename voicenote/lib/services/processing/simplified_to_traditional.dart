import 'package:flutter/services.dart' show rootBundle;

/// 簡體 → 繁體單字轉換（OpenCC STCharacters 對照表）。
///
/// Vosk 中文模型輸出為簡體；本轉換讓筆記呈現繁體（符合企劃 zh-TW 訴求）。
class SimplifiedToTraditional {
  SimplifiedToTraditional._(this._map);
  final Map<String, String> _map;

  static SimplifiedToTraditional? _instance;

  static Future<SimplifiedToTraditional> load() async {
    if (_instance != null) return _instance!;
    final raw = await rootBundle.loadString('assets/s2t/STCharacters.txt');
    final map = <String, String>{};
    for (final line in raw.split('\n')) {
      final l = line.trim();
      if (l.isEmpty || l.startsWith('#')) continue;
      final parts = l.split('\t');
      if (parts.length < 2) continue;
      final s = parts[0];
      final t = parts[1].split(' ').first; // 取第一個繁體對應
      if (s.isNotEmpty && t.isNotEmpty) map[s] = t;
    }
    return _instance = SimplifiedToTraditional._(map);
  }

  String convert(String input) {
    if (_map.isEmpty) return input;
    final sb = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      sb.write(_map[ch] ?? ch);
    }
    return sb.toString();
  }
}