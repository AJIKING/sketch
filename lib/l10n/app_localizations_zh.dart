// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTagline => '画画，更随心。';

  @override
  String gallerySketchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 幅画作',
    );
    return '$_temp0';
  }

  @override
  String get galleryNewCanvas => '新建画布';

  @override
  String get galleryNewSketchSemantic => '开始新的涂鸦';

  @override
  String get untitledSketch => '你的涂鸦';

  @override
  String copyOf(String title) {
    return '$title 的副本';
  }

  @override
  String get commonCancel => '取消';

  @override
  String get commonAdd => '添加';

  @override
  String get commonDelete => '删除';

  @override
  String get commonChange => '修改';

  @override
  String get commonShare => '分享';

  @override
  String get commonApply => '应用';

  @override
  String get actionRename => '重命名';

  @override
  String get renamed => '已重命名';

  @override
  String get actionDuplicate => '复制';

  @override
  String get duplicated => '已复制';

  @override
  String get duplicateFailed => '无法复制';

  @override
  String get deleteSketchTitle => '要删除这幅画作吗?';

  @override
  String get deleteSketchBody => '此操作无法撤销。';

  @override
  String get renameHint => '画作名称';

  @override
  String get languageTitle => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get canvasSizeTitle => '画布尺寸';

  @override
  String get sizeScreen => '屏幕尺寸';

  @override
  String get sizeSquare1080 => '正方形 1080×1080';

  @override
  String get sizeSquare2048 => '正方形 2048×2048';

  @override
  String get sizePortrait => '竖向 1080×1920';

  @override
  String get sizeLandscape => '横向 1920×1080';

  @override
  String get tooltipBackToGallery => '返回作品库';

  @override
  String get tooltipUndo => '撤销';

  @override
  String get tooltipRedo => '重做';

  @override
  String get tooltipResetView => '重置视图';

  @override
  String get tooltipMenu => '菜单';

  @override
  String get filterInvert => '反相';

  @override
  String get filterGrayscale => '灰度';

  @override
  String get filterBlur => '模糊';

  @override
  String get filterMosaic => '马赛克';

  @override
  String get filterBrighten => '调亮';

  @override
  String get filterDarken => '调暗';

  @override
  String get filterContrast => '对比度+';

  @override
  String get menuExport => '保存为图片';

  @override
  String get menuImportPhoto => '导入照片';

  @override
  String get menuShare => '分享(社交平台等)';

  @override
  String get menuTimelapse => '延时录制';

  @override
  String timelapseRecording(int count) {
    return '录制中($count 帧)';
  }

  @override
  String get timelapseOnHint => '开启后记录绘制过程';

  @override
  String get menuExportTimelapse => '导出延时动画(GIF)';

  @override
  String get menuFilter => '滤镜';

  @override
  String get menuFinish => '完成并返回作品库';

  @override
  String get menuClearLayer => '清除该图层';

  @override
  String get selectAll => '全选';

  @override
  String get selectInvert => '反选';

  @override
  String get selectFill => '填充选区';

  @override
  String get selectClear => '清除选区';

  @override
  String get selectDeselect => '取消选择';

  @override
  String get shapeFillToggle => '填充(描边 ↔ 填充)';

  @override
  String get shapeSnapToggle => '吸附(直线45° / 正方形·正圆)';

  @override
  String get gradientStartColor => '起点颜色(色值)';

  @override
  String get gradientTwoColor => '双色渐变';

  @override
  String get gradientTransparentEnd => '终点设为透明';

  @override
  String gradientSecondColor(String hex) {
    return '第二色 $hex';
  }

  @override
  String get gradientDirectionLabel => '方向';

  @override
  String get sliderSize => '尺寸';

  @override
  String get sliderOpac => '不透明';

  @override
  String get adjustHint => '单指=移动 双指=缩放';

  @override
  String get recolorSelection => '将选区改为当前颜色';

  @override
  String get finishAdjust => '完成调整';

  @override
  String get vectorUndo => '撤销矢量';

  @override
  String get vectorRedo => '重做矢量';

  @override
  String get deleteSelection => '删除选区';

  @override
  String get transformCancel => '取消变形';

  @override
  String get transformHint => '变形(单指=移动 / 双指=缩放·旋转)';

  @override
  String get transformConfirm => '确定变形';

  @override
  String get maskEditingBanner => '正在编辑蒙版(点按结束)';

  @override
  String get toolBrush => '画笔';

  @override
  String get toolSmudge => '涂抹';

  @override
  String get toolErase => '橡皮擦';

  @override
  String get toolFill => '填充';

  @override
  String get toolGradient => '渐变';

  @override
  String get toolShape => '形状';

  @override
  String get toolText => '文字';

  @override
  String get toolSelect => '选择';

  @override
  String get toolEyedropper => '吸管';

  @override
  String get toolTransform => '变形';

  @override
  String get vectorOn => '矢量:开';

  @override
  String get vectorOff => '矢量:关';

  @override
  String get layers => '图层';

  @override
  String get pickColor => '选择颜色';

  @override
  String colorTitle(String hex) {
    return '颜色  $hex';
  }

  @override
  String get studioPalette => '工作室色板';

  @override
  String get recentColors => '最近使用';

  @override
  String get noRecentColors => '暂无';

  @override
  String get myPalette => '我的色板';

  @override
  String get saveCurrentColor => '保存当前颜色';

  @override
  String get myPaletteHint => '用「保存当前颜色」收藏自己的颜色(长按删除)';

  @override
  String get symmetryLabel => '对称';

  @override
  String get stabilization => '防抖';

  @override
  String get brushFlow => '浓度';

  @override
  String get brushScatter => '散布';

  @override
  String get brushSpacing => '间距';

  @override
  String get layerAlphaLock => '透明度锁定';

  @override
  String get layerToggleVisible => '切换显示';

  @override
  String get layerClip => '裁剪到下层';

  @override
  String get layerAddMask => '添加蒙版';

  @override
  String get layerMask => '蒙版';

  @override
  String get layerMaskEditEnd => '结束编辑蒙版';

  @override
  String get layerMaskEdit => '编辑蒙版';

  @override
  String get layerMaskRemove => '移除蒙版';

  @override
  String get layerMergeDown => '向下合并';

  @override
  String get lastLayerCannotDelete => '无法删除最后一个图层';

  @override
  String get layerMoveForward => '上移一层';

  @override
  String get layerMoveBackward => '下移一层';

  @override
  String layerName(int n) {
    return '图层 $n';
  }

  @override
  String get shareMessageLabel => '留言(可选)';

  @override
  String get shareMessageHint => '发布到社交平台的文字';

  @override
  String get shareDefaultCaption => '用 Rakuga 绘制 #Rakuga';

  @override
  String get timelapseDefaultCaption => 'Rakuga 延时绘制 #Rakuga';

  @override
  String exportError(String error) {
    return '导出错误:$error';
  }

  @override
  String get timelapseSaved => '已保存延时动画';

  @override
  String get timelapseEmpty => '没有延时录制';

  @override
  String get imageSaved => '已保存图片';

  @override
  String get imageGenerateFailed => '无法生成图片';

  @override
  String get photoImported => '已将照片作为图层导入';

  @override
  String get shared => '已分享';

  @override
  String get hiddenLayerWarning => '无法在隐藏的图层上绘制';

  @override
  String get hexFormatError => '请按 #RRGGBB 格式输入';

  @override
  String get colorCode => '色值';

  @override
  String get saturationValue => '饱和度与明度';

  @override
  String get hue => '色相';

  @override
  String get textEdit => '编辑文字';

  @override
  String get textInputHint => '输入文字(点按开始)';

  @override
  String get textSize => '字号';

  @override
  String get textBold => '加粗';

  @override
  String get textUnderline => '下划线';

  @override
  String get textStrikethrough => '删除线';

  @override
  String get textFont => '字体';

  @override
  String get textColor => '颜色';

  @override
  String get textUpdate => '更新';

  @override
  String get shapeLine => '直线';

  @override
  String get shapeRectangle => '矩形';

  @override
  String get shapeTriangle => '三角形';

  @override
  String get shapeEllipse => '椭圆';

  @override
  String get symNone => '无';

  @override
  String get symVertical => '左右';

  @override
  String get symHorizontal => '上下';

  @override
  String get symQuad => '四分镜像';

  @override
  String get selRectangle => '矩形';

  @override
  String get selLasso => '套索';

  @override
  String get selMagicWand => '魔棒';

  @override
  String get gradHorizontal => '水平';

  @override
  String get gradVertical => '垂直';

  @override
  String get gradDiagonalDown => '斜向 ↘';

  @override
  String get gradDiagonalUp => '斜向 ↗';

  @override
  String get gradRadial => '径向';

  @override
  String get blendNormal => '正常';

  @override
  String get blendMultiply => '正片叠底';

  @override
  String get blendScreen => '滤色';

  @override
  String get blendOverlay => '叠加';

  @override
  String get blendDarken => '变暗';

  @override
  String get blendLighten => '变亮';

  @override
  String get blendColorDodge => '颜色减淡';

  @override
  String get blendColorBurn => '颜色加深';

  @override
  String get blendHardLight => '强光';

  @override
  String get blendSoftLight => '柔光';

  @override
  String get blendDifference => '差值';

  @override
  String get blendExclusion => '排除';

  @override
  String get blendAdd => '添加(发光)';

  @override
  String get blendHue => '色相';

  @override
  String get blendSaturation => '饱和度';

  @override
  String get blendColor => '颜色';

  @override
  String get blendLuminosity => '明度';

  @override
  String get brushNameInk => '墨水';

  @override
  String get brushDescInk => '顺滑均匀,粗细随速度变化';

  @override
  String get brushNamePencil => '铅笔';

  @override
  String get brushDescPencil => '颗粒感铅笔,叠加越多越深';

  @override
  String get brushNameMarker => '马克笔';

  @override
  String get brushDescMarker => '扁平半透明,叠加形成色彩';

  @override
  String get brushNameAir => '喷枪';

  @override
  String get brushDescAir => '柔和雾状堆积';

  @override
  String get brushNameFude => '毛笔';

  @override
  String get brushDescFude => '有起收笔锋,速度带来强弱';

  @override
  String get brushNameCrayon => '蜡笔';

  @override
  String get brushDescCrayon => '粗颗粒涂抹,质感粗糙';

  @override
  String get brushNameChalk => '粉笔';

  @override
  String get brushDescChalk => '柔和带粉感,淡淡叠加';

  @override
  String get brushNameStipple => '点画';

  @override
  String get brushDescStipple => '打散落的点,适合点画与纹理';

  @override
  String get brushNameSoftPen => '软头笔';

  @override
  String get brushDescSoftPen => '柔和边缘,均匀流畅';

  @override
  String get brushNameGlow => '辉光';

  @override
  String get brushDescGlow => '轻柔堆积的光,叠加变亮';

  @override
  String get brushNameSponge => '海绵';

  @override
  String get brushDescSponge => '大颗粒散布,粗糙涂抹';

  @override
  String get brushNameDry => '枯笔';

  @override
  String get brushDescDry => '干涩飞白,质感粗犷';

  @override
  String get brushNameMaru => '圆头笔';

  @override
  String get brushDescMaru => '细而均匀的笔尖,线宽稳定';

  @override
  String get brushNameBallpen => '圆珠笔';

  @override
  String get brushDescBallpen => '略带飞白的均匀线条,适合书写';

  @override
  String get brushNameGpen => 'G笔';

  @override
  String get brushDescGpen => '起收明显的漫画笔,速度带来锐利强弱';

  @override
  String get brushNameWatercolor => '水彩';

  @override
  String get brushDescWatercolor => '晕染的淡彩,叠加越多越沉';

  @override
  String get brushNameOil => '油画';

  @override
  String get brushDescOil => '厚重平涂的颜料,叠加形成质感';

  @override
  String get brushNameBristle => '硬毛笔';

  @override
  String get brushDescBristle => '硬毛分叉的笔触,留下纹理';

  @override
  String get fontDefault => '标准';

  @override
  String get fontGothic => '黑体';

  @override
  String get fontMincho => '明朝体';

  @override
  String get fontRoundGothic => '圆体';

  @override
  String get fontKosugiMaru => '小杉圆体';

  @override
  String get fontZenMaru => 'Zen 圆体';

  @override
  String get fontSawarabiMincho => '蕨明朝';

  @override
  String get fontShipporiMincho => 'Shippori 明朝';

  @override
  String get fontZenKaku => 'Zen 角黑';

  @override
  String get fontYuseiMagic => '油性马克';

  @override
  String get fontDelaGothic => 'Dela 粗黑';

  @override
  String get fontKaiseiDecol => '解星装饰';

  @override
  String get fontRocknRoll => '摇滚体';

  @override
  String get fontHachiMaru => '八丸 Pop';

  @override
  String get fontReggae => '雷鬼体';

  @override
  String get fontStick => '棒体';

  @override
  String get fontPotta => 'Potta One';

  @override
  String get fontDot => '点阵';
}
