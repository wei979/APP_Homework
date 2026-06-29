import 'dart:async';

import '../../models/transcript_segment.dart';
import 'speech_recognizer.dart';

/// 離線示範用辨識器：無需下載模型即可讓整個流程端到端跑起來。
///
/// - 即時辨識：逐字吐出一段固定講稿，模擬 Vosk 串流轉譯。
/// - 整檔辨識：回傳一份預先寫好的資料結構講稿（含 >= 3 秒停頓，
///   會被章節切分器切成多個章節），時間戳為合成值。
///
/// 要換成真實離線辨識，改用 [VoskSpeechRecognizer] 並載入 zh-TW 模型即可，
/// 上層 UI / 處理流程不需改動。
class DemoSpeechRecognizer implements SpeechRecognizer {
  final StreamController<SpeechResult> _live =
      StreamController<SpeechResult>.broadcast();
  Timer? _timer;
  int _charIndex = 0;

  static const String _liveScript =
      '今天我們要介紹資料結構中非常重要的一個主題，叫做堆疊，'
      '它是一種後進先出的線性結構，那等一下我們會看 push 和 pop。';

  /// 整檔辨識用的講稿，每個子陣列是一個章節。
  static const List<List<String>> _script = [
    [
      '今天我們要介紹資料結構裡非常重要的主題，堆疊 Stack。',
      '堆疊是一種後進先出的線性結構，後進先出 LIFO 是堆疊最核心的特性。',
      '堆疊主要的操作是 push 與 pop，push 與 pop 的時間複雜度皆為 O(1)。',
      '堆疊常見的應用包括函式呼叫、運算式求值與回溯。',
    ],
    [
      '接下來看如何用陣列實作堆疊，陣列實作需要一個 top 指標。',
      'push 時 top 加一並寫入元素，pop 時讀出元素並把 top 減一。',
      '陣列實作堆疊的缺點是容量固定，陣列滿了就要重新配置更大的陣列。',
    ],
    [
      '另一種方式是用鏈結串列實作堆疊，鏈結串列可以動態增長。',
      '每次 push 就在鏈結串列開頭插入一個節點，pop 就移除開頭節點。',
      '鏈結串列實作不需要預先配置容量，但每個節點多了指標的記憶體開銷。',
    ],
    [
      '最後我們比較堆疊與佇列 Queue，佇列是先進先出 FIFO。',
      '佇列的操作是 enqueue 與 dequeue，佇列常用於排程與廣度優先搜尋。',
      '堆疊與佇列都是線性結構，差別在於資料進出的順序不同。',
    ],
  ];

  @override
  Stream<SpeechResult> get liveResults => _live.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> startLive() async {
    _charIndex = 0;
    _emitProgressive();
  }

  void _emitProgressive() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 140), (t) {
      _charIndex++;
      if (_charIndex >= _liveScript.length) {
        _live.add(const SpeechResult(_liveScript, isFinal: true));
        t.cancel();
        return;
      }
      _live.add(SpeechResult(_liveScript.substring(0, _charIndex)));
    });
  }

  @override
  Future<void> pauseLive() async => _timer?.cancel();

  @override
  Future<void> resumeLive() async => _emitProgressive();

  @override
  Future<void> stopLive() async => _timer?.cancel();

  @override
  Future<List<TranscriptSegment>> transcribeFile(
    String audioPath, {
    int? totalDurationMs,
  }) async {
    // 模擬離線運算耗時。
    await Future<void>.delayed(const Duration(milliseconds: 600));

    const interChapterGapMs = 3500; // > 3 秒 → 觸發章節切分
    const intraSentenceGapMs = 350; // 句間小停頓（< 3 秒）
    final segments = <TranscriptSegment>[];
    var t = 0;

    for (var c = 0; c < _script.length; c++) {
      if (c > 0) t += interChapterGapMs;
      for (final sentence in _script[c]) {
        final dur = (sentence.length * 220).clamp(2500, 9000);
        segments.add(
          TranscriptSegment(text: sentence, startMs: t, endMs: t + dur),
        );
        t += dur + intraSentenceGapMs;
      }
    }
    return segments;
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _live.close();
  }
}