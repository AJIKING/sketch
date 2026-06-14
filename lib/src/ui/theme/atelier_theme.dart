import 'package:flutter/material.dart';

/// アトリエ(暗色)テーマのデザイントークン。
///
/// プロトタイプ `docs/prototype/hatch-sketch-app.html` の `:root` 変数に準拠する。
/// 実装が進んだら色・角丸・影・タイポグラフィをここへ集約する。
abstract final class AtelierTokens {
  static const Color shell = Color(0xFF1C1813);
  static const Color surface = Color(0xFF221D17);
  static const Color surface2 = Color(0xFF2C2620);
  static const Color surface3 = Color(0xFF373027);
  static const Color paper = Color(0xFFEFE7D6);
  static const Color ink = Color(0xFFF3ECDD);
  static const Color inkDim = Color(0xFFB3A791);
  static const Color inkFaint = Color(0xFF8A8070);
  static const Color hair = Color(0x1AF3ECDD); // rgba(243,236,221,.10)
  static const Color hairStrong = Color(0x2EF3ECDD); // rgba(243,236,221,.18)
  static const Color vermilion = Color(0xFFCF4A2C); // 既定アクセント

  static const double rSm = 10;
  static const double rMd = 16;
  static const double rLg = 24;
  static const double rXl = 32;
}

ThemeData atelierTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AtelierTokens.vermilion,
    brightness: Brightness.dark,
    surface: AtelierTokens.surface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AtelierTokens.shell,
  );
}
