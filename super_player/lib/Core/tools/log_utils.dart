// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

/// log print tools
class LogUtils {

  static const _LOG_COLOR_TABLE = {
    LogLevel.verbose: "37",
    LogLevel.debug: "34",
    LogLevel.info: "32",
    LogLevel.warn: "33",
    LogLevel.error: "31",
  };

  /// control log print
  static bool logOpen = true;

  /// print error log
  static void e(String tag, Object msg) {
    log(LogLevel.error, tag, msg);
  }

  /// print warnning log
  static void w(String tag, Object msg) {
    log(LogLevel.warn, tag, msg);
  }

  /// print info log
  static void i(String tag, Object msg) {
    log(LogLevel.info, tag, msg);
  }

  /// print debug log
  static void d(String tag, Object msg) {
    log(LogLevel.debug, tag, msg);
  }

  /// print verbose log
  static void v(String tag, Object msg) {
    log(LogLevel.verbose, tag, msg);
  }

  /// print custom log
  static void log(int level, String tag, Object msg) {
    if(logOpen) {
      if (tag.isEmpty) {
        tag = "TXFlutterPlayer";
      }
      if(level < LogLevel.verbose) {
        level = LogLevel.verbose;
      }
      if(level > LogLevel.error) {
        level = LogLevel.error;
      }
      StringBuffer logStrBuffer = StringBuffer();
      logStrBuffer.write(tag);
      logStrBuffer.write(":");
      logStrBuffer.write("\t");
      logStrBuffer.write(msg.toString());
      print(_effectLevel(level, logStrBuffer.toString()));
    }
  }

  static String _effectLevel(int level, String str) {
    String formateStr = '\x1B[${_LOG_COLOR_TABLE[level]}m $str \x1B[0m';
    return formateStr;
  }
}

class LogLevel {
  static const verbose = 1;
  static const debug = 2;
  static const info = 3;
  static const warn = 4;
  static const error = 5;
}


