// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

class SuperPlayerWidgetLocals extends LocalizationsDelegate<FSPLocal> {

  static SuperPlayerWidgetLocals delegate = SuperPlayerWidgetLocals();

  @override
  bool isSupported(Locale locale) {
    return ["zh", "en"].contains(locale.languageCode);
  }

  @override
  Future<FSPLocal> load(Locale locale) async {
    return await FSPLocal.loadJson(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<FSPLocal> old) {
    return false;
  }

}