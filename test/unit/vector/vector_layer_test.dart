import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/domain/vector/vector_layer.dart';
import 'package:sketch/src/domain/vector/vector_object.dart';

VectorStroke _dot(String id, double x, double y, {String color = '#000000'}) =>
    VectorStroke(id: id, colorHex: color, width: 10, points: [VecPoint(x, y)]);

void main() {
  test('add / byId / removeById', () {
    final layer = VectorLayer();
    layer.add(_dot('a', 0, 0));
    layer.add(_dot('b', 50, 50));
    expect(layer.length, 2);
    expect(layer.byId('b'), isNotNull);
    expect(layer.removeById('a'), isTrue);
    expect(layer.removeById('missing'), isFalse);
    expect(layer.length, 1);
  });

  test('hitTest は最前面(末尾)優先', () {
    final layer = VectorLayer();
    layer.add(_dot('back', 0, 0));
    layer.add(_dot('front', 0, 0)); // 同位置に重なる
    expect(layer.hitTest(const VecPoint(0, 0), tolerance: 0)!.id, 'front');
    expect(layer.hitTest(const VecPoint(999, 999)), isNull);
  });

  test('moveBy / recolor / setWidth', () {
    final layer = VectorLayer()..add(_dot('a', 0, 0));
    expect(layer.moveBy('a', 5, 5), isTrue);
    expect(
      (layer.byId('a')! as VectorStroke).points.first,
      const VecPoint(5, 5),
    );
    expect(layer.recolor('a', '#FF0000'), isTrue);
    expect(layer.byId('a')!.colorHex, '#FF0000');
    expect(layer.setWidth('a', 3), isTrue);
    expect(layer.byId('a')!.width, 3);
    expect(layer.moveBy('missing', 1, 1), isFalse);
  });

  test('bringToFront / sendToBack で描画順が変わる', () {
    final layer = VectorLayer()
      ..add(_dot('a', 0, 0))
      ..add(_dot('b', 1, 1))
      ..add(_dot('c', 2, 2));
    layer.bringToFront('a');
    expect(layer.objects.map((o) => o.id), ['b', 'c', 'a']);
    layer.sendToBack('c');
    expect(layer.objects.map((o) => o.id), ['c', 'b', 'a']);
  });

  test('copy は独立(追加が元へ波及しない)', () {
    final layer = VectorLayer()..add(_dot('a', 0, 0));
    final twin = layer.copy();
    twin.add(_dot('b', 9, 9));
    expect(layer.length, 1);
    expect(twin.length, 2);
  });
}
