import 'package:flutter/material.dart';

import 'core/clock_ticker.dart';
import 'faces/face_registry.dart';

class ClockFacesApp extends StatelessWidget {
  const ClockFacesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clock Faces Collection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      home: const ClockTickerProvider(child: FacesPageView()),
    );
  }
}

class FacesPageView extends StatefulWidget {
  const FacesPageView({super.key});

  @override
  State<FacesPageView> createState() => _FacesPageViewState();
}

class _FacesPageViewState extends State<FacesPageView> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration _motionDuration(BuildContext context, Duration normal) {
    return MediaQuery.of(context).disableAnimations ? Duration.zero : normal;
  }

  void _advance() {
    final next = (_index + 1) % kClockFaces.length;
    _controller.animateToPage(
      next,
      duration: _motionDuration(context, const Duration(milliseconds: 280)),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.4,
            colors: [
              Color.lerp(colorScheme.surface, colorScheme.primary, 0.05)!,
              colorScheme.surface,
              Color.lerp(colorScheme.surface, Colors.black, 0.3)!,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _advance,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: kClockFaces.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          var page = _index.toDouble();
                          if (_controller.hasClients && _controller.position.haveDimensions) {
                            page = _controller.page ?? page;
                          }
                          final delta = (page - i).abs().clamp(0.0, 1.0);
                          return Opacity(
                            opacity: 1 - delta * 0.45,
                            child: Transform.scale(
                              scale: 1 - delta * 0.06,
                              child: child,
                            ),
                          );
                        },
                        child: kClockFaces[i],
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: _motionDuration(
                        context,
                        const Duration(milliseconds: 200),
                      ),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: Text(
                        kClockFaces[_index].name.toUpperCase(),
                        key: ValueKey(kClockFaces[_index].name),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(kClockFaces.length, (i) {
                        final active = i == _index;
                        return AnimatedContainer(
                          duration: _motionDuration(
                            context,
                            const Duration(milliseconds: 200),
                          ),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active
                                ? colorScheme.primary
                                : colorScheme.outlineVariant.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(alpha: 0.55),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
