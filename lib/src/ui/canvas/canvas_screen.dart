import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../application/canvas_controller.dart';
import '../../application/dependencies.dart';
import '../../application/gallery_controller.dart';
import '../../application/vector_controller.dart';
import '../../domain/brush/brush_preset.dart';
import '../../domain/canvas/filters.dart' as filters;
import '../../domain/canvas/gradient_kind.dart';
import '../../domain/canvas/layer_blend_mode.dart';
import '../../domain/canvas/selection_kind.dart';
import '../../domain/canvas/shape_kind.dart';
import '../../domain/gallery/sketch.dart';
import '../theme/atelier_theme.dart';
import '../widgets/brush_preview.dart';
import 'color_picker.dart';
import 'draw_surface.dart';
import 'raster_layer_store.dart';
import 'v_slider.dart';

/// キャンバス画面。描画面の上にツール UI を重ねる(`docs/product-spec.md`)。
class CanvasScreen extends StatefulWidget {
  const CanvasScreen({
    super.key,
    required this.dependencies,
    required this.gallery,
    this.existing,
    this.backgroundPng,
  });

  final Dependencies dependencies;
  final GalleryController gallery;

  /// 既存スケッチを開く場合のメタ(新規なら null)。
  final Sketch? existing;

  /// 既存スケッチの画像(背景として下敷きにする)。
  final Uint8List? backgroundPng;

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  final GlobalKey<DrawSurfaceState> _drawKey = GlobalKey<DrawSurfaceState>();
  final ValueNotifier<bool> _transforming = ValueNotifier<bool>(false);
  bool _uiVisible = true; // ヘッダー/フッター等のツール UI を表示するか
  late final RasterLayerStore _surface = RasterLayerStore();
  late final CanvasController _c = CanvasController(
    surface: _surface,
    paletteStore: widget.dependencies.paletteStore,
  );
  final VectorController _vec = VectorController();
  late final Listenable _repaint = Listenable.merge([_c, _vec]);

  late final String _id =
      widget.existing?.id ??
      'sketch-${widget.dependencies.clock.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _c.loadCustomPalette();
    final png = widget.backgroundPng;
    if (png != null) _decodeBackground(png);
  }

  // 既存スケッチを開いたら、最下層レイヤーへ画像として読み込む(ADR 0004:
  // PNG のみ保持のため、レイヤー構造は復元されない)。
  Future<void> _decodeBackground(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    _surface.set(_c.layers.layers.first.id, frame.image);
    setState(() {});
  }

  @override
  void dispose() {
    _transforming.dispose();
    _c.dispose();
    _vec.dispose();
    _surface.disposeAll(); // ライブのレイヤー画像を解放(履歴画像とは別オブジェクト)
    super.dispose();
  }

  Color get _currentColor => hexColor(_c.colorHex);

  Future<void> _saveToGallery() async {
    final png = await _drawKey.currentState?.exportPng();
    if (png != null) {
      await widget.gallery.save(id: _id, png: png);
    }
  }

  Future<void> _exit() async {
    await _saveToGallery();
    if (mounted) Navigator.of(context).pop();
  }

  // ---- sheets ----
  // builder を毎回呼ぶことで、controller の通知でシート内容も最新化される。
  void _openSheet(WidgetBuilder build) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AtelierTokens.surface,
      showDragHandle: true,
      isScrollControlled: true,
      // 横画面でも収まるよう高さを制限し、内容はスクロール可能にする。
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      builder: (_) => ListenableBuilder(
        listenable: _c,
        builder: (context, _) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            28 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: build(context),
        ),
      ),
    );
  }

  void _openColorSheet() => _openSheet((_) => _ColorSheet(controller: _c));
  void _openBrushSheet() => _openSheet((_) => _BrushSheet(controller: _c));
  void _openLayerSheet() => _openSheet((_) => _LayerSheet(controller: _c));

  void _openFilterSheet() {
    _openSheet(
      (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _filterTile(
            context,
            '反転',
            Icons.invert_colors,
            (b, w, h) => filters.invert(b),
          ),
          _filterTile(
            context,
            'グレースケール',
            Icons.tonality,
            (b, w, h) => filters.grayscale(b),
          ),
          _filterTile(
            context,
            'ぼかし',
            Icons.blur_on,
            (b, w, h) => filters.boxBlur(b, w, h, 6),
          ),
          _filterTile(
            context,
            'モザイク',
            Icons.grid_on,
            (b, w, h) => filters.mosaic(b, w, h, 12),
          ),
          _filterTile(
            context,
            '明るく',
            Icons.light_mode,
            (b, w, h) => filters.adjustBrightnessContrast(b, brightness: 0.12),
          ),
          _filterTile(
            context,
            '暗く',
            Icons.dark_mode,
            (b, w, h) => filters.adjustBrightnessContrast(b, brightness: -0.12),
          ),
          _filterTile(
            context,
            'コントラスト+',
            Icons.contrast,
            (b, w, h) => filters.adjustBrightnessContrast(b, contrast: 0.3),
          ),
        ],
      ),
    );
  }

  ListTile _filterTile(
    BuildContext context,
    String label,
    IconData icon,
    Uint8List Function(Uint8List rgba, int width, int height) op,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(color: AtelierTokens.ink)),
      onTap: () {
        Navigator.of(context).pop();
        _drawKey.currentState?.applyFilter(op);
      },
    );
  }

  void _openMenuSheet() {
    _openSheet(
      (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('画像として保存'),
            onTap: () async {
              Navigator.of(context).pop();
              final messenger = ScaffoldMessenger.of(this.context);
              final png = await _drawKey.currentState?.exportPng();
              final ok =
                  png != null &&
                  await widget.dependencies.imageExporter.exportPng(png);
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text(ok ? '画像を書き出しました' : '書き出しをキャンセルしました')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('フィルタ'),
            onTap: () {
              Navigator.of(context).pop();
              _openFilterSheet();
            },
          ),
          ListTile(
            leading: const Icon(Icons.check),
            title: const Text('完了してギャラリーへ'),
            onTap: () {
              Navigator.of(context).pop();
              _exit();
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_outline,
              color: AtelierTokens.vermilion,
            ),
            title: const Text(
              'このレイヤーを消去',
              style: TextStyle(color: AtelierTokens.vermilion),
            ),
            onTap: () {
              Navigator.of(context).pop();
              _c.clearActiveLayer();
            },
          ),
        ],
      ),
    );
  }

  void _onToolTap(Tool tool) {
    if (tool == Tool.brush && _c.tool == Tool.brush) {
      _openBrushSheet(); // アクティブなブラシ再タップ → ブラシライブラリ
      return;
    }
    if (tool == Tool.shape && _c.tool == Tool.shape) {
      _openShapeSheet(); // 図形ツール再タップ → 図形の種類設定
      return;
    }
    if (tool == Tool.gradient && _c.tool == Tool.gradient) {
      _openGradientSheet(); // グラデ再タップ → 線形/円形
      return;
    }
    if (tool == Tool.select && _c.tool == Tool.select) {
      _openSelectionSheet(); // 選択再タップ → 種類・操作
      return;
    }
    _c.selectTool(tool);
  }

  void _openSelectionSheet() {
    _openSheet(
      (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final kind in SelectionKind.values)
            ListTile(
              leading: Icon(
                kind == SelectionKind.lasso ? Icons.gesture : Icons.crop_din,
              ),
              title: Text(
                kind.label,
                style: const TextStyle(color: AtelierTokens.ink),
              ),
              trailing: _c.selectionKind == kind
                  ? const Icon(Icons.check, color: AtelierTokens.vermilion)
                  : null,
              onTap: () => _c.setSelectionKind(kind),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text(
              '選択範囲を消去',
              style: TextStyle(color: AtelierTokens.ink),
            ),
            onTap: () {
              Navigator.of(context).pop();
              _drawKey.currentState?.clearInsideSelection();
            },
          ),
          ListTile(
            leading: const Icon(Icons.deselect),
            title: const Text(
              '選択を解除',
              style: TextStyle(color: AtelierTokens.ink),
            ),
            onTap: () {
              Navigator.of(context).pop();
              _drawKey.currentState?.deselect();
            },
          ),
        ],
      ),
    );
  }

  void _openShapeSheet() {
    _openSheet(
      (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final kind in ShapeKind.values)
            ListTile(
              leading: Icon(switch (kind) {
                ShapeKind.line => Icons.remove,
                ShapeKind.rectangle => Icons.crop_square,
                ShapeKind.triangle => Icons.change_history,
                ShapeKind.ellipse => Icons.circle_outlined,
              }),
              title: Text(
                kind.label,
                style: const TextStyle(color: AtelierTokens.ink),
              ),
              trailing: _c.shapeKind == kind
                  ? const Icon(Icons.check, color: AtelierTokens.vermilion)
                  : null,
              onTap: () => _c.setShapeKind(kind),
            ),
          SwitchListTile(
            title: const Text(
              '塗りつぶし(枠線 ↔ 塗り)',
              style: TextStyle(color: AtelierTokens.ink),
            ),
            value: _c.shapeFilled,
            onChanged: _c.setShapeFilled,
          ),
          SwitchListTile(
            title: const Text(
              'スナップ(直線45° / 正方形・正円)',
              style: TextStyle(color: AtelierTokens.ink),
            ),
            value: _c.shapeSnap,
            onChanged: _c.setShapeSnap,
          ),
        ],
      ),
    );
  }

  void _openGradientSheet() {
    _openSheet(
      (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final kind in GradientKind.values)
            ListTile(
              leading: Icon(
                kind == GradientKind.radial
                    ? Icons.blur_circular
                    : Icons.gradient,
              ),
              title: Text(
                kind.label,
                style: const TextStyle(color: AtelierTokens.ink),
              ),
              trailing: _c.gradientKind == kind
                  ? const Icon(Icons.check, color: AtelierTokens.vermilion)
                  : null,
              onTap: () => _c.setGradientKind(kind),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtelierTokens.shell,
      // テキスト入力などでキーボードが出ても全面キャンバスは縮めない
      // (縮むと中央フィットがやり直されてズームが失われるため)。
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _repaint,
          builder: (context, _) {
            return Stack(
              children: [
                // キャンバスは常に全面。ツール UI はこの上に重ねる(被せる)ので、
                // 描ける範囲はボタンに削られず最大化される。ボタンは表示/非表示可能。
                Positioned.fill(
                  child: DrawSurface(
                    key: _drawKey,
                    controller: _c,
                    surface: _surface,
                    clock: widget.dependencies.clock,
                    transforming: _transforming,
                    vector: _vec,
                    // 2 本指ダブルタップでツール UI を表示/非表示。
                    onToggleUi: () => setState(() => _uiVisible = !_uiVisible),
                  ),
                ),
                // ツール UI(ヘッダー/左レール/フッター)。非表示時は描画を遮らない。
                Positioned.fill(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _transforming,
                    builder: (context, transforming, _) {
                      if (!_uiVisible) {
                        return const IgnorePointer(child: SizedBox.shrink());
                      }
                      // 変形モード中はツール UI を無効化(誤操作・状態破壊を防ぐ)。
                      return IgnorePointer(
                        ignoring: transforming,
                        child: Opacity(
                          opacity: transforming ? 0.35 : 1,
                          child: Stack(
                            children: [_topBar(), _leftRail(), _dock()],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _transformBar(),
                if (_uiVisible && _vec.enabled) _vectorBar(),
                if (!_uiVisible) _showUiButton(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topBar() {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'ギャラリーへ戻る',
            onPressed: _exit,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: '取り消す',
            onPressed: _c.canUndo ? _c.undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'やり直す',
            onPressed: _c.canRedo ? _c.redo : null,
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: '表示をリセット',
            onPressed: () => _drawKey.currentState?.resetView(),
          ),
          IconButton(
            icon: const Icon(Icons.unfold_less),
            tooltip: 'ツールを隠す(2本指ダブルタップでも切替)',
            onPressed: () => setState(() => _uiVisible = false),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'メニュー',
            onPressed: _openMenuSheet,
          ),
        ],
      ),
    );
  }

  Widget _leftRail() {
    // 上端(トップバー下)〜下端(ドック上)に収め、横画面でも溢れないよう
    // 2 本のスライダで高さを分け合う(各 VSlider は Expanded で伸縮)。
    return Positioned(
      left: 2,
      top: 72,
      bottom: 104,
      child: SizedBox(
        width: 58,
        child: Column(
          children: [
            Expanded(
              child: VSlider(
                label: 'SIZE',
                value: _c.size,
                min: 1,
                max: 80,
                format: (v) => v.round().toString(),
                onChanged: _c.setSize,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: VSlider(
                label: 'OPAC',
                value: _c.opacity * 100,
                min: 0,
                max: 100,
                format: (v) => '${v.round()}%',
                onChanged: (v) => _c.setOpacity(v / 100),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI 非表示中に表示する、小さな復帰ボタン(右上)。
  Widget _showUiButton() {
    return Positioned(
      top: 4,
      right: 4,
      child: Material(
        color: AtelierTokens.surface2.withValues(alpha: 0.7),
        shape: const CircleBorder(),
        child: IconButton(
          icon: const Icon(Icons.unfold_more, color: AtelierTokens.ink),
          tooltip: 'ツールを表示(2本指ダブルタップでも切替)',
          onPressed: () => setState(() => _uiVisible = true),
        ),
      ),
    );
  }

  // ベクターモードの編集バー(ドック上・選択オブジェクトの操作と undo/redo)。
  Widget _vectorBar() {
    final hasSel = _vec.hasSelection;
    return Positioned(
      bottom: 78,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AtelierTokens.surface3,
            borderRadius: BorderRadius.circular(AtelierTokens.rLg),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'ベクターを取り消す',
                onPressed: _vec.canUndo ? _vec.undo : null,
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                tooltip: 'ベクターをやり直す',
                onPressed: _vec.canRedo ? _vec.redo : null,
              ),
              const SizedBox(
                width: 1,
                height: 24,
                child: ColoredBox(color: AtelierTokens.inkDim),
              ),
              IconButton(
                icon: const Icon(Icons.palette_outlined),
                tooltip: '選択を現在色にする',
                onPressed: hasSel
                    ? () => _vec.recolorSelected(_c.colorHex)
                    : null,
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AtelierTokens.vermilion,
                ),
                tooltip: '選択を削除',
                onPressed: hasSel ? _vec.deleteSelected : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 変形モード中の確定/取消バー(画面上部中央)。
  Widget _transformBar() {
    return Positioned(
      top: 56,
      left: 0,
      right: 0,
      child: ValueListenableBuilder<bool>(
        valueListenable: _transforming,
        builder: (context, on, _) {
          if (!on) return const SizedBox.shrink();
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AtelierTokens.surface3,
                borderRadius: BorderRadius.circular(AtelierTokens.rLg),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: '変形を取消',
                    onPressed: () => _drawKey.currentState?.cancelTransform(),
                  ),
                  const Text(
                    '変形(1本指=移動 / 2本指=拡縮・回転)',
                    style: TextStyle(color: AtelierTokens.ink, fontSize: 12),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.check,
                      color: AtelierTokens.vermilion,
                    ),
                    tooltip: '変形を確定',
                    onPressed: () => _drawKey.currentState?.confirmTransform(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dock() {
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AtelierTokens.surface2,
          borderRadius: BorderRadius.circular(AtelierTokens.rLg),
        ),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _toolButton(Tool.brush, Icons.brush, 'ブラシ'),
                    _toolButton(Tool.smudge, Icons.water_drop_outlined, 'スマッジ'),
                    _toolButton(Tool.erase, Icons.auto_fix_normal, '消しゴム'),
                    _toolButton(Tool.fill, Icons.format_color_fill, '塗りつぶし'),
                    _toolButton(Tool.gradient, Icons.gradient, 'グラデーション'),
                    _toolButton(Tool.shape, Icons.category_outlined, '図形'),
                    _toolButton(Tool.text, Icons.text_fields, 'テキスト'),
                    _toolButton(Tool.select, Icons.highlight_alt, '選択'),
                    _toolButton(Tool.eyedropper, Icons.colorize, 'スポイト'),
                    IconButton(
                      icon: const Icon(Icons.transform),
                      tooltip: '変形',
                      onPressed: () => _drawKey.currentState?.enterTransform(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.timeline),
                      tooltip: _vec.enabled ? 'ベクター: ON' : 'ベクター: OFF',
                      isSelected: _vec.enabled,
                      style: IconButton.styleFrom(
                        backgroundColor: _vec.enabled
                            ? AtelierTokens.vermilion
                            : null,
                        foregroundColor: _vec.enabled
                            ? AtelierTokens.paper
                            : AtelierTokens.ink,
                      ),
                      onPressed: () => _vec.setEnabled(!_vec.enabled),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              width: 1,
              height: 28,
              child: ColoredBox(color: AtelierTokens.inkDim),
            ),
            IconButton.filledTonal(
              icon: Badge(
                label: Text('${_c.layers.length}'),
                child: const Icon(Icons.layers_outlined),
              ),
              tooltip: 'レイヤー',
              onPressed: _openLayerSheet,
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _openColorSheet,
              child: Semantics(
                button: true,
                label: 'カラーを選択',
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _currentColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AtelierTokens.hairStrong,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolButton(Tool tool, IconData icon, String label) {
    final selected = _c.tool == tool;
    return IconButton(
      icon: Icon(icon),
      tooltip: label,
      isSelected: selected,
      style: IconButton.styleFrom(
        backgroundColor: selected ? AtelierTokens.vermilion : null,
        foregroundColor: selected ? AtelierTokens.paper : AtelierTokens.ink,
      ),
      onPressed: () => _onToolTap(tool),
    );
  }
}

// ---------------- sheets ----------------

class _ColorSheet extends StatelessWidget {
  const _ColorSheet({required this.controller});
  final CanvasController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'カラー  ${controller.colorHex}',
          style: const TextStyle(color: AtelierTokens.ink, fontSize: 18),
        ),
        const SizedBox(height: 12),
        ColorPicker(controller: controller),
        const SizedBox(height: 12),
        const Text(
          'Studio Palette',
          style: TextStyle(color: AtelierTokens.inkDim),
        ),
        _swatches(controller.palette, controller.selectColor),
        const SizedBox(height: 8),
        const Text('Recent', style: TextStyle(color: AtelierTokens.inkDim)),
        controller.recent.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'まだありません',
                  style: TextStyle(color: AtelierTokens.inkFaint),
                ),
              )
            : _swatches(controller.recent, controller.selectColor),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('マイパレット', style: TextStyle(color: AtelierTokens.inkDim)),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('現在色を保存'),
              onPressed: () => controller.addCustomColor(),
            ),
          ],
        ),
        controller.customPalette.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '「現在色を保存」で自分の色を貯められます(長押しで削除)',
                  style: TextStyle(color: AtelierTokens.inkFaint),
                ),
              )
            : _swatches(
                controller.customPalette,
                controller.selectColor,
                onLongPress: controller.removeCustomColor,
              ),
      ],
    );
  }

  Widget _swatches(
    List<String> hexes,
    ValueChanged<String> onPick, {
    ValueChanged<String>? onLongPress,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final hex in hexes)
          GestureDetector(
            onTap: () => onPick(hex),
            onLongPress: onLongPress == null ? null : () => onLongPress(hex),
            child: Semantics(
              button: true,
              label: hex,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: hexColor(hex),
                  shape: BoxShape.circle,
                  border: Border.all(color: AtelierTokens.hair),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BrushSheet extends StatelessWidget {
  const _BrushSheet({required this.controller});
  final CanvasController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 96,
              child: Text(
                '手ブレ補正',
                style: TextStyle(color: AtelierTokens.inkDim, fontSize: 13),
              ),
            ),
            Expanded(
              child: Slider(
                value: controller.stabilization,
                label: '${(controller.stabilization * 100).round()}%',
                onChanged: controller.setStabilization,
              ),
            ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            '2色グラデーション(始点→終点)',
            style: TextStyle(color: AtelierTokens.ink),
          ),
          subtitle: const Text(
            '現在色から2色目へ滑らかに変化',
            style: TextStyle(color: AtelierTokens.inkDim),
          ),
          value: controller.gradientBrush,
          onChanged: controller.setGradientBrush,
        ),
        if (controller.gradientBrush) _secondColorPicker(),
        _brushParam(
          '濃さ',
          controller.brush.flow,
          0.02,
          1,
          controller.setBrushFlow,
        ),
        _brushParam(
          '散り',
          controller.brush.scatter,
          0,
          2,
          controller.setBrushScatter,
        ),
        _brushParam(
          '間隔',
          controller.brush.spacing,
          0.05,
          2,
          controller.setBrushSpacing,
        ),
        for (final brush in brushPresets)
          ListTile(
            leading: DecoratedBox(
              decoration: BoxDecoration(
                color: AtelierTokens.paper,
                borderRadius: BorderRadius.circular(AtelierTokens.rSm),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: BrushPreview(brushKey: brush.key, width: 72, height: 36),
              ),
            ),
            title: Text(
              brush.name,
              style: const TextStyle(color: AtelierTokens.ink),
            ),
            subtitle: Text(
              brush.description,
              style: const TextStyle(color: AtelierTokens.inkDim),
            ),
            trailing: controller.brush.key == brush.key
                ? const Icon(Icons.check, color: AtelierTokens.vermilion)
                : null,
            onTap: () {
              controller.selectBrush(brush);
              Navigator.of(context).pop();
            },
          ),
      ],
    );
  }

  /// グラデブラシの 2 色目を選ぶ(1色目=現在色のプレビュー付き)。
  Widget _secondColorPicker() {
    final swatches = <String>{
      ...controller.palette,
      ...controller.customPalette,
      ...controller.recent,
    }.toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 96,
                child: Text(
                  '2色目',
                  style: TextStyle(color: AtelierTokens.inkDim, fontSize: 13),
                ),
              ),
              _dot(controller.colorHex, false),
              const Icon(
                Icons.arrow_right_alt,
                color: AtelierTokens.inkDim,
                size: 20,
              ),
              _dot(controller.secondColorHex, true),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final hex in swatches)
                GestureDetector(
                  onTap: () => controller.setSecondColorHex(hex),
                  child: Semantics(
                    button: true,
                    label: '2色目 $hex',
                    child: _dot(hex, hex == controller.secondColorHex),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(String hex, bool selected) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      color: hexColor(hex),
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? AtelierTokens.vermilion : AtelierTokens.hair,
        width: selected ? 2 : 1,
      ),
    ),
  );

  Widget _brushParam(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: const TextStyle(color: AtelierTokens.inkDim, fontSize: 13),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _LayerSheet extends StatelessWidget {
  const _LayerSheet({required this.controller});
  final CanvasController controller;

  @override
  Widget build(BuildContext context) {
    final layers = controller.layers;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Text(
              'レイヤー',
              style: TextStyle(color: AtelierTokens.ink, fontSize: 18),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('追加'),
              onPressed: controller.addLayer,
            ),
          ],
        ),
        // 最前面を上に表示する。
        for (var i = layers.length - 1; i >= 0; i--) _layerRow(context, i),
      ],
    );
  }

  Widget _layerRow(BuildContext context, int i) {
    final layer = controller.layers.layers[i];
    final active = i == controller.layers.activeIndex;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: active ? AtelierTokens.surface3 : AtelierTokens.surface2,
        borderRadius: BorderRadius.circular(AtelierTokens.rSm),
        border: active
            ? Border.all(color: AtelierTokens.vermilion, width: 1.5)
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  layer.visible ? Icons.visibility : Icons.visibility_off,
                ),
                tooltip: '表示切替',
                onPressed: () => controller.toggleLayerVisible(i),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.setActiveLayer(i),
                  child: Text(
                    layer.name,
                    style: const TextStyle(color: AtelierTokens.ink),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.lock_outline),
                tooltip: 'アルファロック',
                isSelected: layer.alphaLocked,
                color: layer.alphaLocked ? AtelierTokens.vermilion : null,
                onPressed: () => controller.toggleLayerAlphaLock(i),
              ),
              IconButton(
                icon: const Icon(Icons.south_east),
                tooltip: '下のレイヤーでクリッピング',
                isSelected: layer.clipToLower,
                color: layer.clipToLower ? AtelierTokens.vermilion : null,
                onPressed: () => controller.toggleLayerClip(i),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: '削除',
                onPressed: () {
                  if (!controller.removeLayer(i)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('最後のレイヤーは消せません')),
                    );
                  }
                },
              ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 8),
              DropdownButton<LayerBlendMode>(
                value: layer.blendMode,
                dropdownColor: AtelierTokens.surface3,
                underline: const SizedBox.shrink(),
                style: const TextStyle(color: AtelierTokens.ink, fontSize: 13),
                items: [
                  for (final mode in LayerBlendMode.values)
                    DropdownMenuItem(value: mode, child: Text(mode.label)),
                ],
                onChanged: (mode) {
                  if (mode != null) controller.setLayerBlendMode(i, mode);
                },
              ),
              Expanded(
                child: Slider(
                  value: layer.opacity,
                  label: '${(layer.opacity * 100).round()}%',
                  onChanged: (v) => controller.setLayerOpacity(i, v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
