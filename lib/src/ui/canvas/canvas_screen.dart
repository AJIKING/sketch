import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../application/canvas_controller.dart';
import '../../application/dependencies.dart';
import '../../application/gallery_controller.dart';
import '../../domain/brush/brush_preset.dart';
import '../../domain/canvas/filters.dart' as filters;
import '../../domain/canvas/layer_blend_mode.dart';
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
  late final RasterLayerStore _surface = RasterLayerStore();
  late final CanvasController _c = CanvasController(surface: _surface);

  late final String _id =
      widget.existing?.id ??
      'sketch-${widget.dependencies.clock.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
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
    _c.dispose();
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
      builder: (_) => ListenableBuilder(
        listenable: _c,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
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
    _c.selectTool(tool);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtelierTokens.shell,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) {
            return Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 64, 8, 96),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AtelierTokens.rLg),
                      child: DrawSurface(
                        key: _drawKey,
                        controller: _c,
                        surface: _surface,
                        clock: widget.dependencies.clock,
                      ),
                    ),
                  ),
                ),
                _topBar(),
                _leftRail(),
                _dock(),
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
            icon: const Icon(Icons.more_vert),
            tooltip: 'メニュー',
            onPressed: _openMenuSheet,
          ),
        ],
      ),
    );
  }

  Widget _leftRail() {
    return Positioned(
      left: 4,
      top: 80,
      child: Column(
        children: [
          VSlider(
            label: 'SIZE',
            value: _c.size,
            min: 1,
            max: 80,
            format: (v) => v.round().toString(),
            onChanged: _c.setSize,
          ),
          const SizedBox(height: 12),
          VSlider(
            label: 'OPAC',
            value: _c.opacity * 100,
            min: 0,
            max: 100,
            format: (v) => '${v.round()}%',
            onChanged: (v) => _c.setOpacity(v / 100),
          ),
        ],
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
                    _toolButton(Tool.eyedropper, Icons.colorize, 'スポイト'),
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
      ],
    );
  }

  Widget _swatches(List<String> hexes, ValueChanged<String> onPick) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final hex in hexes)
          GestureDetector(
            onTap: () => onPick(hex),
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
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 380),
          child: ListView(
            shrinkWrap: true,
            children: [
              // 最前面を上に表示する。
              for (var i = layers.length - 1; i >= 0; i--)
                _layerRow(context, i),
            ],
          ),
        ),
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
