// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

/// Style resources.
/// 样式资源
class ThemeResource {
  /// Get the common progress bar style.
  /// 获得通用进度条样式
  static ThemeData getCommonSliderTheme() {
    return ThemeData(
        sliderTheme: SliderThemeData(
      trackHeight: 2,
      thumbColor: Color(ColorResource.COLOR_SLIDER_MAIN_THEME),
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4),
      overlayColor: Colors.white,
      overlayShape: RoundSliderOverlayShape(overlayRadius: 10),
      activeTrackColor: Color(ColorResource.COLOR_SLIDER_MAIN_THEME),
      inactiveTrackColor: Color(ColorResource.COLOR_GRAY),
    ));
  }

  /// Get the common progress bar style.
  /// 获得通用进度条样式
  static ThemeData getMiniSliderTheme() {
    return ThemeData(
        sliderTheme: SliderThemeData(
      trackHeight: 1,
      thumbColor: Color(ColorResource.COLOR_SLIDER_MAIN_THEME),
      thumbShape:
          RoundSliderThumbShape(enabledThumbRadius: 0, disabledThumbRadius: 0, elevation: 0, pressedElevation: 0),
      overlayColor: Colors.white,
      overlayShape: RoundSliderOverlayShape(overlayRadius: 1),
      activeTrackColor: Color(ColorResource.COLOR_SLIDER_MAIN_THEME),
      inactiveTrackColor: Color(ColorResource.COLOR_GRAY),
    ));
  }

  static TextStyle getCommonLabelTextStyle() {
    return TextStyle(fontSize: 14, color: Colors.white);
  }

  static TextStyle getCheckedLabelTextStyle() {
    return TextStyle(fontSize: 14, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME));
  }

  static TextStyle getCommonTextStyle() {
    return TextStyle(fontSize: 13, color: Colors.white);
  }

  static TextStyle getCheckedTextStyle() {
    return TextStyle(fontSize: 13, color: Color(ColorResource.COLOR_SLIDER_MAIN_THEME));
  }
}
