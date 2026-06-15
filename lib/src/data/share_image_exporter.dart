import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/gallery/image_exporter.dart';

/// `ImageExporter` の本番実装。PNG を一時ファイルに書き出し、OS の共有シート
/// 経由でエクスポートする(写真への保存・他アプリ送信などはユーザーが選ぶ)。
///
/// 共有結果のステータス([ShareResult.status])はプラットフォームで信頼できない:
/// - Android は成功でも結果を返せず `unavailable` になることが多い。
/// - iOS は「写真に保存」「ファイルに保存」等のアクティビティで、成功しても
///   `dismissed` を返す端末がある(誤って「キャンセル」と表示される原因)。
/// そのため**ステータスでは成否を判定しない**。共有シートを提示できた(例外が
/// 出なかった)時点で成功扱いにし、提示自体に失敗したときだけ false を返す。
class ShareImageExporter implements ImageExporter {
  const ShareImageExporter();

  @override
  Future<bool> exportImage(
    Uint8List bytes, {
    String? suggestedName,
    String? text,
    String mimeType = 'image/png',
  }) async {
    // 例外は握り潰さず呼び出し側へ伝播する(原因を画面で確認できるようにする)。
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${suggestedName ?? 'rakuga-sketch.png'}');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        text: (text != null && text.isNotEmpty) ? text : null,
        // iOS は共有ポップオーバーのアンカー矩形(非ゼロ・source view 内)を
        // 要求する。未指定だと PlatformException になるため明示する。iPhone は
        // フルスクリーン表示のため位置は実質無視される(iPad は左上アンカー)。
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
      ),
    );
    return true;
  }
}
