// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

// const reg = "{@}";
const reg = r'\{\@\}';

// extension for string format
extension StringExt on String {
  String txFormat(List<String> args) {
    String str = this;
    if (str.isNotEmpty) {
      int index = 0;
      str = str.replaceAllMapped(RegExp(reg), (match) {
        if (index < args.length) {
          return args[index++];
        } else {
          return match[0]!;
        }
      });
    }
    return str;
  }
}