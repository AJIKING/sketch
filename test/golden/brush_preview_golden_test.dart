@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/domain/brush/brush_preset.dart';
import 'package:sketch/src/ui/theme/atelier_theme.dart';
import 'package:sketch/src/ui/widgets/brush_preview.dart';

import 'golden_setup.dart';

void main() {
  for (final brush in brushPresets) {
    testWidgets('brush preview ${brush.key}', (tester) async {
      await loadAtelierFonts();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: AtelierTokens.paper,
            body: Center(child: BrushPreview(brushKey: brush.key)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(BrushPreview),
        matchesGoldenFile('goldens/brush_${brush.key}.png'),
      );
    }, skip: skipGoldens);
  }
}
