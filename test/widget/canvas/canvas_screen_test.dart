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
    expect(find.text('手ブレ補正'), findsOneWidget); // Phase4
  });

  testWidgets('メニュー→フィルタでフィルタ一覧が出る(Phase4)', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.byTooltip('メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('フィルタ'));
    await tester.pumpAndSettle();

    expect(find.text('反転'), findsOneWidget);
    expect(find.text('ぼかし'), findsOneWidget);
    expect(find.text('モザイク'), findsOneWidget);
  });

  testWidgets('ドックに塗りつぶし/グラデ/スポイトがある(Phase2)', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.byTooltip('塗りつぶし'), findsOneWidget);
    expect(find.byTooltip('グラデーション'), findsOneWidget);
    expect(find.byTooltip('スポイト'), findsOneWidget);
    expect(find.byTooltip('図形'), findsOneWidget);
    expect(find.byTooltip('テキスト'), findsOneWidget);
    expect(find.byTooltip('選択'), findsOneWidget);
  });

  testWidgets('図形ツール再タップで図形シートが開く', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.byTooltip('図形')); // 選択
    await tester.pump();
    await tester.tap(find.byTooltip('図形')); // 再タップ → シート
    await tester.pumpAndSettle();

    expect(find.text('直線'), findsOneWidget);
    expect(find.text('四角'), findsOneWidget);
    expect(find.text('楕円'), findsOneWidget);
  });

  testWidgets('スケッチ長押しでツール UI を隠す/戻すできる(復帰ボタン不要)', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.byTooltip('メニュー'), findsOneWidget); // ヘッダー
    expect(find.byTooltip('ブラシ'), findsOneWidget); // フッター

    // キャンバスを長押し → UI が隠れる(復帰ボタンは出さない)。
    await tester.longPress(find.byType(DrawSurface));
    await tester.pump();
    expect(find.byTooltip('メニュー'), findsNothing);
    expect(find.byTooltip('ブラシ'), findsNothing);

    // もう一度長押し → UI が戻る。
    await tester.longPress(find.byType(DrawSurface));
    await tester.pump();
    expect(find.byTooltip('メニュー'), findsOneWidget);
    expect(find.byTooltip('ブラシ'), findsOneWidget);
  });

  testWidgets('ベクターをONにすると編集バーが出て、描画→取り消しできる', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.byTooltip('ベクター: OFF'), findsOneWidget);
    await tester.tap(find.byTooltip('ベクター: OFF'));
    await tester.pump();
    expect(find.byTooltip('ベクター: ON'), findsOneWidget);

    // 編集バーの undo は最初は無効。
    final undo = find.ancestor(
      of: find.byTooltip('ベクターを取り消す'),
      matching: find.byType(IconButton),
    );
    expect(undo, findsOneWidget);
    expect(tester.widget<IconButton>(undo).onPressed, isNull);

    // ベクターを描く → 取り消し可能になる。
    await tester.drag(find.byType(DrawSurface), const Offset(60, 20));
    await tester.pump();
    expect(tester.widget<IconButton>(undo).onPressed, isNotNull);
  });

  testWidgets('変形モード中はツール UI が無効化される(Phase3b)', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.byTooltip('変形'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('変形を確定'), findsOneWidget); // 変形バー

    // レイヤーボタンは IgnorePointer で無効 → タップしてもシートが開かない。
    await tester.tap(find.byTooltip('レイヤー'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('追加'), findsNothing);

    await tester.tap(find.byTooltip('変形を取消'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('変形を確定'), findsNothing);
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

  testWidgets('カラーシートで現在色をマイパレットへ保存できる', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('カラーを選択'));
    await tester.pumpAndSettle();
    expect(find.text('マイパレット'), findsOneWidget);
    expect(find.textContaining('自分の色を貯められます'), findsOneWidget);

    await tester.tap(find.text('現在色を保存'));
    await tester.pumpAndSettle();
    // 保存されたのでプレースホルダが消える。
    expect(find.textContaining('自分の色を貯められます'), findsNothing);
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
