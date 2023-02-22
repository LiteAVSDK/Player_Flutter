// Copyright (c) 2022 Tencent. All rights reserved.

import 'package:flutter/material.dart';
import 'package:super_player/super_player.dart';
import 'package:super_player_example/res/app_localizations.dart';

/// 文本国际化代理
class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalizations> {

  static AppLocalizationDelegate delegate = AppLocalizationDelegate();

  /// 设置语言支持
  @override
  bool isSupported(Locale locale) {
    return ["zh", "en"].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final appLocalizations = AppLocalizations(locale);
    await appLocalizations.loadJson();
    return appLocalizations;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }

}