import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Notifies listeners with the current wall-clock time.
///
/// Faces never accumulate elapsed ticks on their own — they always read
/// [ClockTime.value] (which is exactly `DateTime.now()` as of the last
/// tick) so rounding error can never compound across frames.
class ClockTime extends ValueNotifier<DateTime> {
  ClockTime() : super(DateTime.now());
}

/// Drives a single [Ticker] for the whole app and exposes the resulting
/// [ClockTime] to descendants. Every face listens to the same notifier
/// instead of running its own ticker/AnimationController.
class ClockTickerProvider extends StatefulWidget {
  const ClockTickerProvider({super.key, required this.child});

  final Widget child;

  static ClockTime of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_ClockTimeScope>();
    assert(scope != null, 'No ClockTickerProvider found in context');
    return scope!.time;
  }

  @override
  State<ClockTickerProvider> createState() => _ClockTickerProviderState();
}

class _ClockTickerProviderState extends State<ClockTickerProvider>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ClockTime _time = ClockTime();
  DateTime _lastEmitted = DateTime.fromMillisecondsSinceEpoch(0);
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  void _onTick(Duration elapsed) {
    final now = DateTime.now();
    if (_reduceMotion) {
      // Skip the continuous sweep: only step once a whole second has
      // passed, so hands jump instead of animating.
      if (now.difference(_lastEmitted).inMilliseconds < 1000) return;
    }
    _lastEmitted = now;
    _time.value = now;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ClockTimeScope(time: _time, child: widget.child);
  }
}

class _ClockTimeScope extends InheritedWidget {
  const _ClockTimeScope({required this.time, required super.child});

  final ClockTime time;

  @override
  bool updateShouldNotify(_ClockTimeScope oldWidget) => oldWidget.time != time;
}
