import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../domain/gallery/sketch.dart';
import '../theme/atelier_theme.dart';

/// ギャラリーの 1 枚(サムネイル + メタ)。
class PieceCard extends StatelessWidget {
  const PieceCard({
    super.key,
    required this.sketch,
    required this.imageFuture,
    required this.onTap,
  });

  final Sketch sketch;
  final Future<Uint8List?> imageFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AtelierTokens.rMd),
              child: ColoredBox(
                color: AtelierTokens.paper,
                child: FutureBuilder<Uint8List?>(
                  future: imageFuture,
                  builder: (context, snapshot) {
                    final bytes = snapshot.data;
                    if (bytes == null) return const SizedBox.expand();
                    return Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, _, _) => const SizedBox.expand(),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sketch.title ?? 'あなたのスケッチ',
            style: const TextStyle(color: AtelierTokens.inkDim, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
