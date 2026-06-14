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

  testWidgets('ドックに塗りつぶし/グラデ/スポイトがある(Phase2)', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.byTooltip('塗りつぶし'), findsOneWidget);
    expect(find.byTooltip('グラデーション'), findsOneWidget);
    expect(find.byTooltip('スポイト'), findsOneWidget);
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

  testWidgets('レイヤーシートにブレンド/アルファロック/クリップが出る(Phase1)', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.byTooltip('レイヤー'));
    await tester.pumpAndSettle();

    expect(find.text('通常'), findsWidgets); // ブレンドモード既定
    expect(find.byTooltip('アルファロック'), findsWidgets);
    expect(find.byTooltip('下のレイヤーでクリッピング'), findsWidgets);
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

  testWidgets('カラーシートにパレットと HSV ピッカーが出る', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('カラーを選択'));
    await tester.pumpAndSettle();

    expect(find.text('Studio Palette'), findsOneWidget);
    expect(find.bySemanticsLabel('彩度と明度'), findsOneWidget);
    expect(find.bySemanticsLabel('色相'), findsOneWidget);
  });

  testWidgets('Hue バーを操作すると現在色が変わる', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('カラーを選択'));
    await tester.pumpAndSettle();
    expect(find.text('カラー  #CF4A2C'), findsOneWidget); // 既定は朱

    await tester.drag(find.bySemanticsLabel('色相'), const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(find.text('カラー  #CF4A2C'), findsNothing);
  });

  testWidgets('パレットの色を選ぶと現在色になり最近色へ入る', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('カラーを選択'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('#2C4A63')); // 藍
    await tester.pumpAndSettle();
    expect(find.text('カラー  #2C4A63'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
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
