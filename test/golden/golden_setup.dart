import 'dart:io';

/// golden test 共通セットアップ(ADR 0002)。
///
/// golden 画像はフォントレンダリングが platform 依存のため、基準 platform は
/// CI と同じ Linux に固定する。非 Linux(Windows / macOS の開発機)では
/// golden test を skip し、ローカルの `flutter test` を golden 抜きで green に保つ。
///
/// 使い方(各 golden test ファイルの先頭で):
/// ```dart
/// @Tags(['golden'])
/// library;
/// import '../golden/golden_setup.dart';
/// // testWidgets(..., skip: skipGoldens);
/// ```
final bool skipGoldens = !Platform.isLinux;

/// golden を撮る前にカスタムフォントをロードするためのフック(実装は今後追加)。
///
/// device size / text scale / locale / theme の固定とあわせて、ここで
/// `loadFontFromList` 等によりフォントを読み込む。フォントファイルを
/// `assets/fonts/` に追加したら実装する。
Future<void> loadAtelierFonts() async {
  // TODO(hatch): assets/fonts/ のフォントをロードする(pubspec の fonts 参照)。
}
