import 'dart:convert';
import 'dart:io';

import '../domain/palette/palette_store.dart';

/// `PaletteStore` のファイル実装。
///
/// 保存先ディレクトリに `palette_v1.json`(HEX 文字列の配列)として置く。
/// ディレクトリは [resolveDir] で注入する(本番は path_provider)。壊れた / 読めない
/// 保存は空一覧として扱い、例外でアプリを止めない(`FileGalleryStore` と同方針)。
class FilePaletteStore implements PaletteStore {
  FilePaletteStore({required this.resolveDir});

  final Future<Directory> Function() resolveDir;

  static const String fileName = 'palette_v1.json';

  Directory? _cached;

  Future<Directory> _dir() async {
    final dir = _cached ??= await resolveDir();
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  File _file(Directory dir) => File('${dir.path}/$fileName');

  @override
  Future<List<String>> load() async {
    try {
      final dir = await _dir();
      final file = _file(dir);
      if (!await file.exists()) return [];
      final raw = jsonDecode(await file.readAsString()) as List<Object?>;
      return raw.whereType<String>().toList();
    } catch (_) {
      return []; // 壊れた保存は空扱い
    }
  }

  @override
  Future<void> save(List<String> hexes) async {
    final dir = await _dir();
    await _file(dir).writeAsString(jsonEncode(hexes));
  }
}
