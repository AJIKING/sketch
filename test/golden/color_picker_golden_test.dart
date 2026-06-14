@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/application/canvas_controller.dart';
import 'package:sketch/src/ui/canvas/color_picker.dart';
import 'package:sketch/src/ui/theme/atelier_theme.dart';

import '../fixtures/fake_canvas_surface.dart';
import 'golden_setup.dart';

void main() {
  testWidgets('color picker (default vermilion)', (tester) async {
    await loadAtelierFonts();
    final controller = CanvasController(surface: FakeCanvasSurface());
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AtelierTokens.surface,
          body: Center(
            child: SizedBox(
              width: 260,
              child: ColorPicker(controller: controller),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ColorPicker),
      matchesGoldenFile('goldens/color_picker.png'),
    );
  }, skip: skipGoldens);
}
