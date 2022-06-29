// Copyright (c) 2022 Tencent. All rights reserved.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:super_player_example/demo_superplayer.dart';
import 'package:super_player_example/demo_txLiveplayer.dart';
import 'package:super_player_example/demo_txvodplayer.dart';

import 'demo_define.dart';

class TreePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TreePageState();
  }
}

class _TreePageState extends State<TreePage> {
  List<TreeData> _datas = [];
  ScrollController _scrollController = ScrollController();
  int _panelIndex = 0; //展开下标
  List<IconData> _icons = [
    Icons.star_border,
    Icons.child_care,
    Icons.cloud_queue,
    Icons.ac_unit,
    Icons.lightbulb_outline,
  ];

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      //当前位置==最大滑动范围 表示已经滑动到了底部
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
      }
    });

    _datas = [
      TreeData([
        TreeDatachild("直播播放"),
        TreeDatachild("点播播放"),
        TreeDatachild("播放器组件"),
      ], "播放器", false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        //指示器颜色
        color: Theme.of(context).primaryColor,
        //指示器显示时距顶部位置
        displacement: 40,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: ExpansionPanelList(
            //开关动画时长
            animationDuration: Duration(milliseconds: 500),
            //开关回调
            expansionCallback: (panelIndex, isExpanded) {
              setState(() {
                _panelIndex = panelIndex;
                _datas[panelIndex].isExpanded = !isExpanded;
              });
            },
            //内容区
            children: _datas.map<ExpansionPanel>((TreeData treeData) {
              return ExpansionPanel(
                //标题
                headerBuilder: (context, isExpanded) {
                  return ListTile(
                    contentPadding: EdgeInsets.all(10.0),
                    title: Text(
                      treeData.name,
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                    //取随机icon
                    leading: Icon(_icons[Random().nextInt(_icons.length)]),
                  );
                },
                //展开内容
                body: Container(
                  height: 200,
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                  child: ListView.builder(
                    itemCount: treeData.children.length,
                    itemBuilder: (BuildContext context, int position) {
                      return getRow(position, treeData);
                    },
                  ),
                ),
                //是否展开
                isExpanded: treeData.isExpanded,
              );
            }).toList(),
          ),
        ),
        //下拉刷新回调
        onRefresh: () async {
          await Future.delayed(Duration(seconds: 2), () {
          });
        },
      ),
    );
  }

  Widget getRow(int i, TreeData treeData) {
    return GestureDetector(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5.0),
        child: ListTile(
          title: Text(
            treeData.children[i].name,
            style: TextStyle(color: DemoDefine.color_999),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: DemoDefine.color_999,
          ),
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            // ignore: missing_return
            builder: (context) {
              if (i == 0) {
                return DemoTXLivePlayer();
              }else if (i == 1) {
                return DemoTXVodPlayer();
              } else {
                return DemoSuperplayer();
              }
            }
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
