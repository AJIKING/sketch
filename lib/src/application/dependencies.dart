import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/clock.dart';
import '../data/file_gallery_store.dart';
import '../data/unsupported_image_exporter.dart';
import '../domain/gallery/gallery_store.dart';
import '../domain/gallery/image_exporter.dart';

/// 差し替え境界の束(`docs/architecture.md`)。
///
/// composition root(`main*.dart`)が用途別に生成して `HatchApp` へ渡す。
/// 本番・開発・テストで実装だけを差し替える。
class Dependencies {
  const Dependencies({
    required this.clock,
    required this.galleryStore,
    required this.imageExporter,
  });

  final Clock clock;
  final GalleryStore galleryStore;
  final ImageExporter imageExporter;

  /// 本番構成。スケッチはアプリ内ドキュメントディレクトリに永続化する
  /// (ADR 0001)。端末への画像保存は ADR 0001 の `ImageExporter` 実装が
  /// 入るまで未対応。
  factory Dependencies.production() => Dependencies(
    clock: const SystemClock(),
    galleryStore: FileGalleryStore(
      resolveDir: () async {
        final docs = await getApplicationDocumentsDirectory();
        return Directory('${docs.path}/hatch_sketches');
      },
    ),
    imageExporter: const UnsupportedImageExporter(),
  );
}
