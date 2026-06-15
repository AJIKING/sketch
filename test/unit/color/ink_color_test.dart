import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/domain/color/ink_color.dart';

void main() {
  group('hexToRgb', () {
    test('Studio Palette の朱を RGB に変換する', () {
      expect(hexToRgb('#CF4A2C'), (207, 74, 44));
    });

    test('# の有無・大文字小文字を問わない', () {
      expect(hexToRgb('cf4a2c'), (207, 74, 44));
      expect(hexToRgb('#EFE7D6'), (239, 231, 214));
    });
  });

  group('rgbToHex', () {
    test('RGB を大文字 HEX にする', () {
      expect(rgbToHex(207, 74, 44), '#CF4A2C');
    });

    test('1 桁成分をゼロ詰めする', () {
      expect(rgbToHex(0, 9, 16), '#000910');
    });
  });

  group('normalizeHex', () {
    test('6 桁を大文字 #RRGGBB へ(# 有無・空白・小文字を許容)', () {
      expect(normalizeHex('cf4a2c'), '#CF4A2C');
      expect(normalizeHex('#EFE7D6'), '#EFE7D6');
      expect(normalizeHex('  #abcdef '), '#ABCDEF');
    });

    test('3 桁短縮を展開する', () {
      expect(normalizeHex('#abc'), '#AABBCC');
      expect(normalizeHex('f00'), '#FF0000');
    });

    test('不正な入力は null', () {
      expect(normalizeHex(''), isNull);
      expect(normalizeHex('12345'), isNull); // 桁数違い
      expect(normalizeHex('#GG0011'), isNull); // 16進でない
      expect(normalizeHex('zzzzzz'), isNull);
    });
  });

  group('rgb <-> hsv 往復', () {
    test('Studio Palette 全色で RGB が保存される', () {
      for (final hex in studioPalette) {
        final (r, g, b) = hexToRgb(hex);
        final (h, s, v) = rgbToHsv(r, g, b);
        expect(hsvToRgb(h, s, v), (r, g, b), reason: '$hex の往復で色がずれた');
      }
    });
  });
}
