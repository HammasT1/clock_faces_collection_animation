import 'package:flutter/widgets.dart';

/// Contract every clock face implements.
///
/// A face is just a [StatelessWidget] with a display [name]. Adding a new
/// face to the app means creating one file with a class that extends this,
/// then adding an instance to the registry in `faces/face_registry.dart`.
///
/// Implementations should:
///  - read time via `ClockTickerProvider.of(context)` and pass it as the
///    `repaint` listenable to a [CustomPainter], never store their own
///    ticker or accumulate elapsed time.
///  - wrap their painted content in a [RepaintBoundary] so repainting one
///    face never dirties the others.
abstract class ClockFace extends StatelessWidget {
  const ClockFace({super.key});

  /// Short label shown in the face indicator / navigation.
  String get name;
}
