import 'package:flutter/material.dart';

import 'ui/gallery/gallery_screen.dart';
import 'ui/theme/atelier_theme.dart';

/// アプリのルート。テーマ適用と初期画面の決定だけを担う。
///
/// 差し替え境界(`Clock` / `Random` / `GalleryStore` / `ImageExporter`)は
/// composition root(`main*.dart`)で生成して注入する。スケルトン段階では
/// まだ受け取っていない。
class HatchApp extends StatelessWidget {
  const HatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hatch',
      debugShowCheckedModeBanner: false,
      theme: atelierTheme(),
      home: const GalleryScreen(),
    );
  }
}
