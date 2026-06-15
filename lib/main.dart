import 'package:flutter/material.dart';

import 'src/app.dart';

/// 本番 composition root。
///
/// 差し替え境界(`Clock` / `Random` / `GalleryStore` / `ImageExporter`)の
/// 本番実装を生成して `RakugaApp` に注入する場所。スケルトン段階では
/// 起動だけを行う(`docs/architecture.md` の「差し替え境界とエントリーポイント」)。
void main() {
  runApp(const RakugaApp());
}
