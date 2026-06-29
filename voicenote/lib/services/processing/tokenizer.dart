/// 中英混合斷詞器（純 Dart，無外部依賴、無需訓練資料）。
///
/// 英文取單字、中文取相鄰字 bigram，作為 TextRank 句子相似度與
/// 章節關鍵字抽取的基本單位。
class Tokenizer {
  Tokenizer._();

  static const Set<String> _enStop = {
    'the', 'a', 'an', 'and', 'or', 'of', 'to', 'in', 'on', 'for', 'is', 'are',
    'be', 'it', 'this', 'that', 'we', 'you', 'will', 'would', 'can', 'as', 'at',
    'by', 'with', 'so', 'do', 'our', 'my', 'if', 'but', 'not', 'no',
  };

  /// 中文常見虛詞 / 語助詞（單字）。
  static const Set<String> _zhStop = {
    '的', '了', '是', '我', '你', '他', '她', '它', '們', '和', '與', '或', '在',
    '也', '都', '就', '要', '會', '個', '這', '那', '有', '沒', '很', '到', '把',
    '被', '讓', '給', '對', '等', '一', '上', '下', '中', '來', '去', '還', '但',
    '而', '其', '之', '以', '可', '將', '並', '於', '為', '從', '再', '喔', '啊',
    '呢', '嗎', '吧', '嗯', '著', '過',
  };

  static final RegExp _latin = RegExp(r'[a-zA-Z][a-zA-Z0-9+#]*');
  static final RegExp _cjkRun = RegExp(r'[一-鿿]+');

  /// 斷詞（保留重複，方便詞頻統計）。
  static List<String> tokens(String text) {
    final out = <String>[];
    final lower = text.toLowerCase();

    for (final m in _latin.allMatches(lower)) {
      final w = m.group(0)!;
      if (w.length >= 2 && !_enStop.contains(w)) out.add(w);
    }

    for (final m in _cjkRun.allMatches(text)) {
      final run = m.group(0)!;
      if (run.length == 1) {
        if (!_zhStop.contains(run)) out.add(run);
        continue;
      }
      for (var i = 0; i < run.length - 1; i++) {
        final a = run[i];
        final b = run[i + 1];
        if (_zhStop.contains(a) && _zhStop.contains(b)) continue;
        out.add('$a$b');
      }
    }
    return out;
  }
}