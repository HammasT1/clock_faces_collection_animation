import 'package:flutter_test/flutter_test.dart';

import 'package:clock_faces_collection/app.dart';
import 'package:clock_faces_collection/faces/face_registry.dart';

void main() {
  testWidgets('renders the first face by name', (WidgetTester tester) async {
    await tester.pumpWidget(const ClockFacesApp());
    await tester.pump();

    expect(find.text(kClockFaces.first.name.toUpperCase()), findsOneWidget);
  });
}
