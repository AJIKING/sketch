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
