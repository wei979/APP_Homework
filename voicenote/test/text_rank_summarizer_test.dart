import 'package:flutter_test/flutter_test.dart';
import 'package:voicenote/services/processing/text_rank_summarizer.dart';

void main() {
  const summarizer = TextRankSummarizer();

  group('TextRankSummarizer', () {
    test('空輸入回傳空', () {
      expect(summarizer.summarizeIndices([]), isEmpty);
      expect(summarizer.rank([]), isEmpty);
    });

    test('單句回傳該句索引', () {
      expect(summarizer.summarizeIndices(['只有一句話']), [0]);
    });

    test('與主題無關的句子分數最低', () {
      final sentences = [
        '堆疊是一種後進先出的線性結構',
        '堆疊的操作有 push 與 pop',
        '堆疊常用於函式呼叫與回溯',
        '今天天氣很好適合出去玩水',
      ];
      final ranked = summarizer.rank(sentences);
      expect(ranked.first.index, isNot(3));
      expect(ranked.last.index, 3);
    });

    test('摘要索引升冪且數量落在 3~5', () {
      final sentences = List.generate(
        10,
        (i) => '第 $i 段 介紹 堆疊 與 佇列 的 重點 摘要 內容',
      );
      final idx = summarizer.summarizeIndices(sentences);
      expect(idx.length, inInclusiveRange(3, 5));
      final sorted = [...idx]..sort();
      expect(idx, sorted);
    });
  });
}