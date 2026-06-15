import 'dart:typed_data';

/// 画像エクスポート境界(ADR 0001 / `docs/test-plan.md`)。
///
/// 端末の写真ライブラリへの保存や共有シートなど、OS 依存・権限が絡む処理を
/// 抽象化する。テストは記録のみの fake(`recording_image_exporter`)に差し替え、
/// 実ファイル I/O や権限ダイアログに触れない。
abstract interface class ImageExporter {
  /// 画像/GIF バイト列をエクスポート(共有シート/保存)する。提示できたら true。
  ///
  /// [text] を渡すと共有メッセージ(キャプション)を添える(SNS 共有向け)。
  /// [mimeType] は既定 image/png。GIF 等は `image/gif` を渡す。
  Future<bool> exportImage(
    Uint8List bytes, {
    String? suggestedName,
    String? text,
    String mimeType = 'image/png',
  });
}
