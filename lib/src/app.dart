import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'application/dependencies.dart';
import 'application/gallery_controller.dart';
import 'domain/gallery/sketch.dart';
import 'ui/canvas/canvas_screen.dart';
import 'ui/gallery/gallery_screen.dart';
import 'ui/theme/atelier_theme.dart';

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
    if (existing != null) background = await _gallery.image(existing.id);
    if (!mounted) return;
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => CanvasScreen(
          dependencies: _deps,
          gallery: _gallery,
          existing: existing,
          backgroundPng: background,
        ),
      ),
    );
    if (!mounted) return;
    await _gallery.load(); // 戻ったら一覧を更新
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
