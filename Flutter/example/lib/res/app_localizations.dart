// Copyright (c) 2022 Tencent. All rights reserved.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 文本资源国际化加载
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of(context, AppLocalizations);
  }

  static Map<String, Map<String, String>> _localizedStrings = {};

  Future<void> loadJson() async {
    final jsonString = await rootBundle.loadString("assets/json/i18n.json");
    Map<String, dynamic> map = json.decode(jsonString);
    _localizedStrings = map.map((key, value) => MapEntry(key, value.cast<String, String>()));
  }

  String get playerCacheProgressLabel => _localizedStrings[this.locale.languageCode]!["player_cache_progress_label"]!;

  String get playerDownloadList => _localizedStrings[this.locale.languageCode]!["player_download_list"]!;

  String get playerTip => _localizedStrings[this.locale.languageCode]!["player_tip"]!;

  String get playerDeleteFailed => _localizedStrings[this.locale.languageCode]!["player_delete_failed"]!;

  String get playerCaching => _localizedStrings[this.locale.languageCode]!["player_caching"]!;

  String get playerCacheError => _localizedStrings[this.locale.languageCode]!["player_cache_error"]!;

  String get playerCacheInterrupt => _localizedStrings[this.locale.languageCode]!["player_cache_interrupt"]!;

  String get playerCacheComplete => _localizedStrings[this.locale.languageCode]!["player_cache_complete"]!;

  String get playerConfirm => _localizedStrings[this.locale.languageCode]!["player_confirm"]!;

  String get playerCancel => _localizedStrings[this.locale.languageCode]!["player_cancel"]!;

  String get playerCheckUserDeleteVideo => _localizedStrings[this.locale.languageCode]!["player_check_user_delete_video"]!;

  String get playerCacheSize => _localizedStrings[this.locale.languageCode]!["player_cache_size"]!;
}
