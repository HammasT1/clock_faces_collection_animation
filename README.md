<div align="center">

# 🕰️ Clock Faces Collection

**Six hand-drawn clock faces. Zero assets. Pure `CustomPainter`.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.12-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)](#)
[![Release APK](https://github.com/HammasT1/clock_faces_collection_animation/actions/workflows/release.yml/badge.svg)](https://github.com/HammasT1/clock_faces_collection_animation/actions/workflows/release.yml)
[![Zero Assets](https://img.shields.io/badge/images%20%2F%20fonts%20%2F%20assets-zero-success)](#)

A swipeable showcase app — analog, particle, fluid, gradient, rings, and binary — where every pixel is drawn at runtime. No images, no custom fonts, no Lottie or Rive. Just `Canvas`.

</div>

<br>

## 📸 Screenshots

<!-- Add screenshots here, e.g.: -->
<!-- <p align="center">
  <img src="docs/screenshots/minimal-analog.png" width="200" />
  <img src="docs/screenshots/particle-digits.png" width="200" />
  <img src="docs/screenshots/fluid-fill.png" width="200" />
  <img src="docs/screenshots/gradient.png" width="200" />
  <img src="docs/screenshots/concentric-rings.png" width="200" />
  <img src="docs/screenshots/binary.png" width="200" />
</p> -->

*Coming soon.*

## 🎬 Demo

<!-- Add a GIF here, e.g.: -->
<!-- <p align="center">
  <img src="docs/demo.gif" width="280" />
</p> -->

*Coming soon.*

<br>

## ✨ Faces

| | Face | Description |
| :-: | --- | --- |
| 🕐 | **Minimal Analog** | Classic hour/minute/second hands with a smooth, non-ticking sweep and a subtle eased "breathe" on the second hand. |
| 🔢 | **Particle Digits** | HH:MM:SS as a 5×7 dot-matrix. On every digit change, dots tween to their new positions with overshoot and a stagger that ripples outward from the glyph's center. |
| 💧 | **Fluid Fill** | A vessel that fills through the minute, with a liquid surface built from two superimposed sine waves so it never looks like a single mechanical ripple. |
| 🌈 | **Gradient** | An ambient field whose hue, lightness, and axis continuously shift with the time of day. |
| ⭕ | **Concentric Rings** | Three sweeping arcs for hours, minutes, and seconds, each a gradient stroke with a glowing leading edge. |
| 💾 | **Binary** | HH:MM:SS as a binary dot grid, grouped by digit, with bits cross-fading smoothly on every flip. |

<br>

## 🧱 Tech Stack

| | |
| --- | --- |
| **Language** | Dart (SDK `^3.12.2`) |
| **Framework** | Flutter — no third-party packages |
| **Rendering** | `CustomPainter` + `Canvas` for every visual: circles, arcs, paths, gradients, shaders, and batched point clouds (`Canvas.drawRawPoints`) for the particle faces |
| **Timing** | A single shared `Ticker` drives all six faces; each face reads `DateTime.now()` fresh every frame instead of accumulating elapsed time, so there's no drift |
| **CI/CD** | GitHub Actions — lint, test, build, and publish release APKs automatically |

<br>

## 🏗️ Architecture

```
lib/
├── core/
│   ├── clock_ticker.dart      # app-wide Ticker + ValueNotifier<DateTime>
│   ├── clock_face.dart        # the ClockFace interface
│   └── premium_style.dart     # shared bezel/depth shader helpers
├── faces/
│   ├── minimal_analog_face.dart
│   ├── particle_digits_face.dart
│   ├── fluid_fill_face.dart
│   ├── gradient_face.dart
│   ├── concentric_rings_face.dart
│   ├── binary_face.dart
│   └── face_registry.dart     # the ordered list shown in the PageView
└── app.dart                   # swipeable shell: indicator, tap-to-advance, transitions
```

Adding a new face is one file + one line in the registry — nothing else changes.

<br>

## 🚀 Getting Started

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

Swipe left/right — or tap anywhere on a face — to cycle through the collection.

### Check it builds clean

```bash
flutter analyze
flutter test
```

### Build a release APK locally

```bash
flutter build apk --release
```

The APK lands at `build/app/outputs/flutter-apk/app-release.apk`.

### 📦 Automated releases

Pushing a version tag (`v*.*.*`) — or triggering the workflow manually from the **Actions** tab — runs [`.github/workflows/release.yml`](.github/workflows/release.yml), which lints, tests, builds the release APK, and attaches it to a GitHub Release.

```bash
git tag v1.0.1
git push origin v1.0.1
```

<br>

<div align="center">

*Built with Flutter's <code>Canvas</code> — no images, no custom fonts, no animation libraries.*

</div>
