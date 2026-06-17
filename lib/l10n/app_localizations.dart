import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
  ];

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Draw, more freely.'**
  String get appTagline;

  /// No description provided for @gallerySketchCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sketches yet} =1{1 sketch} other{{count} sketches}}'**
  String gallerySketchCount(int count);

  /// No description provided for @galleryNewCanvas.
  ///
  /// In en, this message translates to:
  /// **'New canvas'**
  String get galleryNewCanvas;

  /// No description provided for @galleryNewSketchSemantic.
  ///
  /// In en, this message translates to:
  /// **'Start a new sketch'**
  String get galleryNewSketchSemantic;

  /// No description provided for @untitledSketch.
  ///
  /// In en, this message translates to:
  /// **'Your sketch'**
  String get untitledSketch;

  /// No description provided for @copyOf.
  ///
  /// In en, this message translates to:
  /// **'{title} copy'**
  String copyOf(String title);

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get commonChange;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @actionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get actionRename;

  /// No description provided for @renamed.
  ///
  /// In en, this message translates to:
  /// **'Renamed'**
  String get renamed;

  /// No description provided for @actionDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get actionDuplicate;

  /// No description provided for @duplicated.
  ///
  /// In en, this message translates to:
  /// **'Duplicated'**
  String get duplicated;

  /// No description provided for @duplicateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t duplicate'**
  String get duplicateFailed;

  /// No description provided for @deleteSketchTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this sketch?'**
  String get deleteSketchTitle;

  /// No description provided for @deleteSketchBody.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get deleteSketchBody;

  /// No description provided for @renameHint.
  ///
  /// In en, this message translates to:
  /// **'Sketch name'**
  String get renameHint;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @canvasSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Canvas size'**
  String get canvasSizeTitle;

  /// No description provided for @sizeScreen.
  ///
  /// In en, this message translates to:
  /// **'Screen size'**
  String get sizeScreen;

  /// No description provided for @sizeSquare1080.
  ///
  /// In en, this message translates to:
  /// **'Square 1080×1080'**
  String get sizeSquare1080;

  /// No description provided for @sizeSquare2048.
  ///
  /// In en, this message translates to:
  /// **'Square 2048×2048'**
  String get sizeSquare2048;

  /// No description provided for @sizePortrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait 1080×1920'**
  String get sizePortrait;

  /// No description provided for @sizeLandscape.
  ///
  /// In en, this message translates to:
  /// **'Landscape 1920×1080'**
  String get sizeLandscape;

  /// No description provided for @tooltipBackToGallery.
  ///
  /// In en, this message translates to:
  /// **'Back to gallery'**
  String get tooltipBackToGallery;

  /// No description provided for @tooltipUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get tooltipUndo;

  /// No description provided for @tooltipRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get tooltipRedo;

  /// No description provided for @tooltipResetView.
  ///
  /// In en, this message translates to:
  /// **'Reset view'**
  String get tooltipResetView;

  /// No description provided for @tooltipMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get tooltipMenu;

  /// No description provided for @filterInvert.
  ///
  /// In en, this message translates to:
  /// **'Invert'**
  String get filterInvert;

  /// No description provided for @filterGrayscale.
  ///
  /// In en, this message translates to:
  /// **'Grayscale'**
  String get filterGrayscale;

  /// No description provided for @filterBlur.
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get filterBlur;

  /// No description provided for @filterMosaic.
  ///
  /// In en, this message translates to:
  /// **'Mosaic'**
  String get filterMosaic;

  /// No description provided for @filterBrighten.
  ///
  /// In en, this message translates to:
  /// **'Brighten'**
  String get filterBrighten;

  /// No description provided for @filterDarken.
  ///
  /// In en, this message translates to:
  /// **'Darken'**
  String get filterDarken;

  /// No description provided for @filterContrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast+'**
  String get filterContrast;

  /// No description provided for @menuExport.
  ///
  /// In en, this message translates to:
  /// **'Save as image'**
  String get menuExport;

  /// No description provided for @menuImportPhoto.
  ///
  /// In en, this message translates to:
  /// **'Import photo'**
  String get menuImportPhoto;

  /// No description provided for @menuShare.
  ///
  /// In en, this message translates to:
  /// **'Share (social, etc.)'**
  String get menuShare;

  /// No description provided for @menuTimelapse.
  ///
  /// In en, this message translates to:
  /// **'Timelapse recording'**
  String get menuTimelapse;

  /// No description provided for @timelapseRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording ({count} frames)'**
  String timelapseRecording(int count);

  /// No description provided for @timelapseOnHint.
  ///
  /// In en, this message translates to:
  /// **'Turn on to record the drawing process'**
  String get timelapseOnHint;

  /// No description provided for @menuExportTimelapse.
  ///
  /// In en, this message translates to:
  /// **'Export timelapse (GIF)'**
  String get menuExportTimelapse;

  /// No description provided for @menuFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get menuFilter;

  /// No description provided for @menuFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish and go to gallery'**
  String get menuFinish;

  /// No description provided for @menuClearLayer.
  ///
  /// In en, this message translates to:
  /// **'Clear this layer'**
  String get menuClearLayer;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @selectInvert.
  ///
  /// In en, this message translates to:
  /// **'Invert selection'**
  String get selectInvert;

  /// No description provided for @selectFill.
  ///
  /// In en, this message translates to:
  /// **'Fill selection'**
  String get selectFill;

  /// No description provided for @selectClear.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get selectClear;

  /// No description provided for @selectDeselect.
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get selectDeselect;

  /// No description provided for @shapeFillToggle.
  ///
  /// In en, this message translates to:
  /// **'Fill (outline ↔ fill)'**
  String get shapeFillToggle;

  /// No description provided for @shapeSnapToggle.
  ///
  /// In en, this message translates to:
  /// **'Snap (45° lines / square · circle)'**
  String get shapeSnapToggle;

  /// No description provided for @gradientStartColor.
  ///
  /// In en, this message translates to:
  /// **'Start color (color code)'**
  String get gradientStartColor;

  /// No description provided for @gradientTwoColor.
  ///
  /// In en, this message translates to:
  /// **'Two-color gradient'**
  String get gradientTwoColor;

  /// No description provided for @gradientTransparentEnd.
  ///
  /// In en, this message translates to:
  /// **'Make end transparent'**
  String get gradientTransparentEnd;

  /// No description provided for @gradientSecondColor.
  ///
  /// In en, this message translates to:
  /// **'End color {hex}'**
  String gradientSecondColor(String hex);

  /// No description provided for @gradientDirectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get gradientDirectionLabel;

  /// No description provided for @sliderSize.
  ///
  /// In en, this message translates to:
  /// **'SIZE'**
  String get sliderSize;

  /// No description provided for @sliderOpac.
  ///
  /// In en, this message translates to:
  /// **'OPAC'**
  String get sliderOpac;

  /// No description provided for @adjustHint.
  ///
  /// In en, this message translates to:
  /// **'1 finger = move, 2 fingers = scale'**
  String get adjustHint;

  /// No description provided for @recolorSelection.
  ///
  /// In en, this message translates to:
  /// **'Recolor selection to current color'**
  String get recolorSelection;

  /// No description provided for @finishAdjust.
  ///
  /// In en, this message translates to:
  /// **'Finish adjusting'**
  String get finishAdjust;

  /// No description provided for @vectorUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo vector'**
  String get vectorUndo;

  /// No description provided for @vectorRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo vector'**
  String get vectorRedo;

  /// No description provided for @deleteSelection.
  ///
  /// In en, this message translates to:
  /// **'Delete selection'**
  String get deleteSelection;

  /// No description provided for @transformCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel transform'**
  String get transformCancel;

  /// No description provided for @transformHint.
  ///
  /// In en, this message translates to:
  /// **'Transform (1 finger = move / 2 fingers = scale · rotate)'**
  String get transformHint;

  /// No description provided for @transformConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm transform'**
  String get transformConfirm;

  /// No description provided for @maskEditingBanner.
  ///
  /// In en, this message translates to:
  /// **'Editing mask (tap to finish)'**
  String get maskEditingBanner;

  /// No description provided for @toolBrush.
  ///
  /// In en, this message translates to:
  /// **'Brush'**
  String get toolBrush;

  /// No description provided for @toolSmudge.
  ///
  /// In en, this message translates to:
  /// **'Smudge'**
  String get toolSmudge;

  /// No description provided for @toolErase.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get toolErase;

  /// No description provided for @toolFill.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get toolFill;

  /// No description provided for @toolGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get toolGradient;

  /// No description provided for @toolShape.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get toolShape;

  /// No description provided for @toolText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get toolText;

  /// No description provided for @toolSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get toolSelect;

  /// No description provided for @toolEyedropper.
  ///
  /// In en, this message translates to:
  /// **'Eyedropper'**
  String get toolEyedropper;

  /// No description provided for @toolTransform.
  ///
  /// In en, this message translates to:
  /// **'Transform'**
  String get toolTransform;

  /// No description provided for @vectorOn.
  ///
  /// In en, this message translates to:
  /// **'Vector: ON'**
  String get vectorOn;

  /// No description provided for @vectorOff.
  ///
  /// In en, this message translates to:
  /// **'Vector: OFF'**
  String get vectorOff;

  /// No description provided for @layers.
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get layers;

  /// No description provided for @pickColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get pickColor;

  /// No description provided for @colorTitle.
  ///
  /// In en, this message translates to:
  /// **'Color  {hex}'**
  String colorTitle(String hex);

  /// No description provided for @studioPalette.
  ///
  /// In en, this message translates to:
  /// **'Studio Palette'**
  String get studioPalette;

  /// No description provided for @recentColors.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentColors;

  /// No description provided for @noRecentColors.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet'**
  String get noRecentColors;

  /// No description provided for @myPalette.
  ///
  /// In en, this message translates to:
  /// **'My palette'**
  String get myPalette;

  /// No description provided for @saveCurrentColor.
  ///
  /// In en, this message translates to:
  /// **'Save current color'**
  String get saveCurrentColor;

  /// No description provided for @myPaletteHint.
  ///
  /// In en, this message translates to:
  /// **'Save your own colors with \"Save current color\" (long-press to remove)'**
  String get myPaletteHint;

  /// No description provided for @symmetryLabel.
  ///
  /// In en, this message translates to:
  /// **'Symmetry'**
  String get symmetryLabel;

  /// No description provided for @stabilization.
  ///
  /// In en, this message translates to:
  /// **'Stabilization'**
  String get stabilization;

  /// No description provided for @brushFlow.
  ///
  /// In en, this message translates to:
  /// **'Flow'**
  String get brushFlow;

  /// No description provided for @brushScatter.
  ///
  /// In en, this message translates to:
  /// **'Scatter'**
  String get brushScatter;

  /// No description provided for @brushSpacing.
  ///
  /// In en, this message translates to:
  /// **'Spacing'**
  String get brushSpacing;

  /// No description provided for @layerAlphaLock.
  ///
  /// In en, this message translates to:
  /// **'Alpha lock'**
  String get layerAlphaLock;

  /// No description provided for @layerToggleVisible.
  ///
  /// In en, this message translates to:
  /// **'Toggle visibility'**
  String get layerToggleVisible;

  /// No description provided for @layerClip.
  ///
  /// In en, this message translates to:
  /// **'Clip to layer below'**
  String get layerClip;

  /// No description provided for @layerAddMask.
  ///
  /// In en, this message translates to:
  /// **'Add mask'**
  String get layerAddMask;

  /// No description provided for @layerMask.
  ///
  /// In en, this message translates to:
  /// **'Mask'**
  String get layerMask;

  /// No description provided for @layerMaskEditEnd.
  ///
  /// In en, this message translates to:
  /// **'Finish editing mask'**
  String get layerMaskEditEnd;

  /// No description provided for @layerMaskEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit mask'**
  String get layerMaskEdit;

  /// No description provided for @layerMaskRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove mask'**
  String get layerMaskRemove;

  /// No description provided for @layerMergeDown.
  ///
  /// In en, this message translates to:
  /// **'Merge down'**
  String get layerMergeDown;

  /// No description provided for @lastLayerCannotDelete.
  ///
  /// In en, this message translates to:
  /// **'Can\'t delete the last layer'**
  String get lastLayerCannotDelete;

  /// No description provided for @layerMoveForward.
  ///
  /// In en, this message translates to:
  /// **'Move forward'**
  String get layerMoveForward;

  /// No description provided for @layerMoveBackward.
  ///
  /// In en, this message translates to:
  /// **'Move backward'**
  String get layerMoveBackward;

  /// No description provided for @layerName.
  ///
  /// In en, this message translates to:
  /// **'Layer {n}'**
  String layerName(int n);

  /// No description provided for @shareMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message (optional)'**
  String get shareMessageLabel;

  /// No description provided for @shareMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Caption for social posts'**
  String get shareMessageHint;

  /// No description provided for @shareDefaultCaption.
  ///
  /// In en, this message translates to:
  /// **'Drawn with Rakuga #Rakuga'**
  String get shareDefaultCaption;

  /// No description provided for @timelapseDefaultCaption.
  ///
  /// In en, this message translates to:
  /// **'Timelapse with Rakuga #Rakuga'**
  String get timelapseDefaultCaption;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Export error: {error}'**
  String exportError(String error);

  /// No description provided for @timelapseSaved.
  ///
  /// In en, this message translates to:
  /// **'Timelapse saved'**
  String get timelapseSaved;

  /// No description provided for @timelapseEmpty.
  ///
  /// In en, this message translates to:
  /// **'No timelapse recorded'**
  String get timelapseEmpty;

  /// No description provided for @imageSaved.
  ///
  /// In en, this message translates to:
  /// **'Image saved'**
  String get imageSaved;

  /// No description provided for @imageGenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate the image'**
  String get imageGenerateFailed;

  /// No description provided for @photoImported.
  ///
  /// In en, this message translates to:
  /// **'Imported the photo as a layer'**
  String get photoImported;

  /// No description provided for @shared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get shared;

  /// No description provided for @hiddenLayerWarning.
  ///
  /// In en, this message translates to:
  /// **'Can\'t draw on a hidden layer'**
  String get hiddenLayerWarning;

  /// No description provided for @hexFormatError.
  ///
  /// In en, this message translates to:
  /// **'Enter in #RRGGBB format'**
  String get hexFormatError;

  /// No description provided for @colorCode.
  ///
  /// In en, this message translates to:
  /// **'Color code'**
  String get colorCode;

  /// No description provided for @saturationValue.
  ///
  /// In en, this message translates to:
  /// **'Saturation and value'**
  String get saturationValue;

  /// No description provided for @hue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get hue;

  /// No description provided for @textEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit text'**
  String get textEdit;

  /// No description provided for @textInputHint.
  ///
  /// In en, this message translates to:
  /// **'Enter text (tap to start)'**
  String get textInputHint;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get textSize;

  /// No description provided for @textBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get textBold;

  /// No description provided for @textUnderline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get textUnderline;

  /// No description provided for @textStrikethrough.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get textStrikethrough;

  /// No description provided for @textFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get textFont;

  /// No description provided for @textColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get textColor;

  /// No description provided for @textUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get textUpdate;

  /// No description provided for @shapeLine.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get shapeLine;

  /// No description provided for @shapeRectangle.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get shapeRectangle;

  /// No description provided for @shapeTriangle.
  ///
  /// In en, this message translates to:
  /// **'Triangle'**
  String get shapeTriangle;

  /// No description provided for @shapeEllipse.
  ///
  /// In en, this message translates to:
  /// **'Ellipse'**
  String get shapeEllipse;

  /// No description provided for @symNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get symNone;

  /// No description provided for @symVertical.
  ///
  /// In en, this message translates to:
  /// **'Mirror L/R'**
  String get symVertical;

  /// No description provided for @symHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Mirror T/B'**
  String get symHorizontal;

  /// No description provided for @symQuad.
  ///
  /// In en, this message translates to:
  /// **'Quad'**
  String get symQuad;

  /// No description provided for @selRectangle.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get selRectangle;

  /// No description provided for @selLasso.
  ///
  /// In en, this message translates to:
  /// **'Lasso'**
  String get selLasso;

  /// No description provided for @selMagicWand.
  ///
  /// In en, this message translates to:
  /// **'Magic wand'**
  String get selMagicWand;

  /// No description provided for @gradHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Horizontal'**
  String get gradHorizontal;

  /// No description provided for @gradVertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get gradVertical;

  /// No description provided for @gradDiagonalDown.
  ///
  /// In en, this message translates to:
  /// **'Diagonal ↘'**
  String get gradDiagonalDown;

  /// No description provided for @gradDiagonalUp.
  ///
  /// In en, this message translates to:
  /// **'Diagonal ↗'**
  String get gradDiagonalUp;

  /// No description provided for @gradRadial.
  ///
  /// In en, this message translates to:
  /// **'Radial'**
  String get gradRadial;

  /// No description provided for @blendNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get blendNormal;

  /// No description provided for @blendMultiply.
  ///
  /// In en, this message translates to:
  /// **'Multiply'**
  String get blendMultiply;

  /// No description provided for @blendScreen.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get blendScreen;

  /// No description provided for @blendOverlay.
  ///
  /// In en, this message translates to:
  /// **'Overlay'**
  String get blendOverlay;

  /// No description provided for @blendDarken.
  ///
  /// In en, this message translates to:
  /// **'Darken'**
  String get blendDarken;

  /// No description provided for @blendLighten.
  ///
  /// In en, this message translates to:
  /// **'Lighten'**
  String get blendLighten;

  /// No description provided for @blendColorDodge.
  ///
  /// In en, this message translates to:
  /// **'Color dodge'**
  String get blendColorDodge;

  /// No description provided for @blendColorBurn.
  ///
  /// In en, this message translates to:
  /// **'Color burn'**
  String get blendColorBurn;

  /// No description provided for @blendHardLight.
  ///
  /// In en, this message translates to:
  /// **'Hard light'**
  String get blendHardLight;

  /// No description provided for @blendSoftLight.
  ///
  /// In en, this message translates to:
  /// **'Soft light'**
  String get blendSoftLight;

  /// No description provided for @blendDifference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get blendDifference;

  /// No description provided for @blendExclusion.
  ///
  /// In en, this message translates to:
  /// **'Exclusion'**
  String get blendExclusion;

  /// No description provided for @blendAdd.
  ///
  /// In en, this message translates to:
  /// **'Add (glow)'**
  String get blendAdd;

  /// No description provided for @blendHue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get blendHue;

  /// No description provided for @blendSaturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get blendSaturation;

  /// No description provided for @blendColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get blendColor;

  /// No description provided for @blendLuminosity.
  ///
  /// In en, this message translates to:
  /// **'Luminosity'**
  String get blendLuminosity;

  /// No description provided for @brushNameInk.
  ///
  /// In en, this message translates to:
  /// **'Ink'**
  String get brushNameInk;

  /// No description provided for @brushDescInk.
  ///
  /// In en, this message translates to:
  /// **'Smooth and even; width varies with speed'**
  String get brushDescInk;

  /// No description provided for @brushNamePencil.
  ///
  /// In en, this message translates to:
  /// **'Pencil'**
  String get brushNamePencil;

  /// No description provided for @brushDescPencil.
  ///
  /// In en, this message translates to:
  /// **'Grainy pencil; darker as you layer'**
  String get brushDescPencil;

  /// No description provided for @brushNameMarker.
  ///
  /// In en, this message translates to:
  /// **'Marker'**
  String get brushNameMarker;

  /// No description provided for @brushDescMarker.
  ///
  /// In en, this message translates to:
  /// **'Flat and translucent; overlaps build color'**
  String get brushDescMarker;

  /// No description provided for @brushNameAir.
  ///
  /// In en, this message translates to:
  /// **'Airbrush'**
  String get brushNameAir;

  /// No description provided for @brushDescAir.
  ///
  /// In en, this message translates to:
  /// **'Soft, misty buildup'**
  String get brushDescAir;

  /// No description provided for @brushNameFude.
  ///
  /// In en, this message translates to:
  /// **'Brush pen'**
  String get brushNameFude;

  /// No description provided for @brushDescFude.
  ///
  /// In en, this message translates to:
  /// **'Tapered strokes; speed adds emphasis'**
  String get brushDescFude;

  /// No description provided for @brushNameCrayon.
  ///
  /// In en, this message translates to:
  /// **'Crayon'**
  String get brushNameCrayon;

  /// No description provided for @brushDescCrayon.
  ///
  /// In en, this message translates to:
  /// **'Coarse grain; rough texture'**
  String get brushDescCrayon;

  /// No description provided for @brushNameChalk.
  ///
  /// In en, this message translates to:
  /// **'Chalk'**
  String get brushNameChalk;

  /// No description provided for @brushDescChalk.
  ///
  /// In en, this message translates to:
  /// **'Soft and powdery; layers lightly'**
  String get brushDescChalk;

  /// No description provided for @brushNameStipple.
  ///
  /// In en, this message translates to:
  /// **'Stipple'**
  String get brushNameStipple;

  /// No description provided for @brushDescStipple.
  ///
  /// In en, this message translates to:
  /// **'Sparse dots; good for stippling and texture'**
  String get brushDescStipple;

  /// No description provided for @brushNameSoftPen.
  ///
  /// In en, this message translates to:
  /// **'Soft pen'**
  String get brushNameSoftPen;

  /// No description provided for @brushDescSoftPen.
  ///
  /// In en, this message translates to:
  /// **'Soft edges; lays down smoothly'**
  String get brushDescSoftPen;

  /// No description provided for @brushNameGlow.
  ///
  /// In en, this message translates to:
  /// **'Glow'**
  String get brushNameGlow;

  /// No description provided for @brushDescGlow.
  ///
  /// In en, this message translates to:
  /// **'Soft glowing light; brightens as you layer'**
  String get brushDescGlow;

  /// No description provided for @brushNameSponge.
  ///
  /// In en, this message translates to:
  /// **'Sponge'**
  String get brushNameSponge;

  /// No description provided for @brushDescSponge.
  ///
  /// In en, this message translates to:
  /// **'Large scattered grain; rough fill'**
  String get brushDescSponge;

  /// No description provided for @brushNameDry.
  ///
  /// In en, this message translates to:
  /// **'Dry'**
  String get brushNameDry;

  /// No description provided for @brushDescDry.
  ///
  /// In en, this message translates to:
  /// **'Dry, broken strokes; coarse texture'**
  String get brushDescDry;

  /// No description provided for @brushNameMaru.
  ///
  /// In en, this message translates to:
  /// **'Maru pen'**
  String get brushNameMaru;

  /// No description provided for @brushDescMaru.
  ///
  /// In en, this message translates to:
  /// **'Thin, even nib; stable line width'**
  String get brushDescMaru;

  /// No description provided for @brushNameBallpen.
  ///
  /// In en, this message translates to:
  /// **'Ballpoint'**
  String get brushNameBallpen;

  /// No description provided for @brushDescBallpen.
  ///
  /// In en, this message translates to:
  /// **'Slightly faint, even line; good for writing'**
  String get brushDescBallpen;

  /// No description provided for @brushNameGpen.
  ///
  /// In en, this message translates to:
  /// **'G-pen'**
  String get brushNameGpen;

  /// No description provided for @brushDescGpen.
  ///
  /// In en, this message translates to:
  /// **'Expressive manga pen; sharp speed-based variation'**
  String get brushDescGpen;

  /// No description provided for @brushNameWatercolor.
  ///
  /// In en, this message translates to:
  /// **'Watercolor'**
  String get brushNameWatercolor;

  /// No description provided for @brushDescWatercolor.
  ///
  /// In en, this message translates to:
  /// **'Bleeding, pale wash; deepens as you layer'**
  String get brushDescWatercolor;

  /// No description provided for @brushNameOil.
  ///
  /// In en, this message translates to:
  /// **'Oil'**
  String get brushNameOil;

  /// No description provided for @brushDescOil.
  ///
  /// In en, this message translates to:
  /// **'Thick, flat paint; overlaps build texture'**
  String get brushDescOil;

  /// No description provided for @brushNameBristle.
  ///
  /// In en, this message translates to:
  /// **'Bristle'**
  String get brushNameBristle;

  /// No description provided for @brushDescBristle.
  ///
  /// In en, this message translates to:
  /// **'Splitting bristles; streaky fill'**
  String get brushDescBristle;

  /// No description provided for @fontDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get fontDefault;

  /// No description provided for @fontGothic.
  ///
  /// In en, this message translates to:
  /// **'Gothic'**
  String get fontGothic;

  /// No description provided for @fontMincho.
  ///
  /// In en, this message translates to:
  /// **'Mincho'**
  String get fontMincho;

  /// No description provided for @fontRoundGothic.
  ///
  /// In en, this message translates to:
  /// **'Round Gothic'**
  String get fontRoundGothic;

  /// No description provided for @fontKosugiMaru.
  ///
  /// In en, this message translates to:
  /// **'Kosugi Maru'**
  String get fontKosugiMaru;

  /// No description provided for @fontZenMaru.
  ///
  /// In en, this message translates to:
  /// **'Zen Maru'**
  String get fontZenMaru;

  /// No description provided for @fontSawarabiMincho.
  ///
  /// In en, this message translates to:
  /// **'Sawarabi Mincho'**
  String get fontSawarabiMincho;

  /// No description provided for @fontShipporiMincho.
  ///
  /// In en, this message translates to:
  /// **'Shippori Mincho'**
  String get fontShipporiMincho;

  /// No description provided for @fontZenKaku.
  ///
  /// In en, this message translates to:
  /// **'Zen Kaku'**
  String get fontZenKaku;

  /// No description provided for @fontYuseiMagic.
  ///
  /// In en, this message translates to:
  /// **'Yusei Magic'**
  String get fontYuseiMagic;

  /// No description provided for @fontDelaGothic.
  ///
  /// In en, this message translates to:
  /// **'Dela Gothic'**
  String get fontDelaGothic;

  /// No description provided for @fontKaiseiDecol.
  ///
  /// In en, this message translates to:
  /// **'Kaisei Decol'**
  String get fontKaiseiDecol;

  /// No description provided for @fontRocknRoll.
  ///
  /// In en, this message translates to:
  /// **'RocknRoll'**
  String get fontRocknRoll;

  /// No description provided for @fontHachiMaru.
  ///
  /// In en, this message translates to:
  /// **'Hachi Maru Pop'**
  String get fontHachiMaru;

  /// No description provided for @fontReggae.
  ///
  /// In en, this message translates to:
  /// **'Reggae'**
  String get fontReggae;

  /// No description provided for @fontStick.
  ///
  /// In en, this message translates to:
  /// **'Stick'**
  String get fontStick;

  /// No description provided for @fontPotta.
  ///
  /// In en, this message translates to:
  /// **'Potta One'**
  String get fontPotta;

  /// No description provided for @fontDot.
  ///
  /// In en, this message translates to:
  /// **'Dot'**
  String get fontDot;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
