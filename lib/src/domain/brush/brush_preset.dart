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
    required this.name,
    required this.description,
    required this.flow,
    required this.soft,
    required this.scatter,
    required this.spacing,
    this.stroked = false,
    this.velocity = false,
    this.flat = false,
  });

  final String key;
  final String name;
  final String description;
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
    name: name,
    description: description,
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
  name: 'インク',
  description: 'なめらかで均一。速度で太さが変化',
  flow: 1,
  soft: 0,
  scatter: 0,
  spacing: 0.25,
  stroked: true,
  velocity: true,
);

const BrushPreset pencilBrush = BrushPreset(
  key: 'pencil',
  name: 'ペンシル',
  description: 'ざらりとした鉛筆。重ねるほど濃く',
  flow: 0.5,
  soft: 0,
  scatter: 0.9,
  spacing: 0.5,
);

const BrushPreset markerBrush = BrushPreset(
  key: 'marker',
  name: 'マーカー',
  description: '平らで半透明。重なりが色を作る',
  flow: 0.55,
  soft: 0.1,
  scatter: 0,
  spacing: 0.2,
  stroked: true,
  flat: true,
);

const BrushPreset airBrush = BrushPreset(
  key: 'air',
  name: 'エアブラシ',
  description: 'やわらかく霧状に積もる',
  flow: 0.18,
  soft: 1,
  scatter: 0.2,
  spacing: 0.18,
);

const BrushPreset fudeBrush = BrushPreset(
  key: 'fude',
  name: '筆',
  description: '入り抜きのある線。速度で強弱がつく',
  flow: 1,
  soft: 0,
  scatter: 0,
  spacing: 0.2,
  stroked: true,
  velocity: true,
);

const BrushPreset crayonBrush = BrushPreset(
  key: 'crayon',
  name: 'クレヨン',
  description: '粗い粒で塗り込む。ざらついた質感',
  flow: 0.65,
  soft: 0,
  scatter: 0.55,
  spacing: 0.3,
);

const BrushPreset chalkBrush = BrushPreset(
  key: 'chalk',
  name: 'チョーク',
  description: 'やわらかく粉っぽい。淡く重なる',
  flow: 0.45,
  soft: 0.3,
  scatter: 0.7,
  spacing: 0.45,
);

const BrushPreset stippleBrush = BrushPreset(
  key: 'stipple',
  name: '点描',
  description: 'まばらな点を打つ。点描・テクスチャ向き',
  flow: 0.9,
  soft: 0,
  scatter: 0.25,
  spacing: 1.4,
);

const BrushPreset softPenBrush = BrushPreset(
  key: 'softpen',
  name: 'ソフトペン',
  description: 'やわらかい縁。さらりと均一に乗る',
  flow: 0.6,
  soft: 0.6,
  scatter: 0.05,
  spacing: 0.12,
);

const BrushPreset glowBrush = BrushPreset(
  key: 'glow',
  name: 'グロー',
  description: 'ふんわり淡く積もる光。重ねて明るく',
  flow: 0.12,
  soft: 1,
  scatter: 0,
  spacing: 0.1,
);

const BrushPreset spongeBrush = BrushPreset(
  key: 'sponge',
  name: 'スポンジ',
  description: '大きく散る粒。ざらついた塗り',
  flow: 0.4,
  soft: 0,
  scatter: 1,
  spacing: 0.6,
);

const BrushPreset dryBrush = BrushPreset(
  key: 'dry',
  name: 'ドライ',
  description: 'かすれた擦れ。粗い質感の線',
  flow: 0.7,
  soft: 0,
  scatter: 0.4,
  spacing: 0.75,
);

/// ブラシシートの表示順。
const List<BrushPreset> brushPresets = [
  inkBrush,
  fudeBrush,
  pencilBrush,
  markerBrush,
  airBrush,
  crayonBrush,
  chalkBrush,
  stippleBrush,
  softPenBrush,
  glowBrush,
  spongeBrush,
  dryBrush,
];

/// key からプリセットを引く。未知の key は [inkBrush] にフォールバックする。
BrushPreset brushByKey(String key) =>
    brushPresets.firstWhere((b) => b.key == key, orElse: () => inkBrush);
