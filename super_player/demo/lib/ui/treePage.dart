// Copyright (c) 2022 Tencent. All rights reserved.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:super_player_example/common/demo_config.dart';
import 'package:super_player_example/demo_superplayer.dart';
import 'package:super_player_example/demo_txLiveplayer.dart';
import 'package:super_player_example/demo_txvodplayer.dart';
import 'package:super_player_example/res/app_localizations.dart';
import 'package:super_player/super_player.dart';

import '../demo_short_video_player.dart';
import 'demo_define.dart';

class TreePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TreePageState();
  }
}

class _TreePageState extends State<TreePage> {
  List<TreeData> _data = [];
  ScrollController _scrollController = ScrollController();
  int _panelIndex = 0; // Expanded index
  List<IconData> _icons = [
    Icons.star_border,
    Icons.child_care,
    Icons.cloud_queue,
    Icons.ac_unit,
    Icons.lightbulb_outline,
  ];
  /// set player license
  Future<void> initPlayerLicense() async {
    await SuperPlayerPlugin.setGlobalLicense(LICENSE_URL, LICENSE_KEY);
  }

  @override
  void initState() {
    super.initState();
    // license add to here, prevent first launch due to license loading failure caused by no network
    initPlayerLicense();
    _scrollController.addListener(() {
      // Current position = maximum sliding range means that it has already been scrolled to the bottom.
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
      }
    });
    _data = [
      TreeData([
        TreeDataChild("player_live_play"),
        TreeDataChild("player_vod_player"),
        TreeDataChild("player_play_widget"),
        TreeDataChild("player_short_video_play")
      ], "player_video_player", false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        // Indicator color
        color: Theme.of(context).primaryColor,
        // Distance from the top when the indicator is displayed
        displacement: 40,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: ExpansionPanelList(
            // Switch animation duration
            animationDuration: Duration(milliseconds: 500),
            // Switch callback
            expansionCallback: (panelIndex, isExpanded) {
              setState(() {
                _panelIndex = panelIndex;
                _data[panelIndex].isExpanded = !_data[panelIndex].isExpanded;
              });
            },
            // Content area
            children: _data.map<ExpansionPanel>((TreeData treeData) {
              return ExpansionPanel(
                // title
                headerBuilder: (context, isExpanded) {
                  return ListTile(
                    contentPadding: EdgeInsets.all(10.0),
                    title: Text(
                      AppLocals.current.findStr(treeData.name)!,
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                    // random icon
                    leading: Icon(_icons[Random().nextInt(_icons.length)]),
                  );
                },
                // expand content
                body: Container(
                  height: 250,
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                  child: ListView.builder(
                    itemCount: treeData.children.length,
                    itemBuilder: (BuildContext context, int position) {
                      return getRow(position, treeData);
                    },
                  ),
                ),
                // is expanded
                isExpanded: treeData.isExpanded,
              );
            }).toList(),
          ),
        ),
        // Pull-down refresh callback
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
            AppLocals.current.findStr(treeData.children[i].name)!,
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
              } else if (i==2){
                return DemoSuperPlayer();
              } else {
                return DemoShortVideoPlayer();
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
