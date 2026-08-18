import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/clock_face.dart';
import '../core/clock_ticker.dart';

/// Bit width of each column: H-tens, H-ones, M-tens, M-ones, S-tens, S-ones.
const List<int> _kColumnBits = <int>[2, 4, 3, 4, 3, 4];
const int _kRows = 4; // enough for the widest column (4 bits)
const double _kFadeDuration = 0.22; // seconds

class _Dot {
  _Dot({required this.col, required this.row, required this.active});

  final int col;
  final int row;
  final bool active; // false = unused bit position for this column's range

  bool on = false;
  bool fromOn = false;
  int transitionStartMicros = 0;
}

/// Face 6 — HH:MM:SS as a binary dot grid (one column per digit, MSB at
/// top). A dot cross-fades between its dim/lit states on a bit flip instead
/// of popping.
class BinaryFace extends ClockFace {
  const BinaryFace({super.key});

  @override
  String get name => 'Binary';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final time = ClockTickerProvider.of(context);
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox.expand(
          child: CustomPaint(
            painter: _BinaryPainter(colorScheme: colorScheme, repaint: time),
          ),
        ),
      ),
    );
  }
}

class _BinaryPainter extends CustomPainter {
  _BinaryPainter({required this.colorScheme, required Listenable repaint})
      : super(repaint: repaint) {
    for (var c = 0; c < _kColumnBits.length; c++) {
      final width = _kColumnBits[c];
      for (var r = 0; r < _kRows; r++) {
        _dots.add(_Dot(col: c, row: r, active: r >= _kRows - width));
      }
    }
  }

  final ColorScheme colorScheme;
  final List<_Dot> _dots = <_Dot>[];

  static const int _kMaxDots = 24; // 6 columns x 4 rows

  // Three settled-state batches (lit / dim-off / permanently-inactive),
  // reused every frame — only dots mid-fade are drawn individually so
  // their interpolated alpha can vary.
  final Float32List _onBuffer = Float32List(_kMaxDots * 2);
  final Float32List _offBuffer = Float32List(_kMaxDots * 2);
  final Float32List _inactiveBuffer = Float32List(_kMaxDots * 2);

  final Paint _panelPaint = Paint()..style = PaintingStyle.fill;
  final Paint _panelBorderPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _dividerPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _glowPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  final Paint _batchPaint = Paint()..strokeCap = StrokeCap.round;
  final Paint _singlePaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final nowMicros = now.microsecondsSinceEpoch;

    final cellSize = math.min(size.width / _kColumnBits.length, size.height / _kRows);
    final gridWidth = _kColumnBits.length * cellSize;
    final gridHeight = _kRows * cellSize;
    final originX = (size.width - gridWidth) / 2;
    final originY = (size.height - gridHeight) / 2;
    final dotRadius = cellSize * 0.28;
    final dotDiameter = dotRadius * 2;
    final panelPadding = cellSize * 0.55;

    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        originX - panelPadding,
        originY - panelPadding,
        gridWidth + panelPadding * 2,
        gridHeight + panelPadding * 2,
      ),
      Radius.circular(cellSize * 0.7),
    );
    _panelPaint.color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    canvas.drawRRect(panelRect, _panelPaint);
    _panelBorderPaint
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.35)
      ..strokeWidth = cellSize * 0.03;
    canvas.drawRRect(panelRect, _panelBorderPaint);

    // Group dividers between H | M | S pairs.
    _dividerPaint
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.25)
      ..strokeWidth = cellSize * 0.02;
    for (final col in const [2, 4]) {
      final x = originX + col * cellSize;
      canvas.drawLine(
        Offset(x, originY - panelPadding * 0.6),
        Offset(x, originY + gridHeight + panelPadding * 0.6),
        _dividerPaint,
      );
    }

    final values = <int>[
      now.hour ~/ 10,
      now.hour % 10,
      now.minute ~/ 10,
      now.minute % 10,
      now.second ~/ 10,
      now.second % 10,
    ];

    final onColor = colorScheme.primary;
    final offColor = colorScheme.outlineVariant.withValues(alpha: 0.35);
    final inactiveColor = colorScheme.outlineVariant.withValues(alpha: 0.12);

    var onCount = 0;
    var offCount = 0;
    var inactiveCount = 0;

    for (final dot in _dots) {
      final x = originX + (dot.col + 0.5) * cellSize;
      final y = originY + (dot.row + 0.5) * cellSize;

      if (!dot.active) {
        _inactiveBuffer[inactiveCount * 2] = x;
        _inactiveBuffer[inactiveCount * 2 + 1] = y;
        inactiveCount++;
        continue;
      }

      final bitPos = _kRows - 1 - dot.row;
      final newOn = ((values[dot.col] >> bitPos) & 1) == 1;
      if (newOn != dot.on) {
        dot.fromOn = dot.on;
        dot.on = newOn;
        dot.transitionStartMicros = nowMicros;
      }

      final t = ((nowMicros - dot.transitionStartMicros) / 1e6 / _kFadeDuration)
          .clamp(0.0, 1.0);

      if (t >= 1.0) {
        if (dot.on) {
          _onBuffer[onCount * 2] = x;
          _onBuffer[onCount * 2 + 1] = y;
          onCount++;
        } else {
          _offBuffer[offCount * 2] = x;
          _offBuffer[offCount * 2 + 1] = y;
          offCount++;
        }
      } else {
        final eased = Curves.easeInOut.transform(t);
        final fromColor = dot.fromOn ? onColor : offColor;
        final toColor = dot.on ? onColor : offColor;
        _singlePaint.color = Color.lerp(fromColor, toColor, eased)!;
        canvas.drawCircle(Offset(x, y), dotRadius, _singlePaint);
      }
    }

    if (onCount > 0) {
      final onPoints = Float32List.sublistView(_onBuffer, 0, onCount * 2);
      _glowPaint
        ..color = onColor.withValues(alpha: 0.55)
        ..strokeWidth = dotDiameter * 1.8;
      canvas.drawRawPoints(ui.PointMode.points, onPoints, _glowPaint);
      _batchPaint
        ..color = onColor
        ..strokeWidth = dotDiameter;
      canvas.drawRawPoints(ui.PointMode.points, onPoints, _batchPaint);
    }
    if (offCount > 0) {
      _batchPaint
        ..color = offColor
        ..strokeWidth = dotDiameter;
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.sublistView(_offBuffer, 0, offCount * 2),
        _batchPaint,
      );
    }
    if (inactiveCount > 0) {
      _batchPaint
        ..color = inactiveColor
        ..strokeWidth = dotDiameter * 0.7;
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.sublistView(_inactiveBuffer, 0, inactiveCount * 2),
        _batchPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BinaryPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme;
  }
}
