import 'package:sketch/src/domain/palette/palette_store.dart';

/// テスト用のインメモリ `PaletteStore`。保存回数を [saves] で観測できる。
class InMemoryPaletteStore implements PaletteStore {
  InMemoryPaletteStore([List<String>? initial]) : _hexes = [...?initial];

  List<String> _hexes;
  int saves = 0;

  @override
  Future<List<String>> load() async => List.of(_hexes);

  @override
  Future<void> save(List<String> hexes) async {
    _hexes = List.of(hexes);
    saves++;
  }
}
