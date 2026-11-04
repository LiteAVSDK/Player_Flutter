// Copyright (c) 2022 Tencent. All rights reserved.
import 'package:flutter/material.dart';

typedef void DemoSpeedSliderFinishCallback(
    double value);

class DemoSpeedSlider extends StatefulWidget {
  double value;
  DemoSpeedSliderFinishCallback callback;

  DemoSpeedSlider(this.value, this.callback);

  @override
  _DemoSpeedSliderState createState() => _DemoSpeedSliderState();
}

class _DemoSpeedSliderState extends State<DemoSpeedSlider> {
  @override
  Widget build(BuildContext context) {
    return  GestureDetector(
        onTap: () async {
          this.widget.callback(this.widget.value.toDouble());
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
                      this.widget.value = data.toDouble();
                      this.widget.callback(this.widget.value.toDouble());
                    });
                  },
                  onChangeStart: (data){
                    print('start:$data');
                  },
                  onChangeEnd: (data){
                    print('end:$data');
                  },
                  min: 0.5,
                  max: 1.5,
                  divisions: 100,
                  label: (this.widget.value.toDouble()).toString(),
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