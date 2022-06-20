// Copyright (c) 2022 Tencent. All rights reserved.
import 'package:flutter/material.dart';

abstract class DemoDefine{
  static const mainViewBackgroundColor = Color(0xFF0D0D0D);
  static const expaBackgroundColorNormal = Colors.blueGrey;
  static const expaBackgroundColorSelected = Colors.grey;
  static const Color color_F9F9F9 = Color(0xffF9F9F9);
  static const Color color_999 = Color(0xff999999);
}

class TreeData {
  List<TreeDatachild> children;
  String name;
  //标识是否初始化
  bool isExpanded;

  TreeData(this.children, this.name, this.isExpanded);
}

class TreeDatachild {
  String name;

  TreeDatachild(this.name);
}