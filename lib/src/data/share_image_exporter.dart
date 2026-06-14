import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/gallery/image_exporter.dart';

/// `ImageExporter` の本番実装。PNG を一時ファイルに書き出し、OS の共有シート
/// 経由でエクスポートする(写真への保存・他アプリ送信などはユーザーが選ぶ)。
///
/// 共有のキャンセルや未対応 platform は false を返す。失敗で例外は投げない
/// (UI は false を受けて案内するだけ)。
class ShareImageExporter implements ImageExporter {
  const ShareImageExporter();

  @override
  Future<bool> exportPng(Uint8List bytes, {String? suggestedName}) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${suggestedName ?? 'hatch-sketch.png'}');
      await file.writeAsBytes(bytes);
      final result = await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'image/png')]),
      );
      return result.status == ShareResultStatus.success;
    } catch (_) {
      return false;
    }
  }
}
