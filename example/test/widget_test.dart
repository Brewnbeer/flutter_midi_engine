import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_midi_engine'),
      (call) async => call.method == 'loadSoundfont' ? true : null,
    );
  });

  testWidgets('shows the piano after loading', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Instrument'), findsOneWidget);
    expect(find.text('C4'), findsOneWidget);
  });
}
