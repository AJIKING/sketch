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
    await tester.pumpWidget(RakugaApp(dependencies: _testDeps()));
    await tester.pump();

    expect(find.text('Rakuga'), findsOneWidget);
    expect(find.text('描くを、もっと気軽に。'), findsOneWidget);
    expect(find.text('新規キャンバス'), findsOneWidget);
  });

  // 回帰: ギャラリー→キャンバスの遷移(Navigator.of の context 不正で
  // 実機がクラッシュした不具合を捕捉する)。サイズ選択ダイアログ経由。
  testWidgets('新規キャンバス→サイズ選択→キャンバスへ遷移する', (tester) async {
    await tester.pumpWidget(RakugaApp(dependencies: _testDeps()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('新規キャンバス'));
    await tester.pumpAndSettle();

    // サイズ選択ダイアログ。
    expect(find.text('キャンバスサイズ'), findsOneWidget);
    expect(find.text('正方形 2048×2048'), findsOneWidget);

    await tester.tap(find.text('画面サイズ'));
    await tester.pumpAndSettle();

    // キャンバスのツールドックが出ている。
    expect(find.byTooltip('ブラシ'), findsOneWidget);
    expect(find.byTooltip('レイヤー'), findsOneWidget);
  });
}
