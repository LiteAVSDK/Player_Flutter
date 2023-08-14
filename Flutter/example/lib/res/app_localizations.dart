// Copyright (c) 2022 Tencent. All rights reserved.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Load text resource internationalization
/// 文本资源国际化加载
class AppLocals {
  final Locale locale;

  static AppLocals? _current;

  static AppLocals get current {
    assert(_current != null, 'No instance of AppLocals was loaded. '
        'Try to initialize the AppLocals delegate before accessing AppLocals.current.');
    return _current!;
  }

  AppLocals(this.locale);

  static AppLocals of(BuildContext context) {
    final instance = AppLocals.maybeOf(context);
    assert(instance != null,
        'No instance of AppLocals present in the widget tree. Did you add AppLocalizationDelegate in localizationsDelegates?');
    return instance!;
  }

  static Map<String, String> _localStrings = {};

  static AppLocals? maybeOf(BuildContext context) {
    return Localizations.of<AppLocals>(context, AppLocals);
  }

  static Future<AppLocals> loadJson(Locale locale) async {
    final name = (locale.countryCode?.isEmpty ?? false) ? locale.languageCode : locale.toString();
    AppLocals appLocals = AppLocals(locale);
    await appLocals.loadIntl(name);
    AppLocals._current = appLocals;
    return appLocals;
  }

  Future<void> loadIntl(String currentLanguageName) async {
    final jsonString = await rootBundle.loadString("assets/json/i18n.json");
    Map<String, dynamic> map = json.decode(jsonString);
    Map<String, Map<String, String>> parentMap = map.map((key, value) => MapEntry(key, value.cast<String, String>()));
    Map<String, String>? tmpLocal = parentMap[currentLanguageName];
    _localStrings = tmpLocal ?? {};
  }

  String? findStr(String key) => _localStrings[key];

  String get playerTitle => _localStrings["player_title"]!;

  // download demo
  String get playerCacheProgressLabel => _localStrings["player_cache_progress_label"]!;
  String get playerDownloadList => _localStrings["player_download_list"]!;
  String get playerTip => _localStrings["player_tip"]!;
  String get playerDeleteFailed => _localStrings["player_delete_failed"]!;
  String get playerCaching => _localStrings["player_caching"]!;
  String get playerCacheError => _localStrings["player_cache_error"]!;
  String get playerCacheInterrupt => _localStrings["player_cache_interrupt"]!;
  String get playerCacheComplete => _localStrings["player_cache_complete"]!;
  String get playerConfirm => _localStrings["player_confirm"]!;
  String get playerCancel => _localStrings["player_cancel"]!;
  String get playerCheckUserDeleteVideo => _localStrings["player_check_user_delete_video"]!;
  String get playerCacheSize => _localStrings["player_cache_size"]!;
  // player widget demo
  String get playerPlayWidget => _localStrings["player_play_widget"]!;
  String get playerTestVideo => _localStrings["player_test_video"]!;
  String get playerVodVideo => _localStrings["player_vod_video"]!;
  String get playerTencentCloud => _localStrings["player_tencent_cloud"]!;
  String get playerEncryptVideo => _localStrings["player_encrypt_video"]!;
  String get playerVod => _localStrings["player_vod"]!;
  String get playerLive => _localStrings["player_live"]!;
  String get playerInputAddTip => _localStrings["player_input_add_tip"]!;
  String get playerVideoTitleAchievement => _localStrings["player_video_title_achievement"]!;
  String get playerVideoTitleNumber => _localStrings["player_video_title_number"]!;
  String get playerVideoTitleEasy => _localStrings["player_video_title_easy"]!;
  String get playerVideoTitleIntroduction => _localStrings["player_video_title_introduction"]!;
  // player live demo
  String get playerSwitchTo1080 => _localStrings["player_switch_to_1080"]!;
  String get playerSwitchTo480 => _localStrings["player_switch_to_480"]!;
  String get playerLiveSwitchFailed => _localStrings["player_live_switch_failed"]!;
  String get playerLivePlay => _localStrings["player_live_play"]!;
  String get playerLiveStopTip => _localStrings["player_live_stop_tip"]!;
  String get playerResumePlay => _localStrings["player_resume_play"]!;
  String get playerPausePlay => _localStrings["player_pause_play"]!;
  String get playerStopPlay => _localStrings["player_stop_play"]!;
  String get playerReplay => _localStrings["player_replay"]!;
  String get playerQualitySwitch => _localStrings["player_quality_switch"]!;
  String get playerCancelMute => _localStrings["player_cancel_mute"]!;
  String get playerSetMute => _localStrings["player_set_mute"]!;
  String get playerAdjustVolume => _localStrings["player_adjust_volume"]!;
  // player vod demo
  String get playerVodPlayer => _localStrings["player_vod_player"]!;
  String get playerPlayback => _localStrings["player_playback"]!;
  String get playerPause => _localStrings["player_pause"]!;
  String get playerVariableSpeedPlay => _localStrings["player_variable_speed_play"]!;
  String get playerNoOtherBitrate => _localStrings["player_no_other_bitrate"]!;
  String get playerSwitchBitrate => _localStrings["player_switch_bitrate"]!;
  String get playerPlaybackDuration => _localStrings["player_playback_duration"]!;
  String get playerVideoSize => _localStrings["player_video_size"]!;
  String get playerLoopStatus => _localStrings["player_loop_status"]!;
  String get playerHardEncode => _localStrings["player_hard_encode"]!;
  String get playerSoftEncode => _localStrings["player_soft_encode"]!;
  String get playerSwitchSucTo => _localStrings["player_switch_suc_to"]!;
  String get playerSwitchFailedTo => _localStrings["player_switch_failed_to"]!;
  String get playerPlayEnd => _localStrings["player_play_end"]!;
  String get playerSwitchSoft => _localStrings["player_switch_soft"]!;
  String get playerSwitchHard => _localStrings["player_switch_hard"]!;
  String get playerPlayableDurationTo => _localStrings["player_playable_duration_to"]!;
  String get playerPlayableTime => _localStrings["player_playable_time"]!;
  String get playerCacheTime => _localStrings["player_cache_time"]!;
  String get playerSwitchSuc => _localStrings["player_switch_suc"]!;
  String get playerSecond => _localStrings["player_second"]!;
  // player component
  String get playerBitrate => _localStrings["player_bitrate"]!;
  String get playerInputAppId => _localStrings["player_input_appId"]!;
  String get playerInputFileId => _localStrings["player_input_fileId"]!;
  String get playerInputSign => _localStrings["player_input_sign"]!;
  String get playerIsEnableDownload => _localStrings["player_is_enable_download"]!;
  String get playerInputPlaybackAdd => _localStrings["player_input_playback_add"]!;
  String get playerShortVideoPlay => _localStrings["player_short_video_play"]!;
  String get playerVideoPlayer => _localStrings["player_video_player"]!;
  String get playerInputUrl => _localStrings["player_input_url"]!;
}
