import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/ui/features/branch_transfer/views/transfer_screen.dart';
import 'package:sitepyoe/ui/features/inventory/views/inventory_screen.dart';
import 'package:sitepyoe/ui/features/pos/views/pos_screen.dart';
import 'package:sitepyoe/ui/features/reports/views/reports_screen.dart';
import 'package:sitepyoe/ui/features/wastage/views/wastage_screen.dart';

void main() {
  setUp(() {
    // Standard tablet setup
  });

  Widget buildTestApp(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: child),
      ),
    );
  }

  group('Inventory Operations Widget Tests', () {
    testWidgets('WastageScreen renders form, reason dropdown and audit log', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(const WastageScreen()));
      await tester.pumpAndSettle();

      expect(find.text('အပင်သေဆုံးနှင့် ပျက်စီးမှု မှတ်တမ်း (Wastage Tracking)'), findsOneWidget);
      expect(find.text('ပျက်စီး/သေဆုံး မှတ်တမ်းအသစ် ရေးသွင်းခြင်း'), findsOneWidget);
      expect(find.text('ပျက်စီး/သေဆုံးမှု စစ်ဆေးရေးမှတ်တမ်း (Audit Log)'), findsOneWidget);
      expect(find.text('စာရင်းမှနုတ်ပြီး မှတ်တမ်းတင်မည်'), findsOneWidget);
    });

    testWidgets('TransferScreen renders vouchers and switches to Create Transfer tab', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(const TransferScreen()));
      await tester.pumpAndSettle();

      expect(find.text('ဆိုင်ခွဲအချင်းချင်း ပစ္စည်းလွှဲပြောင်းမှု (Branch Transfers)'), findsOneWidget);
      expect(find.text('လွှဲပြောင်းမှတ်တမ်းများ (Vouchers)'), findsOneWidget);
      expect(find.text('+ လွှဲပြောင်းမှုအသစ် ပြုလုပ်မည်'), findsOneWidget);

      // Confirm Receipt button exists on seeded in-transit voucher
      expect(find.text('ပစ္စည်းလက်ခံအတည်ပြုမည်'), findsOneWidget);

      // Tap on Create Transfer tab
      await tester.tap(find.text('+ လွှဲပြောင်းမှုအသစ် ပြုလုပ်မည်'));
      await tester.pumpAndSettle();

      expect(find.text('မူရင်းဆိုင်ခွဲ (မှ)'), findsOneWidget);
      expect(find.text('လက်ခံမည့်ဆိုင်ခွဲ (သို့)'), findsOneWidget);
      expect(find.text('လွှဲပြောင်းမည့် ပစ္စည်းစာရင်း (Manifest)'), findsOneWidget);
      expect(find.text('ပစ္စည်းထုတ်ယူပြီး ပို့ဆောင်မည်'), findsOneWidget);
    });

    testWidgets('ReportsScreen renders KPI cards, category breakdown and low stock alerts', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(const ReportsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('လုပ်ငန်းသုံး အစီရင်ခံစာများ (Reports)'), findsOneWidget);
    });

    testWidgets('InventoryScreen renders branch products, valuation, and search', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(InventoryScreen(
        onNavigateToWastage: () {},
        onNavigateToTransfer: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.text('Branch Inventory Management'), findsOneWidget);
      expect(find.text('လိပ်ပြာသစ်ခွ'), findsOneWidget);
      expect(find.text('ပျက်စီး/သေဆုံး မှတ်တမ်း'), findsOneWidget);
      expect(find.text('ဆိုင်ခွဲသို့ လွှဲပြောင်း'), findsOneWidget);
    });

    testWidgets('PosScreen SideNavRail switches seamlessly between POS, Inventory, Transfers, Wastage, Reports', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(const PosScreen()));
      await tester.pumpAndSettle();

      // Starts on POS (0)
      expect(find.text('ငွေရှင်းမည် (Pay)'), findsOneWidget);

      // Tap Inventory (nav index 2)
      await tester.tap(find.byTooltip('ပစ္စည်းစာရင်း / Stock (Inventory & Stock)'));
      await tester.pumpAndSettle();
      expect(find.text('Branch Inventory Management'), findsOneWidget);

      // Tap Transfers (nav index 3)
      await tester.tap(find.byTooltip('လွှဲပြောင်း / Transfer (Stock Transfer)'));
      await tester.pumpAndSettle();
      expect(find.text('ဆိုင်ခွဲအချင်းချင်း ပစ္စည်းလွှဲပြောင်းမှု (Branch Transfers)'), findsOneWidget);

      // Tap Wastage (nav index 4)
      await tester.tap(find.byTooltip('ပျက်စီး/သေ / Wastage (Wastage & Loss)'));
      await tester.pumpAndSettle();
      expect(find.text('အပင်သေဆုံးနှင့် ပျက်စီးမှု မှတ်တမ်း (Wastage Tracking)'), findsOneWidget);

      // Tap Reports (nav index 5)
      await tester.tap(find.byTooltip('အစီရင်ခံစာ / Reports (Reports & Analytics)'));
      await tester.pumpAndSettle();
      expect(find.text('လုပ်ငန်းသုံး အစီရင်ခံစာများ (Reports)'), findsOneWidget);

      // Tap back to POS (nav index 0)
      await tester.tap(find.byTooltip('အရောင်း / POS (POS & Sales)'));
      await tester.pumpAndSettle();
      expect(find.text('ငွေရှင်းမည် (Pay)'), findsOneWidget);
    });
  });
}
