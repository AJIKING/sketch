import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/app.dart';
import 'package:sketch/src/application/dependencies.dart';

import '../fixtures/fake_clock.dart';
import '../fixtures/in_memory_gallery_store.dart';
import '../fixtures/recording_image_exporter.dart';

Dependencies _testDeps() => Dependencies(
  clock: FakeClock(),
  galleryStore: InMemoryGalleryStore(),
  imageExporter: RecordingImageExporter(),
);

void main() {
  testWidgets('起動するとギャラリーのブランドと新規ボタンが出る', (tester) async {
    await tester.pumpWidget(HatchApp(dependencies: _testDeps()));
    await tester.pump();

    expect(find.text('Hatch'), findsOneWidget);
    expect(find.text('Pocket Atelier'), findsOneWidget);
    expect(find.text('新規キャンバス'), findsOneWidget);
  });

  // 回帰: ギャラリー→キャンバスの遷移(Navigator.of の context 不正で
  // 実機がクラッシュした不具合を捕捉する)。
  testWidgets('新規キャンバスをタップするとキャンバスへ遷移する', (tester) async {
    await tester.pumpWidget(HatchApp(dependencies: _testDeps()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('新規キャンバス'));
    await tester.pumpAndSettle();

    // キャンバスのツールドックが出ている。
    expect(find.byTooltip('ブラシ'), findsOneWidget);
    expect(find.byTooltip('レイヤー'), findsOneWidget);
  });
}
