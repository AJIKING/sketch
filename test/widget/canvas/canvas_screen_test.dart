import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/application/dependencies.dart';
import 'package:sketch/src/application/gallery_controller.dart';
import 'package:sketch/src/ui/canvas/canvas_screen.dart';
import 'package:sketch/src/ui/canvas/draw_surface.dart';

import '../../fixtures/fake_clock.dart';
import '../../fixtures/in_memory_gallery_store.dart';
import '../../fixtures/recording_image_exporter.dart';

Widget _app() {
  final deps = Dependencies(
    clock: FakeClock(),
    galleryStore: InMemoryGalleryStore(),
    imageExporter: RecordingImageExporter(),
  );
  return MaterialApp(
    home: CanvasScreen(
      dependencies: deps,
      gallery: GalleryController(store: deps.galleryStore, clock: deps.clock),
    ),
  );
}

void main() {
  testWidgets('アクティブなブラシを再タップするとブラシシートが開く', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.byTooltip('ブラシ'));
    await tester.pumpAndSettle();

    expect(find.text('インク'), findsOneWidget);
    expect(find.text('ペンシル'), findsOneWidget);
    expect(find.text('エアブラシ'), findsOneWidget);
  });

  testWidgets('レイヤーシートで追加するとレイヤーが増える', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.byTooltip('レイヤー'));
    await tester.pumpAndSettle();
    expect(find.text('レイヤー 1'), findsOneWidget);
    expect(find.text('レイヤー 2'), findsOneWidget);

    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
    expect(find.text('レイヤー 3'), findsOneWidget);
  });

  testWidgets('メニューシートに保存/完了/消去が並ぶ', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.byTooltip('メニュー'));
    await tester.pumpAndSettle();

    expect(find.text('画像として保存'), findsOneWidget);
    expect(find.text('完了してギャラリーへ'), findsOneWidget);
    expect(find.text('このレイヤーを消去'), findsOneWidget);
  });

  testWidgets('カラーシートにパレットが出る', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('カラーを選択'));
    await tester.pumpAndSettle();

    expect(find.text('Studio Palette'), findsOneWidget);
    expect(find.text('色相'), findsOneWidget);
  });

  testWidgets('描画すると取り消しが有効になる', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    final undo = find.widgetWithIcon(IconButton, Icons.undo);
    expect(tester.widget<IconButton>(undo).onPressed, isNull);

    await tester.drag(find.byType(DrawSurface), const Offset(40, 40));
    await tester.pump();

    expect(tester.widget<IconButton>(undo).onPressed, isNotNull);
  });
}
