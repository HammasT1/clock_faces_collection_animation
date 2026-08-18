import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/clock_face.dart';
import '../core/clock_ticker.dart';
import '../core/premium_style.dart';

/// Face 1 — a plain analog clock with a smooth (non-ticking) second hand.
class MinimalAnalogFace extends ClockFace {
  const MinimalAnalogFace({super.key});

  @override
  String get name => 'Minimal Analog';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final time = ClockTickerProvider.of(context);
    return RepaintBoundary(
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: SizedBox.expand(
              child: CustomPaint(
                painter: _MinimalAnalogPainter(
                  colorScheme: colorScheme,
                  repaint: time,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MinimalAnalogPainter extends CustomPainter {
  _MinimalAnalogPainter({required this.colorScheme, required Listenable repaint})
      : super(repaint: repaint);

  final ColorScheme colorScheme;

  // Paint objects are created once and mutated per-frame in paint() —
  // never reallocated inside the hot path.
  final Paint _shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.35)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
  final Paint _facePaint = Paint()..style = PaintingStyle.fill;
  final Paint _bezelPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _rimPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _tickPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _hourHandPaint = Paint()..strokeCap = StrokeCap.round;
  final Paint _minuteHandPaint = Paint()..strokeCap = StrokeCap.round;
  final Paint _secondHandPaint = Paint()..strokeCap = StrokeCap.round;
  final Paint _secondGlowPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  final Paint _hubPaint = Paint()..style = PaintingStyle.fill;
  final Paint _hubHighlightPaint = Paint()..style = PaintingStyle.fill;

  // Shaders only depend on size (colorScheme is fixed for this painter's
  // lifetime — a theme change swaps the whole painter instance), so they're
  // cached and rebuilt only when the layout actually changes.
  Size? _cachedSize;
  late Shader _depthShader;
  late Shader _bezelShader;

  static const double _degToRad = math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    if (_cachedSize != size) {
      _depthShader = buildDepthShader(center, radius, colorScheme);
      _bezelShader = buildBezelShader(center, radius * 1.02, colorScheme);
      _cachedSize = size;
    }

    canvas.drawCircle(center + const Offset(0, 6), radius * 0.97, _shadowPaint);

    _facePaint.shader = _depthShader;
    canvas.drawCircle(center, radius, _facePaint);

    _bezelPaint
      ..shader = _bezelShader
      ..strokeWidth = radius * 0.03;
    canvas.drawCircle(center, radius * 0.98, _bezelPaint);

    _rimPaint
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.6)
      ..strokeWidth = radius * 0.006;
    canvas.drawCircle(center, radius * 0.9, _rimPaint);

    _tickPaint.color = colorScheme.onSurfaceVariant;
    for (var i = 0; i < 60; i++) {
      final isHour = i % 5 == 0;
      final angle = i * 6 * _degToRad;
      final dir = Offset(math.sin(angle), -math.cos(angle));
      final outer = center + dir * (radius * 0.86);
      final inner = center + dir * (radius * (isHour ? 0.74 : 0.82));
      _tickPaint.strokeWidth = radius * (isHour ? 0.022 : 0.008);
      canvas.drawLine(inner, outer, _tickPaint);
    }

    // Ease the sub-second fraction instead of sweeping at constant angular
    // velocity, so the hand has a faint breathe instead of a mechanical
    // tick-free glide.
    final secondFraction = Curves.easeInOutCubic.transform(now.millisecond / 1000);
    final seconds = now.second + secondFraction;
    final minutes = now.minute + seconds / 60;
    final hours = (now.hour % 12) + minutes / 60;

    final hourAngle = hours * 30 * _degToRad;
    final minuteAngle = minutes * 6 * _degToRad;
    final secondAngle = seconds * 6 * _degToRad;

    _hourHandPaint
      ..color = colorScheme.onSurface
      ..strokeWidth = radius * 0.045;
    canvas.drawLine(
      center,
      center + Offset(math.sin(hourAngle), -math.cos(hourAngle)) * (radius * 0.48),
      _hourHandPaint,
    );

    _minuteHandPaint
      ..color = colorScheme.onSurface
      ..strokeWidth = radius * 0.028;
    canvas.drawLine(
      center,
      center + Offset(math.sin(minuteAngle), -math.cos(minuteAngle)) * (radius * 0.7),
      _minuteHandPaint,
    );

    final secondTip =
        center + Offset(math.sin(secondAngle), -math.cos(secondAngle)) * (radius * 0.82);
    _secondGlowPaint
      ..color = colorScheme.primary.withValues(alpha: 0.55)
      ..strokeWidth = radius * 0.03;
    canvas.drawLine(center, secondTip, _secondGlowPaint);
    _secondHandPaint
      ..color = colorScheme.primary
      ..strokeWidth = radius * 0.01;
    canvas.drawLine(center, secondTip, _secondHandPaint);

    _hubPaint.color = colorScheme.primary;
    canvas.drawCircle(center, radius * 0.032, _hubPaint);
    _hubHighlightPaint.color = Colors.white.withValues(alpha: 0.5);
    canvas.drawCircle(center - Offset(radius * 0.01, radius * 0.01), radius * 0.012, _hubHighlightPaint);
  }

  @override
  bool shouldRepaint(covariant _MinimalAnalogPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme;
  }
}
