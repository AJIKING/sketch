import 'dart:typed_data';

import 'package:sketch/src/domain/gallery/image_exporter.dart';

/// `ImageExporter` の記録のみ fake。許可/拒否も再現できる(`docs/test-plan.md`)。
class RecordingImageExporter implements ImageExporter {
  RecordingImageExporter({this.granted = true});

  /// exportPng が返す許可結果。拒否(false)も再現できる。
  bool granted;

  final List<({Uint8List bytes, String? name})> calls = [];

  @override
  Future<bool> exportPng(Uint8List bytes, {String? suggestedName}) async {
    calls.add((bytes: bytes, name: suggestedName));
    return granted;
  }
}
