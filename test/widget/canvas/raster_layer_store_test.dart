import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/ui/canvas/raster_layer_store.dart';

Future<ui.Image> _img() {
  final rec = ui.PictureRecorder();
  ui.Canvas(rec).drawRect(
    const Rect.fromLTWH(0, 0, 1, 1),
    ui.Paint()..color = const Color(0xFFFFFFFF),
  );
  return rec.endRecording().toImage(1, 1);
}

void main() {
  testWidgets('参照計数: ライブと履歴の双方が外れた画像だけ破棄する', (tester) async {
    await tester.runAsync(() async {
      final store = RasterLayerStore();
      final a = await _img();
      final b = await _img();

      store.set('L', a); // live = a
      final snap = store.snapshot('L'); // スナップショットも a を参照

      store.set('L', b); // live を b へ。a はスナップショットが保持 → まだ破棄しない
      expect(a.debugDisposed, isFalse, reason: '履歴が握っている間は生存');
      expect(b.debugDisposed, isFalse);

      store.disposeSnapshot(snap); // 最後の a 参照が外れる → 破棄
      expect(a.debugDisposed, isTrue);
      expect(b.debugDisposed, isFalse, reason: 'b はまだライブ');

      store.disposeAll();
      expect(b.debugDisposed, isTrue);
    });
  });

  testWidgets('参照計数: 同じ画像を 2 つのスナップショットが共有しても二重破棄しない', (tester) async {
    await tester.runAsync(() async {
      final store = RasterLayerStore();
      final a = await _img();
      store.set('L', a);
      final s1 = store.snapshot('L');
      final s2 = store.snapshot('L'); // 同じ a を共有

      store.clear('L'); // ライブ参照を外す(まだ s1/s2 が保持)
      expect(a.debugDisposed, isFalse);
      store.disposeSnapshot(s1);
      expect(a.debugDisposed, isFalse, reason: 's2 がまだ保持');
      store.disposeSnapshot(s2);
      expect(a.debugDisposed, isTrue); // 最後の参照で 1 回だけ破棄
    });
  });
}
