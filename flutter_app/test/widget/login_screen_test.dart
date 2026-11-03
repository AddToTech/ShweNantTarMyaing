import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/ui/features/auth/view_models/auth_notifier.dart';
import 'package:sitepyoe/ui/features/auth/views/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders branding, inputs, and logs in', (tester) async {
    // Set landscape tablet size
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final container = ProviderContainer();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Brand & Titles
    expect(find.text('ရွှေနံ့သာမြိုင်'), findsOneWidget);
    expect(find.text('Terminal Sign In'), findsOneWidget);
    expect(find.text('Sign In to Terminal (ဝင်ရောက်မည်)'), findsOneWidget);

    // Enter Super Admin Daw Hla credentials
    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.first, 'admin@sitepyoe.com');
    await tester.enterText(textFields.last, 'password123');
    await tester.pumpAndSettle();

    // Tap Sign In button
    final signInButton = find.text('Sign In to Terminal (ဝင်ရောက်မည်)');
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    // Check AuthState
    expect(container.read(authProvider).isAuthenticated, isTrue);
    expect(container.read(authProvider).currentUser?.name, 'Daw Hla');
  });
}
