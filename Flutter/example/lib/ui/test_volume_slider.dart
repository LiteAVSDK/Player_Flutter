import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

typedef void TestVolumeSliderFinishCallback(
    int value);

class TestVolumeSlider extends StatefulWidget {
  int value;
  TestVolumeSliderFinishCallback callback;

  TestVolumeSlider(this.value, this.callback);

  @override
  _TestVolumeSliderState createState() => _TestVolumeSliderState();
}

class _TestVolumeSliderState extends State<TestVolumeSlider> {
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