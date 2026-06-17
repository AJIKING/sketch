// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTagline => '描くを、もっと気軽に。';

  @override
  String gallerySketchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count点のスケッチ',
    );
    return '$_temp0';
  }

  @override
  String get galleryNewCanvas => '新規キャンバス';

  @override
  String get galleryNewSketchSemantic => '新しいスケッチを始める';

  @override
  String get untitledSketch => 'あなたのスケッチ';

  @override
  String copyOf(String title) {
    return '$title のコピー';
  }

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonAdd => '追加';

  @override
  String get commonDelete => '削除';

  @override
  String get commonChange => '変更';

  @override
  String get commonShare => '共有';

  @override
  String get commonApply => '適用';

  @override
  String get actionRename => '名前を変更';

  @override
  String get renamed => '名前を変更しました';

  @override
  String get actionDuplicate => '複製';

  @override
  String get duplicated => '複製しました';

  @override
  String get duplicateFailed => '複製できませんでした';

  @override
  String get deleteSketchTitle => 'スケッチを削除しますか?';

  @override
  String get deleteSketchBody => 'この操作は取り消せません。';

  @override
  String get renameHint => 'スケッチの名前';

  @override
  String get languageTitle => '言語';

  @override
  String get languageSystem => 'システム既定';

  @override
  String get canvasSizeTitle => 'キャンバスサイズ';

  @override
  String get sizeScreen => '画面サイズ';

  @override
  String get sizeSquare1080 => '正方形 1080×1080';

  @override
  String get sizeSquare2048 => '正方形 2048×2048';

  @override
  String get sizePortrait => '縦 1080×1920';

  @override
  String get sizeLandscape => '横 1920×1080';

  @override
  String get tooltipBackToGallery => 'ギャラリーへ戻る';

  @override
  String get tooltipUndo => '取り消す';

  @override
  String get tooltipRedo => 'やり直す';

  @override
  String get tooltipResetView => '表示をリセット';

  @override
  String get tooltipMenu => 'メニュー';

  @override
  String get filterInvert => '反転';

  @override
  String get filterGrayscale => 'グレースケール';

  @override
  String get filterBlur => 'ぼかし';

  @override
  String get filterMosaic => 'モザイク';

  @override
  String get filterBrighten => '明るく';

  @override
  String get filterDarken => '暗く';

  @override
  String get filterContrast => 'コントラスト+';

  @override
  String get menuExport => '画像として保存';

  @override
  String get menuImportPhoto => '写真を読み込む';

  @override
  String get menuShare => '共有(SNS など)';

  @override
  String get menuTimelapse => 'タイムラプス記録';

  @override
  String timelapseRecording(int count) {
    return '記録中($countコマ)';
  }

  @override
  String get timelapseOnHint => 'ONで描画過程を記録';

  @override
  String get menuExportTimelapse => 'タイムラプスを書き出す(GIF)';

  @override
  String get menuFilter => 'フィルタ';

  @override
  String get menuFinish => '完了してギャラリーへ';

  @override
  String get menuClearLayer => 'このレイヤーを消去';

  @override
  String get selectAll => '全選択';

  @override
  String get selectInvert => '選択を反転';

  @override
  String get selectFill => '選択内を塗る';

  @override
  String get selectClear => '選択範囲を消去';

  @override
  String get selectDeselect => '選択を解除';

  @override
  String get shapeFillToggle => '塗りつぶし(枠線 ↔ 塗り)';

  @override
  String get shapeSnapToggle => 'スナップ(直線45° / 正方形・正円)';

  @override
  String get gradientStartColor => '始点の色(カラーコード)';

  @override
  String get gradientTwoColor => '2色グラデーション';

  @override
  String get gradientTransparentEnd => '終点を透明にする';

  @override
  String gradientSecondColor(String hex) {
    return '2色目 $hex';
  }

  @override
  String get gradientDirectionLabel => '方向';

  @override
  String get sliderSize => 'SIZE';

  @override
  String get sliderOpac => 'OPAC';

  @override
  String get adjustHint => '1本指=移動 2本指=拡縮';

  @override
  String get recolorSelection => '選択を現在色にする';

  @override
  String get finishAdjust => '調整を完了';

  @override
  String get vectorUndo => 'ベクターを取り消す';

  @override
  String get vectorRedo => 'ベクターをやり直す';

  @override
  String get deleteSelection => '選択を削除';

  @override
  String get transformCancel => '変形を取消';

  @override
  String get transformHint => '変形(1本指=移動 / 2本指=拡縮・回転)';

  @override
  String get transformConfirm => '変形を確定';

  @override
  String get maskEditingBanner => 'マスク編集中(タップで終了)';

  @override
  String get toolBrush => 'ブラシ';

  @override
  String get toolSmudge => 'スマッジ';

  @override
  String get toolErase => '消しゴム';

  @override
  String get toolFill => '塗りつぶし';

  @override
  String get toolGradient => 'グラデーション';

  @override
  String get toolShape => '図形';

  @override
  String get toolText => 'テキスト';

  @override
  String get toolSelect => '選択';

  @override
  String get toolEyedropper => 'スポイト';

  @override
  String get toolTransform => '変形';

  @override
  String get vectorOn => 'ベクター: ON';

  @override
  String get vectorOff => 'ベクター: OFF';

  @override
  String get layers => 'レイヤー';

  @override
  String get pickColor => 'カラーを選択';

  @override
  String colorTitle(String hex) {
    return 'カラー  $hex';
  }

  @override
  String get studioPalette => 'Studio Palette';

  @override
  String get recentColors => 'Recent';

  @override
  String get noRecentColors => 'まだありません';

  @override
  String get myPalette => 'マイパレット';

  @override
  String get saveCurrentColor => '現在色を保存';

  @override
  String get myPaletteHint => '「現在色を保存」で自分の色を貯められます(長押しで削除)';

  @override
  String get symmetryLabel => '対称(シンメトリー)';

  @override
  String get stabilization => '手ブレ補正';

  @override
  String get brushFlow => '濃さ';

  @override
  String get brushScatter => '散り';

  @override
  String get brushSpacing => '間隔';

  @override
  String get layerAlphaLock => 'アルファロック';

  @override
  String get layerToggleVisible => '表示切替';

  @override
  String get layerClip => '下のレイヤーでクリッピング';

  @override
  String get layerAddMask => 'マスクを追加';

  @override
  String get layerMask => 'マスク';

  @override
  String get layerMaskEditEnd => 'マスク編集を終了';

  @override
  String get layerMaskEdit => 'マスクを編集';

  @override
  String get layerMaskRemove => 'マスクを解除';

  @override
  String get layerMergeDown => '下のレイヤーと結合';

  @override
  String get lastLayerCannotDelete => '最後のレイヤーは消せません';

  @override
  String get layerMoveForward => '前面へ';

  @override
  String get layerMoveBackward => '背面へ';

  @override
  String layerName(int n) {
    return 'レイヤー $n';
  }

  @override
  String get shareMessageLabel => 'メッセージ(任意)';

  @override
  String get shareMessageHint => 'SNS に添える文章';

  @override
  String get shareDefaultCaption => 'Rakuga で描きました #Rakuga';

  @override
  String get timelapseDefaultCaption => 'Rakuga でタイムラプス #Rakuga';

  @override
  String exportError(String error) {
    return '書き出しエラー: $error';
  }

  @override
  String get timelapseSaved => 'タイムラプスを保存しました';

  @override
  String get timelapseEmpty => 'タイムラプスの記録がありません';

  @override
  String get imageSaved => '画像を保存しました';

  @override
  String get imageGenerateFailed => '画像を生成できませんでした';

  @override
  String get photoImported => '写真をレイヤーとして読み込みました';

  @override
  String get shared => '共有しました';

  @override
  String get hiddenLayerWarning => '非表示のレイヤーには描けません';

  @override
  String get hexFormatError => '#RRGGBB の形式で入力してください';

  @override
  String get colorCode => 'カラーコード';

  @override
  String get saturationValue => '彩度と明度';

  @override
  String get hue => '色相';

  @override
  String get textEdit => 'テキストを編集';

  @override
  String get textInputHint => '文字を入力(タップで開始)';

  @override
  String get textSize => 'サイズ';

  @override
  String get textBold => '太字';

  @override
  String get textUnderline => '下線';

  @override
  String get textStrikethrough => '取り消し線';

  @override
  String get textFont => 'フォント';

  @override
  String get textColor => '色';

  @override
  String get textUpdate => '更新';

  @override
  String get shapeLine => '直線';

  @override
  String get shapeRectangle => '四角';

  @override
  String get shapeTriangle => '三角';

  @override
  String get shapeEllipse => '楕円';

  @override
  String get symNone => 'なし';

  @override
  String get symVertical => '左右';

  @override
  String get symHorizontal => '上下';

  @override
  String get symQuad => '4分割';

  @override
  String get selRectangle => '矩形';

  @override
  String get selLasso => 'なげなわ';

  @override
  String get selMagicWand => '自動選択';

  @override
  String get gradHorizontal => '横';

  @override
  String get gradVertical => '縦';

  @override
  String get gradDiagonalDown => '斜め ↘';

  @override
  String get gradDiagonalUp => '斜め ↗';

  @override
  String get gradRadial => '放射';

  @override
  String get blendNormal => '通常';

  @override
  String get blendMultiply => '乗算';

  @override
  String get blendScreen => 'スクリーン';

  @override
  String get blendOverlay => 'オーバーレイ';

  @override
  String get blendDarken => '比較(暗)';

  @override
  String get blendLighten => '比較(明)';

  @override
  String get blendColorDodge => '覆い焼き';

  @override
  String get blendColorBurn => '焼き込み';

  @override
  String get blendHardLight => 'ハードライト';

  @override
  String get blendSoftLight => 'ソフトライト';

  @override
  String get blendDifference => '差の絶対値';

  @override
  String get blendExclusion => '除外';

  @override
  String get blendAdd => '加算発光';

  @override
  String get blendHue => '色相';

  @override
  String get blendSaturation => '彩度';

  @override
  String get blendColor => 'カラー';

  @override
  String get blendLuminosity => '輝度';

  @override
  String get brushNameInk => 'インク';

  @override
  String get brushDescInk => 'なめらかで均一。速度で太さが変化';

  @override
  String get brushNamePencil => 'ペンシル';

  @override
  String get brushDescPencil => 'ざらりとした鉛筆。重ねるほど濃く';

  @override
  String get brushNameMarker => 'マーカー';

  @override
  String get brushDescMarker => '平らで半透明。重なりが色を作る';

  @override
  String get brushNameAir => 'エアブラシ';

  @override
  String get brushDescAir => 'やわらかく霧状に積もる';

  @override
  String get brushNameFude => '筆';

  @override
  String get brushDescFude => '入り抜きのある線。速度で強弱がつく';

  @override
  String get brushNameCrayon => 'クレヨン';

  @override
  String get brushDescCrayon => '粗い粒で塗り込む。ざらついた質感';

  @override
  String get brushNameChalk => 'チョーク';

  @override
  String get brushDescChalk => 'やわらかく粉っぽい。淡く重なる';

  @override
  String get brushNameStipple => '点描';

  @override
  String get brushDescStipple => 'まばらな点を打つ。点描・テクスチャ向き';

  @override
  String get brushNameSoftPen => 'ソフトペン';

  @override
  String get brushDescSoftPen => 'やわらかい縁。さらりと均一に乗る';

  @override
  String get brushNameGlow => 'グロー';

  @override
  String get brushDescGlow => 'ふんわり淡く積もる光。重ねて明るく';

  @override
  String get brushNameSponge => 'スポンジ';

  @override
  String get brushDescSponge => '大きく散る粒。ざらついた塗り';

  @override
  String get brushNameDry => 'ドライ';

  @override
  String get brushDescDry => 'かすれた擦れ。粗い質感の線';

  @override
  String get brushNameMaru => '丸ペン';

  @override
  String get brushDescMaru => '細く均一なペン先。線幅が変わらず安定';

  @override
  String get brushNameBallpen => 'ボールペン';

  @override
  String get brushDescBallpen => 'わずかに掠れる均一な線。筆記向き';

  @override
  String get brushNameGpen => 'Gペン';

  @override
  String get brushDescGpen => '入り抜きの効いた漫画ペン。速度で鋭く強弱';

  @override
  String get brushNameWatercolor => '水彩';

  @override
  String get brushDescWatercolor => 'にじむ淡い塗り。重ねるほど深く沈む';

  @override
  String get brushNameOil => '油彩';

  @override
  String get brushDescOil => '厚く平らに置く絵具。重なりが質感を作る';

  @override
  String get brushNameBristle => 'ブリストル';

  @override
  String get brushDescBristle => '剛毛が割れる筆。筋の残る塗り';

  @override
  String get fontDefault => '標準';

  @override
  String get fontGothic => 'ゴシック';

  @override
  String get fontMincho => '明朝';

  @override
  String get fontRoundGothic => '丸ゴシック';

  @override
  String get fontKosugiMaru => '小杉丸ゴ';

  @override
  String get fontZenMaru => 'Zen 丸ゴ';

  @override
  String get fontSawarabiMincho => 'さわらび明朝';

  @override
  String get fontShipporiMincho => 'しっぽり明朝';

  @override
  String get fontZenKaku => 'Zen 角ゴ';

  @override
  String get fontYuseiMagic => '油性マジック';

  @override
  String get fontDelaGothic => 'Dela ゴ太';

  @override
  String get fontKaiseiDecol => '解星デコール';

  @override
  String get fontRocknRoll => 'ロックロール';

  @override
  String get fontHachiMaru => 'はちまるポップ';

  @override
  String get fontReggae => 'レゲエ';

  @override
  String get fontStick => 'ステッキ';

  @override
  String get fontPotta => 'ポッタワン';

  @override
  String get fontDot => 'ドット';
}
