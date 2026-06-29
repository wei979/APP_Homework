import 'tokenizer.dart';

/// 由章節文字抽取關鍵詞作為章節標題。
///
/// 取出現頻率最高（>= 2 次）的詞作標題；若沒有明顯重複關鍵字，
/// 退回使用該段句首片段。
class KeywordExtractor {
  const KeywordExtractor();

  String title(String text, {int fallbackIndex = 0}) {
    final tokens = Tokenizer.tokens(text);
    final freq = <String, int>{};
    for (final t in tokens) {
      if (t.length >= 2) freq[t] = (freq[t] ?? 0) + 1;
    }
    if (freq.isEmpty) return _snippet(text, fallbackIndex);

    final best = freq.entries.reduce((a, b) {
      if (b.value != a.value) return b.value > a.value ? b : a;
      return b.key.length > a.key.length ? b : a;
    });
    if (best.value < 2) return _snippet(text, fallbackIndex);
    return best.key;
  }

  String _snippet(String text, int index) {
    final clean = text.trim();
    if (clean.isEmpty) return '章節 ${index + 1}';
    return clean.length > 12 ? '${clean.substring(0, 12)}…' : clean;
  }
}