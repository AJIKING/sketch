import 'dart:convert';
import 'dart:io';

import '../domain/settings/settings_store.dart';

/// `SettingsStore` のファイル実装。
///
/// 保存先ディレクトリに `settings_v1.json`(`{"locale": "ja"}` など)として置く。
/// ディレクトリは [resolveDir] で注入する(本番は path_provider)。壊れた / 読めない
/// 保存は未設定(`null`)として扱い、例外でアプリを止めない(`FilePaletteStore` と同方針)。
class FileSettingsStore implements SettingsStore {
  FileSettingsStore({required this.resolveDir});

  final Future<Directory> Function() resolveDir;

  static const String fileName = 'settings_v1.json';

  Directory? _cached;

  Future<Directory> _dir() async {
    final dir = _cached ??= await resolveDir();
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  File _file(Directory dir) => File('${dir.path}/$fileName');

  @override
  Future<String?> loadLocale() async {
    try {
      final dir = await _dir();
      final file = _file(dir);
      if (!await file.exists()) return null;
      final raw = jsonDecode(await file.readAsString()) as Map<String, Object?>;
      final code = raw['locale'];
      return code is String && code.isNotEmpty ? code : null;
    } catch (_) {
      return null; // 壊れた保存は未設定扱い
    }
  }

  @override
  Future<void> saveLocale(String? code) async {
    final dir = await _dir();
    await _file(dir).writeAsString(jsonEncode({'locale': code}));
  }
}
