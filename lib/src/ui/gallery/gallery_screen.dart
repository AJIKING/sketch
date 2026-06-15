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
                            'Rakuga',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: AtelierTokens.ink,
                            ),
                          ),
                          Text(
                            '描くを、もっと気軽に。',
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

  /// 長押しメニュー(名前変更・複製・削除)。
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
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text(
                '名前を変更',
                style: TextStyle(color: AtelierTokens.ink),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final messenger = ScaffoldMessenger.of(context);
                final name = await _promptName(context, sketch.title);
                if (name == null) return; // キャンセル
                await controller.rename(sketch.id, name);
                messenger.showSnackBar(
                  const SnackBar(content: Text('名前を変更しました')),
                );
              },
            ),
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

  /// 名前入力ダイアログ。確定で入力文字列、キャンセルで null を返す。
  Future<String?> _promptName(BuildContext context, String? initial) {
    return showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: initial ?? ''),
    );
  }
}

/// 名前変更ダイアログ(コントローラを State で確実に dispose する)。
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});
  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('名前を変更'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'スケッチの名前'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(onPressed: _submit, child: const Text('変更')),
      ],
    );
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
