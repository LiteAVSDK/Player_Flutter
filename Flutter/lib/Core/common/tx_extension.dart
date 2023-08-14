// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

const reg = "{@}";

// extension for string format
extension StringExt on String {
  String txFormat(List<String> args) {
    String str = this;
    if (str.isNotEmpty) {
      RegExp regExp = RegExp(reg);
      Iterable<Match> findResult = regExp.allMatches(str);
      for (int i = 0; i < findResult.length && i < args.length; i++) {
        Match match = findResult.elementAt(i);
        str = str.replaceRange(match.start, match.end, args[i]);
      }
    }
    return str;
  }
}