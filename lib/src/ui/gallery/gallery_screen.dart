import 'package:flutter/material.dart';

import '../theme/atelier_theme.dart';

/// ギャラリー画面のプレースホルダ。
///
/// スケルトン段階では「新規キャンバス」ボタンとブランド表記だけを置く。
/// 実装は `docs/product-spec.md`「ギャラリー」と `docs/architecture.md` の
/// フォルダ構成に従って肉付けする(piece_card / gallery_controller など)。
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hatch',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AtelierTokens.ink,
                ),
              ),
              const Text(
                'Pocket Atelier',
                style: TextStyle(color: AtelierTokens.inkDim),
              ),
              const Spacer(),
              Center(
                child: FilledButton.icon(
                  onPressed: () {
                    // TODO(hatch): キャンバス画面へ遷移する(product-spec 参照)。
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('新規キャンバス'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
