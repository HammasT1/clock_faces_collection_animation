import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/clock_face.dart';
import '../core/clock_ticker.dart';

/// 5x7 dot-matrix glyphs. '#' is a lit cell, '.' is empty.
const Map<int, List<String>> _kDigitGlyphs = <int, List<String>>{
  0: ['.###.', '#...#', '#..##', '#.#.#', '##..#', '#...#', '.###.'],
  1: ['..#..', '.##..', '..#..', '..#..', '..#..', '..#..', '.###.'],
  2: ['.###.', '#...#', '....#', '...#.', '..#..', '.#...', '#####'],
  3: ['.###.', '#...#', '....#', '..##.', '....#', '#...#', '.###.'],
  4: ['...#.', '..##.', '.#.#.', '#..#.', '#####', '...#.', '...#.'],
  5: ['#####', '#....', '####.', '....#', '....#', '#...#', '.###.'],
  6: ['..##.', '.#...', '#....', '####.', '#...#', '#...#', '.###.'],
  7: ['#####', '....#', '...#.', '..#..', '.#...', '.#...', '.#...'],
  8: ['.###.', '#...#', '#...#', '.###.', '#...#', '#...#', '.###.'],
  9: ['.###.', '#...#', '#...#', '.####', '....#', '...#.', '.###.'],
};

const int _kCols = 5;
const int _kRows = 7;
const Offset _kGlyphCenter = Offset(2.0, 3.0);
const double _kGlyphMaxDist = 3.6055512754639892; // distance to a corner

const double _kMoveDuration = 0.22; // seconds, per-particle tween
const double _kMaxStagger = 0.12; // seconds, spread across a glyph

enum _Kind { move, spawn, despawn }

class _Particle {
  _Particle({
    required this.from,
    required this.to,
    required this.kind,
    required this.delay,
  });

  final Offset from;
  final Offset to;
  final _Kind kind;
  final double delay;
}

/// One H/M/S digit or a colon separator. Digit slots morph their dot
/// pattern via [_Particle] tweens; colon slots are static.
class _Slot {
  _Slot({required this.isColon, required this.colOffset, required this.colWidth});

  final bool isColon;
  final double colOffset; // left edge, in grid-column units
  final double colWidth; // in grid-column units

  int digit = -1; // -1 forces an initial "assemble" transition
  List<_Particle> particles = <_Particle>[];
  int transitionStartMicros = 0;
}

double _staggerDelay(Offset localTarget) {
  final d = (localTarget - _kGlyphCenter).distance;
  return (d / _kGlyphMaxDist) * _kMaxStagger;
}

int _nearestIndex(List<Offset> points, Offset target) {
  var best = 0;
  var bestDist = double.infinity;
  for (var i = 0; i < points.length; i++) {
    final d = (points[i] - target).distanceSquared;
    if (d < bestDist) {
      bestDist = d;
      best = i;
    }
  }
  return best;
}

/// Every cell of a 5x7 glyph, used to paint a dim always-on backdrop grid
/// (an "unlit LED" look) behind the animated digits.
List<Offset> _buildTrackCells() {
  final cells = <Offset>[];
  for (var r = 0; r < _kRows; r++) {
    for (var c = 0; c < _kCols; c++) {
      cells.add(Offset(c.toDouble(), r.toDouble()));
    }
  }
  return cells;
}

List<Offset> _glyphCells(int digit) {
  final rows = _kDigitGlyphs[digit]!;
  final cells = <Offset>[];
  for (var r = 0; r < _kRows; r++) {
    for (var c = 0; c < _kCols; c++) {
      if (rows[r][c] == '#') cells.add(Offset(c.toDouble(), r.toDouble()));
    }
  }
  return cells;
}

/// Greedy nearest-neighbor pairing between the old on-cells and the new
/// on-cells, so particles glide to the closest matching dot in the new
/// glyph instead of jumping by raw index. Only runs on a digit change
/// (at most once a second for the seconds slot), so allocating here is
/// fine — it never happens in the steady per-frame paint path.
List<_Particle> _planTransition(List<Offset> from, List<Offset> to) {
  final n = from.length;
  final m = to.length;
  final assigned = List<int>.filled(m, -1);
  final usedFrom = List<bool>.filled(n, false);

  if (n > 0 && m > 0) {
    final pairs = <(int, int, double)>[];
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < m; j++) {
        pairs.add((i, j, (from[i] - to[j]).distanceSquared));
      }
    }
    pairs.sort((a, b) => a.$3.compareTo(b.$3));
    var remaining = math.min(n, m);
    for (final (i, j, _) in pairs) {
      if (remaining == 0) break;
      if (usedFrom[i] || assigned[j] != -1) continue;
      usedFrom[i] = true;
      assigned[j] = i;
      remaining--;
    }
  }

  final particles = <_Particle>[];
  for (var j = 0; j < m; j++) {
    if (assigned[j] != -1) {
      particles.add(_Particle(
        from: from[assigned[j]],
        to: to[j],
        kind: _Kind.move,
        delay: _staggerDelay(to[j]),
      ));
    } else {
      final origin = from.isNotEmpty ? from[_nearestIndex(from, to[j])] : _kGlyphCenter;
      particles.add(_Particle(
        from: origin,
        to: to[j],
        kind: _Kind.spawn,
        delay: _staggerDelay(to[j]),
      ));
    }
  }
  for (var i = 0; i < n; i++) {
    if (!usedFrom[i]) {
      final target = to.isNotEmpty ? to[_nearestIndex(to, from[i])] : _kGlyphCenter;
      particles.add(_Particle(
        from: from[i],
        to: target,
        kind: _Kind.despawn,
        delay: _staggerDelay(from[i]),
      ));
    }
  }
  return particles;
}

/// Face 2 — HH:MM:SS rendered as hardcoded 5x7 dot-matrix digits. When a
/// digit changes, its dots tween to the new glyph's dots with a per-particle
/// delay (staggered outward from the glyph's center) and a slight overshoot.
class ParticleDigitsFace extends ClockFace {
  const ParticleDigitsFace({super.key});

  @override
  String get name => 'Particle Digits';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final time = ClockTickerProvider.of(context);
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox.expand(
          child: CustomPaint(
            painter: _ParticleDigitsPainter(colorScheme: colorScheme, repaint: time),
          ),
        ),
      ),
    );
  }
}

class _ParticleDigitsPainter extends CustomPainter {
  _ParticleDigitsPainter({required this.colorScheme, required Listenable repaint})
      : super(repaint: repaint) {
    var col = 0.0;
    for (var i = 0; i < _slots.length; i++) {
      final isColon = i == 2 || i == 5;
      final width = isColon ? 1.0 : _kCols.toDouble();
      _slots[i] = _Slot(isColon: isColon, colOffset: col, colWidth: width);
      col += width + 1.0; // 1 column of gap after every slot
    }
    _totalCols = col - 1.0;

    // Colon dots never move: build their static particles once.
    for (final slot in _slots) {
      if (slot.isColon) {
        for (final row in const [2.0, 4.0]) {
          final p = Offset(0.0, row);
          slot.particles.add(_Particle(from: p, to: p, kind: _Kind.move, delay: 0));
        }
        slot.digit = 0; // any non-negative sentinel: never re-triggers
      }
    }
  }

  final ColorScheme colorScheme;

  static const int _slotCount = 8; // H H : M M : S S
  final List<_Slot> _slots = List<_Slot>.filled(_slotCount, _Slot(isColon: false, colOffset: 0, colWidth: 0));
  late double _totalCols;

  // Reused every frame: capacity generously covers every slot fully lit.
  static const int _kMaxBatchPoints = _slotCount * (_kCols * _kRows);
  final Float32List _pointBuffer = Float32List(_kMaxBatchPoints * 2);

  // Dim "unlit LED" cells drawn behind every digit slot, once per frame.
  static final List<Offset> _trackCells = _buildTrackCells();
  final Float32List _trackBuffer = Float32List(_kMaxBatchPoints * 2);

  final Paint _panelPaint = Paint()..style = PaintingStyle.fill;
  final Paint _panelBorderPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _trackPaint = Paint()..strokeCap = StrokeCap.round;
  final Paint _dotGlowPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  final Paint _dotBatchPaint = Paint()..strokeCap = StrokeCap.round;
  final Paint _dotSinglePaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final nowMicros = now.microsecondsSinceEpoch;

    final cellSize = math.min(size.width / _totalCols, size.height / _kRows);
    final gridWidth = _totalCols * cellSize;
    final gridHeight = _kRows * cellSize;
    final originX = (size.width - gridWidth) / 2;
    final originY = (size.height - gridHeight) / 2;
    final dotRadius = cellSize * 0.32;
    final panelPadding = cellSize * 0.6;

    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        originX - panelPadding,
        originY - panelPadding,
        gridWidth + panelPadding * 2,
        gridHeight + panelPadding * 2,
      ),
      Radius.circular(cellSize * 0.9),
    );
    _panelPaint.color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    canvas.drawRRect(panelRect, _panelPaint);
    _panelBorderPaint
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.35)
      ..strokeWidth = cellSize * 0.03;
    canvas.drawRRect(panelRect, _panelBorderPaint);

    var trackCount = 0;
    for (final slot in _slots) {
      if (slot.isColon) continue;
      final slotOriginX = originX + slot.colOffset * cellSize;
      for (final cell in _trackCells) {
        _trackBuffer[trackCount * 2] = slotOriginX + (cell.dx + 0.5) * cellSize;
        _trackBuffer[trackCount * 2 + 1] = originY + (cell.dy + 0.5) * cellSize;
        trackCount++;
      }
    }
    _trackPaint
      ..color = colorScheme.onSurface.withValues(alpha: 0.06)
      ..strokeWidth = dotRadius * 2 * 0.7;
    canvas.drawRawPoints(
      ui.PointMode.points,
      Float32List.sublistView(_trackBuffer, 0, trackCount * 2),
      _trackPaint,
    );

    _updateDigits(now, nowMicros);

    var batchCount = 0;
    final baseColor = colorScheme.primary;

    for (final slot in _slots) {
      final slotOriginX = originX + slot.colOffset * cellSize;
      List<_Particle>? keep;
      for (var i = 0; i < slot.particles.length; i++) {
        final particle = slot.particles[i];
        final elapsed = (nowMicros - slot.transitionStartMicros) / 1e6 - particle.delay;
        final t = (elapsed / _kMoveDuration).clamp(0.0, 1.0);

        if (particle.kind == _Kind.despawn && t >= 1.0) {
          keep ??= slot.particles.sublist(0, i);
          continue;
        }
        keep?.add(particle);

        final posT = Curves.easeOutBack.transform(t);
        final localX = particle.from.dx + (particle.to.dx - particle.from.dx) * posT;
        final localY = particle.from.dy + (particle.to.dy - particle.from.dy) * posT;
        final x = slotOriginX + (localX + 0.5) * cellSize;
        final y = originY + (localY + 0.5) * cellSize;

        double alpha;
        bool batchable;
        switch (particle.kind) {
          case _Kind.move:
            alpha = 1.0;
            batchable = true;
          case _Kind.spawn:
            if (t >= 1.0) {
              alpha = 1.0;
              batchable = true;
            } else {
              alpha = Curves.easeOut.transform(t);
              batchable = false;
            }
          case _Kind.despawn:
            alpha = 1.0 - Curves.easeIn.transform(t);
            batchable = false;
        }

        if (batchable) {
          _pointBuffer[batchCount * 2] = x;
          _pointBuffer[batchCount * 2 + 1] = y;
          batchCount++;
        } else {
          _dotSinglePaint.color = baseColor.withValues(alpha: alpha);
          canvas.drawCircle(Offset(x, y), dotRadius, _dotSinglePaint);
        }
      }
      if (keep != null) slot.particles = keep;
    }

    if (batchCount > 0) {
      final points = Float32List.sublistView(_pointBuffer, 0, batchCount * 2);
      _dotGlowPaint
        ..color = baseColor.withValues(alpha: 0.5)
        ..strokeWidth = dotRadius * 3.4;
      canvas.drawRawPoints(ui.PointMode.points, points, _dotGlowPaint);
      _dotBatchPaint
        ..color = baseColor
        ..strokeWidth = dotRadius * 2;
      canvas.drawRawPoints(ui.PointMode.points, points, _dotBatchPaint);
    }
  }

  void _updateDigits(DateTime now, int nowMicros) {
    final values = <int>[
      now.hour ~/ 10,
      now.hour % 10,
      now.minute ~/ 10,
      now.minute % 10,
      now.second ~/ 10,
      now.second % 10,
    ];
    var digitSlot = 0;
    for (final slot in _slots) {
      if (slot.isColon) continue;
      final value = values[digitSlot++];
      if (slot.digit != value) {
        final from = <Offset>[
          for (final p in slot.particles)
            if (p.kind != _Kind.despawn) _currentLocal(slot, p, nowMicros),
        ];
        slot.particles = _planTransition(from, _glyphCells(value));
        slot.digit = value;
        slot.transitionStartMicros = nowMicros;
      }
    }
  }

  Offset _currentLocal(_Slot slot, _Particle particle, int nowMicros) {
    final elapsed = (nowMicros - slot.transitionStartMicros) / 1e6 - particle.delay;
    final t = (elapsed / _kMoveDuration).clamp(0.0, 1.0);
    final posT = Curves.easeOutBack.transform(t);
    return Offset(
      particle.from.dx + (particle.to.dx - particle.from.dx) * posT,
      particle.from.dy + (particle.to.dy - particle.from.dy) * posT,
    );
  }

  @override
  bool shouldRepaint(covariant _ParticleDigitsPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme;
  }
}
