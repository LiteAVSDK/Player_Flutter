import 'dart:ui';
import 'package:flutter/material.dart';

abstract class TestDefine{
  static const mainViewBackgroundColor = Color(0xFF0D0D0D);
  static const expaBackgroundColorNormal = Colors.blueGrey;
  static const expaBackgroundColorSelected = Colors.grey;
  static const Color color_F9F9F9 = Color(0xffF9F9F9);
  static const Color color_999 = Color(0xff999999);
}

class TreeData {
  // int visible;
  List<TreeDatachild> children;
  String name;
  // bool userControlSetTop;
  // int id;
  // int courseId;
  // int parentChapterId;
  // int order;
  bool isExpanded;//标识是否初始化

  TreeData(this.children, this.name, this.isExpanded);

  // TreeData({this.visible, this.children, this.name, this.userControlSetTop, this.id, this.courseId, this.parentChapterId, this.order,this.isExpanded});
  //
  // TreeData.fromJson(Map<String, dynamic> json) {
  //   visible = json['visible'];
  //   if (json['children'] != null) {
  //     children = new List<TreeDatachild>();(json['children'] as List).forEach((v) { children.add(new TreeDatachild.fromJson(v)); });
  //   }
  //   name = json['name'];
  //   userControlSetTop = json['userControlSetTop'];
  //   id = json['id'];
  //   courseId = json['courseId'];
  //   parentChapterId = json['parentChapterId'];
  //   order = json['order'];
  //   isExpanded = json['isExpanded'];
  // }
  //
  // Map<String, dynamic> toJson() {
  //   final Map<String, dynamic> data = new Map<String, dynamic>();
  //   data['visible'] = this.visible;
  //   if (this.children != null) {
  //     data['children'] =  this.children.map((v) => v.toJson()).toList();
  //   }
  //   data['name'] = this.name;
  //   data['userControlSetTop'] = this.userControlSetTop;
  //   data['id'] = this.id;
  //   data['courseId'] = this.courseId;
  //   data['parentChapterId'] = this.parentChapterId;
  //   data['order'] = this.order;
  //   data['isExpanded'] = this.isExpanded;
  //   return data;
  // }
}

class TreeDatachild {
  // int visible;
  // List<Null> children;
  String name;
  // bool userControlSetTop;
  // int id;
  // int courseId;
  // int parentChapterId;
  // int order;

  TreeDatachild(this.name);
  // TreeDatachild({this.visible, this.children, this.name, this.userControlSetTop, this.id, this.courseId, this.parentChapterId, this.order});

  // TreeDatachild.fromJson(Map<String, dynamic> json) {
  //   visible = json['visible'];
  //   if (json['children'] != null) {
  //     children = new List<Null>();
  //   }
  //   name = json['name'];
  //   userControlSetTop = json['userControlSetTop'];
  //   id = json['id'];
  //   courseId = json['courseId'];
  //   parentChapterId = json['parentChapterId'];
  //   order = json['order'];
  // }
  //
  // Map<String, dynamic> toJson() {
  //   final Map<String, dynamic> data = new Map<String, dynamic>();
  //   data['visible'] = this.visible;
  //   if (this.children != null) {
  //     data['children'] =  [];
  //   }
  //   data['name'] = this.name;
  //   data['userControlSetTop'] = this.userControlSetTop;
  //   data['id'] = this.id;
  //   data['courseId'] = this.courseId;
  //   data['parentChapterId'] = this.parentChapterId;
  //   data['order'] = this.order;
  //   return data;
  // }
}