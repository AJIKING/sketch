import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../domain/canvas/gradient_direction.dart';
import '../theme/atelier_theme.dart';
import 'color_picker.dart';
import 'l10n_labels.dart';

/// グラデーション設定の共通 UI(グラデツール・ブラシ・テキストで統一)。
///
/// 各画面が状態の持ち方(コントローラ / ダイアログのローカル)を問わず使えるよう、
/// 値とコールバックだけ受け取る「dumb」widget にしている。表示する項目は引数で
/// 出し分ける(有効トグル・透明終点・方向は不要なら null で省略)。
class GradientSettings extends StatelessWidget {
  const GradientSettings({
    super.key,
    this.enabled,
    this.onEnabledChanged,
    required this.firstColorHex,
    required this.secondColorHex,
    required this.onSecondColorHex,
    this.swatches = const [],
    this.transparent,
    this.onTransparentChanged,
    this.direction,
    this.onDirectionChanged,
  });

  /// グラデ有効トグル(null = 常時オン=トグルを出さない。例: グラデツール)。
  final bool? enabled;
  final ValueChanged<bool>? onEnabledChanged;

  /// 始点色(プレビュー用)。
  final String firstColorHex;
  final String secondColorHex;
  final ValueChanged<String> onSecondColorHex;
  final List<String> swatches;

  /// 終点を透明にするトグル(null = 出さない)。
  final bool? transparent;
  final ValueChanged<bool>? onTransparentChanged;

  /// 方向(null = 出さない。ブラシは方向=ストロークなので渡さない)。
  final GradientDirection? direction;
  final ValueChanged<GradientDirection>? onDirectionChanged;

  bool get _active => enabled ?? true;
  bool get _useSecondColor => transparent != true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (enabled != null)
          SwitchListTile(
            key: const Key('gradient-enable-switch'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              l.gradientTwoColor,
              style: const TextStyle(color: AtelierTokens.ink),
            ),
            value: enabled!,
            onChanged: onEnabledChanged,
          ),
        if (_active) ...[
          if (transparent != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l.gradientTransparentEnd,
                style: const TextStyle(color: AtelierTokens.ink),
              ),
              value: transparent!,
              onChanged: onTransparentChanged,
            ),
          if (_useSecondColor) ...[
            Row(
              children: [
                const SizedBox(width: 4),
                _dot(firstColorHex, false),
                const Icon(
                  Icons.arrow_right_alt,
                  color: AtelierTokens.inkDim,
                  size: 20,
                ),
                _dot(secondColorHex, true),
                const SizedBox(width: 8),
                Text(
                  l.gradientSecondColor(secondColorHex),
                  style: const TextStyle(
                    color: AtelierTokens.inkDim,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            HexColorField(hex: secondColorHex, onSubmitted: onSecondColorHex),
            if (swatches.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final hex in swatches)
                    GestureDetector(
                      onTap: () => onSecondColorHex(hex),
                      child: Semantics(
                        button: true,
                        label: l.gradientSecondColor(hex),
                        child: _dot(hex, hex == secondColorHex),
                      ),
                    ),
                ],
              ),
            ],
          ],
          if (direction != null) ...[
            const SizedBox(height: 12),
            Text(
              l.gradientDirectionLabel,
              style: const TextStyle(color: AtelierTokens.inkDim, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final d in GradientDirection.values)
                  ChoiceChip(
                    label: Text(d.label(l)),
                    selected: direction == d,
                    onSelected: (_) => onDirectionChanged?.call(d),
                  ),
              ],
            ),
          ],
        ],
      ],
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
}
