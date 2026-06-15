import 'dart:typed_data';

import 'package:sketch/src/domain/gallery/photo_source.dart';

/// テスト用の `PhotoSource`。返すバイト列を差し込め、呼び出し回数を観測できる。
class FakePhotoSource implements PhotoSource {
  FakePhotoSource([this.bytes]);

  Uint8List? bytes;
  int calls = 0;

  @override
  Future<Uint8List?> pickImage() async {
    calls++;
    return bytes;
  }
}
