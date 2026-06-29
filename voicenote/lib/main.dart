import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/note_list_provider.dart';
import 'screens/note_list/note_list_screen.dart';
import 'services/app_services.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.initialize();
  runApp(VoiceNoteApp(services: services));
}

/// VoiceNote — 智慧離線語音筆記 App 根節點。
///
/// 全域提供 [AppServices]（倉儲 / 辨識器 / 處理器 / 匯出）與筆記列表狀態；
/// 錄音、處理、播放等畫面則各自建立 scope 內的 Provider。
class VoiceNoteApp extends StatelessWidget {
  final AppServices services;
  const VoiceNoteApp({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppServices>.value(value: services),
        ChangeNotifierProvider<NoteListProvider>(
          create: (_) => NoteListProvider(services.repository),
        ),
      ],
      child: MaterialApp(
        title: 'VoiceNote',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const NoteListScreen(),
      ),
    );
  }
}