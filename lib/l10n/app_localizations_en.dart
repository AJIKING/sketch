// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Draw, more freely.';

  @override
  String gallerySketchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sketches',
      one: '1 sketch',
      zero: 'No sketches yet',
    );
    return '$_temp0';
  }

  @override
  String get galleryNewCanvas => 'New canvas';

  @override
  String get galleryNewSketchSemantic => 'Start a new sketch';

  @override
  String get untitledSketch => 'Your sketch';

  @override
  String copyOf(String title) {
    return '$title copy';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonChange => 'Change';

  @override
  String get commonShare => 'Share';

  @override
  String get commonApply => 'Apply';

  @override
  String get actionRename => 'Rename';

  @override
  String get renamed => 'Renamed';

  @override
  String get actionDuplicate => 'Duplicate';

  @override
  String get duplicated => 'Duplicated';

  @override
  String get duplicateFailed => 'Couldn\'t duplicate';

  @override
  String get deleteSketchTitle => 'Delete this sketch?';

  @override
  String get deleteSketchBody => 'This can\'t be undone.';

  @override
  String get renameHint => 'Sketch name';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'Follow system';

  @override
  String get canvasSizeTitle => 'Canvas size';

  @override
  String get sizeScreen => 'Screen size';

  @override
  String get sizeSquare1080 => 'Square 1080×1080';

  @override
  String get sizeSquare2048 => 'Square 2048×2048';

  @override
  String get sizePortrait => 'Portrait 1080×1920';

  @override
  String get sizeLandscape => 'Landscape 1920×1080';

  @override
  String get tooltipBackToGallery => 'Back to gallery';

  @override
  String get tooltipUndo => 'Undo';

  @override
  String get tooltipRedo => 'Redo';

  @override
  String get tooltipResetView => 'Reset view';

  @override
  String get tooltipMenu => 'Menu';

  @override
  String get filterInvert => 'Invert';

  @override
  String get filterGrayscale => 'Grayscale';

  @override
  String get filterBlur => 'Blur';

  @override
  String get filterMosaic => 'Mosaic';

  @override
  String get filterBrighten => 'Brighten';

  @override
  String get filterDarken => 'Darken';

  @override
  String get filterContrast => 'Contrast+';

  @override
  String get menuExport => 'Save as image';

  @override
  String get menuImportPhoto => 'Import photo';

  @override
  String get menuShare => 'Share (social, etc.)';

  @override
  String get menuTimelapse => 'Timelapse recording';

  @override
  String timelapseRecording(int count) {
    return 'Recording ($count frames)';
  }

  @override
  String get timelapseOnHint => 'Turn on to record the drawing process';

  @override
  String get menuExportTimelapse => 'Export timelapse (GIF)';

  @override
  String get menuFilter => 'Filter';

  @override
  String get menuFinish => 'Finish and go to gallery';

  @override
  String get menuClearLayer => 'Clear this layer';

  @override
  String get selectAll => 'Select all';

  @override
  String get selectInvert => 'Invert selection';

  @override
  String get selectFill => 'Fill selection';

  @override
  String get selectClear => 'Clear selection';

  @override
  String get selectDeselect => 'Deselect';

  @override
  String get shapeFillToggle => 'Fill (outline ↔ fill)';

  @override
  String get shapeSnapToggle => 'Snap (45° lines / square · circle)';

  @override
  String get gradientStartColor => 'Start color (color code)';

  @override
  String get gradientTwoColor => 'Two-color gradient';

  @override
  String get gradientTransparentEnd => 'Make end transparent';

  @override
  String gradientSecondColor(String hex) {
    return 'End color $hex';
  }

  @override
  String get gradientDirectionLabel => 'Direction';

  @override
  String get sliderSize => 'SIZE';

  @override
  String get sliderOpac => 'OPAC';

  @override
  String get adjustHint => '1 finger = move, 2 fingers = scale';

  @override
  String get recolorSelection => 'Recolor selection to current color';

  @override
  String get finishAdjust => 'Finish adjusting';

  @override
  String get vectorUndo => 'Undo vector';

  @override
  String get vectorRedo => 'Redo vector';

  @override
  String get deleteSelection => 'Delete selection';

  @override
  String get transformCancel => 'Cancel transform';

  @override
  String get transformHint =>
      'Transform (1 finger = move / 2 fingers = scale · rotate)';

  @override
  String get transformConfirm => 'Confirm transform';

  @override
  String get maskEditingBanner => 'Editing mask (tap to finish)';

  @override
  String get toolBrush => 'Brush';

  @override
  String get toolSmudge => 'Smudge';

  @override
  String get toolErase => 'Eraser';

  @override
  String get toolFill => 'Fill';

  @override
  String get toolGradient => 'Gradient';

  @override
  String get toolShape => 'Shape';

  @override
  String get toolText => 'Text';

  @override
  String get toolSelect => 'Select';

  @override
  String get toolEyedropper => 'Eyedropper';

  @override
  String get toolTransform => 'Transform';

  @override
  String get vectorOn => 'Vector: ON';

  @override
  String get vectorOff => 'Vector: OFF';

  @override
  String get layers => 'Layers';

  @override
  String get pickColor => 'Pick a color';

  @override
  String colorTitle(String hex) {
    return 'Color  $hex';
  }

  @override
  String get studioPalette => 'Studio Palette';

  @override
  String get recentColors => 'Recent';

  @override
  String get noRecentColors => 'Nothing yet';

  @override
  String get myPalette => 'My palette';

  @override
  String get saveCurrentColor => 'Save current color';

  @override
  String get myPaletteHint =>
      'Save your own colors with \"Save current color\" (long-press to remove)';

  @override
  String get symmetryLabel => 'Symmetry';

  @override
  String get stabilization => 'Stabilization';

  @override
  String get brushFlow => 'Flow';

  @override
  String get brushScatter => 'Scatter';

  @override
  String get brushSpacing => 'Spacing';

  @override
  String get layerAlphaLock => 'Alpha lock';

  @override
  String get layerToggleVisible => 'Toggle visibility';

  @override
  String get layerClip => 'Clip to layer below';

  @override
  String get layerAddMask => 'Add mask';

  @override
  String get layerMask => 'Mask';

  @override
  String get layerMaskEditEnd => 'Finish editing mask';

  @override
  String get layerMaskEdit => 'Edit mask';

  @override
  String get layerMaskRemove => 'Remove mask';

  @override
  String get layerMergeDown => 'Merge down';

  @override
  String get lastLayerCannotDelete => 'Can\'t delete the last layer';

  @override
  String get layerMoveForward => 'Move forward';

  @override
  String get layerMoveBackward => 'Move backward';

  @override
  String layerName(int n) {
    return 'Layer $n';
  }

  @override
  String get shareMessageLabel => 'Message (optional)';

  @override
  String get shareMessageHint => 'Caption for social posts';

  @override
  String get shareDefaultCaption => 'Drawn with Rakuga #Rakuga';

  @override
  String get timelapseDefaultCaption => 'Timelapse with Rakuga #Rakuga';

  @override
  String exportError(String error) {
    return 'Export error: $error';
  }

  @override
  String get timelapseSaved => 'Timelapse saved';

  @override
  String get timelapseEmpty => 'No timelapse recorded';

  @override
  String get imageSaved => 'Image saved';

  @override
  String get imageGenerateFailed => 'Couldn\'t generate the image';

  @override
  String get photoImported => 'Imported the photo as a layer';

  @override
  String get shared => 'Shared';

  @override
  String get hiddenLayerWarning => 'Can\'t draw on a hidden layer';

  @override
  String get hexFormatError => 'Enter in #RRGGBB format';

  @override
  String get colorCode => 'Color code';

  @override
  String get saturationValue => 'Saturation and value';

  @override
  String get hue => 'Hue';

  @override
  String get textEdit => 'Edit text';

  @override
  String get textInputHint => 'Enter text (tap to start)';

  @override
  String get textSize => 'Size';

  @override
  String get textBold => 'Bold';

  @override
  String get textUnderline => 'Underline';

  @override
  String get textStrikethrough => 'Strikethrough';

  @override
  String get textFont => 'Font';

  @override
  String get textColor => 'Color';

  @override
  String get textUpdate => 'Update';

  @override
  String get shapeLine => 'Line';

  @override
  String get shapeRectangle => 'Rectangle';

  @override
  String get shapeTriangle => 'Triangle';

  @override
  String get shapeEllipse => 'Ellipse';

  @override
  String get symNone => 'None';

  @override
  String get symVertical => 'Mirror L/R';

  @override
  String get symHorizontal => 'Mirror T/B';

  @override
  String get symQuad => 'Quad';

  @override
  String get selRectangle => 'Rectangle';

  @override
  String get selLasso => 'Lasso';

  @override
  String get selMagicWand => 'Magic wand';

  @override
  String get gradHorizontal => 'Horizontal';

  @override
  String get gradVertical => 'Vertical';

  @override
  String get gradDiagonalDown => 'Diagonal ↘';

  @override
  String get gradDiagonalUp => 'Diagonal ↗';

  @override
  String get gradRadial => 'Radial';

  @override
  String get blendNormal => 'Normal';

  @override
  String get blendMultiply => 'Multiply';

  @override
  String get blendScreen => 'Screen';

  @override
  String get blendOverlay => 'Overlay';

  @override
  String get blendDarken => 'Darken';

  @override
  String get blendLighten => 'Lighten';

  @override
  String get blendColorDodge => 'Color dodge';

  @override
  String get blendColorBurn => 'Color burn';

  @override
  String get blendHardLight => 'Hard light';

  @override
  String get blendSoftLight => 'Soft light';

  @override
  String get blendDifference => 'Difference';

  @override
  String get blendExclusion => 'Exclusion';

  @override
  String get blendAdd => 'Add (glow)';

  @override
  String get blendHue => 'Hue';

  @override
  String get blendSaturation => 'Saturation';

  @override
  String get blendColor => 'Color';

  @override
  String get blendLuminosity => 'Luminosity';

  @override
  String get brushNameInk => 'Ink';

  @override
  String get brushDescInk => 'Smooth and even; width varies with speed';

  @override
  String get brushNamePencil => 'Pencil';

  @override
  String get brushDescPencil => 'Grainy pencil; darker as you layer';

  @override
  String get brushNameMarker => 'Marker';

  @override
  String get brushDescMarker => 'Flat and translucent; overlaps build color';

  @override
  String get brushNameAir => 'Airbrush';

  @override
  String get brushDescAir => 'Soft, misty buildup';

  @override
  String get brushNameFude => 'Brush pen';

  @override
  String get brushDescFude => 'Tapered strokes; speed adds emphasis';

  @override
  String get brushNameCrayon => 'Crayon';

  @override
  String get brushDescCrayon => 'Coarse grain; rough texture';

  @override
  String get brushNameChalk => 'Chalk';

  @override
  String get brushDescChalk => 'Soft and powdery; layers lightly';

  @override
  String get brushNameStipple => 'Stipple';

  @override
  String get brushDescStipple => 'Sparse dots; good for stippling and texture';

  @override
  String get brushNameSoftPen => 'Soft pen';

  @override
  String get brushDescSoftPen => 'Soft edges; lays down smoothly';

  @override
  String get brushNameGlow => 'Glow';

  @override
  String get brushDescGlow => 'Soft glowing light; brightens as you layer';

  @override
  String get brushNameSponge => 'Sponge';

  @override
  String get brushDescSponge => 'Large scattered grain; rough fill';

  @override
  String get brushNameDry => 'Dry';

  @override
  String get brushDescDry => 'Dry, broken strokes; coarse texture';

  @override
  String get brushNameMaru => 'Maru pen';

  @override
  String get brushDescMaru => 'Thin, even nib; stable line width';

  @override
  String get brushNameBallpen => 'Ballpoint';

  @override
  String get brushDescBallpen => 'Slightly faint, even line; good for writing';

  @override
  String get brushNameGpen => 'G-pen';

  @override
  String get brushDescGpen =>
      'Expressive manga pen; sharp speed-based variation';

  @override
  String get brushNameWatercolor => 'Watercolor';

  @override
  String get brushDescWatercolor => 'Bleeding, pale wash; deepens as you layer';

  @override
  String get brushNameOil => 'Oil';

  @override
  String get brushDescOil => 'Thick, flat paint; overlaps build texture';

  @override
  String get brushNameBristle => 'Bristle';

  @override
  String get brushDescBristle => 'Splitting bristles; streaky fill';

  @override
  String get fontDefault => 'Default';

  @override
  String get fontGothic => 'Gothic';

  @override
  String get fontMincho => 'Mincho';

  @override
  String get fontRoundGothic => 'Round Gothic';

  @override
  String get fontKosugiMaru => 'Kosugi Maru';

  @override
  String get fontZenMaru => 'Zen Maru';

  @override
  String get fontSawarabiMincho => 'Sawarabi Mincho';

  @override
  String get fontShipporiMincho => 'Shippori Mincho';

  @override
  String get fontZenKaku => 'Zen Kaku';

  @override
  String get fontYuseiMagic => 'Yusei Magic';

  @override
  String get fontDelaGothic => 'Dela Gothic';

  @override
  String get fontKaiseiDecol => 'Kaisei Decol';

  @override
  String get fontRocknRoll => 'RocknRoll';

  @override
  String get fontHachiMaru => 'Hachi Maru Pop';

  @override
  String get fontReggae => 'Reggae';

  @override
  String get fontStick => 'Stick';

  @override
  String get fontPotta => 'Potta One';

  @override
  String get fontDot => 'Dot';
}
