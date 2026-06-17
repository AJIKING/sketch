import 'layer_blend_mode.dart';

/// レイヤー [layerId] のマスク画像を格納するための派生 id。
///
/// マスクの画素はレイヤー画素と同じ surface に、この id をキーに保持する。マスクは
/// アルファでレイヤーの可視範囲を制御する(alpha=0 で隠す)非破壊の仕組み。
String maskLayerId(String layerId) => '$layerId#mask';

/// レイヤーのメタ情報(pure Dart)。
///
/// ピクセル(`dart:ui.Image`)は持たない。画素は ui / application が
/// レイヤー [id] をキーに別管理する(`docs/architecture.md` / ADR 0004)。
class LayerMeta {
  LayerMeta({
    required this.id,
    required this.number,
    this.visible = true,
    this.opacity = 1,
    this.blendMode = LayerBlendMode.normal,
    this.alphaLocked = false,
    this.clipToLower = false,
    this.hasMask = false,
  });

  final String id;

  /// 作成順の通し番号(1 始まり)。表示名「レイヤー N / Layer N / 图层 N」は UI 層が
  /// [AppLocalizations] でこの番号から組み立てる(`docs/architecture.md`「UI が表示を所有」)。
  final int number;
  bool visible;
  double opacity;

  /// 合成モード(乗算・スクリーン等)。
  LayerBlendMode blendMode;

  /// 不透明部分のみ描けるアルファロック。
  bool alphaLocked;

  /// 直下のレイヤーへのクリッピング(下の不透明部分にのみ表示)。
  bool clipToLower;

  /// レイヤーマスクを持つか(画素は [maskLayerId] をキーに別管理)。
  bool hasMask;

  /// メタ情報の複製(undo スナップショットが後続の変更で書き換わらないよう独立化)。
  LayerMeta copy() => LayerMeta(
    id: id,
    number: number,
    visible: visible,
    opacity: opacity,
    blendMode: blendMode,
    alphaLocked: alphaLocked,
    clipToLower: clipToLower,
    hasMask: hasMask,
  );
}

/// レイヤー構成の不変スナップショット(undo 用)。[layers] は複製済み。
class LayerStackData {
  LayerStackData(this.layers, this.activeIndex, this.counter);

  final List<LayerMeta> layers;
  final int activeIndex;
  final int counter;
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

  /// id でレイヤーを引く(無ければ null)。
  LayerMeta? byId(String id) {
    for (final l in _layers) {
      if (l.id == id) return l;
    }
    return null;
  }

  LayerMeta _append() {
    _counter++;
    final layer = LayerMeta(id: 'layer-$_counter', number: _layers.length + 1);
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

  /// [index] のレイヤーを [delta] だけ動かす(+1 で前面へ、-1 で背面へ)。
  /// 範囲外なら false。アクティブは動かしたレイヤーに追従する(任意 [delta] 可)。
  bool move(int index, int delta) {
    final to = index + delta;
    if (index < 0 ||
        index >= _layers.length ||
        to < 0 ||
        to >= _layers.length) {
      return false;
    }
    final active = _layers[_activeIndex];
    final layer = _layers.removeAt(index);
    _layers.insert(to, layer);
    _activeIndex = _layers.indexOf(active); // 動いた後の位置へ追従
    return true;
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

  void setMask(int index, bool hasMask) {
    _layers[index].hasMask = hasMask;
  }

  /// [index] のレイヤーを直下([index]-1)へ結合する。構成上は [index] を取り除き
  /// アクティブを直下へ移すだけ(画素合成は呼び出し側が事前に行う)。最下層や
  /// 範囲外なら false。
  bool mergeDown(int index) {
    if (index <= 0 || index >= _layers.length) return false;
    _layers.removeAt(index);
    _activeIndex = index - 1;
    return true;
  }

  /// 構成の完全スナップショットを取る(メタは複製)。
  LayerStackData snapshot() => LayerStackData(
    _layers.map((l) => l.copy()).toList(),
    _activeIndex,
    _counter,
  );

  /// スナップショットへ構成を戻す(メタは複製して取り込む)。
  void restore(LayerStackData data) {
    _layers
      ..clear()
      ..addAll(data.layers.map((l) => l.copy()));
    _activeIndex = data.activeIndex;
    _counter = data.counter;
  }
}
