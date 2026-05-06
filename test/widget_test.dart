import 'package:flutter_test/flutter_test.dart';

import 'package:photodukan_app/src/app.dart';
import 'package:photodukan_app/src/services/firebase_bootstrap.dart';

void main() {
  testWidgets('shows setup guidance when firebase is not configured', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      PhotoDukanApp(
        bootstrap: _FakeFirebaseBootstrap(),
      ),
    );
    await tester.pump();

    expect(find.text('Firebase setup required'), findsOneWidget);
    expect(find.textContaining('Missing Firebase dart-defines'), findsOneWidget);
  });
}

class _FakeFirebaseBootstrap extends FirebaseBootstrap {
  @override
  Future<FirebaseBootstrapResult> initialize() {
    return Future.value(
      const FirebaseBootstrapResult(
        isConfigured: false,
        isReady: false,
        message: 'Missing Firebase dart-defines.',
      ),
    );
  }
}
