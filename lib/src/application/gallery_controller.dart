import 'package:flutter/foundation.dart';

import '../core/clock.dart';
import '../domain/gallery/gallery_store.dart';
import '../domain/gallery/sketch.dart';

/// ギャラリー画面の状態(`docs/test-plan.md` Widget「ギャラリー」)。
///
/// スケッチ一覧の読み込みと保存・削除を [GalleryStore] 越しに行う。日時は
/// [Clock] から取る(ADR 0003)。
class GalleryController extends ChangeNotifier {
  GalleryController({required this.store, required this.clock});

  final GalleryStore store;
  final Clock clock;

  List<Sketch> _sketches = const [];
  bool _loading = false;

  List<Sketch> get sketches => List.unmodifiable(_sketches);
  int get count => _sketches.length;
  bool get isLoading => _loading;

  Sketch? _byId(String id) {
    for (final s in _sketches) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// 一覧を読み込む(新しい順)。
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _sketches = await store.loadIndex();
    _loading = false;
    notifyListeners();
  }

  /// スケッチを保存する。既存 id は更新日時だけ進めて上書きする。
  Future<Sketch> save({
    required String id,
    required Uint8List png,
    String? title,
  }) async {
    final now = clock.now();
    final existing = _byId(id);
    final sketch = existing == null
        ? Sketch(id: id, title: title, createdAt: now, updatedAt: now)
        : existing.copyWith(title: title ?? existing.title, updatedAt: now);
    await store.save(sketch, png);
    await load();
    return sketch;
  }

  Future<void> remove(String id) async {
    await store.delete(id);
    await load();
  }

  Future<Uint8List?> image(String id) => store.loadImage(id);
}
