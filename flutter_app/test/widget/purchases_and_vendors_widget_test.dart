import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/core/theme/app_theme.dart';
import 'package:sitepyoe/ui/features/pos/views/pos_screen.dart';
import 'package:sitepyoe/ui/features/purchases/views/purchase_screen.dart';
import 'package:sitepyoe/ui/features/purchases/views/vendor_management_screen.dart';
import 'package:sitepyoe/ui/features/purchases/view_models/purchase_notifier.dart';

void main() {
  group('PurchaseScreen Widget Tests', () {
    testWidgets('PurchaseScreen renders 2-tab layout and switches tabs',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: PurchaseScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify header
      expect(find.text('အဝယ်စာရင်း — Purchases / Stock-In'), findsOneWidget);

      // 2. Verify both tabs exist
      expect(find.text('ဝယ်ယူမှု သစ်'), findsOneWidget);
      expect(find.text('မှတ်တမ်း'), findsOneWidget);

      // 3. In Tab 0, verify vendor dropdown hint and product selector are present
      expect(find.text('ကုန်သည် (Vendor) ရွေးချယ်ပါ'), findsOneWidget);
      expect(find.text('+ အသစ်'), findsOneWidget);

      // 4. Switch to Tab 1 (မှတ်တမ်း)
      await tester.tap(find.text('မှတ်တမ်း'));
      await tester.pumpAndSettle();

      // 5. Verify Tab 1 is active (search field / filter)
      expect(find.text('ဘောင်ချာ နံပါတ် / ကုန်သည် ရှာဖွေ...'), findsOneWidget);
    });

    testWidgets('PurchaseDetailDialog allows settling credit payment to fully paid status',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Pre-populate a credit purchase of 30,000 MMK
      container.read(purchaseProvider.notifier).submitPurchase(
        branchId: 'branch_a',
        vendorId: 'v001',
        vendorName: 'ကိုကိုမြိုင် သစ်ပင်ကုန်သည်',
        purchaseDate: DateTime(2026, 10, 15),
        items: const [
          PurchaseItem(
            productId: 'p001',
            productName: 'Rose Bush',
            quantity: 3,
            unitCost: 10000,
          ),
        ],
        discount: 0,
        paidAmount: 0,
        paymentStatus: PurchasePaymentStatus.unpaid,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: PurchaseScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Switch to 'မှတ်တမ်း' tab
      await tester.tap(find.text('မှတ်တမ်း'));
      await tester.pumpAndSettle();

      // 2. Locate and tap on the purchase row to view details
      expect(find.text('ကိုကိုမြိုင် သစ်ပင်ကုန်သည်'), findsWidgets);
      await tester.tap(find.text('ကိုကိုမြိုင် သစ်ပင်ကုန်သည်').first);
      await tester.pumpAndSettle();

      // 3. Verify PurchaseDetailDialog is open and shows outstanding debt
      expect(find.text('ပေးချေရန် ကြွေးကျန် (Outstanding Balance)'), findsOneWidget);
      expect(find.text('30,000 Ks ကျန်ရှိပါသည်'), findsOneWidget);
      expect(find.text('ငွေချေမည် (Make Payment)'), findsOneWidget);

      // 4. Tap 'ငွေချေမည် (Make Payment)' button
      await tester.tap(find.text('ငွေချေမည် (Make Payment)'));
      await tester.pumpAndSettle();

      // 5. Verify Settle Payment Dialog opens with pre-filled 30,000 balance
      expect(find.text('ကြွေးကျန် ပေးချေလွှာ (Settle Purchase Payment)'), findsOneWidget);
      expect(find.text('အတည်ပြု ပေးချေမည် (Confirm Payment)'), findsOneWidget);

      // 6. Tap 'အတည်ပြု ပေးချေမည်' to settle full amount
      await tester.tap(find.text('အတည်ပြု ပေးချေမည် (Confirm Payment)'));
      await tester.pumpAndSettle();

      // 7. Verify the PurchaseDetailDialog reactively updates to Fully Paid!
      expect(find.text('ဤဘောင်ချာအတွက် ငွေအကြေ ပေးချေပြီးဖြစ်ပါသည် (Fully Paid)'), findsOneWidget);
      expect(find.text('ငွေချေမည် (Make Payment)'), findsNothing);
    });
  });

  group('VendorManagementScreen Widget Tests', () {
    testWidgets('VendorManagementScreen renders vendor list and opens Add Vendor dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: VendorManagementScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify header
      expect(find.text('ကုန်သည်များ — Vendors / Suppliers'), findsOneWidget);

      // 2. Verify demo vendors rendered
      expect(find.text('ကိုကိုမြိုင် သစ်ပင်ကုန်သည်'), findsOneWidget);
      expect(find.text('မြဝတီ ပြည်တွင်းပင် ပေါင်းစုံ'), findsOneWidget);

      // 3. Tap 'ကုန်သည်သစ် ထည့်မည်' button
      final addButton = find.text('ကုန်သည်သစ် ထည့်မည်');
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // 4. Verify Add Vendor dialog opens
      expect(find.text('ကုန်သည်သစ် ထည့်သွင်းမည်'), findsOneWidget);
      expect(find.text('ကုန်သည်အမည် *'), findsOneWidget);

      // 5. Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('ကုန်သည်သစ် ထည့်သွင်းမည်'), findsNothing);
    });
  });

  group('PosScreen Integration Tests for Purchases and Vendors', () {
    testWidgets('Navigation rail contains Purchases and Settings can switch to Vendors tab',
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

      // 1. Tap on Purchases nav rail item
      final purchasesNav = find.byTooltip('အဝယ်စာရင်း / Purchases (Purchases / Stock-In)');
      expect(purchasesNav, findsOneWidget);
      await tester.tap(purchasesNav);
      await tester.pumpAndSettle();

      // Verify PurchaseScreen is rendered
      expect(find.byType(PurchaseScreen), findsOneWidget);
      expect(find.text('အဝယ်စာရင်း — Purchases / Stock-In'), findsOneWidget);

      // 2. Tap on Settings nav rail item
      final settingsNav = find.byTooltip('ဆက်တင် / Settings (System Settings)');
      expect(settingsNav, findsOneWidget);
      await tester.tap(settingsNav);
      await tester.pumpAndSettle();

      // Verify SettingsScreen is rendered and has Vendors tab
      expect(find.text('Vendors & Suppliers'), findsOneWidget);

      // 3. Switch to Vendors tab inside Settings
      await tester.tap(find.text('Vendors & Suppliers'));
      await tester.pumpAndSettle();

      // Verify VendorManagementScreen is rendered inside Settings
      expect(find.byType(VendorManagementScreen), findsOneWidget);
      expect(find.text('ကုန်သည်သစ် ထည့်မည်'), findsOneWidget);
    });
  });
}
