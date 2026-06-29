import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../../models/transcript_segment.dart';
import '../processing/simplified_to_traditional.dart';
import 'speech_recognizer.dart';

/// 真實離線語音辨識（sherpa-onnx + Paraformer 中文，純 Dart FFI）。
///
/// 模型 model.int8.onnx (~230MB) 首次使用時自 HuggingFace 串流下載到 App 目錄，
/// 之後離線使用。辨識結果含 token 級時間戳，輸出再經簡→繁。
/// 錄音中即時辨識本版不做（停止後對整段 WAV 離線辨識）。
class SherpaSpeechRecognizer implements SpeechRecognizer {
  static const String _dirName = 'sherpa-paraformer-zh-2023-09-14';
  static const String _base =
      'https://huggingface.co/csukuangfj/sherpa-onnx-paraformer-zh-2023-09-14/resolve/main';
  static const int _minModelBytes = 200000000; // ~200MB 視為下載完整
  static const double _sentenceGapSec = 0.7; // token 間隔 > 此值視為換句

  final StreamController<SpeechResult> _live =
      StreamController<SpeechResult>.broadcast();
  final StreamController<String> _status =
      StreamController<String>.broadcast();
  SimplifiedToTraditional? _s2t;
  sherpa.OfflineRecognizer? _recognizer;
  Future<void>? _ready;

  @override
  Stream<SpeechResult> get liveResults => _live.stream;

  @override
  Stream<String>? get setupStatus => _status.stream;

  @override
  Future<void> initialize() async {
    sherpa.initBindings();
    _s2t = await SimplifiedToTraditional.load();
  }

  Future<void> _ensureReady() => _ready ??= _prepare();

  Future<void> _prepare() async {
    final dir = await getApplicationSupportDirectory();
    final modelDir = Directory(p.join(dir.path, _dirName));
    await modelDir.create(recursive: true);
    final modelPath = p.join(modelDir.path, 'model.int8.onnx');
    final tokensPath = p.join(modelDir.path, 'tokens.txt');

    final modelFile = File(modelPath);
    final ready =
        await modelFile.exists() && await modelFile.length() > _minModelBytes;
    if (!ready) {
      await _download('$_base/tokens.txt', tokensPath, '辨識模型字表');
      await _download('$_base/model.int8.onnx', modelPath, '辨識模型');
    }

    _status.add('載入辨識模型中…');
    final config = sherpa.OfflineRecognizerConfig(
      model: sherpa.OfflineModelConfig(
        paraformer: sherpa.OfflineParaformerModelConfig(model: modelPath),
        tokens: tokensPath,
        modelType: 'paraformer',
        numThreads: 2,
      ),
    );
    _recognizer = sherpa.OfflineRecognizer(config);
    _status.add('');
  }

  Future<void> _download(String url, String dest, String label) async {
    final file = File(dest);
    if (await file.exists()) await file.delete();
    _status.add('下載$label 0%');
    final client = HttpClient();
    try {
      final resp = await (await client.getUrl(Uri.parse(url))).close();
      if (resp.statusCode != 200) {
        throw HttpException('下載失敗 HTTP ${resp.statusCode}', uri: Uri.parse(url));
      }
      final total = resp.contentLength;
      var received = 0;
      var lastPct = -1;
      final sink = file.openWrite();
      await for (final chunk in resp) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          final pct = (received / total * 100).round();
          if (pct != lastPct) {
            lastPct = pct;
            _status.add('下載$label $pct%');
          }
        }
      }
      await sink.close();
      if (total > 0 && received < total) {
        throw HttpException('下載不完整（$received/$total）', uri: Uri.parse(url));
      }
    } finally {
      client.close();
    }
  }

  @override
  Future<List<TranscriptSegment>> transcribeFile(
    String audioPath, {
    int? totalDurationMs,
  }) async {
    await _ensureReady();
    final rec = _recognizer!;
    final wave = sherpa.readWave(audioPath);
    final stream = rec.createStream();
    stream.acceptWaveform(samples: wave.samples, sampleRate: wave.sampleRate);
    rec.decode(stream);
    final result = rec.getResult(stream);
    stream.free();
    return _buildSegments(result.tokens, result.timestamps, result.text);
  }

  /// 依 token 時間戳分句，組成含時間戳的段落（供章節切分 / 摘要）。
  List<TranscriptSegment> _buildSegments(
    List<String> tokens,
    List<double> timestamps,
    String fullText,
  ) {
    final s2t = _s2t;
    String conv(String s) => s2t != null ? s2t.convert(s) : s;

    if (tokens.isEmpty ||
        timestamps.isEmpty ||
        tokens.length != timestamps.length) {
      final text = conv(fullText.replaceAll(' ', '')).trim();
      if (text.isEmpty) return const [];
      return [TranscriptSegment(text: text, startMs: 0, endMs: 0)];
    }

    final segments = <TranscriptSegment>[];
    var buf = StringBuffer();
    var segStart = timestamps.first;
    var prevTs = timestamps.first;

    void flush(double endTs) {
      final text = conv(buf.toString().replaceAll(' ', '')).trim();
      if (text.isNotEmpty) {
        segments.add(
          TranscriptSegment(
            text: text,
            startMs: (segStart * 1000).round(),
            endMs: (endTs * 1000).round(),
          ),
        );
      }
      buf = StringBuffer();
    }

    for (var i = 0; i < tokens.length; i++) {
      final ts = timestamps[i];
      if (i > 0 && ts - prevTs > _sentenceGapSec) {
        flush(prevTs);
        segStart = ts;
      }
      buf.write(tokens[i].replaceAll('@@', ''));
      prevTs = ts;
    }
    flush(prevTs);
    return segments;
  }

  @override
  Future<void> startLive() async {}
  @override
  Future<void> pauseLive() async {}
  @override
  Future<void> resumeLive() async {}
  @override
  Future<void> stopLive() async {}

  @override
  Future<void> dispose() async {
    _recognizer?.free();
    await _live.close();
    await _status.close();
  }
}