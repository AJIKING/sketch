import 'package:flutter/material.dart';

import '../../application/gallery_controller.dart';
import '../../application/locale_controller.dart';
import '../../domain/gallery/sketch.dart';
import '../../../l10n/app_localizations.dart';
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
    this.localeController,
  });

  final GalleryController controller;
  final VoidCallback onNewCanvas;
  final void Function(Sketch sketch) onOpenSketch;

  /// 表示言語の切替(任意。null なら言語ボタンを出さない)。
  final LocaleController? localeController;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                  // 左右をそれぞれ 2 行に揃える:
                  //   Rakuga       … 言語アイコン
                  //   タグライン   … N 点のスケッチ
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 46,
                            child: Text(
                              'Rakuga',
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: AtelierTokens.ink,
                              ),
                            ),
                          ),
                          Text(
                            l.appTagline,
                            style: const TextStyle(color: AtelierTokens.inkDim),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 46,
                            child: localeController != null
                                ? IconButton(
                                    icon: const Icon(Icons.language),
                                    tooltip: l.languageTitle,
                                    color: AtelierTokens.inkDim,
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        _showLanguageSheet(context),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          Text(
                            l.gallerySketchCount(controller.count),
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: AtelierTokens.inkDim),
                          ),
                        ],
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
    final l = AppLocalizations.of(context);
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
              title: Text(
                l.actionRename,
                style: const TextStyle(color: AtelierTokens.ink),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final messenger = ScaffoldMessenger.of(context);
                final name = await _promptName(context, sketch.title);
                if (name == null) return; // キャンセル
                await controller.rename(sketch.id, name);
                messenger.showSnackBar(SnackBar(content: Text(l.renamed)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_all_outlined),
              title: Text(
                l.actionDuplicate,
                style: const TextStyle(color: AtelierTokens.ink),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final messenger = ScaffoldMessenger.of(context);
                final copy = await controller.duplicate(
                  sketch.id,
                  copyName: l.copyOf(sketch.title ?? l.untitledSketch),
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      copy != null ? l.duplicated : l.duplicateFailed,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AtelierTokens.vermilion,
              ),
              title: Text(
                l.commonDelete,
                style: const TextStyle(color: AtelierTokens.vermilion),
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
    final l = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.deleteSketchTitle),
        content: Text(l.deleteSketchBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l.commonDelete,
              style: const TextStyle(color: AtelierTokens.vermilion),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// 言語切替シート(システムに従う / 日本語 / English / 简体中文)。
  void _showLanguageSheet(BuildContext context) {
    final controller = localeController;
    if (controller == null) return;
    final l = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AtelierTokens.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        Widget option(String label, Locale? locale) {
          final selected =
              controller.locale?.languageCode == locale?.languageCode;
          return ListTile(
            title: Text(
              label,
              style: const TextStyle(color: AtelierTokens.ink),
            ),
            trailing: selected
                ? const Icon(Icons.check, color: AtelierTokens.vermilion)
                : null,
            onTap: () {
              controller.setLocale(locale);
              Navigator.of(sheetContext).pop();
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              option(l.languageSystem, null),
              option('日本語', const Locale('ja')),
              option('English', const Locale('en')),
              option('简体中文', const Locale('zh')),
            ],
          ),
        );
      },
    );
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
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.actionRename),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l.renameHint),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        TextButton(onPressed: _submit, child: Text(l.commonChange)),
      ],
    );
  }
}

class _NewCanvasCard extends StatelessWidget {
  const _NewCanvasCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l.galleryNewSketchSemantic,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AtelierTokens.hairStrong),
            borderRadius: BorderRadius.circular(AtelierTokens.rMd),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: AtelierTokens.ink, size: 28),
              const SizedBox(height: 8),
              Text(
                l.galleryNewCanvas,
                style: const TextStyle(color: AtelierTokens.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
