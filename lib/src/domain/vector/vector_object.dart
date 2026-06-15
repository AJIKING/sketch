import 'dart:math' as math;

import '../canvas/shape_kind.dart';

/// ベクターの座標(pure Dart, `dart:ui` 非依存)。
typedef VecPoint = math.Point<double>;

/// バウンディングボックス(left, top, right, bottom)。
typedef VecBounds = ({double left, double top, double right, double bottom});

/// 再編集可能なベクターオブジェクト(ADR 0005, pure Dart, 不変)。
///
/// 移動 / 色変更 / 線幅変更は新しいインスタンスを返す(不変)。当たり判定 [hitTest]
/// と外接矩形 [bounds] を提供する。描画は ui 層の `vector_render` が行う。
sealed class VectorObject {
  const VectorObject({
    required this.id,
    required this.colorHex,
    required this.width,
  });

  final String id;
  final String colorHex;
  final double width;

  VectorObject translate(double dx, double dy);
  VectorObject withColor(String colorHex);
  VectorObject withWidth(double width);

  VecBounds get bounds;
  bool hitTest(VecPoint p, {double tolerance = 8});
}

/// 点列ストローク(線)。
class VectorStroke extends VectorObject {
  VectorStroke({
    required super.id,
    required super.colorHex,
    required super.width,
    required List<VecPoint> points,
  }) : assert(points.isNotEmpty, 'stroke needs at least 1 point'),
       points = List.unmodifiable(points);

  final List<VecPoint> points;

  @override
  VectorStroke translate(double dx, double dy) => VectorStroke(
    id: id,
    colorHex: colorHex,
    width: width,
    points: [for (final p in points) VecPoint(p.x + dx, p.y + dy)],
  );

  @override
  VectorStroke withColor(String colorHex) =>
      VectorStroke(id: id, colorHex: colorHex, width: width, points: points);

  @override
  VectorStroke withWidth(double width) =>
      VectorStroke(id: id, colorHex: colorHex, width: width, points: points);

  @override
  VecBounds get bounds {
    var minX = points.first.x, maxX = points.first.x;
    var minY = points.first.y, maxY = points.first.y;
    for (final p in points) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }
    return (left: minX, top: minY, right: maxX, bottom: maxY);
  }

  @override
  bool hitTest(VecPoint p, {double tolerance = 8}) {
    final r = width / 2 + tolerance;
    if (points.length == 1) return p.distanceTo(points.first) <= r;
    for (var i = 1; i < points.length; i++) {
      if (_distToSegment(p, points[i - 1], points[i]) <= r) return true;
    }
    return false;
  }
}

/// 図形オブジェクト(`ShapeKind` + 外接矩形)。
class VectorShapeObject extends VectorObject {
  const VectorShapeObject({
    required super.id,
    required super.colorHex,
    required super.width,
    required this.kind,
    required this.start,
    required this.end,
    this.filled = false,
  });

  final ShapeKind kind;
  final VecPoint start;
  final VecPoint end;
  final bool filled;

  VectorShapeObject _copyWith({
    String? colorHex,
    double? width,
    VecPoint? start,
    VecPoint? end,
  }) => VectorShapeObject(
    id: id,
    colorHex: colorHex ?? this.colorHex,
    width: width ?? this.width,
    kind: kind,
    start: start ?? this.start,
    end: end ?? this.end,
    filled: filled,
  );

  @override
  VectorShapeObject translate(double dx, double dy) => _copyWith(
    start: VecPoint(start.x + dx, start.y + dy),
    end: VecPoint(end.x + dx, end.y + dy),
  );

  @override
  VectorShapeObject withColor(String colorHex) => _copyWith(colorHex: colorHex);

  @override
  VectorShapeObject withWidth(double width) => _copyWith(width: width);

  @override
  VecBounds get bounds => (
    left: math.min(start.x, end.x),
    top: math.min(start.y, end.y),
    right: math.max(start.x, end.x),
    bottom: math.max(start.y, end.y),
  );

  @override
  bool hitTest(VecPoint p, {double tolerance = 8}) {
    // 直線は線分との距離。他(矩形/三角/楕円)は外接矩形ベースの近似。
    if (kind == ShapeKind.line) {
      return _distToSegment(p, start, end) <= width / 2 + tolerance;
    }
    final b = bounds;
    return p.x >= b.left - tolerance &&
        p.x <= b.right + tolerance &&
        p.y >= b.top - tolerance &&
        p.y <= b.bottom + tolerance;
  }
}

/// テキストオブジェクト(再編集可能)。
///
/// 描画ボックスのサイズ([boxWidth]/[boxHeight])は UI 層が `TextPainter` で測って
/// 渡す(domain は `dart:ui` 非依存のため自前で測れない)。当たり判定/外接矩形は
/// このボックスを使う。基底の [width] は [fontSize] と同義。
class VectorText extends VectorObject {
  const VectorText({
    required super.id,
    required super.colorHex,
    required this.position,
    required this.text,
    required this.fontSize,
    required this.boxWidth,
    required this.boxHeight,
    this.bold = false,
    this.underline = false,
    this.strikethrough = false,
  }) : super(width: fontSize);

  final VecPoint position; // 左上(canvas/doc 空間)
  final String text;
  final double fontSize;
  final double boxWidth;
  final double boxHeight;
  final bool bold;
  final bool underline;
  final bool strikethrough;

  VectorText copyWith({
    String? colorHex,
    VecPoint? position,
    String? text,
    double? fontSize,
    double? boxWidth,
    double? boxHeight,
    bool? bold,
    bool? underline,
    bool? strikethrough,
  }) => VectorText(
    id: id,
    colorHex: colorHex ?? this.colorHex,
    position: position ?? this.position,
    text: text ?? this.text,
    fontSize: fontSize ?? this.fontSize,
    boxWidth: boxWidth ?? this.boxWidth,
    boxHeight: boxHeight ?? this.boxHeight,
    bold: bold ?? this.bold,
    underline: underline ?? this.underline,
    strikethrough: strikethrough ?? this.strikethrough,
  );

  @override
  VectorText translate(double dx, double dy) =>
      copyWith(position: VecPoint(position.x + dx, position.y + dy));

  @override
  VectorText withColor(String colorHex) => copyWith(colorHex: colorHex);

  @override
  VectorText withWidth(double width) {
    // フォントサイズに比例してボックスも縮拡し、当たり判定と描画をずらさない。
    final factor = fontSize == 0 ? 1.0 : width / fontSize;
    return copyWith(
      fontSize: width,
      boxWidth: boxWidth * factor,
      boxHeight: boxHeight * factor,
    );
  }

  @override
  VecBounds get bounds => (
    left: position.x,
    top: position.y,
    right: position.x + boxWidth,
    bottom: position.y + boxHeight,
  );

  @override
  bool hitTest(VecPoint p, {double tolerance = 8}) =>
      p.x >= position.x - tolerance &&
      p.x <= position.x + boxWidth + tolerance &&
      p.y >= position.y - tolerance &&
      p.y <= position.y + boxHeight + tolerance;
}

/// 点 [p] と線分 [a]-[b] の最短距離。
double _distToSegment(VecPoint p, VecPoint a, VecPoint b) {
  final dx = b.x - a.x, dy = b.y - a.y;
  final lenSq = dx * dx + dy * dy;
  if (lenSq == 0) return p.distanceTo(a);
  var t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / lenSq;
  t = t.clamp(0.0, 1.0);
  return p.distanceTo(VecPoint(a.x + t * dx, a.y + t * dy));
}
