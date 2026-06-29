import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../services/app_services.dart';
import '../services/processing/note_processor.dart';

/// 驅動「處理中」畫面：依序執行 辨識 → 章節切分/摘要 → 寫入資料庫。
class ProcessingController extends ChangeNotifier {
  final AppServices services;
  final String title;
  final String audioPath;
  final int durationMs;

  ProcessingController({
    required this.services,
    required this.title,
    required this.audioPath,
    required this.durationMs,
  });

  bool _disposed = false;

  ProcessingStage _stage = ProcessingStage.savingAudio;
  ProcessingStage get stage => _stage;

  Note? _result;
  Note? get result => _result;

  int? _savedId;
  int? get savedId => _savedId;

  Object? _error;
  Object? get error => _error;

  String? _detail;
  String? get statusDetail => _detail;

  Future<void> run() async {
    try {
      _setStage(ProcessingStage.savingAudio);
      await Future<void>.delayed(const Duration(milliseconds: 500));

      _setStage(ProcessingStage.recognizing);
      final statusSub = services.recognizer.setupStatus?.listen((s) {
        _detail = s.isEmpty ? null : s;
        _notify();
      });
      final segments = await services.recognizer
          .transcribeFile(audioPath, totalDurationMs: durationMs);
      await statusSub?.cancel();
      _detail = null;

      _setStage(ProcessingStage.summarizing);
      final note = services.processor.buildNote(
        title: title,
        audioPath: audioPath,
        durationMs: durationMs,
        segments: segments,
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));

      _setStage(ProcessingStage.generating);
      _savedId = await services.repository.add(note);
      _result = note;
      await Future<void>.delayed(const Duration(milliseconds: 300));

      _setStage(ProcessingStage.done);
    } catch (e) {
      _error = e;
      _notify();
    }
  }

  void _setStage(ProcessingStage s) {
    _stage = s;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool isDone(ProcessingStage s) => s.index < _stage.index;
  bool isActive(ProcessingStage s) =>
      s == _stage && _stage != ProcessingStage.done;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}