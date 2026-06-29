import 'dart:developer' as developer;

import '../data/note_repository.dart';
import 'export/markdown_exporter.dart';
import 'processing/note_processor.dart';
import 'speech/demo_speech_recognizer.dart';
import 'speech/speech_recognizer.dart';
import 'speech/sherpa_speech_recognizer.dart';

/// 應用層服務容器：集中建立並持有跨畫面共用的服務（手動 DI）。
class AppServices {
  final NoteRepository repository;
  final SpeechRecognizer recognizer;
  final NoteProcessor processor;
  final MarkdownExporter exporter;

  AppServices({
    required this.repository,
    required this.recognizer,
    required this.processor,
    required this.exporter,
  });

  static Future<AppServices> initialize() async {
    final repository = await NoteRepository.create();

    // 預設使用真實離線辨識（sherpa-onnx Paraformer）；初始化失敗（如非 Android）退回示範辨識器，
    // 確保 App 仍可運作。
    SpeechRecognizer recognizer;
    try {
      final sherpa = SherpaSpeechRecognizer();
      await sherpa.initialize();
      recognizer = sherpa;
    } catch (e) {
      developer.log('sherpa-onnx 初始化失敗，改用示範辨識器：$e', name: 'AppServices');
      final demo = DemoSpeechRecognizer();
      await demo.initialize();
      recognizer = demo;
    }

    return AppServices(
      repository: repository,
      recognizer: recognizer,
      processor: const NoteProcessor(),
      exporter: const MarkdownExporter(),
    );
  }
}