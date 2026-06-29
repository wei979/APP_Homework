import 'dart:math' as math;

import 'tokenizer.dart';

/// TextRank 排序後的句子。
class RankedSentence {
  final int index;
  final String sentence;
  final double score;
  const RankedSentence(this.index, this.sentence, this.score);
}

/// 經典 TextRank 摘要演算法（純 Dart，不需訓練資料）。
///
/// 以句子間 token 重疊度建構無向圖，跑 PageRank 迭代算出句子重要性，
/// 計算量小、可在中低階手機即時運算。
class TextRankSummarizer {
  final double damping;
  final int maxIterations;
  final double tolerance;

  const TextRankSummarizer({
    this.damping = 0.85,
    this.maxIterations = 60,
    this.tolerance = 1e-5,
  });

  /// 對所有句子計算 TextRank 分數並由高到低排序。
  List<RankedSentence> rank(List<String> sentences) {
    final n = sentences.length;
    if (n == 0) return const [];
    if (n == 1) return [RankedSentence(0, sentences.first, 1)];

    final tokenSets = [for (final s in sentences) Tokenizer.tokens(s).toSet()];

    final sim = List.generate(n, (_) => List.filled(n, 0.0));
    final rowSum = List.filled(n, 0.0);
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final s = _similarity(tokenSets[i], tokenSets[j]);
        sim[i][j] = s;
        sim[j][i] = s;
      }
    }
    for (var i = 0; i < n; i++) {
      var sum = 0.0;
      for (var j = 0; j < n; j++) {
        sum += sim[i][j];
      }
      rowSum[i] = sum;
    }

    var scores = List.filled(n, 1.0 / n);
    final base = (1 - damping) / n;
    for (var iter = 0; iter < maxIterations; iter++) {
      final next = List.filled(n, base);
      for (var i = 0; i < n; i++) {
        var acc = 0.0;
        for (var j = 0; j < n; j++) {
          if (j == i) continue;
          final w = sim[i][j];
          if (w == 0 || rowSum[j] == 0) continue;
          acc += (w / rowSum[j]) * scores[j];
        }
        next[i] += damping * acc;
      }
      var diff = 0.0;
      for (var i = 0; i < n; i++) {
        diff += (next[i] - scores[i]).abs();
      }
      scores = next;
      if (diff < tolerance) break;
    }

    final ranked = [
      for (var i = 0; i < n; i++) RankedSentence(i, sentences[i], scores[i]),
    ];
    ranked.sort((a, b) {
      final c = b.score.compareTo(a.score);
      return c != 0 ? c : a.index.compareTo(b.index);
    });
    return ranked;
  }

  /// 回傳重點句的原始順序索引（升冪）。數量依句數縮放，落在 [minN, maxN]。
  List<int> summarizeIndices(
    List<String> sentences, {
    int minN = 3,
    int maxN = 5,
  }) {
    final n = sentences.length;
    if (n == 0) return const [];
    final target =
        n <= minN ? n : math.min(maxN, math.max(minN, (n * 0.4).round()));
    final picked = rank(sentences).take(target).map((e) => e.index).toList()
      ..sort();
    return picked;
  }

  double _similarity(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final small = a.length < b.length ? a : b;
    final big = identical(small, a) ? b : a;
    var inter = 0;
    for (final t in small) {
      if (big.contains(t)) inter++;
    }
    if (inter == 0) return 0;
    final denom = math.log(a.length + 1) + math.log(b.length + 1);
    if (denom <= 0) return 0;
    return inter / denom;
  }
}