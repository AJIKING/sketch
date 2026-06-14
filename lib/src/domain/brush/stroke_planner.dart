import 'dart:math';

import 'brush_preset.dart';

/// 線分スタンプ(ink / marker)。UI 側でこの幾何をラスタライズする。
class Segment {
  const Segment({
    required this.from,
    required this.to,
    required this.width,
    required this.alpha,
    required this.round,
    required this.flat,
  });

  final Point<double> from;
  final Point<double> to;
  final double width;
  final double alpha;

  /// 線端を丸める(ink）か否か。
  final bool round;

  /// 平筆(marker。lineCap=butt)か否か。
  final bool flat;
}

/// 点スタンプ(pencil / air)。
class Dab {
  const Dab({
    required this.center,
    required this.radius,
    required this.alpha,
    required this.soft,
  });

  final Point<double> center;
  final double radius;
  final double alpha;

  /// 放射グラデーション(air)で積むか、硬い点(pencil)か。
  final bool soft;
}

/// 1 ストローク区間(前点→現点)の描画計画。
///
/// ink / marker は [segments] に 1 本、pencil / air は [dabs] にダブ列が入る。
/// domain は「何をどこに描くか」までを返し、ピクセル化は ui 層が行う
/// (`docs/architecture.md` / ADR 0003)。
class StrokePlan {
  const StrokePlan({this.segments = const [], this.dabs = const []});

  final List<Segment> segments;
  final List<Dab> dabs;
}

/// 前点 [from] から現点 [to] への 1 区間を、ブラシ・サイズ・不透明度・速度から
/// スタンプ列へ変換する純関数。
///
/// 散らし(scatter)・粒状感の乱数は注入した [random] を使う。同じ引数なら
/// 同じ出力になる(プロトタイプの `Math.random()` 直叩きは踏襲しない)。
///
/// - [size]: ブラシサイズ(入力点と同じ座標系の論理値。DPR は ui 側で扱う)。
/// - [opacity]: 0..1。
/// - [speed]: 移動距離 / 経過時間。ink の筆幅にのみ影響する。
StrokePlan planStroke({
  required Point<double> from,
  required Point<double> to,
  required double speed,
  required BrushPreset brush,
  required double size,
  required double opacity,
  required Random random,
}) {
  final base = size;

  if (brush.isStroked) {
    // ink は速度で細る。marker は base 固定。
    final width = brush.key == 'ink'
        ? base * (1.15 - speed * 0.9).clamp(0.4, 1.0)
        : base;
    return StrokePlan(
      segments: [
        Segment(
          from: from,
          to: to,
          width: width,
          alpha: brush.flow * opacity,
          round: brush.soft == 0, // ink: 丸 / marker: 平
          flat: brush.key == 'marker',
        ),
      ],
    );
  }

  // pencil / air: spacing 間隔でダブを置き、scatter 分だけ位置を散らす。
  final dx = to.x - from.x;
  final dy = to.y - from.y;
  final dist = sqrt(dx * dx + dy * dy);
  final step = max(base * brush.spacing, 1.0);
  final n = max(1, (dist / step).floor());

  final dabs = <Dab>[];
  for (var i = 0; i <= n; i++) {
    final t = i / n;
    // 乱数の消費順は固定(再現性のため): dx-jitter → dy-jitter →
    // (pencil のみ) alpha-jitter → radius-jitter。
    final jx = (random.nextDouble() - 0.5) * base * brush.scatter;
    final jy = (random.nextDouble() - 0.5) * base * brush.scatter;
    final x = from.x + dx * t + jx;
    final y = from.y + dy * t + jy;

    if (brush.soft > 0) {
      // air: やわらかい放射グラデーションを積む。
      dabs.add(
        Dab(
          center: Point(x, y),
          radius: base,
          alpha: brush.flow * opacity,
          soft: true,
        ),
      );
    } else {
      // pencil: 硬い点をランダムな濃さ・大きさで重ねる。
      final alpha = brush.flow * opacity * (0.5 + random.nextDouble() * 0.5);
      final radius = base * (0.25 + random.nextDouble() * 0.2);
      dabs.add(
        Dab(center: Point(x, y), radius: radius, alpha: alpha, soft: false),
      );
    }
  }
  return StrokePlan(dabs: dabs);
}
