import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'dart:typed_data';

import '../core/clock.dart';
import '../data/file_gallery_store.dart';
import '../data/file_palette_store.dart';
import '../data/gif_encoder.dart';
import '../data/picker_photo_source.dart';
import '../data/share_image_exporter.dart';
import '../domain/gallery/gallery_store.dart';
import '../domain/gallery/image_exporter.dart';
import '../domain/gallery/photo_source.dart';
import '../domain/palette/palette_store.dart';
import '../domain/timelapse/timelapse_frame.dart';

/// タイムラプスのフレーム列 → GIF バイト列。data の `encodeGif` を注入する型。
typedef GifEncoder =
    Uint8List? Function(List<TimelapseFrame> frames, {int frameMs});

/// 差し替え境界の束(`docs/architecture.md`)。
///
/// composition root(`main*.dart`)が用途別に生成して `RakugaApp` へ渡す。
/// 本番・開発・テストで実装だけを差し替える。
class Dependencies {
  const Dependencies({
    required this.clock,
    required this.galleryStore,
    required this.imageExporter,
    this.paletteStore,
    this.photoSource,
    this.gifEncoder,
  });

  final Clock clock;
  final GalleryStore galleryStore;
  final ImageExporter imageExporter;

  /// ユーザー定義カラーパレットの保存先(任意。null なら非永続)。
  final PaletteStore? paletteStore;

  /// 写真の読み込み元(任意。null なら「写真を読み込む」を出さない)。
  final PhotoSource? photoSource;

  /// タイムラプスの GIF エンコーダ(任意。null なら書き出し不可)。
  final GifEncoder? gifEncoder;

  /// 本番構成。スケッチはアプリ内ドキュメントディレクトリに永続化し(ADR 0001)、
  /// 画像エクスポートは OS の共有シート経由(`ShareImageExporter`)。
  factory Dependencies.production() => Dependencies(
    clock: const SystemClock(),
    galleryStore: FileGalleryStore(
      resolveDir: () async {
        final docs = await getApplicationDocumentsDirectory();
        return Directory('${docs.path}/hatch_sketches');
      },
    ),
    imageExporter: const ShareImageExporter(),
    paletteStore: FilePaletteStore(
      resolveDir: () async {
        final docs = await getApplicationDocumentsDirectory();
        return Directory('${docs.path}/hatch_sketches');
      },
    ),
    photoSource: const PickerPhotoSource(),
    gifEncoder: encodeGif,
  );
}
