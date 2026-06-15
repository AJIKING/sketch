import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'application/dependencies.dart';
import 'application/gallery_controller.dart';
import 'domain/gallery/sketch.dart';
import 'ui/canvas/canvas_screen.dart';
import 'ui/gallery/gallery_screen.dart';
import 'ui/theme/atelier_theme.dart';

/// 新規キャンバスのサイズプリセット(ADR 0006)。null は画面サイズ追従。
const List<(String, Size?)> _sizePresets = [
  ('画面サイズ', null),
  ('正方形 1080×1080', Size(1080, 1080)),
  ('正方形 2048×2048', Size(2048, 2048)),
  ('縦 1080×1920', Size(1080, 1920)),
  ('横 1920×1080', Size(1920, 1080)),
];

/// アプリのルート。差し替え境界([Dependencies])を受け取り、ギャラリーを起点に
/// キャンバスへ遷移する。テストでは fake を束ねた [Dependencies] を渡す。
class HatchApp extends StatefulWidget {
  const HatchApp({super.key, this.dependencies});

  /// 省略時は本番構成(`Dependencies.production()`)。
  final Dependencies? dependencies;

  @override
  State<HatchApp> createState() => _HatchAppState();
}

class _HatchAppState extends State<HatchApp> {
  // MaterialApp が内部に作る Navigator を、HatchApp(その祖先)の context からでも
  // 操作するための key。`Navigator.of(context)` を HatchApp の context で呼ぶと
  // 「Navigator を含まない context」エラーになるため、これを使う。
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late final Dependencies _deps =
      widget.dependencies ?? Dependencies.production();
  late final GalleryController _gallery = GalleryController(
    store: _deps.galleryStore,
    clock: _deps.clock,
  )..load();

  @override
  void dispose() {
    _gallery.dispose();
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
      builder: (dialogCtx) => SimpleDialog(
        title: const Text('キャンバスサイズ'),
        children: [
          for (final preset in _sizePresets)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogCtx).pop((size: preset.$2)),
              child: Text(preset.$1),
            ),
        ],
      ),
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
    return MaterialApp(
      title: 'Hatch',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: atelierTheme(),
      home: GalleryScreen(
        controller: _gallery,
        onNewCanvas: _openCanvas,
        onOpenSketch: (sketch) => _openCanvas(existing: sketch),
      ),
    );
  }
}
