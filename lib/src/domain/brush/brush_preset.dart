/// ブラシプリセット(pure Dart)。
///
/// プロトタイプ `docs/prototype/hatch-sketch-app.html` の `BRUSHES` を起点に拡張。
/// 各値の意味:
/// - [flow]: 基本の不透明度(α の係数)。
/// - [soft]: ぼかし。> 0 で放射グラデーション(エアブラシ系)になる。
/// - [scatter]: ダブを散らす量(0 で散らさない)。
/// - [spacing]: ダブ間隔(サイズに対する比)。
/// - [stroked]: 線分で描く(true)か、ダブを散らして描く(false)か。
/// - [velocity]: 速度で筆幅を細らせる(ink/筆系)。
/// - [flat]: 平筆(線端 butt)。マーカー系。
class BrushPreset {
  const BrushPreset({
    required this.key,
    required this.flow,
    required this.soft,
    required this.scatter,
    required this.spacing,
    this.stroked = false,
    this.velocity = false,
    this.flat = false,
  });

  /// プリセットの識別子(`ink` / `pencil` …)。表示名・説明は UI 層
  /// ([AppLocalizations] 経由・`ui/canvas/l10n_labels.dart`)で [key] から解決する。
  final String key;
  final double flow;
  final double soft;
  final double scatter;
  final double spacing;
  final bool stroked;
  final bool velocity;
  final bool flat;

  bool get isStroked => stroked;

  BrushPreset copyWith({
    double? flow,
    double? soft,
    double? scatter,
    double? spacing,
  }) => BrushPreset(
    key: key,
    flow: flow ?? this.flow,
    soft: soft ?? this.soft,
    scatter: scatter ?? this.scatter,
    spacing: spacing ?? this.spacing,
    stroked: stroked,
    velocity: velocity,
    flat: flat,
  );
}

const BrushPreset inkBrush = BrushPreset(
  key: 'ink',
  flow: 1,
  soft: 0,
  scatter: 0,
  spacing: 0.25,
  stroked: true,
  velocity: true,
);

const BrushPreset pencilBrush = BrushPreset(
  key: 'pencil',
  flow: 0.5,
  soft: 0,
  scatter: 0.9,
  spacing: 0.5,
);

const BrushPreset markerBrush = BrushPreset(
  key: 'marker',
  flow: 0.55,
  soft: 0.1,
  scatter: 0,
  spacing: 0.2,
  stroked: true,
  flat: true,
);

const BrushPreset airBrush = BrushPreset(
  key: 'air',
  flow: 0.18,
  soft: 1,
  scatter: 0.2,
  spacing: 0.18,
);

const BrushPreset fudeBrush = BrushPreset(
  key: 'fude',
  flow: 1,
  soft: 0,
  scatter: 0,
  spacing: 0.2,
  stroked: true,
  velocity: true,
);

const BrushPreset crayonBrush = BrushPreset(
  key: 'crayon',
  flow: 0.65,
  soft: 0,
  scatter: 0.55,
  spacing: 0.3,
);

const BrushPreset chalkBrush = BrushPreset(
  key: 'chalk',
  flow: 0.45,
  soft: 0.3,
  scatter: 0.7,
  spacing: 0.45,
);

const BrushPreset stippleBrush = BrushPreset(
  key: 'stipple',
  flow: 0.9,
  soft: 0,
  scatter: 0.25,
  spacing: 1.4,
);

const BrushPreset softPenBrush = BrushPreset(
  key: 'softpen',
  flow: 0.6,
  soft: 0.6,
  scatter: 0.05,
  spacing: 0.12,
);

const BrushPreset glowBrush = BrushPreset(
  key: 'glow',
  flow: 0.12,
  soft: 1,
  scatter: 0,
  spacing: 0.1,
);

const BrushPreset spongeBrush = BrushPreset(
  key: 'sponge',
  flow: 0.4,
  soft: 0,
  scatter: 1,
  spacing: 0.6,
);

const BrushPreset dryBrush = BrushPreset(
  key: 'dry',
  flow: 0.7,
  soft: 0,
  scatter: 0.4,
  spacing: 0.75,
);

const BrushPreset maruPenBrush = BrushPreset(
  key: 'maru',
  flow: 1,
  soft: 0,
  scatter: 0,
  spacing: 0.18,
  stroked: true,
);

const BrushPreset ballPenBrush = BrushPreset(
  key: 'ballpen',
  flow: 0.9,
  soft: 0,
  scatter: 0.08,
  spacing: 0.22,
  stroked: true,
);

const BrushPreset gPenBrush = BrushPreset(
  key: 'gpen',
  flow: 1,
  soft: 0,
  scatter: 0,
  spacing: 0.14,
  stroked: true,
  velocity: true,
);

const BrushPreset watercolorBrush = BrushPreset(
  key: 'watercolor',
  flow: 0.2,
  soft: 0.55,
  scatter: 0.5,
  spacing: 0.28,
);

const BrushPreset oilBrush = BrushPreset(
  key: 'oil',
  flow: 0.85,
  soft: 0,
  scatter: 0.35,
  spacing: 0.45,
  stroked: true,
  flat: true,
);

const BrushPreset bristleBrush = BrushPreset(
  key: 'bristle',
  flow: 0.6,
  soft: 0,
  scatter: 0.7,
  spacing: 0.32,
);

/// ブラシシートの表示順。
const List<BrushPreset> brushPresets = [
  inkBrush,
  fudeBrush,
  gPenBrush,
  maruPenBrush,
  ballPenBrush,
  pencilBrush,
  markerBrush,
  airBrush,
  watercolorBrush,
  oilBrush,
  crayonBrush,
  chalkBrush,
  bristleBrush,
  stippleBrush,
  softPenBrush,
  glowBrush,
  spongeBrush,
  dryBrush,
];

/// key からプリセットを引く。未知の key は [inkBrush] にフォールバックする。
BrushPreset brushByKey(String key) =>
    brushPresets.firstWhere((b) => b.key == key, orElse: () => inkBrush);
