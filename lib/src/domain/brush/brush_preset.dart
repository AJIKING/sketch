/// ブラシプリセット(pure Dart)。
///
/// プロトタイプ `docs/prototype/hatch-sketch-app.html` の `BRUSHES` を移植。
/// 各値の意味:
/// - [flow]: 基本の不透明度(α の係数)。
/// - [soft]: ぼかし。> 0 で放射グラデーション(エアブラシ)になる。
/// - [scatter]: ダブを散らす量(0 で散らさない)。
/// - [spacing]: ダブ間隔(サイズに対する比)。線系(ink/marker)では線分描画。
class BrushPreset {
  const BrushPreset({
    required this.key,
    required this.name,
    required this.description,
    required this.flow,
    required this.soft,
    required this.scatter,
    required this.spacing,
  });

  final String key;
  final String name;
  final String description;
  final double flow;
  final double soft;
  final double scatter;
  final double spacing;

  /// 線分で描く(ink / marker)か、ダブを散らして描く(pencil / air)か。
  bool get isStroked => key == 'ink' || key == 'marker';
}

const BrushPreset inkBrush = BrushPreset(
  key: 'ink',
  name: 'インク',
  description: 'なめらかで均一。速度で太さが変化',
  flow: 1,
  soft: 0,
  scatter: 0,
  spacing: 0.25,
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

/// プロトタイプの並び順(ブラシシートの表示順)を保持する。
const List<BrushPreset> brushPresets = [
  inkBrush,
  pencilBrush,
  markerBrush,
  airBrush,
];

/// key からプリセットを引く。未知の key は [inkBrush] にフォールバックする。
BrushPreset brushByKey(String key) =>
    brushPresets.firstWhere((b) => b.key == key, orElse: () => inkBrush);
