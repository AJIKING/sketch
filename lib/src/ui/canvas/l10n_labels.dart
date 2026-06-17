import '../../../l10n/app_localizations.dart';
import '../../domain/canvas/gradient_direction.dart';
import '../../domain/canvas/layer_blend_mode.dart';
import '../../domain/canvas/selection_kind.dart';
import '../../domain/canvas/shape_kind.dart';
import '../../domain/canvas/symmetry_mode.dart';

/// ドメインの安定キー(enum 値 / ブラシ key / フォント family)を、表示言語に応じた
/// ラベルへ解決する UI 層のヘルパ(`docs/architecture.md`「UI が表示を所有」)。
///
/// domain は pure Dart のまま識別子だけを持ち、ここで [AppLocalizations] と対応づける。
extension ShapeKindL10n on ShapeKind {
  String label(AppLocalizations l) => switch (this) {
    ShapeKind.line => l.shapeLine,
    ShapeKind.rectangle => l.shapeRectangle,
    ShapeKind.triangle => l.shapeTriangle,
    ShapeKind.ellipse => l.shapeEllipse,
  };
}

extension SymmetryModeL10n on SymmetryMode {
  String label(AppLocalizations l) => switch (this) {
    SymmetryMode.none => l.symNone,
    SymmetryMode.vertical => l.symVertical,
    SymmetryMode.horizontal => l.symHorizontal,
    SymmetryMode.quad => l.symQuad,
  };
}

extension SelectionKindL10n on SelectionKind {
  String label(AppLocalizations l) => switch (this) {
    SelectionKind.rectangle => l.selRectangle,
    SelectionKind.lasso => l.selLasso,
    SelectionKind.magicWand => l.selMagicWand,
  };
}

extension GradientDirectionL10n on GradientDirection {
  String label(AppLocalizations l) => switch (this) {
    GradientDirection.horizontal => l.gradHorizontal,
    GradientDirection.vertical => l.gradVertical,
    GradientDirection.diagonalDown => l.gradDiagonalDown,
    GradientDirection.diagonalUp => l.gradDiagonalUp,
    GradientDirection.radial => l.gradRadial,
  };
}

extension LayerBlendModeL10n on LayerBlendMode {
  String label(AppLocalizations l) => switch (this) {
    LayerBlendMode.normal => l.blendNormal,
    LayerBlendMode.multiply => l.blendMultiply,
    LayerBlendMode.screen => l.blendScreen,
    LayerBlendMode.overlay => l.blendOverlay,
    LayerBlendMode.darken => l.blendDarken,
    LayerBlendMode.lighten => l.blendLighten,
    LayerBlendMode.colorDodge => l.blendColorDodge,
    LayerBlendMode.colorBurn => l.blendColorBurn,
    LayerBlendMode.hardLight => l.blendHardLight,
    LayerBlendMode.softLight => l.blendSoftLight,
    LayerBlendMode.difference => l.blendDifference,
    LayerBlendMode.exclusion => l.blendExclusion,
    LayerBlendMode.add => l.blendAdd,
    LayerBlendMode.hue => l.blendHue,
    LayerBlendMode.saturation => l.blendSaturation,
    LayerBlendMode.color => l.blendColor,
    LayerBlendMode.luminosity => l.blendLuminosity,
  };
}

/// ブラシプリセットの表示名(`BrushPreset.key` から解決)。未知キーは key をそのまま返す。
String brushName(AppLocalizations l, String key) => switch (key) {
  'ink' => l.brushNameInk,
  'pencil' => l.brushNamePencil,
  'marker' => l.brushNameMarker,
  'air' => l.brushNameAir,
  'fude' => l.brushNameFude,
  'crayon' => l.brushNameCrayon,
  'chalk' => l.brushNameChalk,
  'stipple' => l.brushNameStipple,
  'softpen' => l.brushNameSoftPen,
  'glow' => l.brushNameGlow,
  'sponge' => l.brushNameSponge,
  'dry' => l.brushNameDry,
  'maru' => l.brushNameMaru,
  'ballpen' => l.brushNameBallpen,
  'gpen' => l.brushNameGpen,
  'watercolor' => l.brushNameWatercolor,
  'oil' => l.brushNameOil,
  'bristle' => l.brushNameBristle,
  _ => key,
};

/// ブラシプリセットの説明文(`BrushPreset.key` から解決)。未知キーは空文字。
String brushDescription(AppLocalizations l, String key) => switch (key) {
  'ink' => l.brushDescInk,
  'pencil' => l.brushDescPencil,
  'marker' => l.brushDescMarker,
  'air' => l.brushDescAir,
  'fude' => l.brushDescFude,
  'crayon' => l.brushDescCrayon,
  'chalk' => l.brushDescChalk,
  'stipple' => l.brushDescStipple,
  'softpen' => l.brushDescSoftPen,
  'glow' => l.brushDescGlow,
  'sponge' => l.brushDescSponge,
  'dry' => l.brushDescDry,
  'maru' => l.brushDescMaru,
  'ballpen' => l.brushDescBallpen,
  'gpen' => l.brushDescGpen,
  'watercolor' => l.brushDescWatercolor,
  'oil' => l.brushDescOil,
  'bristle' => l.brushDescBristle,
  _ => '',
};
