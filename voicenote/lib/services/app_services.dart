import '../data/note_repository.dart';
import 'export/markdown_exporter.dart';
import 'processing/note_processor.dart';
import 'speech/demo_speech_recognizer.dart';
import 'speech/speech_recognizer.dart';

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
    final recognizer = DemoSpeechRecognizer();
    await recognizer.initialize();
    return AppServices(
      repository: repository,
      recognizer: recognizer,
      processor: const NoteProcessor(),
      exporter: const MarkdownExporter(),
    );
  }
}