import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/processing_controller.dart';
import '../../providers/recording_provider.dart';
import '../../services/app_services.dart';
import '../../services/processing/note_processor.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/duration_format.dart';
import '../note_detail/note_detail_screen.dart';

/// 步驟三：結束錄音後的「處理中」畫面。
class ProcessingScreen extends StatelessWidget {
  final RecordingResult result;
  const ProcessingScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final services = context.read<AppServices>();
    return ChangeNotifierProvider(
      create: (_) => ProcessingController(
        services: services,
        title: result.title,
        audioPath: result.audioPath,
        durationMs: result.durationMs,
      )..run(),
      child: const _ProcessingView(),
    );
  }
}

class _ProcessingView extends StatefulWidget {
  const _ProcessingView();
  @override
  State<_ProcessingView> createState() => _ProcessingViewState();
}

class _ProcessingViewState extends State<_ProcessingView> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ProcessingController>();

    if (c.stage == ProcessingStage.done && c.savedId != null && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => NoteDetailScreen(noteId: c.savedId!),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('處理中',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const _Orb(),
              const SizedBox(height: 22),
              const Text('正在整理你的筆記…',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              const Text(
                '所有處理皆於本機完成\n不會上傳任何錄音內容',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, height: 1.6, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              _StepRow(
                label: '音訊儲存完成（${DurationFormat.hms(c.durationMs)}）',
                state: _stateOf(c, ProcessingStage.savingAudio),
              ),
              _StepRow(
                label: '離線語音辨識完成',
                state: _stateOf(c, ProcessingStage.recognizing),
              ),
              _StepRow(
                label: '章節切分・TextRank 摘要',
                state: _stateOf(c, ProcessingStage.summarizing),
              ),
              _StepRow(
                label: '產生筆記',
                state: _stateOf(c, ProcessingStage.generating),
              ),
              if (c.statusDetail != null) ...[
                const SizedBox(height: 12),
                Text(
                  c.statusDetail!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.primary),
                ),
              ],
              const Spacer(),
              if (c.error != null)
                Text('處理失敗：${c.error}',
                    style: const TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ),
    );
  }

  _StepState _stateOf(ProcessingController c, ProcessingStage s) {
    if (c.isDone(s)) return _StepState.done;
    if (c.isActive(s)) return _StepState.active;
    return _StepState.pending;
  }
}

enum _StepState { done, active, pending }

class _StepRow extends StatelessWidget {
  final String label;
  final _StepState state;
  const _StepRow({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final isActive = state == _StepState.active;
    final isPending = state == _StepState.pending;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryContainer
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
      child: Row(
        children: [
          SizedBox(width: 22, height: 22, child: _icon(state)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                color: isPending
                    ? AppColors.outline
                    : (isActive
                        ? AppColors.onPrimaryContainer
                        : AppColors.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _icon(_StepState state) {
    switch (state) {
      case _StepState.done:
        return const Icon(Icons.check_circle,
            size: 20, color: AppColors.primary);
      case _StepState.active:
        return const Padding(
          padding: EdgeInsets.all(1),
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary),
        );
      case _StepState.pending:
        return const Icon(Icons.radio_button_unchecked,
            size: 20, color: AppColors.outline);
    }
  }
}

/// 處理中的能量球（漸層 + 漣漪動畫）。
class _Orb extends StatefulWidget {
  const _Orb();
  @override
  State<_Orb> createState() => _OrbState();
}

class _OrbState extends State<_Orb> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _ring(double t) {
    final v = t % 1.0;
    return Opacity(
      opacity: (0.5 * (1 - v)).clamp(0.0, 0.5),
      child: Transform.scale(
        scale: 1 + 0.45 * v,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 190,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _ring(_c.value),
              _ring((_c.value + 0.5) % 1.0),
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(-0.3, -0.4),
                    colors: [
                      Color(0xFFB6F0D8),
                      Color(0xFF6ABF9D),
                      AppColors.primary,
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 56, color: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }
}