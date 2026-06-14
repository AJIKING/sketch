import 'package:flutter/material.dart';

import '../../application/gallery_controller.dart';
import '../../domain/gallery/sketch.dart';
import '../theme/atelier_theme.dart';
import 'piece_card.dart';

/// ギャラリー画面(`docs/product-spec.md`「ギャラリー」)。
///
/// スケッチ点数・一覧・「新規キャンバス」を表示する。遷移は呼び出し側に委ねる
/// ([onNewCanvas] / [onOpenSketch])ため、画面単体で widget テストできる。
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({
    super.key,
    required this.controller,
    required this.onNewCanvas,
    required this.onOpenSketch,
  });

  final GalleryController controller;
  final VoidCallback onNewCanvas;
  final void Function(Sketch sketch) onOpenSketch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final sketches = controller.sketches;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hatch',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: AtelierTokens.ink,
                            ),
                          ),
                          Text(
                            'Pocket Atelier',
                            style: TextStyle(color: AtelierTokens.inkDim),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '${controller.count}点の\nスケッチ',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: AtelierTokens.inkDim),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.78,
                    children: [
                      _NewCanvasCard(onTap: onNewCanvas),
                      for (final sketch in sketches)
                        PieceCard(
                          sketch: sketch,
                          imageFuture: controller.image(sketch.id),
                          onTap: () => onOpenSketch(sketch),
                          onLongPress: () => _showActions(context, sketch),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 長押しメニュー(複製・削除)。
  void _showActions(BuildContext context, Sketch sketch) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AtelierTokens.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_all_outlined),
              title: const Text(
                '複製',
                style: TextStyle(color: AtelierTokens.ink),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final messenger = ScaffoldMessenger.of(context);
                final copy = await controller.duplicate(sketch.id);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(copy != null ? '複製しました' : '複製できませんでした'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AtelierTokens.vermilion,
              ),
              title: const Text(
                '削除',
                style: TextStyle(color: AtelierTokens.vermilion),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final ok = await _confirmDelete(context);
                if (ok) await controller.remove(sketch.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('スケッチを削除しますか?'),
        content: const Text('この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              '削除',
              style: TextStyle(color: AtelierTokens.vermilion),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _NewCanvasCard extends StatelessWidget {
  const _NewCanvasCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '新しいスケッチを始める',
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AtelierTokens.hairStrong),
            borderRadius: BorderRadius.circular(AtelierTokens.rMd),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: AtelierTokens.ink, size: 28),
              SizedBox(height: 8),
              Text('新規キャンバス', style: TextStyle(color: AtelierTokens.ink)),
            ],
          ),
        ),
      ),
    );
  }
}
