import 'dart:math' as math;

/// 色変換ユーティリティ(pure Dart, `dart:ui` 非依存)。
///
/// プロトタイプ `docs/prototype/hatch-sketch-app.html` の hsv2rgb / rgb2hsv /
/// hex ヘルパを Dart へ移植したもの。HSV を真実として保持し、表示時に
/// RGB / HEX へ変換する。`docs/test-plan.md` の「色変換」を満たす。

/// (r, g, b) 各 0..255。
typedef Rgb = (int r, int g, int b);

/// (h, s, v) — h は 0..360、s と v は 0..1。
typedef Hsv = (double h, double s, double v);

/// Studio Palette(プロトタイプ準拠の固定 10 色)。
const List<String> studioPalette = [
  '#CF4A2C', // 朱(vermilion）
  '#E08A2E',
  '#C69749', // 黄土(ochre)
  '#5E8A4E',
  '#2C4A63', // 藍(indigo)
  '#46357A',
  '#A23B68',
  '#2A2620', // 墨(sumi)
  '#7A726A',
  '#EFE7D6', // 紙(paper)
];

Rgb hsvToRgb(double h, double s, double v) {
  final hh = h / 360;
  final i = (hh * 6).floor();
  final f = hh * 6 - i;
  final p = v * (1 - s);
  final q = v * (1 - f * s);
  final t = v * (1 - (1 - f) * s);
  final double r;
  final double g;
  final double b;
  switch (i % 6) {
    case 0:
      r = v;
      g = t;
      b = p;
    case 1:
      r = q;
      g = v;
      b = p;
    case 2:
      r = p;
      g = v;
      b = t;
    case 3:
      r = p;
      g = q;
      b = v;
    case 4:
      r = t;
      g = p;
      b = v;
    default:
      r = v;
      g = p;
      b = q;
  }
  return ((r * 255).round(), (g * 255).round(), (b * 255).round());
}

Hsv rgbToHsv(int r0, int g0, int b0) {
  final r = r0 / 255;
  final g = g0 / 255;
  final b = b0 / 255;
  final mx = math.max(r, math.max(g, b));
  final mn = math.min(r, math.min(g, b));
  final d = mx - mn;
  var h = 0.0;
  if (d != 0) {
    if (mx == r) {
      h = ((g - b) / d) % 6;
    } else if (mx == g) {
      h = (b - r) / d + 2;
    } else {
      h = (r - g) / d + 4;
    }
    h *= 60;
    if (h < 0) h += 360;
  }
  return (h, mx == 0 ? 0.0 : d / mx, mx);
}

String rgbToHex(int r, int g, int b) =>
    '#${_hex2(r)}${_hex2(g)}${_hex2(b)}'.toUpperCase();

String _hex2(int x) => x.toRadixString(16).padLeft(2, '0');

Rgb hexToRgb(String hex) {
  final h = hex.replaceAll('#', '');
  return (
    int.parse(h.substring(0, 2), radix: 16),
    int.parse(h.substring(2, 4), radix: 16),
    int.parse(h.substring(4, 6), radix: 16),
  );
}

/// 入力文字列を `#RRGGBB`(大文字)へ正規化する。
///
/// 先頭 `#` の有無・前後空白・3 桁短縮(`#abc` → `#AABBCC`)を許容する。
/// 16 進として不正、または桁数が違うときは null を返す(UI のバリデーション用)。
String? normalizeHex(String input) {
  var s = input.trim().toUpperCase();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 3) {
    s = '${s[0]}${s[0]}${s[1]}${s[1]}${s[2]}${s[2]}';
  }
  if (s.length != 6) return null;
  for (final cu in s.codeUnits) {
    final isDigit = cu >= 0x30 && cu <= 0x39; // 0-9
    final isHexAlpha = cu >= 0x41 && cu <= 0x46; // A-F
    if (!isDigit && !isHexAlpha) return null;
  }
  return '#$s';
}
