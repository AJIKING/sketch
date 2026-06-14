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
