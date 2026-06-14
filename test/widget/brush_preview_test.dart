import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/domain/brush/brush_preset.dart';
import 'package:sketch/src/ui/widgets/brush_preview.dart';

void main() {
  testWidgets('4 種のブラシプレビューが例外なく描画される', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              for (final brush in brushPresets)
                BrushPreview(brushKey: brush.key),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BrushPreview), findsNWidgets(brushPresets.length));
    expect(tester.takeException(), isNull);
  });
}
