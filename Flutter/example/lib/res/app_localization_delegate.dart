// Copyright (c) 2022 Tencent. All rights reserved.

import 'package:flutter/material.dart';
import 'package:super_player_example/res/app_localizations.dart';

/// Text internationalization delegate
///
/// 文本国际化代理
class AppLocalizationDelegate extends LocalizationsDelegate<AppLocals> {

  static AppLocalizationDelegate delegate = AppLocalizationDelegate();

  /// Set language support.
  /// 设置语言支持
  @override
  bool isSupported(Locale locale) {
    return ["zh", "en"].contains(locale.languageCode);
  }

  @override
  Future<AppLocals> load(Locale locale) async {
    return await AppLocals.loadJson(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocals> old) {
    return false;
  }

}