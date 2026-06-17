import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'application/dependencies.dart';
import 'application/gallery_controller.dart';
import 'application/locale_controller.dart';
import 'domain/gallery/sketch.dart';
import '../l10n/app_localizations.dart';
import 'ui/canvas/canvas_screen.dart';
import 'ui/gallery/gallery_screen.dart';
import 'ui/theme/atelier_theme.dart';

/// 新規キャンバスのサイズプリセット(ADR 0006)。null は画面サイズ追従。
/// 表示名は [AppLocalizations] から解決するため、ここでは寸法のみ保持する。
const List<Size?> _sizePresets = [
  null,
  Size(1080, 1080),
  Size(2048, 2048),
  Size(1080, 1920),
  Size(1920, 1080),
];

/// プリセット寸法の表示名(`null` は画面サイズ追従)。
String _sizeLabel(AppLocalizations l, Size? size) {
  if (size == null) return l.sizeScreen;
  if (size == const Size(1080, 1080)) return l.sizeSquare1080;
  if (size == const Size(2048, 2048)) return l.sizeSquare2048;
  if (size == const Size(1080, 1920)) return l.sizePortrait;
  return l.sizeLandscape;
}

/// アプリのルート。差し替え境界([Dependencies])を受け取り、ギャラリーを起点に
/// キャンバスへ遷移する。テストでは fake を束ねた [Dependencies] を渡す。
class RakugaApp extends StatefulWidget {
  const RakugaApp({super.key, this.dependencies});

  /// 省略時は本番構成(`Dependencies.production()`)。
  final Dependencies? dependencies;

  @override
  State<RakugaApp> createState() => _RakugaAppState();
}

class _RakugaAppState extends State<RakugaApp> {
  // MaterialApp が内部に作る Navigator を、RakugaApp(その祖先)の context からでも
  // 操作するための key。`Navigator.of(context)` を RakugaApp の context で呼ぶと
  // 「Navigator を含まない context」エラーになるため、これを使う。
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late final Dependencies _deps =
      widget.dependencies ?? Dependencies.production();
  late final GalleryController _gallery = GalleryController(
    store: _deps.galleryStore,
    clock: _deps.clock,
  )..load();
  late final LocaleController _locale = LocaleController(
    store: _deps.settingsStore,
  )..load();

  @override
  void dispose() {
    _gallery.dispose();
    _locale.dispose();
    super.dispose();
  }

  Future<void> _openCanvas({Sketch? existing}) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    Uint8List? background;
    Size? documentSize;
    if (existing != null) {
      // 既存は保存 PNG の解像度をドキュメントサイズとして復元する。
      background = await _gallery.image(existing.id);
      if (background != null) documentSize = await _imageSize(background);
    } else {
      // 新規はサイズを選ぶ(キャンセルなら開かない)。
      final choice = await _promptDocumentSize();
      if (choice == null) return;
      documentSize = choice.size;
    }
    if (!mounted) return;
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => CanvasScreen(
          dependencies: _deps,
          gallery: _gallery,
          existing: existing,
          backgroundPng: background,
          documentSize: documentSize,
        ),
      ),
    );
    if (!mounted) return;
    await _gallery.load(); // 戻ったら一覧を更新
  }

  /// 新規キャンバスのサイズ選択。戻り値 null はキャンセル、size null は画面サイズ。
  Future<({Size? size})?> _promptDocumentSize() {
    final ctx = _navigatorKey.currentContext;
    if (ctx == null) return Future<({Size? size})?>.value(null);
    return showDialog<({Size? size})>(
      context: ctx,
      builder: (dialogCtx) {
        final l = AppLocalizations.of(dialogCtx);
        return SimpleDialog(
          title: Text(l.canvasSizeTitle),
          children: [
            for (final size in _sizePresets)
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogCtx).pop((size: size)),
                child: Text(_sizeLabel(l, size)),
              ),
          ],
        );
      },
    );
  }

  /// PNG バイト列の画素寸法。デコード不可なら null。
  Future<Size?> _imageSize(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _locale,
      builder: (context, _) => MaterialApp(
        title: 'Rakuga',
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: atelierTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // null は端末設定に追従。未対応ロケールは英語へフォールバックする。
        locale: _locale.locale,
        localeResolutionCallback: (deviceLocale, supported) {
          for (final s in supported) {
            if (s.languageCode == deviceLocale?.languageCode) return s;
          }
          return const Locale('en');
        },
        home: GalleryScreen(
          controller: _gallery,
          localeController: _locale,
          onNewCanvas: _openCanvas,
          onOpenSketch: (sketch) => _openCanvas(existing: sketch),
        ),
      ),
    );
  }
}
