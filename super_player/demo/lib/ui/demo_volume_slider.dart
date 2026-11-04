// Copyright (c) 2022 Tencent. All rights reserved.
import 'package:flutter/material.dart';

typedef void DemoVolumeSliderFinishCallback(
    int value);

class DemoVolumeSlider extends StatefulWidget {
  int value;
  DemoVolumeSliderFinishCallback callback;

  DemoVolumeSlider(this.value, this.callback);

  @override
  _DemoVolumeSliderState createState() => _DemoVolumeSliderState();
}

class _DemoVolumeSliderState extends State<DemoVolumeSlider> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return  GestureDetector(
      onTap: () async {
        this.widget.callback(this.widget.value.toInt());
        Navigator.of(context).pop();
      },
      child: Container(
        color: Color.fromARGB(180, 0, 0, 0),
        child: Center(
            child: Container(
              height: 50,
              child: Slider(
                value: this.widget.value.toDouble(),
                onChanged: (data){
                  setState(() {
                    this.widget.value = data.toInt();
                    this.widget.callback(this.widget.value.toInt());
                  });
                },
                onChangeStart: (data){
                  print('start:$data');
                },
                onChangeEnd: (data){
                  print('end:$data');
                },
                min: 0.0,
                max: 100.0,
                divisions: 100,
                label: (this.widget.value.toInt()).toString(),
                activeColor: Colors.green,
                inactiveColor: Colors.grey,
                semanticFormatterCallback: (double newValue) {
                  return '${newValue.round()} dollars}';
                },
              ),
            )
        ),
      )
    );
  }

}