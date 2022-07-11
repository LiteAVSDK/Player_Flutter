// Copyright (c) 2022 Tencent. All rights reserved.
import 'package:flutter/material.dart';
import 'package:super_player/super_player.dart';

/// 进度条widget
class VideoSliderView extends StatefulWidget {

  final ChangeNotifier _controller;

  VideoSliderView(this._controller,Key key):super(key: key);

  @override
  State<StatefulWidget> createState() {
    return VideoSliderState();
  }
}

class VideoSliderState extends State<VideoSliderView> {

  double _currentProgress = 0.0;
  double _videoDuration = 0.0;

  bool isSliding = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: ThemeData(
            sliderTheme: SliderThemeData(
              trackHeight: 2,
              thumbColor: Color(0xFFFF4640),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4),
              overlayColor: Colors.white,
              overlayShape: RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: Color(0xFFFF4640),
              inactiveTrackColor: Color(0xFFBBBBBB),
            )),
        child: Slider(
          min: 0,
          max: 1,
          value: _currentProgress,
          onChanged: (double value) {
            isSliding = true;
            setState(() {
              _currentProgress = value;
            });
          },
          onChangeEnd: (double value) {
            setState(() {
              isSliding = false;
              _currentProgress = value;
              if (widget._controller is TXVodPlayerController) {
                TXVodPlayerController controller = widget._controller as TXVodPlayerController;
                controller.seek(_currentProgress * _videoDuration);
              } else if (widget._controller is TXLivePlayerController) {
                TXLivePlayerController controller = widget._controller as TXLivePlayerController;
                controller.seek(_currentProgress * _videoDuration);
              }
              
              print("_currentProgress:$_currentProgress,_videoDuration:"
                  "$_videoDuration,currentDuration:${_currentProgress * _videoDuration}");
            });
          },
        ));
  }

  void updatePorgess(double progress,double totalDuration) {
    if(!isSliding) {
      setState(() {
        if(progress > 1.0) {
          progress = 1.0;
        }
        if(progress < 0) {
          progress = 0;
        }
        _currentProgress = progress;
        _videoDuration = totalDuration;
      });
    }
  }

}