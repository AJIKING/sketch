import 'package:flutter/material.dart';

import '../theme/atelier_theme.dart';

/// 縦スライダー(SIZE / OPAC)。回転した [Slider] を使い、ラベルと現在値を添える。
///
/// プロトタイプのカスタム縦スライダー相当。Slider なのでドラッグもキーボードも
/// 効き、semantics ラベルも付く(`docs/test-plan.md` Widget「縦スライダー」)。
class VSlider extends StatelessWidget {
  const VSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.format,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String Function(double) format;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    // 高さは親(Expanded)から与えられた範囲いっぱいに伸びる。横画面でも収まる。
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AtelierTokens.inkDim,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              label: format(value),
              semanticFormatterCallback: (v) => '$label ${format(v)}',
              onChanged: onChanged,
            ),
          ),
        ),
        Text(
          format(value),
          style: const TextStyle(color: AtelierTokens.ink, fontSize: 12),
        ),
      ],
    );
  }
}
