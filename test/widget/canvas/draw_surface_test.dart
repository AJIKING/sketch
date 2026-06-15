import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/application/canvas_controller.dart';
import 'package:sketch/src/application/vector_controller.dart';
import 'package:sketch/src/domain/canvas/shape_kind.dart';
import 'package:sketch/src/domain/timelapse/timelapse_frame.dart';
import 'package:sketch/src/domain/vector/vector_object.dart';
import 'package:sketch/src/ui/canvas/draw_surface.dart';
import 'package:sketch/src/ui/canvas/raster_layer_store.dart';

import '../../fixtures/fake_clock.dart';

Future<void> _pumpKeyed(
  WidgetTester tester,
  GlobalKey<DrawSurfaceState> key,
  CanvasController c,
  RasterLayerStore s,
) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: DrawSurface(
              key: key,
              controller: c,
              surface: s,
              clock: FakeClock(),
              transforming: ValueNotifier<bool>(false),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  CanvasController c,
  RasterLayerStore s,
) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: DrawSurface(
              controller: c,
              surface: s,
              clock: FakeClock(),
              transforming: ValueNotifier<bool>(false),
            ),
          ),
        ),
      ),
    ),
  );
}

/// 背の高いテキスト編集ダイアログ(HSV ピッカー等)が収まるよう、テスト画面を
/// 縦長にする。DrawSurface は固定 200x200 なので影響しない。
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> pumpVector(
  WidgetTester tester,
  CanvasController c,
  RasterLayerStore s,
  VectorController v,
) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: DrawSurface(
              controller: c,
              surface: s,
              clock: FakeClock(),
              transforming: ValueNotifier<bool>(false),
              vector: v,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('描く→レイヤー画像へ焼き込み、undo/redo で戻る(ADR 0004)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    await _pump(tester, controller, surface);

    final activeId = controller.layers.active.id;
    expect(surface.imageOf(activeId), isNull);

    await tester.drag(find.byType(DrawSurface), const Offset(40, 40));
    await tester.pump();

    expect(surface.imageOf(activeId), isNotNull, reason: '確定で画像へ焼き込まれる');
    expect(controller.canUndo, isTrue);

    controller.undo();
    expect(surface.imageOf(activeId), isNull, reason: 'ストローク前(空)へ戻る');

    controller.redo();
    expect(surface.imageOf(activeId), isNotNull, reason: 'やり直しで画像が戻る');
  });

  testWidgets('描画中に外部操作が入ると進行中ストロークは破棄される(回帰)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    await _pump(tester, controller, surface);
    final id = controller.layers.active.id;

    final g = await tester.startGesture(
      tester.getCenter(find.byType(DrawSurface)),
    );
    await g.moveBy(const Offset(20, 10));
    await tester.pump();

    // 別ポインタでのツール変更・undo 等に相当(コントローラ通知)。
    controller.selectTool(Tool.erase);
    await tester.pump();

    await g.up();
    await tester.pump();

    // 進行中ストロークは無効化され、焼き込まれない。
    expect(surface.imageOf(id), isNull);
    expect(controller.canUndo, isFalse);
  });

  testWidgets('非表示レイヤーには焼き込まれない', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    await _pump(tester, controller, surface);

    controller.toggleLayerVisible(controller.layers.activeIndex);
    final activeId = controller.layers.active.id;

    await tester.drag(find.byType(DrawSurface), const Offset(40, 40));
    await tester.pump();

    expect(surface.imageOf(activeId), isNull);
    expect(controller.canUndo, isFalse);
  });

  testWidgets('アルファロック中の空レイヤーには焼き込まれない(Phase1)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    await _pump(tester, controller, surface);

    controller.toggleLayerAlphaLock(controller.layers.activeIndex);
    final activeId = controller.layers.active.id;

    await tester.drag(find.byType(DrawSurface), const Offset(40, 40));
    await tester.pump();

    expect(surface.imageOf(activeId), isNull, reason: '不透明部分が無いので塗れない');
  });

  testWidgets('テキストツール: タップ→入力で再編集可能なテキストを作る', (tester) async {
    _useTallSurface(tester);
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface)
      ..selectTool(Tool.text);
    final vector = VectorController();
    await pumpVector(tester, controller, surface, vector);

    await tester.tap(find.byType(DrawSurface));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AlertDialog, 'テキスト'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'ABC');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();

    expect(vector.count, 1);
    expect(vector.selected, isA<VectorText>());
    expect((vector.selected! as VectorText).text, 'ABC');
    // 焼き込まれず再編集できる(ラスターは空)。
    expect(surface.imageOf(controller.layers.active.id), isNull);
  });

  testWidgets('テキストツール: 既存テキストをタップすると編集できる', (tester) async {
    _useTallSurface(tester);
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface)
      ..selectTool(Tool.text);
    final vector = VectorController();
    await pumpVector(tester, controller, surface, vector);

    await tester.tap(find.byType(DrawSurface));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Hello');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
    final id = vector.selectedId!;

    // 同じ位置を再タップ → 既存テキストの編集(プリフィル)。
    await tester.tap(find.byType(DrawSurface));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AlertDialog, 'テキストを編集'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'World');
    await tester.tap(find.text('更新'));
    await tester.pumpAndSettle();

    expect(vector.count, 1); // 増えない(更新)
    expect((vector.layer.byId(id)! as VectorText).text, 'World');
  });

  testWidgets('テキスト: カラーコード入力で色を設定できる', (tester) async {
    _useTallSurface(tester);
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface)
      ..selectTool(Tool.text);
    final vector = VectorController();
    await pumpVector(tester, controller, surface, vector);

    await tester.tap(find.byType(DrawSurface));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'X'); // 文字入力
    await tester.enterText(find.byType(TextField).last, '00FF00'); // カラーコード
    await tester.tap(find.text('適用'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();

    expect((vector.selected! as VectorText).colorHex, '#00FF00');
  });

  testWidgets('テキストツール: 内容を空にして更新すると削除される', (tester) async {
    _useTallSurface(tester);
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface)
      ..selectTool(Tool.text);
    final vector = VectorController();
    await pumpVector(tester, controller, surface, vector);

    await tester.tap(find.byType(DrawSurface));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Hello');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
    expect(vector.count, 1);

    await tester.tap(find.byType(DrawSurface));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.text('更新'));
    await tester.pumpAndSettle();

    expect(vector.count, 0); // 空で削除
  });

  Future<void> pumpToggle(
    WidgetTester tester,
    CanvasController c,
    RasterLayerStore s,
    void Function() onToggle,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: DrawSurface(
                controller: c,
                surface: s,
                clock: FakeClock(),
                transforming: ValueNotifier<bool>(false),
                onToggleUi: onToggle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('長押し(動かさない)でツール UI トグルが呼ばれ、描画されない', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    var toggles = 0;
    await pumpToggle(tester, controller, surface, () => toggles++);

    final g = await tester.startGesture(
      tester.getCenter(find.byType(DrawSurface)),
    );
    await tester.pump(const Duration(milliseconds: 500)); // 長押しタイマー発火
    await g.up();
    await tester.pump();

    expect(toggles, 1);
    // 長押しなので焼き込まれない。
    expect(surface.imageOf(controller.layers.active.id), isNull);
    expect(controller.canUndo, isFalse);
  });

  testWidgets('動かしたら描画になり、トグルは呼ばれない', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    var toggles = 0;
    await pumpToggle(tester, controller, surface, () => toggles++);

    await tester.drag(find.byType(DrawSurface), const Offset(40, 40));
    await tester.pump();

    expect(toggles, 0);
    expect(surface.imageOf(controller.layers.active.id), isNotNull);
  });

  testWidgets('図形ツール: ドラッグで焼き込み、undo で戻る', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface)
      ..selectTool(Tool.shape);
    await _pump(tester, controller, surface);
    final id = controller.layers.active.id;
    expect(surface.imageOf(id), isNull);

    await tester.drag(find.byType(DrawSurface), const Offset(60, 40));
    await tester.pump();

    expect(surface.imageOf(id), isNotNull);
    expect(controller.canUndo, isTrue);

    controller.undo();
    expect(surface.imageOf(id), isNull);
  });

  testWidgets('グラデーションをドラッグするとレイヤーへ焼き込まれる(Phase2)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface)
      ..selectTool(Tool.gradient);
    await _pump(tester, controller, surface);
    final id = controller.layers.active.id;

    await tester.drag(find.byType(DrawSurface), const Offset(60, 60));
    await tester.pump();

    expect(surface.imageOf(id), isNotNull);
    expect(controller.canUndo, isTrue);
  });

  testWidgets('空レイヤーでスポイトすると紙の色になる(Phase2)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface)
      ..selectTool(Tool.eyedropper);
    await _pump(tester, controller, surface);

    await tester.tap(find.byType(DrawSurface));
    await tester.pump();

    expect(controller.colorHex, '#EFE7D6'); // 紙の色
  });

  testWidgets('選択: 矩形で選択→範囲消去(undo可)→解除', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final key = GlobalKey<DrawSurfaceState>();
    await _pumpKeyed(tester, key, controller, surface);

    // まず描画して画像を作る。
    await tester.drag(find.byType(DrawSurface), const Offset(80, 60));
    await tester.pump();
    final id = controller.layers.active.id;
    final before = surface.imageOf(id);
    expect(before, isNotNull);

    // 選択ツールで矩形選択。
    controller.selectTool(Tool.select);
    await tester.drag(find.byType(DrawSurface), const Offset(60, 50));
    await tester.pump();
    expect(key.currentState!.hasSelection, isTrue);

    // 範囲消去 → 画像が変わり undo 可能。
    key.currentState!.clearInsideSelection();
    expect(surface.imageOf(id), isNot(same(before)));
    expect(controller.canUndo, isTrue);
    controller.undo();
    expect(surface.imageOf(id), same(before));

    key.currentState!.deselect();
    expect(key.currentState!.hasSelection, isFalse);
  });

  testWidgets('2 本指ピンチでビューが拡大する(Phase3)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final key = GlobalKey<DrawSurfaceState>();
    await _pumpKeyed(tester, key, controller, surface);

    expect(key.currentState!.viewport.scale, 1);

    final center = tester.getCenter(find.byType(DrawSurface));
    final g1 = await tester.startGesture(
      center + const Offset(-20, 0),
      pointer: 1,
    );
    final g2 = await tester.startGesture(
      center + const Offset(20, 0),
      pointer: 2,
    );
    await g1.moveBy(const Offset(-40, 0));
    await g2.moveBy(const Offset(40, 0));
    await g1.up();
    await g2.up();
    await tester.pump();

    expect(key.currentState!.viewport.scale, greaterThan(1.5));

    key.currentState!.resetView();
    expect(key.currentState!.viewport.scale, 1);
  });

  testWidgets('保存はビューポート(ズーム)に依存しない(回帰)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final key = GlobalKey<DrawSurfaceState>();
    await _pumpKeyed(tester, key, controller, surface);

    await tester.drag(find.byType(DrawSurface), const Offset(50, 30));
    await tester.pump();

    Uint8List? before;
    Uint8List? after;
    await tester.runAsync(() async {
      before = await key.currentState!.exportPng();
    });

    final c = tester.getCenter(find.byType(DrawSurface));
    final g1 = await tester.startGesture(c + const Offset(-20, 0), pointer: 1);
    final g2 = await tester.startGesture(c + const Offset(20, 0), pointer: 2);
    await g1.moveBy(const Offset(-50, 0));
    await g2.moveBy(const Offset(50, 0));
    await g1.up();
    await g2.up();
    await tester.pump();
    expect(key.currentState!.viewport.scale, greaterThan(1.0));

    await tester.runAsync(() async {
      after = await key.currentState!.exportPng();
    });

    expect(before, isNotNull);
    expect(after, equals(before)); // ズームしても出力は同一
  });

  testWidgets('回転すると新しい向きいっぱいに表示し直す(等倍・全面)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final key = GlobalKey<DrawSurfaceState>();

    Widget app(Size size) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: DrawSurface(
              key: key,
              controller: controller,
              surface: surface,
              clock: FakeClock(),
              transforming: ValueNotifier<bool>(false),
            ),
          ),
        ),
      ),
    );

    // 縦長で起動 → 等倍・原点(全面)。
    await tester.pumpWidget(app(const Size(100, 200)));
    await tester.pump();
    expect(key.currentState!.viewport.scale, closeTo(1, 1e-9));
    expect(key.currentState!.viewport.offset, Offset.zero);

    // 横長へ回転 → レターボックスにせず、横全面(等倍・原点)へ。
    await tester.pumpWidget(app(const Size(300, 100)));
    await tester.pump();
    final v = key.currentState!.viewport;
    expect(v.scale, closeTo(1, 1e-9)); // 縮小フィットしない
    expect(v.offset, Offset.zero);
  });

  testWidgets('固定解像度ドキュメントは中央フィット表示で docSize 固定(A2)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final key = GlobalKey<DrawSurfaceState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: DrawSurface(
                key: key,
                controller: controller,
                surface: surface,
                clock: FakeClock(),
                transforming: ValueNotifier<bool>(false),
                documentSize: const Size(100, 200),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // doc 100x200 を view 300x300 へ: scale=min(3,1.5)=1.5、中央寄せ。
    final v = key.currentState!.viewport;
    expect(v.scale, closeTo(1.5, 1e-9));
    expect(v.offset.dx, closeTo(75, 1e-6)); // (300-150)/2
    expect(v.offset.dy, closeTo(0, 1e-6)); // (300-300)/2

    // 描くと固定解像度(100x200)で焼き込まれる(画面サイズではない)。
    await tester.drag(find.byType(DrawSurface), const Offset(0, 30));
    await tester.pump();
    final img = surface.imageOf(controller.layers.active.id);
    expect(img, isNotNull);
    expect(img!.width, 100);
    expect(img.height, 200);
  });

  testWidgets('固定解像度: 同じ向きのリサイズではズームを保持する(回帰)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final key = GlobalKey<DrawSurfaceState>();
    Widget app(Size view) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: view.width,
            height: view.height,
            child: DrawSurface(
              key: key,
              controller: controller,
              surface: surface,
              clock: FakeClock(),
              transforming: ValueNotifier<bool>(false),
              documentSize: const Size(100, 200),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(const Size(300, 400))); // 縦
    await tester.pump();

    final c = tester.getCenter(find.byType(DrawSurface));
    final g1 = await tester.startGesture(c + const Offset(-20, 0), pointer: 1);
    final g2 = await tester.startGesture(c + const Offset(20, 0), pointer: 2);
    await g1.moveBy(const Offset(-40, 0));
    await g2.moveBy(const Offset(40, 0));
    await g1.up();
    await g2.up();
    await tester.pump();
    final zoomed = key.currentState!.viewport.scale;
    expect(zoomed, greaterThan(2.5)); // 初期フィット 2.0 から拡大

    // 同じ縦向きのまま少しリサイズ → ズーム保持(再フィットしない)。
    await tester.pumpWidget(app(const Size(290, 400)));
    await tester.pump();
    expect(key.currentState!.viewport.scale, closeTo(zoomed, 1e-9));
  });

  testWidgets('同じ向きの微小リサイズではユーザーのズームを保持する(回帰)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final key = GlobalKey<DrawSurfaceState>();

    Widget app(Size size) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: DrawSurface(
              key: key,
              controller: controller,
              surface: surface,
              clock: FakeClock(),
              transforming: ValueNotifier<bool>(false),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(const Size(200, 300))); // 縦
    await tester.pump();

    // 2 本指ピンチでズーム。
    final c = tester.getCenter(find.byType(DrawSurface));
    final g1 = await tester.startGesture(c + const Offset(-20, 0), pointer: 1);
    final g2 = await tester.startGesture(c + const Offset(20, 0), pointer: 2);
    await g1.moveBy(const Offset(-40, 0));
    await g2.moveBy(const Offset(40, 0));
    await g1.up();
    await g2.up();
    await tester.pump();
    final zoomed = key.currentState!.viewport.scale;
    expect(zoomed, greaterThan(1.2));

    // 同じ縦向きのまま少しリサイズ → ズームは保持(中央フィットし直さない)。
    await tester.pumpWidget(app(const Size(190, 300)));
    await tester.pump();
    expect(key.currentState!.viewport.scale, closeTo(zoomed, 1e-9));
  });

  testWidgets('ベクターモード: ドラッグでベクターを追加し、ラスターは焼かれない', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final vector = VectorController()..setEnabled(true);
    await pumpVector(tester, controller, surface, vector);

    expect(vector.count, 0);
    await tester.drag(find.byType(DrawSurface), const Offset(60, 20));
    await tester.pump();

    expect(vector.count, 1);
    expect(vector.selected, isA<VectorStroke>());
    // ラスターレイヤーには焼き込まれない。
    expect(surface.imageOf(controller.layers.active.id), isNull);
    expect(controller.canUndo, isFalse);
  });

  testWidgets('ベクターモード: 選択ツールでオブジェクトを掴んで移動できる', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final vector = VectorController()..setEnabled(true);
    await pumpVector(tester, controller, surface, vector);

    // 中心(100,100)から描いてストロークを作る。
    await tester.drag(find.byType(DrawSurface), const Offset(40, 0));
    await tester.pump();
    final id = vector.selectedId;
    expect(id, isNotNull);

    // 選択ツールで中心(始点付近)を掴んで +30 移動。
    controller.selectTool(Tool.select);
    await tester.pump();
    await tester.drag(find.byType(DrawSurface), const Offset(30, 0));
    await tester.pump();

    expect(vector.selectedId, id); // 同じオブジェクトを選択
    final moved = vector.layer.byId(id!)! as VectorStroke;
    expect(moved.points.first.x, closeTo(130, 1)); // 100 → 130
    vector.undo(); // 移動全体が 1 回で戻る
    expect(
      (vector.layer.byId(id)! as VectorStroke).points.first.x,
      closeTo(100, 1),
    );
  });

  testWidgets('captureFrame は縮小した RGBA フレームを返す(タイムラプス用)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final key = GlobalKey<DrawSurfaceState>();
    await _pumpKeyed(tester, key, controller, surface); // 200x200

    TimelapseFrame? frame;
    await tester.runAsync(() async {
      frame = await key.currentState!.captureFrame(100);
    });

    expect(frame, isNotNull);
    expect(frame!.width, lessThanOrEqualTo(100));
    expect(frame!.height, lessThanOrEqualTo(100));
    expect(frame!.rgba.length, frame!.width * frame!.height * 4);
  });

  testWidgets('写真読み込み: 新規レイヤーへ画像が焼き込まれ undo できる', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final key = GlobalKey<DrawSurfaceState>();
    await _pumpKeyed(tester, key, controller, surface);
    final before = controller.layers.length;

    // 画像デコードはテスト環境で不可のため、合成画像を作って配置経路を検証する。
    late ui.Image image;
    await tester.runAsync(() async {
      final rec = ui.PictureRecorder();
      ui.Canvas(rec).drawRect(
        const Rect.fromLTWH(0, 0, 10, 10),
        ui.Paint()..color = const Color(0xFFFF0000),
      );
      image = await rec.endRecording().toImage(10, 10);
    });

    key.currentState!.placeImageLayer(image);
    await tester.pump();

    expect(controller.layers.length, before + 1); // 新規レイヤーへ
    expect(surface.imageOf(controller.layers.active.id), isNotNull);
    expect(controller.canUndo, isTrue); // 取り込み前へ戻せる
  });

  testWidgets('長押しでオブジェクト調整: ドラッグで移動する', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final vector = VectorController()
      ..addShape(
        kind: ShapeKind.rectangle,
        start: const VecPoint(80, 80),
        end: const VecPoint(120, 120),
        colorHex: '#000000',
        width: 4,
        filled: true,
      );
    await pumpVector(tester, controller, surface, vector);

    // 中心(100,100)を長押し → そのオブジェクトの調整モードへ。
    await tester.longPress(find.byType(DrawSurface));
    await tester.pump();
    expect(vector.adjusting, isTrue);
    final id = vector.selectedId!;

    // ドラッグで移動(+20, 0)。
    await tester.drag(find.byType(DrawSurface), const Offset(20, 0));
    await tester.pump();
    final moved = vector.layer.byId(id)! as VectorShapeObject;
    expect(moved.start.x, closeTo(100, 1)); // 80 → 100
  });

  testWidgets('長押しからそのまま同じ指でドラッグして移動でき、undo できる(回帰)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final vector = VectorController()
      ..addShape(
        kind: ShapeKind.rectangle,
        start: const VecPoint(80, 80),
        end: const VecPoint(120, 120),
        colorHex: '#000000',
        width: 4,
        filled: true,
      );
    await pumpVector(tester, controller, surface, vector);

    // 中心を押し続けて長押し成立 → そのまま同じ指で移動。
    final g = await tester.startGesture(
      tester.getCenter(find.byType(DrawSurface)),
    );
    await tester.pump(const Duration(milliseconds: 500)); // 長押し発火
    expect(vector.adjusting, isTrue);
    final id = vector.selectedId!;

    await g.moveBy(const Offset(25, 0));
    await tester.pump();
    await g.up();
    await tester.pump();

    final moved = vector.layer.byId(id)! as VectorShapeObject;
    expect(moved.start.x, closeTo(105, 1)); // 80 → 105
    expect(vector.canUndo, isTrue); // 移動は undo 可能
    vector.undo();
    expect(
      (vector.layer.byId(id)! as VectorShapeObject).start.x,
      closeTo(80, 1),
    );
  });

  testWidgets('長押しでオブジェクト調整: ピンチで拡大する', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final vector = VectorController()
      ..addShape(
        kind: ShapeKind.rectangle,
        start: const VecPoint(80, 80),
        end: const VecPoint(120, 120),
        colorHex: '#000000',
        width: 4,
        filled: true,
      );
    await pumpVector(tester, controller, surface, vector);

    await tester.longPress(find.byType(DrawSurface));
    await tester.pump();
    final id = vector.selectedId!;
    final before = vector.layer.byId(id)! as VectorShapeObject;
    final beforeW = before.end.x - before.start.x;

    // 2 本指を広げてピンチ拡大。
    final center = tester.getCenter(find.byType(DrawSurface));
    final g1 = await tester.startGesture(
      center + const Offset(-10, 0),
      pointer: 1,
    );
    final g2 = await tester.startGesture(
      center + const Offset(10, 0),
      pointer: 2,
    );
    await g1.moveBy(const Offset(-30, 0));
    await g2.moveBy(const Offset(30, 0));
    await g1.up();
    await g2.up();
    await tester.pump();

    final after = vector.layer.byId(id)! as VectorShapeObject;
    expect(after.end.x - after.start.x, greaterThan(beforeW));
  });

  testWidgets('グラデブラシ: 2色目を持つストロークが焼き込まれる', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface)
      ..setColorHex('#CF4A2C')
      ..setSecondColorHex('#2C4A63')
      ..setGradientBrush(true);
    await _pump(tester, controller, surface);
    final id = controller.layers.active.id;

    await tester.drag(find.byType(DrawSurface), const Offset(60, 0));
    await tester.pump();

    expect(surface.imageOf(id), isNotNull);
    expect(controller.canUndo, isTrue);
  });

  testWidgets('変形モード: 移動して確定で焼き込み、undo で戻る(Phase3b)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final key = GlobalKey<DrawSurfaceState>();
    final transforming = ValueNotifier<bool>(false);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: DrawSurface(
                key: key,
                controller: controller,
                surface: surface,
                clock: FakeClock(),
                transforming: transforming,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(DrawSurface), const Offset(40, 30));
    await tester.pump();
    final id = controller.layers.active.id;
    final before = surface.imageOf(id);
    expect(before, isNotNull);

    key.currentState!.enterTransform();
    await tester.pump();
    expect(transforming.value, isTrue);

    // 1 本指で移動(プレビュー)。確定までレイヤー画像は変わらない。
    await tester.drag(find.byType(DrawSurface), const Offset(20, 10));
    await tester.pump();
    expect(surface.imageOf(id), same(before));

    key.currentState!.confirmTransform();
    await tester.pump();
    expect(transforming.value, isFalse);
    expect(surface.imageOf(id), isNotNull);
    expect(surface.imageOf(id), isNot(same(before))); // 新しい画像へ焼込
    expect(controller.canUndo, isTrue);

    controller.undo();
    expect(surface.imageOf(id), same(before)); // 変形前へ戻る

    transforming.dispose();
  });
}
