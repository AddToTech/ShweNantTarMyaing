import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/core/theme/app_theme.dart';
import 'package:sitepyoe/ui/features/pos/views/pos_screen.dart';
import 'package:sitepyoe/ui/features/pos/widgets/payment_dialog.dart';
import 'package:sitepyoe/ui/features/pos/widgets/receipt_dialog.dart';

void main() {
  testWidgets('Full Payment Flow: Cart -> PaymentDialog -> Quick Cash -> ReceiptDialog',
      (WidgetTester tester) async {
    // 10-inch landscape tablet resolution
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const PosScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Add product to cart
    await tester.tap(find.text('လိပ်ပြာသစ်ခွ'));
    await tester.pumpAndSettle();

    // 2. Tap Checkout button
    final checkoutBtn = find.text('ငွေရှင်းမည် (Pay)');
    expect(checkoutBtn, findsOneWidget);
    await tester.tap(checkoutBtn);
    await tester.pumpAndSettle();

    // 3. Verify PaymentDialog is displayed
    expect(find.byType(PaymentDialog), findsOneWidget);
    expect(find.text('ငွေရှင်းလွှာ (Payment Checkout)'), findsOneWidget);
    expect(find.textContaining('TOTAL DUE'), findsOneWidget);
    expect(find.text('Cash (ငွေသား)'), findsOneWidget);
    expect(find.text('KPay / Wave'), findsOneWidget);
    expect(find.text('Credit (အကြွေး)'), findsOneWidget);

    // 4. Verify Quick Cash buttons
    expect(find.textContaining('အတိအကျ'), findsOneWidget);
    expect(find.text('50,000 Ks'), findsOneWidget);

    // 5. Tap Quick Cash 50,000 Ks
    await tester.tap(find.text('50,000 Ks'));
    await tester.pumpAndSettle();

    // Change Due should be 50,000 - 25,000 = 25,000 Ks
    expect(
        find.descendant(
          of: find.byType(PaymentDialog),
          matching: find.textContaining('Change Due (ပြန်အမ်းငွေ)'),
        ),
        findsOneWidget);

    // 6. Confirm Payment
    final confirmBtn = find.text('ငွေရှင်းပြီး ဘောက်ချာထုတ်မည်');
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // 7. Verify ReceiptDialog opened
    expect(find.byType(ReceiptDialog), findsOneWidget);
    expect(find.text('Thermal Receipt Preview'), findsOneWidget);
    expect(find.text('ရွှေနံ့သာမြိုင်'), findsOneWidget);
    expect(find.text('58mm'), findsOneWidget);
    expect(find.text('80mm'), findsOneWidget);
    expect(find.text('Print Thermal Receipt'), findsOneWidget);

    // 8. Close ReceiptDialog
    await tester.tap(find.text('Done / Next Order'));
    await tester.pumpAndSettle();

    // 9. Back to POS screen with empty cart
    expect(find.byType(ReceiptDialog), findsNothing);
    expect(find.text('ခြင်းတောင်းထဲတွင် ပစ္စည်းမရှိပါ'), findsOneWidget);
  });

  testWidgets('PaymentDialog switches to Credit mode and validates required fields',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const PosScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Add product & open payment
    await tester.tap(find.text('လိပ်ပြာသစ်ခွ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ငွေရှင်းမည် (Pay)'));
    await tester.pumpAndSettle();

    // Switch to Credit tab
    await tester.tap(find.text('Credit (အကြွေး)'));
    await tester.pumpAndSettle();

    // Verify customer input fields exist
    expect(find.text('Customer Name (ဝယ်ယူသူအမည်) *'), findsOneWidget);
    expect(find.text('Customer Phone (ဖုန်းနံပါတ်) *'), findsOneWidget);

    // Tap confirm without entering name -> shows snackbar error
    await tester.tap(find.text('ငွေရှင်းပြီး ဘောက်ချာထုတ်မည်'));
    await tester.pump(); // frame for snackbar
    expect(find.text('အကြွေးစနစ်အတွက် ဝယ်သူအမည်နှင့် ဖုန်းနံပါတ် ဖြည့်ရန် လိုအပ်ပါသည်!'),
        findsOneWidget);
  });
}
