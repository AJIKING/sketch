import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../domain/gallery/photo_source.dart';

/// `PhotoSource` の本番実装。OS のフォトピッカーで画像を 1 枚選ぶ。
class PickerPhotoSource implements PhotoSource {
  const PickerPhotoSource();

  @override
  Future<Uint8List?> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    return picked.readAsBytes();
  }
}
