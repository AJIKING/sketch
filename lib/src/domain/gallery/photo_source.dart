import 'dart:typed_data';

/// 端末から写真(画像)を 1 枚読み込む境界。
///
/// 本番は OS のフォトピッカー(`data/picker_photo_source.dart`)、テストは
/// バイト列を返すだけの fake(`test/fixtures/fake_photo_source.dart`)。
/// 返り値はエンコード済み(PNG/JPEG 等)のバイト列。キャンセル/未対応は null。
abstract interface class PhotoSource {
  Future<Uint8List?> pickImage();
}
