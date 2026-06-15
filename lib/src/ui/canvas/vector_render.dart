import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/color/ink_color.dart';
import '../../domain/vector/vector_layer.dart';
import '../../domain/vector/vector_object.dart';
import 'shape_render.dart';

/// 解決済みフォントファミリ名のキャッシュ(family → 実フォント名)。
///
/// 描画は毎フレーム走るため、google_fonts の `getFont`(ロード future を毎回
/// 生成する)を都度呼ばず、初回に登録名だけ控えて以降は素の `fontFamily` 指定で
/// 描く。ロード失敗(オフライン初回など)は握り潰し、未処理例外を残さない。
final Map<String, String> _resolvedFontFamily = {};

/// [family] を google_fonts で解決して登録名を返す(初回のみロードを起動)。
/// 取得できない/失敗時は空(= 既定フォントへフォールバック)。
String _resolveFontFamily(String family) {
  if (family.isEmpty) return '';
  return _resolvedFontFamily.putIfAbsent(family, () {
    final resolved = GoogleFonts.getFont(family).fontFamily ?? '';
    // ロード future の失敗を握り潰す(未処理例外・ログ汚染を避ける)。
    unawaited(GoogleFonts.pendingFonts().catchError((Object _) => <void>[]));
    return resolved;
  });
}

/// テスト/プリロード用: [family] の実フォントのロード完了を待つ。失敗は無視。
Future<void> ensureFontLoaded(String family) async {
  if (family.isEmpty) return;
  GoogleFonts.getFont(family); // 未開始ならロードを起動
  try {
    await GoogleFonts.pendingFonts();
  } catch (_) {
    // オフライン等。フォールバックで続行する。
  }
  _resolvedFontFamily.putIfAbsent(
    family,
    () => GoogleFonts.getFont(family).fontFamily ?? '',
  );
}

/// ベクターレイヤー(ADR 0005)を `Canvas` へ描く(ui 層)。
///
/// 幾何・編集は domain(`VectorObject` / `VectorLayer`)が持ち、ここは色とパスへ
/// 落とすだけ。図形は `renderShape` を再利用する。ラスター合成へ渡すときは、
/// 呼び出し側が `PictureRecorder` 経由で `ui.Image` 化する。
void renderVectorLayer(Canvas canvas, VectorLayer layer) {
  for (final object in layer.objects) {
    renderVectorObject(canvas, object);
  }
}

void renderVectorObject(Canvas canvas, VectorObject object) {
  final (r, g, b) = hexToRgb(object.colorHex);
  switch (object) {
    case VectorStroke stroke:
      final color = Color.fromARGB(255, r, g, b);
      final first = stroke.points.first;
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          Offset(first.x, first.y),
          stroke.width / 2,
          Paint()..color = color,
        );
        return;
      }
      final path = Path()..moveTo(first.x, first.y);
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.x, p.y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = stroke.width
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    case VectorShapeObject shape:
      renderShape(
        canvas,
        kind: shape.kind,
        start: Offset(shape.start.x, shape.start.y),
        end: Offset(shape.end.x, shape.end.y),
        rgb: (r, g, b),
        size: shape.width,
        opacity: 1,
        filled: shape.filled,
      );
    case VectorText t:
      buildVectorTextPainter(
        text: t.text,
        colorHex: t.colorHex,
        fontSize: t.fontSize,
        bold: t.bold,
        underline: t.underline,
        strikethrough: t.strikethrough,
        fontFamily: t.fontFamily,
        gradient: t.gradient,
        secondColorHex: t.secondColorHex,
      ).paint(canvas, Offset(t.position.x, t.position.y));
  }
}

/// テキストの描画/測定に使う `TextPainter`(レイアウト済み)。下線・取消線・
/// フォント・2 色グラデーションに対応。描画(`vector_render`)と box 測定
/// (`draw_surface`)で同じ体裁を使うため共有する。
TextPainter buildVectorTextPainter({
  required String text,
  required String colorHex,
  required double fontSize,
  required bool bold,
  required bool underline,
  required bool strikethrough,
  String? fontFamily,
  bool gradient = false,
  String? secondColorHex,
}) {
  final (r, g, b) = hexToRgb(colorHex);
  final color = Color.fromARGB(255, r, g, b);
  final decorations = <TextDecoration>[
    if (underline) TextDecoration.underline,
    if (strikethrough) TextDecoration.lineThrough,
  ];
  final weight = bold ? FontWeight.w800 : FontWeight.w600;

  var style = TextStyle(
    color: color,
    fontSize: fontSize,
    fontWeight: weight,
    decoration: TextDecoration.combine(decorations),
    decorationColor: color,
    decorationThickness: 2,
    height: 1.2,
  );
  // フォント指定があれば解決名を適用(初回のみ取得、以降は名前指定で描く)。
  if (fontFamily != null && fontFamily.isNotEmpty) {
    final resolved = _resolveFontFamily(fontFamily);
    if (resolved.isNotEmpty) style = style.copyWith(fontFamily: resolved);
  }

  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  // グラデーションは前景シェーダで上書きする(レイアウト後の寸法が要るので 2 段)。
  if (gradient) {
    final (sr, sg, sb) = hexToRgb(
      (secondColorHex == null || secondColorHex.isEmpty)
          ? colorHex
          : secondColorHex,
    );
    final shader = ui.Gradient.linear(Offset.zero, Offset(painter.width, 0), [
      color,
      Color.fromARGB(255, sr, sg, sb),
    ]);
    painter.text = TextSpan(
      text: text,
      style: style.copyWith(
        color: null,
        foreground: Paint()..shader = shader,
        decorationColor: color,
      ),
    );
    painter.layout();
  }
  return painter;
}
