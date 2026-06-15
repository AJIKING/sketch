import 'layer_stack.dart';

/// undo/redo の 1 ステップ(pure Dart)。画素編集と構成変更を区別する。
///
/// 画素編集は「対象レイヤー 1 枚の画像」を、構成変更は「レイヤー構成 + 全レイヤーの
/// 画素」を丸ごと巻き戻す。画素(`dart:ui.Image`)は不透明な [Object] として扱う
/// (`docs/architecture.md` / ADR 0003)。
sealed class UndoEntry {}

/// 単一レイヤーの画素編集(ストローク・塗り・消去など)。安価。
class PixelEdit extends UndoEntry {
  PixelEdit(this.layerId, this.pixels);

  final String layerId;
  final Object pixels;
}

/// レイヤー構成そのものの変更(結合など)。構成の完全スナップショットと、その時点の
/// 全レイヤー画素を保持し、構造ごと巻き戻せるようにする。構成変更はまれなので、
/// 全レイヤー分を保持しても実用上問題にならない。
class StackEdit extends UndoEntry {
  StackEdit(this.stack, this.pixels);

  final LayerStackData stack;
  final Map<String, Object> pixels;
}
