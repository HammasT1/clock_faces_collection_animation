import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/clock_face.dart';
import '../core/clock_ticker.dart';

/// Face 4 — a pure ambient gradient whose hue sweeps a full cycle across
/// the day and whose lightness peaks near midday and dips near midnight.
/// The gradient axis itself slowly rotates over the same 24h cycle, a soft
/// bloom drifts across the field on its own slow cycle, and a vignette
/// grounds the edges so it reads as a lit surface rather than a flat sheet
/// of color.
class GradientFace extends ClockFace {
  const GradientFace({super.key});

  @override
  String get name => 'Gradient';

  @override
  Widget build(BuildContext context) {
    final time = ClockTickerProvider.of(context);
    return RepaintBoundary(
      child: SizedBox.expand(
        child: CustomPaint(painter: _GradientPainter(repaint: time)),
      ),
    );
  }
}

class _GradientPainter extends CustomPainter {
  _GradientPainter({required Listenable repaint}) : super(repaint: repaint);

  final Paint _basePaint = Paint();
  final Paint _bloomPaint = Paint()..blendMode = BlendMode.plus;
  final Paint _vignettePaint = Paint();

  // The vignette only depends on size, so it's built once and reused.
  Size? _cachedSize;
  late Shader _vignetteShader;

  static const double _twoPi = math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final rect = Offset.zero & size;
    final dayFraction = (now.hour * 3600 +
            now.minute * 60 +
            now.second +
            now.millisecond / 1000) /
        86400;

    final hue1 = dayFraction * 360;
    final hue2 = (hue1 + 48) % 360;
    // Lightness peaks a little after midday, dips near midnight.
    final lightness = 0.42 + 0.16 * math.sin(_twoPi * (dayFraction - 0.28));

    final color1 = HSLColor.fromAHSL(1, hue1, 0.55, lightness).toColor();
    final color2 =
        HSLColor.fromAHSL(1, hue2, 0.55, (lightness * 0.72).clamp(0.08, 1.0))
            .toColor();

    final angle = dayFraction * _twoPi;
    final begin = Alignment(-math.cos(angle), -math.sin(angle));
    final end = Alignment(math.cos(angle), math.sin(angle));

    _basePaint.shader = LinearGradient(
      colors: [color1, color2],
      begin: begin,
      end: end,
    ).createShader(rect);
    canvas.drawRect(rect, _basePaint);

    // A soft highlight that drifts slowly on its own cycle (independent of
    // the day-length hue rotation) so the field never sits perfectly still.
    final driftT = now.millisecondsSinceEpoch / 1000;
    final bloomCenter = Offset(
      size.width * (0.5 + 0.3 * math.sin(driftT * 0.05)),
      size.height * (0.5 + 0.3 * math.cos(driftT * 0.037)),
    );
    _bloomPaint.shader = RadialGradient(
      colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.0)],
    ).createShader(Rect.fromCircle(center: bloomCenter, radius: size.longestSide * 0.55));
    canvas.drawRect(rect, _bloomPaint);

    if (_cachedSize != size) {
      _vignetteShader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.38)],
        stops: const [0.55, 1.0],
      ).createShader(rect);
      _cachedSize = size;
    }
    _vignettePaint.shader = _vignetteShader;
    canvas.drawRect(rect, _vignettePaint);
  }

  @override
  bool shouldRepaint(covariant _GradientPainter oldDelegate) => false;
}
