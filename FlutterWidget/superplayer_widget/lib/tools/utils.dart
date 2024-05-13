// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

class Utils {

  static bool compareBuffer(Uint8List? buffer1, Uint8List? buffer2) {
    if(buffer1 == null || buffer2 == null) {
      return false;
    }
    if (buffer1.length != buffer2.length) {
      return false;
    }
    for (int i = 0; i < buffer1.length; i++) {
      if (buffer1[i] != buffer2[i]) {
        return false;
      }
    }
    return true;
  }

  /// Convert seconds to the format of hh:mm:ss.
  /// 将秒数转换为hh:mm:ss的格式
  static String formattedTime(double second) {
    int h = second ~/ 3600;
    int m = (second % 3600) ~/ 60;
    int s = ((second % 3600) % 60).toInt();
    String formatTime;
    if (h == 0) {
      formatTime = "${asTwoDigit(m)}:${asTwoDigit(s)}";
    } else {
      formatTime = "${asTwoDigit(h)}:${asTwoDigit(m)}:${asTwoDigit(s)}";
    }
    return formatTime;
  }

  static String asTwoDigit(int digit) {
    String value = "";
    if (digit < 10) {
      value = "0";
    }
    value += digit.toString();
    return value;
  }

}