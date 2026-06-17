import 'package:flutter/material.dart';
import 'package:sketch/l10n/app_localizations.dart';

/// widget テスト用に [AppLocalizations] を効かせる `MaterialApp` ラッパ。
///
/// 既定ロケールは日本語(既存テストの日本語アサートを保つため)。多言語の検証は
/// [locale] を切り替えて行う(`test/widget/localization_test.dart`)。
MaterialApp localizedApp(Widget home, {Locale locale = const Locale('ja')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}
