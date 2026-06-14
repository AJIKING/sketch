import 'dart:typed_data';

import '../domain/gallery/image_exporter.dart';

/// 端末保存/共有が未実装の間のスタブ。常に false(未対応)を返す。
///
/// 写真ライブラリ保存や共有シートは plugin 導入時に実装する(ADR 0001 の
/// `ImageExporter` 境界)。UI は false を受けて「未対応」を案内する。
class UnsupportedImageExporter implements ImageExporter {
  const UnsupportedImageExporter();

  @override
  Future<bool> exportPng(Uint8List bytes, {String? suggestedName}) async =>
      false;
}
