import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/application/gallery_controller.dart';
import 'package:sketch/src/domain/gallery/sketch.dart';
import 'package:sketch/src/ui/gallery/gallery_screen.dart';

import '../../fixtures/fake_clock.dart';
import '../../fixtures/in_memory_gallery_store.dart';

// 1x1 透明 PNG(Image.memory のデコードが成功するように本物を使う)。
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  testWidgets('点数とスケッチを表示し、新規/オープンのコールバックが呼ばれる', (tester) async {
    final controller = GalleryController(
      store: InMemoryGalleryStore(),
      clock: FakeClock(),
    );
    await controller.save(id: 'a', png: _png, title: '朝の習作');
    await controller.load();

    var newTapped = false;
    Sketch? opened;

    await tester.pumpWidget(
      MaterialApp(
        home: GalleryScreen(
          controller: controller,
          onNewCanvas: () => newTapped = true,
          onOpenSketch: (s) => opened = s,
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('1点'), findsOneWidget);
    expect(find.text('朝の習作'), findsOneWidget);
    expect(find.text('新規キャンバス'), findsOneWidget);

    await tester.tap(find.text('新規キャンバス'));
    expect(newTapped, isTrue);

    await tester.tap(find.text('朝の習作'));
    expect(opened?.id, 'a');
  });

  testWidgets('長押し→複製でスケッチが増える', (tester) async {
    final controller = GalleryController(
      store: InMemoryGalleryStore(),
      clock: FakeClock(),
    );
    await controller.save(id: 'a', png: _png, title: '朝の習作');
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: GalleryScreen(
          controller: controller,
          onNewCanvas: () {},
          onOpenSketch: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(controller.count, 1);

    await tester.longPress(find.text('朝の習作'));
    await tester.pumpAndSettle();
    expect(find.text('複製'), findsOneWidget);

    await tester.tap(find.text('複製'));
    await tester.pumpAndSettle();

    expect(controller.count, 2);
    expect(find.text('複製しました'), findsOneWidget); // SnackBar
    // 複製されたスケッチが「… のコピー」名で存在する。
    expect(
      controller.sketches.any((s) => s.title == '朝の習作 のコピー'),
      isTrue,
    );
  });

  testWidgets('スケッチ 0 件でも新規カードが出る', (tester) async {
    final controller = GalleryController(
      store: InMemoryGalleryStore(),
      clock: FakeClock(),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: GalleryScreen(
          controller: controller,
          onNewCanvas: () {},
          onOpenSketch: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('0点'), findsOneWidget);
    expect(find.text('新規キャンバス'), findsOneWidget);
  });
}
