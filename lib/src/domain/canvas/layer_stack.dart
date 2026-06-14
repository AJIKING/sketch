import 'layer_blend_mode.dart';

/// レイヤーのメタ情報(pure Dart)。
///
/// ピクセル(`dart:ui.Image`)は持たない。画素は ui / application が
/// レイヤー [id] をキーに別管理する(`docs/architecture.md` / ADR 0004)。
class LayerMeta {
  LayerMeta({
    required this.id,
    required this.name,
    this.visible = true,
    this.opacity = 1,
    this.blendMode = LayerBlendMode.normal,
    this.alphaLocked = false,
    this.clipToLower = false,
  });

  final String id;
  String name;
  bool visible;
  double opacity;

  /// 合成モード(乗算・スクリーン等)。
  LayerBlendMode blendMode;

  /// 不透明部分のみ描けるアルファロック。
  bool alphaLocked;

  /// 直下のレイヤーへのクリッピング(下の不透明部分にのみ表示)。
  bool clipToLower;
}

/// レイヤーの並びとアクティブ位置を管理する(pure Dart)。
///
/// プロトタイプ準拠: index 0 が最下層、末尾が最前面。初期状態は 2 枚で
/// 最前面(末尾)がアクティブ。`docs/test-plan.md`「レイヤー操作」を満たす。
class LayerStack {
  LayerStack._(this._layers, this._activeIndex, this._counter);

  /// 初期状態(レイヤー 2 枚、最前面アクティブ)。
  factory LayerStack.initial() {
    final stack = LayerStack._([], 0, 0);
    stack._append();
    stack._append();
    stack._activeIndex = stack._layers.length - 1; // 最前面
    return stack;
  }

  final List<LayerMeta> _layers;
  int _activeIndex;
  int _counter;

  List<LayerMeta> get layers => List.unmodifiable(_layers);
  int get length => _layers.length;
  int get activeIndex => _activeIndex;
  LayerMeta get active => _layers[_activeIndex];

  LayerMeta _append() {
    _counter++;
    final layer = LayerMeta(
      id: 'layer-$_counter',
      name: 'レイヤー ${_layers.length + 1}',
    );
    _layers.add(layer);
    return layer;
  }

  /// 新しいレイヤーを最前面に追加し、アクティブにする。追加したレイヤーを返す。
  LayerMeta add() {
    final layer = _append();
    _activeIndex = _layers.length - 1;
    return layer;
  }

  /// [index] のレイヤーを削除する。最後の 1 枚は削除できず false を返す。
  bool remove(int index) {
    if (_layers.length <= 1) return false;
    _layers.removeAt(index);
    if (_activeIndex >= _layers.length) {
      _activeIndex = _layers.length - 1;
    } else if (_activeIndex > index) {
      _activeIndex--;
    }
    return true;
  }

  void setActive(int index) {
    if (index < 0 || index >= _layers.length) return;
    _activeIndex = index;
  }

  void toggleVisible(int index) {
    _layers[index].visible = !_layers[index].visible;
  }

  void setOpacity(int index, double opacity) {
    _layers[index].opacity = opacity.clamp(0.0, 1.0);
  }

  void setBlendMode(int index, LayerBlendMode mode) {
    _layers[index].blendMode = mode;
  }

  void toggleAlphaLock(int index) {
    _layers[index].alphaLocked = !_layers[index].alphaLocked;
  }

  void toggleClip(int index) {
    _layers[index].clipToLower = !_layers[index].clipToLower;
  }
}
