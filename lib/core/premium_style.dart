import 'package:flutter/material.dart';

/// A brushed-metal sweep used as a bezel ring on the circular faces, so
/// they share one consistent premium finish instead of each inventing
/// its own rim treatment.
Shader buildBezelShader(Offset center, double radius, ColorScheme colorScheme) {
  final rect = Rect.fromCircle(center: center, radius: radius);
  return SweepGradient(
    colors: [
      colorScheme.outlineVariant,
      colorScheme.surfaceContainerHighest,
      colorScheme.primary.withValues(alpha: 0.55),
      colorScheme.surfaceContainerHighest,
      colorScheme.outlineVariant,
    ],
    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
  ).createShader(rect);
}

/// A soft radial glow used behind a face's primary surface for a bit of
/// depth instead of a flat fill.
Shader buildDepthShader(Offset center, double radius, ColorScheme colorScheme) {
  final rect = Rect.fromCircle(center: center, radius: radius);
  return RadialGradient(
    center: const Alignment(-0.3, -0.35),
    radius: 1.05,
    colors: [
      Color.lerp(colorScheme.surfaceContainerHighest, colorScheme.primary, 0.06)!,
      colorScheme.surfaceContainerHighest,
      Color.lerp(colorScheme.surfaceContainerHighest, Colors.black, 0.25)!,
    ],
    stops: const [0.0, 0.6, 1.0],
  ).createShader(rect);
}
