import 'dart:ui';

import '../../domain/canvas/layer_blend_mode.dart';

/// domain の [LayerBlendMode] を `dart:ui.BlendMode` に対応づける(ui 層)。
BlendMode toUiBlendMode(LayerBlendMode mode) => switch (mode) {
  LayerBlendMode.normal => BlendMode.srcOver,
  LayerBlendMode.multiply => BlendMode.multiply,
  LayerBlendMode.screen => BlendMode.screen,
  LayerBlendMode.overlay => BlendMode.overlay,
  LayerBlendMode.darken => BlendMode.darken,
  LayerBlendMode.lighten => BlendMode.lighten,
  LayerBlendMode.colorDodge => BlendMode.colorDodge,
  LayerBlendMode.colorBurn => BlendMode.colorBurn,
  LayerBlendMode.hardLight => BlendMode.hardLight,
  LayerBlendMode.softLight => BlendMode.softLight,
  LayerBlendMode.difference => BlendMode.difference,
  LayerBlendMode.exclusion => BlendMode.exclusion,
  LayerBlendMode.add => BlendMode.plus,
  LayerBlendMode.hue => BlendMode.hue,
  LayerBlendMode.saturation => BlendMode.saturation,
  LayerBlendMode.color => BlendMode.color,
  LayerBlendMode.luminosity => BlendMode.luminosity,
};
