import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/gallery/image_exporter.dart';

/// `ImageExporter` の本番実装。PNG を一時ファイルに書き出し、OS の共有シート
/// 経由でエクスポートする(写真への保存・他アプリ送信などはユーザーが選ぶ)。
///
/// 共有結果のステータスはプラットフォームで信頼性が低い:
/// - Android は成功でも結果を返せず `unavailable` になることが多い。
/// - iOS でも一部アクティビティ(写真へ保存等)は `success` を返さない。
/// そのため、ユーザーが明示的に取り消した [ShareResultStatus.dismissed] のときだけ
/// false(キャンセル)とみなす。失敗で例外は投げない(UI は結果を案内するだけ)。
class ShareImageExporter implements ImageExporter {
  const ShareImageExporter();

  @override
  Future<bool> exportPng(
    Uint8List bytes, {
    String? suggestedName,
    String? text,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${suggestedName ?? 'hatch-sketch.png'}');
      await file.writeAsBytes(bytes);
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: (text != null && text.isNotEmpty) ? text : null,
        ),
      );
      return result.status != ShareResultStatus.dismissed;
    } catch (_) {
      return false;
    }
  }
}
