import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// 錄音波形：依正規化音量串流即時繪製長條。
class WaveformView extends StatelessWidget {
  final List<double> amplitudes;
  const WaveformView({super.key, required this.amplitudes});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      width: double.infinity,
      child: CustomPaint(
        painter: _WavePainter(amplitudes, AppColors.primary),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final List<double> amps;
  final Color color;
  _WavePainter(this.amps, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    const gap = 7.0;
    final n = (size.width / gap).floor();
    final center = size.height / 2;
    for (var i = 0; i < n; i++) {
      final idx = amps.length - n + i;
      final a = (idx >= 0 && idx < amps.length) ? amps[idx] : 0.06;
      final h = (8 + a * 52).clamp(6.0, size.height);
      final x = i * gap + gap / 2;
      canvas.drawLine(
        Offset(x, center - h / 2),
        Offset(x, center + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}