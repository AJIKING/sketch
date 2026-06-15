import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/application/dependencies.dart';
import 'package:sketch/src/application/gallery_controller.dart';
import 'package:sketch/src/ui/canvas/canvas_screen.dart';
import 'package:sketch/src/ui/canvas/draw_surface.dart';

import '../../fixtures/fake_clock.dart';
import '../../fixtures/fake_photo_source.dart';
import '../../fixtures/in_memory_gallery_store.dart';
import '../../fixtures/recording_image_exporter.dart';

Widget _app() => _appWith(RecordingImageExporter());

Widget _appWith(
  RecordingImageExporter exporter, {
  FakePhotoSource? photoSource,
}) {
  final deps = Dependencies(
    clock: FakeClock(),
    galleryStore: InMemoryGalleryStore(),
    imageExporter: exporter,
    photoSource: photoSource,
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

  testWidgets('グラデブラシの2色目をカラーコードで設定できる', (tester) async {
    // 背の高いブラシシートが収まるよう縦長画面にする。
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_app());
    await tester.pump();

    // ブラシシートを開き、2色グラデーションを有効化。
    await tester.tap(find.byTooltip('ブラシ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    // 2色目欄(唯一の TextField=カラーコード)へ入力して適用。
    await tester.enterText(find.byType(TextField), '0000FF');
    await tester.tap(find.text('適用'));
    await tester.pumpAndSettle();

    // 正規化された #0000FF がフィールドへ反映される。
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '#0000FF');
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

  testWidgets('PhotoSource 未注入なら「写真を読み込む」を出さない', (tester) async {
    await tester.pumpWidget(_app()); // photoSource なし
    await tester.pump();
    await tester.tap(find.byTooltip('メニュー'));
    await tester.pumpAndSettle();
    expect(find.text('写真を読み込む'), findsNothing);
  });

  testWidgets('メニュー→写真を読み込むで PhotoSource が呼ばれる', (tester) async {
    final photo = FakePhotoSource(Uint8List.fromList([0, 1, 2, 3]));
    await tester.pumpWidget(
      _appWith(RecordingImageExporter(), photoSource: photo),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('メニュー'));
    await tester.pumpAndSettle();
    expect(find.text('写真を読み込む'), findsOneWidget); // 注入時のみ出る

    await tester.tap(find.text('写真を読み込む'));
    await tester.pumpAndSettle();
    expect(photo.calls, 1); // ピッカーが呼ばれる(デコード失敗でも導線は成立)
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

  testWidgets('オブジェクト長押しで調整バーが出て、完了で抜ける', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    // ベクターでオブジェクトを 1 つ描く。
    await tester.tap(find.byTooltip('ベクター: OFF'));
    await tester.pump();
    await tester.drag(find.byType(DrawSurface), const Offset(60, 20));
    await tester.pump();

    // そのオブジェクトの始点付近を長押し → 調整バー。
    await tester.longPress(find.byType(DrawSurface));
    await tester.pumpAndSettle();
    expect(find.byTooltip('調整を完了'), findsOneWidget);

    await tester.tap(find.byTooltip('調整を完了'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('調整を完了'), findsNothing);
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
    expect(find.text('共有(SNS など)'), findsOneWidget);
    expect(find.text('完了してギャラリーへ'), findsOneWidget);
    expect(find.text('このレイヤーを消去'), findsOneWidget);
    // photoSource 未注入の _app() では「写真を読み込む」は出ない。
    expect(find.text('写真を読み込む'), findsNothing);
    // タイムラプス記録トグルがある(記録前は書き出しは出ない)。
    expect(find.text('タイムラプス記録'), findsOneWidget);
    expect(find.text('タイムラプスを書き出す(GIF)'), findsNothing);
  });

  testWidgets('photoSource 注入時はメニューから写真を読み込む(ピッカー起動)', (tester) async {
    final fake = FakePhotoSource(); // bytes=null(キャンセル相当)
    final deps = Dependencies(
      clock: FakeClock(),
      galleryStore: InMemoryGalleryStore(),
      imageExporter: RecordingImageExporter(),
      photoSource: fake,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CanvasScreen(
          dependencies: deps,
          gallery: GalleryController(
            store: deps.galleryStore,
            clock: deps.clock,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('メニュー'));
    await tester.pumpAndSettle();
    expect(find.text('写真を読み込む'), findsOneWidget);

    await tester.tap(find.text('写真を読み込む'));
    await tester.pumpAndSettle();
    expect(fake.calls, 1); // ピッカーが呼ばれる
  });

  testWidgets('共有メニューで既定キャプション付きのダイアログが出る', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.byTooltip('メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('共有(SNS など)'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Hatch で描きました #Hatch'), findsOneWidget); // 既定

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
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

  testWidgets('カラーシートでカラーコードを入力して色を設定できる', (tester) async {
    // 背の高い色シートが収まるよう縦長画面にする。
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('カラーを選択'));
    await tester.pumpAndSettle();
    expect(find.text('カラー  #CF4A2C'), findsOneWidget); // 既定は朱

    // カラーシートの唯一の TextField がカラーコード欄。
    await tester.enterText(find.byType(TextField), '00FF00');
    await tester.tap(find.text('適用'));
    await tester.pumpAndSettle();

    expect(find.text('カラー  #00FF00'), findsOneWidget);
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
