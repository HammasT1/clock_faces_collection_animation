import '../core/clock_face.dart';
import 'binary_face.dart';
import 'concentric_rings_face.dart';
import 'fluid_fill_face.dart';
import 'gradient_face.dart';
import 'minimal_analog_face.dart';
import 'particle_digits_face.dart';

/// All faces available in the app, in swipe order.
///
/// To add a face: create a file implementing [ClockFace] and add an
/// instance here — nothing else in the app needs to change.
const List<ClockFace> kClockFaces = <ClockFace>[
  MinimalAnalogFace(),
  ParticleDigitsFace(),
  FluidFillFace(),
  GradientFace(),
  ConcentricRingsFace(),
  BinaryFace(),
];
