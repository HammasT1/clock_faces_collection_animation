import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/clock_face.dart';
import '../core/clock_ticker.dart';
import '../core/premium_style.dart';

/// Face 3 — a circular vessel that fills through the minute, with a wavy
/// surface made of two superimposed sine waves (different frequency,
/// amplitude and drift direction) so it never reads as a single regular
/// ripple.
class FluidFillFace extends ClockFace {
  const FluidFillFace({super.key});

  @override
  String get name => 'Fluid Fill';

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
                painter: _FluidFillPainter(colorScheme: colorScheme, repaint: time),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FluidFillPainter extends CustomPainter {
  _FluidFillPainter({required this.colorScheme, required Listenable repaint})
      : super(repaint: repaint);

  final ColorScheme colorScheme;

  final Paint _shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.35)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
  final Paint _vesselPaint = Paint()..style = PaintingStyle.fill;
  final Paint _bezelPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _rimPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _liquidPaint = Paint()..style = PaintingStyle.fill;
  final Paint _surfaceLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _glassHighlightPaint = Paint()..style = PaintingStyle.fill;
  final Path _clipPath = Path();
  final Path _wavePath = Path();
  final Path _surfacePath = Path();

  // Cached shaders: only depend on size, not on the animated waterline.
  Size? _cachedSize;
  late Shader _vesselShader;
  late Shader _bezelShader;

  static const double _twoPi = math.pi * 2;

  // Primary swell: slow, broad.
  static const double _wave1Length = 1.0; // fraction of vessel width
  static const double _wave1SpeedHz = 0.18;
  static const double _wave1AmpFactor = 0.03; // fraction of radius

  // Secondary ripple: faster, tighter, drifting the other way — breaks up
  // the periodicity of wave 1 so the surface reads as liquid, not a sine
  // plotter.
  static const double _wave2Length = 0.62;
  static const double _wave2SpeedHz = -0.27;
  static const double _wave2AmpFactor = 0.014;

  static const int _steps = 48;

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final radius = size.shortestSide / 2;
    final center = size.center(Offset.zero);

    if (_cachedSize != size) {
      _vesselShader = buildDepthShader(center, radius, colorScheme);
      _bezelShader = buildBezelShader(center, radius * 1.02, colorScheme);
      _cachedSize = size;
    }

    canvas.drawCircle(center + const Offset(0, 6), radius * 0.97, _shadowPaint);

    _vesselPaint.shader = _vesselShader;
    canvas.drawCircle(center, radius, _vesselPaint);

    final secondsIntoMinute = now.second + now.millisecond / 1000;
    final level = secondsIntoMinute / 60; // rises continuously through the minute

    final top = center.dy - radius;
    final bottom = center.dy + radius;
    final surfaceY = bottom - level * (bottom - top);

    final t = now.millisecondsSinceEpoch / 1000;
    final amp1 = radius * _wave1AmpFactor;
    final amp2 = radius * _wave2AmpFactor;
    final width = radius * 2;
    final left = center.dx - radius;

    _surfacePath.reset();
    _wavePath.reset();
    for (var i = 0; i <= _steps; i++) {
      final fx = i / _steps;
      final x = left + fx * width;
      final y = surfaceY +
          amp1 * math.sin(_twoPi * (fx / _wave1Length + t * _wave1SpeedHz)) +
          amp2 * math.sin(_twoPi * (fx / _wave2Length + t * _wave2SpeedHz));
      if (i == 0) {
        _wavePath.moveTo(x, y);
        _surfacePath.moveTo(x, y);
      } else {
        _wavePath.lineTo(x, y);
        _surfacePath.lineTo(x, y);
      }
    }
    _wavePath.lineTo(left + width, bottom + radius);
    _wavePath.lineTo(left, bottom + radius);
    _wavePath.close();

    _clipPath.reset();
    _clipPath.addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.save();
    canvas.clipPath(_clipPath);

    final liquidRect = Rect.fromLTRB(left, top, left + width, bottom + radius);
    _liquidPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(colorScheme.primary, Colors.white, 0.22)!,
        colorScheme.primary,
        Color.lerp(colorScheme.primary, Colors.black, 0.35)!,
      ],
      stops: const [0.0, 0.35, 1.0],
    ).createShader(liquidRect);
    canvas.drawPath(_wavePath, _liquidPaint);

    // A bright crest line along the wave, so the surface reads as liquid
    // rather than a flat-shaded fill.
    _surfaceLinePaint
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = radius * 0.012;
    canvas.drawPath(_surfacePath, _surfaceLinePaint);

    canvas.restore();

    // A soft glass specular highlight, upper-left, ignoring the liquid.
    canvas.save();
    canvas.clipPath(_clipPath);
    _glassHighlightPaint.shader = RadialGradient(
      colors: [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0.0)],
    ).createShader(Rect.fromCircle(center: center + Offset(-radius * 0.35, -radius * 0.4), radius: radius * 0.6));
    canvas.drawCircle(center + Offset(-radius * 0.35, -radius * 0.4), radius * 0.6, _glassHighlightPaint);
    canvas.restore();

    _bezelPaint
      ..shader = _bezelShader
      ..strokeWidth = radius * 0.025;
    canvas.drawCircle(center, radius * 0.99, _bezelPaint);

    _rimPaint
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.5)
      ..strokeWidth = radius * 0.008;
    canvas.drawCircle(center, radius * 0.9, _rimPaint);
  }

  @override
  bool shouldRepaint(covariant _FluidFillPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme;
  }
}
