import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sitepyoe/core/theme/app_theme.dart';
import 'package:sitepyoe/ui/features/reports/views/reports_screen.dart';

void main() {
  testWidgets('Capture reports screen test', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: RepaintBoundary(
            key: repaintKey,
            child: const Scaffold(
              body: ReportsScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      File('/Users/admin/.gemini/antigravity-ide/brain/d5a45158-ee19-4ea6-97e2-6b9eb40a74c7/screens/11_reports_screen.png')
          .writeAsBytesSync(byteData.buffer.asUint8List());
      // ignore: avoid_print
      print('REPORTS SCREEN CAPTURED!');
    }
  });
}
