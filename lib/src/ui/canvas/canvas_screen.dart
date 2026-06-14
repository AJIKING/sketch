import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../application/canvas_controller.dart';
import '../../application/dependencies.dart';
import '../../application/gallery_controller.dart';
import '../../domain/brush/brush_preset.dart';
import '../../domain/gallery/sketch.dart';
import '../theme/atelier_theme.dart';
import 'draw_surface.dart';
import 'v_slider.dart';
import 'vector_canvas_surface.dart';

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
  late final VectorCanvasSurface _surface = VectorCanvasSurface();
  late final CanvasController _c = CanvasController(surface: _surface);

  ui.Image? _background;
  late final String _id =
      widget.existing?.id ??
      'sketch-${widget.dependencies.clock.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    final png = widget.backgroundPng;
    if (png != null) _decodeBackground(png);
  }

  Future<void> _decodeBackground(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _background = frame.image);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Color get _currentColor {
    final (r, g, b) = (
      int.parse(_c.colorHex.substring(1, 3), radix: 16),
      int.parse(_c.colorHex.substring(3, 5), radix: 16),
      int.parse(_c.colorHex.substring(5, 7), radix: 16),
    );
    return Color.fromARGB(255, r, g, b);
  }

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
                SnackBar(content: Text(ok ? '画像を保存しました' : '保存は未対応です')),
              );
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
                        background: _background,
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _toolButton(Tool.brush, Icons.brush, 'ブラシ'),
            _toolButton(Tool.smudge, Icons.water_drop_outlined, 'スマッジ'),
            _toolButton(Tool.erase, Icons.auto_fix_normal, '消しゴム'),
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
    final (h, s, v) = controller.hsv;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'カラー  ${controller.colorHex}',
          style: const TextStyle(color: AtelierTokens.ink, fontSize: 18),
        ),
        const SizedBox(height: 8),
        _hsvSlider(
          '色相',
          h,
          0,
          360,
          (x) => controller.setHsv(x, s, v),
          () => controller.addRecent(),
        ),
        _hsvSlider(
          '彩度',
          s,
          0,
          1,
          (x) => controller.setHsv(h, x, v),
          () => controller.addRecent(),
        ),
        _hsvSlider(
          '明度',
          v,
          0,
          1,
          (x) => controller.setHsv(h, s, x),
          () => controller.addRecent(),
        ),
        const SizedBox(height: 8),
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

  Widget _hsvSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    VoidCallback onEnd,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: const TextStyle(color: AtelierTokens.inkDim, fontSize: 12),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            onChangeEnd: (_) => onEnd(),
          ),
        ),
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
                  color: Color.fromARGB(
                    255,
                    int.parse(hex.substring(1, 3), radix: 16),
                    int.parse(hex.substring(3, 5), radix: 16),
                    int.parse(hex.substring(5, 7), radix: 16),
                  ),
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
        for (final brush in brushPresets)
          ListTile(
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
        // 最前面を上に表示する。
        for (var i = layers.length - 1; i >= 0; i--)
          ListTile(
            selected: i == layers.activeIndex,
            selectedTileColor: AtelierTokens.surface3,
            title: Text(
              layers.layers[i].name,
              style: const TextStyle(color: AtelierTokens.ink),
            ),
            subtitle: Text(
              '${(layers.layers[i].opacity * 100).round()}%',
              style: const TextStyle(color: AtelierTokens.inkDim),
            ),
            onTap: () => controller.setActiveLayer(i),
            leading: IconButton(
              icon: Icon(
                layers.layers[i].visible
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              tooltip: '表示切替',
              onPressed: () => controller.toggleLayerVisible(i),
            ),
            trailing: IconButton(
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
          ),
      ],
    );
  }
}
