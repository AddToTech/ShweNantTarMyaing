import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/core/theme/app_theme.dart';
import 'package:sitepyoe/ui/features/pos/views/pos_screen.dart';
import 'package:sitepyoe/ui/features/pos/widgets/cart_panel.dart';
import 'package:sitepyoe/ui/features/pos/widgets/category_filter_bar.dart';
import 'package:sitepyoe/ui/features/pos/widgets/product_grid_item.dart';

void main() {
  testWidgets('PosScreen renders tablet dual-pane layout and interacts with cart',
      (WidgetTester tester) async {
    // 10-inch landscape tablet resolution (1280x800)
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

    // 1. Verify Navigation Rail items
    expect(find.textContaining('POS'), findsOneWidget);
    expect(find.textContaining('Stock'), findsOneWidget);
    expect(find.textContaining('Transfer'), findsOneWidget);
    expect(find.textContaining('Wastage'), findsOneWidget);
    expect(find.textContaining('Reports'), findsOneWidget);
    expect(find.textContaining('Settings'), findsOneWidget);
    expect(find.textContaining('HR'), findsOneWidget);

    // 2. Verify Category Filter Bar & Cart Panel
    expect(find.byType(CategoryFilterBar), findsOneWidget);
    expect(find.byType(CartPanel), findsOneWidget);
    expect(find.textContaining('#SP-001'), findsOneWidget);
    expect(find.textContaining('ခြင်းတောင်းထဲတွင် ပစ္စည်းမရှိပါ'), findsOneWidget);

    // 3. Verify Product Grid Items rendered
    expect(find.byType(ProductGridItem), findsWidgets);

    // 4. Tap the first product to add to cart
    await tester.tap(find.text('လိပ်ပြာသစ်ခွ'));
    await tester.pumpAndSettle();

    // 5. Cart should now not be empty and should have item count updated
    expect(find.textContaining('ခြင်းတောင်းထဲတွင် ပစ္စည်းမရှိပါ'), findsNothing);
    expect(find.textContaining('ငွေရှင်းမည်'), findsOneWidget);
    expect(find.textContaining('ဆိုင်းငံ့'), findsOneWidget);
  });
}
