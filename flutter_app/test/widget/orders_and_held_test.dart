import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/core/theme/app_theme.dart';
import 'package:sitepyoe/data/mock/mock_products.dart';
import 'package:sitepyoe/ui/features/orders/views/order_history_screen.dart';
import 'package:sitepyoe/ui/features/pos/view_models/cart_notifier.dart';
import 'package:sitepyoe/ui/features/pos/views/pos_screen.dart';
import 'package:sitepyoe/ui/features/pos/widgets/held_orders_dialog.dart';

void main() {
  Widget buildApp(Widget child, [ProviderContainer? container]) {
    return ProviderScope(
      // ignore: deprecated_member_use
      parent: container,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: child,
      ),
    );
  }

  group('Order History & Held Items Widget Tests', () {
    testWidgets('OrderHistoryScreen renders default today date filter, KPIs, and vouchers',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp(const OrderHistoryScreen()));
      await tester.pumpAndSettle();

      // 1. Verify Header & Title
      expect(find.textContaining('အရောင်းဘောက်ချာမှတ်တမ်း'), findsOneWidget);

      // 2. Verify Date filter chips exist and Today is visible
      expect(find.text('ယနေ့ (Today)'), findsOneWidget);
      expect(find.text('မနေ့က (Yesterday)'), findsOneWidget);
      expect(find.text('ဒီတစ်ပတ် (7 Days)'), findsOneWidget);
      expect(find.text('အားလုံး (All Time)'), findsOneWidget);

      // 3. Verify KPI cards
      expect(find.text('ဘောက်ချာအရေအတွက်'), findsOneWidget);
      expect(find.text('စုစုပေါင်းအရောင်း'), findsOneWidget);
      expect(find.text('ငွေသားအရောင်း'), findsOneWidget);
      expect(find.text('ဒစ်ဂျစ်တယ် (KPay/Wave)'), findsOneWidget);
      expect(find.text('အကြွေးရောင်းရငွေ'), findsOneWidget);

      // 4. Verify Today's Seeded Vouchers (SP-20261013-1001 and 1002)
      expect(find.text('SP-20261013-1001'), findsOneWidget);
      expect(find.text('SP-20261013-1002'), findsOneWidget);
      expect(find.text('အသေးစိတ်'), findsWidgets);
      expect(find.text('ပြန်ထုတ်မည်'), findsWidgets);

      // 5. Tap Yesterday filter chip
      await tester.tap(find.text('မနေ့က (Yesterday)'));
      await tester.pumpAndSettle();

      // Today's 1001 voucher should no longer be in the filtered list
      expect(find.text('SP-20261013-1001'), findsNothing);
      // Yesterday's voucher 1004 should now be visible
      expect(find.text('SP-20261012-1004'), findsOneWidget);
    });

    testWidgets('HeldOrdersDialog renders empty state and populated state with restore action',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final container = ProviderContainer();

      // Initially empty held orders
      await tester.pumpWidget(buildApp(const Scaffold(body: Center(child: HeldOrdersDialog())), container));
      await tester.pumpAndSettle();

      expect(find.text('ဆိုင်းငံ့ထားသော အော်ဒါများ (Held Orders)'), findsOneWidget);
      expect(find.text('ဆိုင်းငံ့ထားသော အော်ဒါမရှိပါ'), findsOneWidget);

      // Add product and hold cart
      container.read(cartProvider.notifier).addItem(kMockProducts[0]);
      container.read(cartProvider.notifier).holdCurrentCart(customerName: 'Daw Mya');

      // Re-render dialog
      await tester.pumpWidget(buildApp(const Scaffold(body: Center(child: HeldOrdersDialog())), container));
      await tester.pumpAndSettle();

      expect(find.textContaining('SP-001'), findsOneWidget);
      expect(find.text('Daw Mya'), findsOneWidget);
      expect(find.text('ဆက်လက်ရောင်းမည်'), findsOneWidget);
      expect(find.text('ပယ်ဖျက်မည်'), findsOneWidget);

      container.dispose();
    });

    testWidgets('PosScreen includes Orders in Nav Rail and supports Hold action workflow',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp(const PosScreen()));
      await tester.pumpAndSettle();

      // 1. Verify Orders in Navigation Rail
      expect(find.textContaining('Orders'), findsWidgets);

      // 2. Add an item to cart
      await tester.tap(find.text('လိပ်ပြာသစ်ခွ'));
      await tester.pumpAndSettle();

      // 3. Tap Hold button
      await tester.tap(find.text('ဆိုင်းငံ့ (Hold)'));
      await tester.pumpAndSettle();

      // 4. Hold confirmation dialog should appear
      expect(find.textContaining('ဆိုင်းငံ့မည်လား'), findsOneWidget);
      expect(find.text('ဆိုင်းငံ့မည် (Hold Order)'), findsOneWidget);

      // 5. Confirm hold
      await tester.tap(find.text('ဆိုင်းငံ့မည် (Hold Order)'));
      await tester.pumpAndSettle();

      // 6. Active cart is now SP-002 and held badge appears
      expect(find.textContaining('SP-002'), findsOneWidget);
      expect(find.textContaining('ဆိုင်းငံ့ (1)'), findsWidgets);
    });
  });
}
