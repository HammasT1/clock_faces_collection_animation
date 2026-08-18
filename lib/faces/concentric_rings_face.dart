import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/clock_face.dart';
import '../core/clock_ticker.dart';

/// Face 5 — hours, minutes and seconds as three concentric sweeping arcs,
/// each a gradient stroke over a faint full-circle track, with a small glow
/// riding the leading edge of every arc.
class ConcentricRingsFace extends ClockFace {
  const ConcentricRingsFace({super.key});

  @override
  String get name => 'Concentric Rings';

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
                painter: _ConcentricRingsPainter(colorScheme: colorScheme, repaint: time),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConcentricRingsPainter extends CustomPainter {
  _ConcentricRingsPainter({required this.colorScheme, required Listenable repaint})
      : super(repaint: repaint);

  final ColorScheme colorScheme;

  final Paint _backdropPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
  final Paint _trackPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _secondPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _minutePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _hourPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _tipGlowPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _tipPaint = Paint()..style = PaintingStyle.fill;

  // The gradient sweep for each ring only depends on layout (center/radius)
  // and the fixed theme colors, so it's cached and rebuilt only on resize.
  Size? _cachedSize;
  late Shader _secondShader;
  late Shader _minuteShader;
  late Shader _hourShader;

  static const double _startAngle = -math.pi / 2; // 12 o'clock
  static const double _twoPi = math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    final strokeWidth = maxRadius * 0.09;
    final gap = maxRadius * 0.05;

    // Same sub-second ease as the analog face, so the outer (seconds) ring
    // breathes instead of sweeping at constant angular velocity.
    final secondFraction = Curves.easeInOutCubic.transform(now.millisecond / 1000);
    final seconds = now.second + secondFraction;
    final minutes = now.minute + seconds / 60;
    final hours = (now.hour % 12) + minutes / 60;

    final outerRadius = maxRadius - strokeWidth / 2;
    final middleRadius = outerRadius - strokeWidth - gap;
    final innerRadius = middleRadius - strokeWidth - gap;

    if (_cachedSize != size) {
      _secondShader = _ringShader(center, outerRadius, colorScheme.primary);
      _minuteShader = _ringShader(center, middleRadius, colorScheme.secondary);
      _hourShader = _ringShader(center, innerRadius, colorScheme.tertiary);
      _cachedSize = size;
    }

    _backdropPaint.color = colorScheme.primary.withValues(alpha: 0.08);
    canvas.drawCircle(center, innerRadius * 0.7, _backdropPaint);

    _trackPaint
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.25)
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, outerRadius, _trackPaint);
    canvas.drawCircle(center, middleRadius, _trackPaint);
    canvas.drawCircle(center, innerRadius, _trackPaint);

    _drawArc(canvas, center, outerRadius, strokeWidth, seconds / 60,
        _secondPaint..shader = _secondShader, colorScheme.primary);
    _drawArc(canvas, center, middleRadius, strokeWidth, minutes / 60,
        _minutePaint..shader = _minuteShader, colorScheme.secondary);
    _drawArc(canvas, center, innerRadius, strokeWidth, hours / 12,
        _hourPaint..shader = _hourShader, colorScheme.tertiary);
  }

  Shader _ringShader(Offset center, double radius, Color color) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    return SweepGradient(
      startAngle: 0,
      endAngle: _twoPi,
      transform: GradientRotation(_startAngle),
      colors: [color.withValues(alpha: 0.35), color],
    ).createShader(rect);
  }

  void _drawArc(
    Canvas canvas,
    Offset center,
    double radius,
    double strokeWidth,
    double progress,
    Paint paint,
    Color tipColor,
  ) {
    if (progress <= 0) return;
    paint.strokeWidth = strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = _twoPi * progress;
    canvas.drawArc(rect, _startAngle, sweep, false, paint);

    final tipAngle = _startAngle + sweep;
    final tip = center + Offset(math.cos(tipAngle), math.sin(tipAngle)) * radius;
    _tipGlowPaint.color = tipColor.withValues(alpha: 0.6);
    canvas.drawCircle(tip, strokeWidth * 0.75, _tipGlowPaint);
    _tipPaint.color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(tip, strokeWidth * 0.22, _tipPaint);
  }

  @override
  bool shouldRepaint(covariant _ConcentricRingsPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme;
  }
}
