# Clock Faces Collection

A Flutter showcase of six hand-drawn clock faces — analog, particle, fluid, gradient, rings, and binary — swipeable in one app. Every visual is drawn at runtime with `CustomPainter`; there are **zero image, font, or animation-library assets** in the project.

## Screenshots

<!-- Add screenshots here, e.g.: -->
<!-- <p align="center">
  <img src="docs/screenshots/minimal-analog.png" width="220" />
  <img src="docs/screenshots/particle-digits.png" width="220" />
  <img src="docs/screenshots/fluid-fill.png" width="220" />
</p> -->

## Demo

<!-- Add a GIF here, e.g.: -->
<!-- <p align="center">
  <img src="docs/demo.gif" width="280" />
</p> -->

## Faces

| Face | Description |
| --- | --- |
| **Minimal Analog** | Classic hour/minute/second hands with a smooth, non-ticking sweep and a subtle eased "breathe" on the second hand. |
| **Particle Digits** | HH:MM:SS as a 5×7 dot-matrix. On every digit change, dots tween to their new positions with overshoot and a stagger that ripples outward from the glyph's center. |
| **Fluid Fill** | A vessel that fills through the minute, with a liquid surface built from two superimposed sine waves so it never looks like a single mechanical ripple. |
| **Gradient** | An ambient field whose hue, lightness, and axis continuously shift with the time of day. |
| **Concentric Rings** | Three sweeping arcs for hours, minutes, and seconds, each a gradient stroke with a glowing leading edge. |
| **Binary** | HH:MM:SS as a binary dot grid, grouped by digit, with bits cross-fading smoothly on every flip. |

## Tech Stack

- **[Flutter](https://flutter.dev)** / **Dart** (SDK `^3.12.2`) — no third-party packages; the entire UI is Flutter's SDK plus `CustomPainter`.
- **`CustomPainter` + `Canvas`** for every visual — circles, arcs, paths, gradients, shaders, and batched point clouds (`Canvas.drawRawPoints`) for the particle faces.
- **A single shared `Ticker`** drives all six faces; each face reads `DateTime.now()` fresh every frame instead of accumulating elapsed time, so there's no drift.
- **GitHub Actions** for CI (`flutter analyze` + `flutter test`) and building/publishing signed-with-debug-key release APKs.

## Architecture

- `lib/core/clock_ticker.dart` — the app-wide `Ticker` and the `ValueNotifier<DateTime>` every face listens to.
- `lib/core/clock_face.dart` — the `ClockFace` interface. Adding a new face means creating one file and registering it.
- `lib/faces/` — one file per face, each a `RepaintBoundary` + `CustomPainter` pair.
- `lib/faces/face_registry.dart` — the ordered list of faces shown in the `PageView`.
- `lib/app.dart` — the swipeable shell (page indicator, tap-to-advance, transitions).

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- A connected device, emulator, or simulator — or a desktop/web target enabled in your Flutter install

### Run it

```bash
git clone https://github.com/HammasT1/clock_faces_collection_animation.git
cd clock_faces_collection_animation
flutter pub get
flutter run
```

Swipe left/right (or tap anywhere on a face) to cycle through the collection.

### Check it builds clean

```bash
flutter analyze
flutter test
```

### Build a release APK locally

```bash
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

### Automated releases

Pushing a version tag (`v*.*.*`) — or triggering the workflow manually from the **Actions** tab — runs [`.github/workflows/release.yml`](.github/workflows/release.yml), which lints, tests, builds the release APK, and attaches it to a GitHub Release.

```bash
git tag v1.0.1
git push origin v1.0.1
```
