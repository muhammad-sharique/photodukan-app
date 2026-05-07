import 'package:flutter_test/flutter_test.dart';

import 'package:photodukan_app/src/app.dart';
import 'package:photodukan_app/src/services/firebase_bootstrap.dart';

void main() {
  testWidgets('shows setup guidance when firebase bootstrap is not ready', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      PhotoDukanApp(
        bootstrap: _FakeFirebaseBootstrap(),
      ),
    );
    await tester.pump();

    expect(find.text('Setup needed'), findsOneWidget);
    expect(find.textContaining('Firebase bootstrap failed'), findsOneWidget);
  });
}

class _FakeFirebaseBootstrap extends FirebaseBootstrap {
  @override
  Future<FirebaseBootstrapResult> initialize() {
    return Future.value(
      const FirebaseBootstrapResult(
        isConfigured: true,
        isReady: false,
        message: 'Firebase bootstrap failed.',
      ),
    );
  }
}
