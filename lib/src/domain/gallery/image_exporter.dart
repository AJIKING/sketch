import 'dart:typed_data';

/// 画像エクスポート境界(ADR 0001 / `docs/test-plan.md`)。
///
/// 端末の写真ライブラリへの保存や共有シートなど、OS 依存・権限が絡む処理を
/// 抽象化する。テストは記録のみの fake(`recording_image_exporter`)に差し替え、
/// 実ファイル I/O や権限ダイアログに触れない。
abstract interface class ImageExporter {
  /// PNG バイト列をエクスポートする。許可が得られたら true。
  Future<bool> exportPng(Uint8List bytes, {String? suggestedName});
}
