import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/ui/features/auth/view_models/auth_notifier.dart';
import 'package:sitepyoe/ui/features/auth/views/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders branding, inputs, demo accounts, and logs in', (tester) async {
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
    expect(find.text('SitePyoe'), findsOneWidget);
    expect(find.text('Terminal Sign In'), findsOneWidget);
    expect(find.text('Sign In to Terminal (ဝင်ရောက်မည်)'), findsOneWidget);

    // Verify Default Super Admin credentials prefilled
    expect(find.text('admin@sitepyoe.com'), findsOneWidget);

    // Tap demo chip for Manager U Thant
    final managerChip = find.text('U Thant Zin (Branch)');
    expect(managerChip, findsOneWidget);
    await tester.tap(managerChip);
    await tester.pumpAndSettle();

    // Verify input changed to manager.a@sitepyoe.com
    expect(find.text('manager.a@sitepyoe.com'), findsOneWidget);

    // Tap demo chip for Super Admin Daw Hla
    final adminChip = find.text('Daw Hla (Super)');
    expect(adminChip, findsOneWidget);
    await tester.tap(adminChip);
    await tester.pumpAndSettle();
    expect(find.text('admin@sitepyoe.com'), findsOneWidget);

    // Tap Sign In button
    final signInButton = find.text('Sign In to Terminal (ဝင်ရောက်မည်)');
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    // Check AuthState
    expect(container.read(authProvider).isAuthenticated, isTrue);
    expect(container.read(authProvider).currentUser?.name, 'Daw Hla');
  });
}
