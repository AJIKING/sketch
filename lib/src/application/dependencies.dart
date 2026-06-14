import '../core/clock.dart';
import '../data/in_memory_gallery_store.dart';
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

  /// 本番構成。永続化と画像保存は ADR 0001 の実装が入るまで暫定。
  factory Dependencies.production() => Dependencies(
    clock: const SystemClock(),
    galleryStore: InMemoryGalleryStore(),
    imageExporter: const UnsupportedImageExporter(),
  );
}
