import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// キャンバスのビューポート変換(拡大率・回転・平行移動)。
///
/// canvas(ドキュメント)座標 ⇄ view(画面)座標を相互変換する。描画入力は
/// [toCanvas] で canvas 座標へ戻してから扱い、表示は [toMatrix] を Canvas に
/// 適用する(Phase3)。
class ViewportTransform {
  const ViewportTransform({
    this.scale = 1,
    this.rotation = 0,
    this.offset = Offset.zero,
  });

  final double scale;
  final double rotation;
  final Offset offset;

  ViewportTransform copyWith({
    double? scale,
    double? rotation,
    Offset? offset,
  }) => ViewportTransform(
    scale: scale ?? this.scale,
    rotation: rotation ?? this.rotation,
    offset: offset ?? this.offset,
  );

  /// canvas 座標 → view 座標。
  Offset toView(Offset c) {
    final cosr = math.cos(rotation);
    final sinr = math.sin(rotation);
    return Offset(
      (c.dx * cosr - c.dy * sinr) * scale + offset.dx,
      (c.dx * sinr + c.dy * cosr) * scale + offset.dy,
    );
  }

  /// view 座標 → canvas 座標(逆変換)。
  Offset toCanvas(Offset v) {
    final dx = (v.dx - offset.dx) / scale;
    final dy = (v.dy - offset.dy) / scale;
    final cosr = math.cos(-rotation);
    final sinr = math.sin(-rotation);
    return Offset(dx * cosr - dy * sinr, dx * sinr + dy * cosr);
  }

  /// 表示用の行列(列優先。[toView] と一致する)。
  Matrix4 toMatrix() {
    final cosr = math.cos(rotation);
    final sinr = math.sin(rotation);
    return Matrix4(
      scale * cosr,
      scale * sinr,
      0,
      0, // col0
      -scale * sinr,
      scale * cosr,
      0,
      0, // col1
      0,
      0,
      1,
      0, // col2
      offset.dx,
      offset.dy,
      0,
      1, // col3
    );
  }

  /// アートボード [doc] を表示域 [view] に歪みなく収める変換(中央寄せ・無回転)。
  ///
  /// アスペクト比を保ったまま「縦横どちらか」が収まる倍率にし、余白を均等に振る。
  /// 端末回転やリサイズで表示域が変わったときの基準ビューポートに使う。
  static ViewportTransform fit(Size doc, Size view) {
    if (doc.isEmpty || view.isEmpty) return const ViewportTransform();
    final scale = math.min(view.width / doc.width, view.height / doc.height);
    return ViewportTransform(
      scale: scale,
      offset: Offset(
        (view.width - doc.width * scale) / 2,
        (view.height - doc.height * scale) / 2,
      ),
    );
  }

  /// 2 本指ジェスチャから新しい変換を求める。
  ///
  /// ジェスチャ開始時の状態 [start] と 2 点 [a0],[b0]、現在の 2 点 [a],[b] から、
  /// 掴んだ canvas 点が指の中点に追従するよう scale/rotation/offset を更新する。
  static ViewportTransform fromTwoFinger({
    required ViewportTransform start,
    required Offset a0,
    required Offset b0,
    required Offset a,
    required Offset b,
  }) {
    final d0 = (b0 - a0).distance;
    final d = (b - a).distance;
    final scaleFactor = d0 == 0 ? 1.0 : d / d0;
    final ang0 = math.atan2((b0 - a0).dy, (b0 - a0).dx);
    final ang = math.atan2((b - a).dy, (b - a).dx);

    final newScale = (start.scale * scaleFactor).clamp(0.1, 20.0);
    final newRotation = start.rotation + (ang - ang0);

    final focal0 = (a0 + b0) / 2;
    final focal = (a + b) / 2;
    final canvasFocal = start.toCanvas(focal0);

    final cosr = math.cos(newRotation);
    final sinr = math.sin(newRotation);
    final rx = (canvasFocal.dx * cosr - canvasFocal.dy * sinr) * newScale;
    final ry = (canvasFocal.dx * sinr + canvasFocal.dy * cosr) * newScale;

    return ViewportTransform(
      scale: newScale,
      rotation: newRotation,
      offset: Offset(focal.dx - rx, focal.dy - ry),
    );
  }
}
