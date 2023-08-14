// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

class FSPLocal {
  final Locale locale;

  static FSPLocal? _current;

  static Map<String, String> _localStrings = {};

  static FSPLocal get current {
    assert(_current != null, 'No instance of FSPLocal was loaded. '
        'Try to initialize the FSPLocal delegate before accessing FSPLocal.current.');
    return _current!;
  }

  FSPLocal(this.locale);

  static FSPLocal of(BuildContext context) {
    final instance = FSPLocal.maybeOf(context);
    assert(instance != null,
    'No instance of FSPLocal present in the widget tree. Did you add SuperPlayerLocalizations in localizationsDelegates?');
    return instance!;
  }

  static FSPLocal? maybeOf(BuildContext context) {
    return Localizations.of<FSPLocal>(context, FSPLocal);
  }

  static Future<FSPLocal> loadJson(Locale locale) async {
    final name = (locale.countryCode?.isEmpty ?? false) ? locale.languageCode : locale.toString();
    FSPLocal fspLocals = FSPLocal(locale);
    await fspLocals.loadIntl(name);
    FSPLocal._current = fspLocals;
    return fspLocals;
  }

  Future<void> loadIntl(String currentLanguageName) async {
    String resFile = findLanguageFile(currentLanguageName);
    final jsonString = await rootBundle.loadString("packages/${PlayerConstants.PKG_NAME}/$resFile");
    Map<String, dynamic> map = json.decode(jsonString);
    _localStrings = map.map((key, value) => MapEntry(key, value.toString()));
  }

  String findLanguageFile(String languageName) {
    switch(languageName) {
      case 'zh':
        return "assets/json/string_zh.json";
      case 'en':
        return "assets/json/string_en.json";
      default:
        // default en
        return "assets/json/string_en.json";
    }
  }

  // SuperPlayer
  String get txSpwNetWeak => _localStrings["tx_spw_net_weak"]!;
  String get txSpwErrPlayTo => _localStrings["tx_spw_err_play_to"]!;
  String get txSpwErrEmptyUrl => _localStrings["tx_spw_err_empty_url"]!;
  String get txSpwStartDownload => _localStrings["tx_spw_start_download"]!;
  String get txSpwDownloadComplete => _localStrings["tx_spw_download_complete"]!;
  String get txSpwDownloadErrorTo => _localStrings["tx_spw_download_error_to"]!;
  String get txSpwSound => _localStrings["tx_spw_sound"]!;
  String get txSpwBrightness => _localStrings["tx_spw_brightness"]!;
  String get txSpwMultiPlay => _localStrings["tx_spw_multi_play"]!;
  String get txSpwHardwareAccel => _localStrings["tx_spw_hardware_accel"]!;
  String get txSpwOpeningPip => _localStrings["tx_spw_opening_pip"]!;
  String get txSpwClosingPip => _localStrings["tx_spw_closing_pip"]!;
  String get txSpwOpenPipFailed => _localStrings["tx_spw_open_pip_failed"]!;
  String get txSpwTestVideo => _localStrings["tx_spw_test_video"]!;
  String get txSpwFlu => _localStrings["tx_spw_flu"]!;
  String get txSpwSd => _localStrings["tx_spw_sd"]!;
  String get txSpwHd => _localStrings["tx_spw_hd"]!;
  String get txSpwFsd => _localStrings["tx_spw_fsd"]!;
  String get txSpwFhd => _localStrings["tx_spw_fhd"]!;
  String get txSpwFhd2 => _localStrings["tx_spw_fhd2"]!;
  String get txSpw240p => _localStrings["tx_spw_240p"]!;
  String get txSpw360p => _localStrings["tx_spw_360p"]!;
  String get txSpw480p => _localStrings["tx_spw_480p"]!;
  String get txSpw540p => _localStrings["tx_spw_540p"]!;
  String get txSpw720p => _localStrings["tx_spw_720p"]!;
  String get txSpw1080p => _localStrings["tx_spw_1080p"]!;
  String get txSpw2k => _localStrings["tx_spw_2k"]!;
  String get txSpw4k => _localStrings["tx_spw_4k"]!;
  String get txSpwOd => _localStrings["tx_spw_od"]!;
  // cgi
  String get txSpwErrFileNotExist => _localStrings["tx_spw_err_file_not_exist"]!;
  String get txSpwErrInvalidTrialDuration => _localStrings["tx_spw_err_invalid_trial_duration"]!;
  String get txSpwErrPcfgNotUnique => _localStrings["tx_spw_err_pcfg_not_unique"]!;
  String get txSpwErrLicenseExpired => _localStrings["tx_spw_err_license_expired"]!;
  String get txSpwErrNoAdaptiveStream => _localStrings["tx_spw_err_no_adaptive_stream"]!;
  String get txSpwErrInvalidRequestFormat => _localStrings["tx_spw_err_invalid_request_format"]!;
  String get txSpwErrNoUser => _localStrings["tx_spw_err_no_user"]!;
  String get txSpwErrNoAntiLeechInfo => _localStrings["tx_spw_err_no_anti-leech_info"]!;
  String get txSpwErrCheckSignFailed => _localStrings["tx_spw_err_check_sign_failed"]!;
  String get txSpwErrOther => _localStrings["tx_spw_err_other"]!;
  String get txSpwErrInternal => _localStrings["tx_spw_err_internal"]!;

}