import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/recording_provider.dart';
import '../../services/app_services.dart';
import '../../services/audio/audio_recorder_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/duration_format.dart';
import '../processing/processing_screen.dart';
import 'widgets/waveform_view.dart';

/// 步驟二：錄音頁。輸入課程名稱、即時計時 / 波形 / 辨識文字。
class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();
    return ChangeNotifierProvider(
      create: (_) =>
          RecordingProvider(AudioRecorderService(), services.recognizer),
      child: const _RecordView(),
    );
  }
}

class _RecordView extends StatefulWidget {
  const _RecordView();
  @override
  State<_RecordView> createState() => _RecordViewState();
}

class _RecordViewState extends State<_RecordView> {
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _onStop() async {
    final provider = context.read<RecordingProvider>();
    final result = await provider.stop();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ProcessingScreen(result: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecordingProvider>();
    final recording = provider.state == RecorderState.recording;
    final paused = provider.state == RecorderState.paused;
    final active = recording || paused;

    final (timerMain, timerMs) = DurationFormat.timer(provider.elapsedMs);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('錄音中',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.tune)),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                onChanged: (v) => provider.title = v,
                decoration: InputDecoration(
                  labelText: '課程名稱',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              RichText(
                text: TextSpan(
                  text: timerMain,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    color: AppColors.onSurface,
                    letterSpacing: 2,
                    fontFeatures: [],
                  ),
                  children: [
                    TextSpan(
                      text: timerMs,
                      style: const TextStyle(
                        fontSize: 24,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _RecStatus(recording: recording, paused: paused),
              const SizedBox(height: 16),
              WaveformView(amplitudes: provider.amplitudes),
              const SizedBox(height: 14),
              Expanded(child: _LiveTranscript(text: provider.liveText)),
              const SizedBox(height: 12),
              _Controls(
                active: active,
                paused: paused,
                onStart: () async {
                  await provider.start();
                  if (provider.permissionDenied && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('需要麥克風權限才能錄音')),
                    );
                  }
                },
                onTogglePause: () =>
                    paused ? provider.resume() : provider.pause(),
                onStop: _onStop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecStatus extends StatelessWidget {
  final bool recording;
  final bool paused;
  const _RecStatus({required this.recording, required this.paused});

  @override
  Widget build(BuildContext context) {
    if (!recording && !paused) {
      return const Text('按下錄音鍵開始',
          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant));
    }
    final label = paused ? '已暫停' : 'REC ・ 離線辨識中';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (recording) const _BlinkingDot() else const _StaticDot(),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.error)),
      ],
    );
  }
}

class _StaticDot extends StatelessWidget {
  const _StaticDot();
  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
            color: AppColors.error, shape: BoxShape.circle),
      );
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.3).animate(_c),
        child: const _StaticDot(),
      );
}

class _LiveTranscript extends StatelessWidget {
  final String text;
  const _LiveTranscript({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              const Text('VOSK 即時辨識',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              child: Text(
                text.isEmpty ? '錄音中…停止後會離線辨識並自動整理成章節重點' : text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.7,
                  color: text.isEmpty
                      ? AppColors.onSurfaceVariant
                      : AppColors.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final bool active;
  final bool paused;
  final VoidCallback onStart;
  final VoidCallback onTogglePause;
  final VoidCallback onStop;

  const _Controls({
    required this.active,
    required this.paused,
    required this.onStart,
    required this.onTogglePause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MainButton(icon: Icons.mic, onTap: onStart),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SmallButton(icon: Icons.stop, onTap: onStop),
        const SizedBox(width: 28),
        _MainButton(
          icon: paused ? Icons.mic : Icons.pause,
          onTap: onTogglePause,
        ),
        const SizedBox(width: 28),
        _SmallButton(icon: Icons.bookmark_add, onTap: () {}),
      ],
    );
  }
}

class _MainButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MainButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: const BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1FBA1A1A),
              blurRadius: 0,
              spreadRadius: 6,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.onSurfaceVariant, size: 26),
      ),
    );
  }
}