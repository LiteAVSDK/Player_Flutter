// Copyright (c) 2022 Tencent. All rights reserved.
import 'package:flutter/material.dart';
import 'package:super_player_example/res/app_localizations.dart';

typedef void TestBitrateCheckboxFinishCallback(
    int value);

class DemoBitrateCheckbox extends StatefulWidget {
  List supportedBitrates;
  int index;
  TestBitrateCheckboxFinishCallback callback;

  DemoBitrateCheckbox(this.supportedBitrates, this.index, this.callback);

  @override
  _DemoBitrateCheckboxState createState() => _DemoBitrateCheckboxState();
}

class _DemoBitrateCheckboxState extends State<DemoBitrateCheckbox> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () async {
          Navigator.of(context).pop();
          this.widget.callback(this.widget.index);
        },
        child: Container(
          color: Color.fromARGB(180, 0, 0, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: this.widget.supportedBitrates.map((e) {
              String s = e["index"].toString();
              return Row(
                children: [
                  Text("${AppLocals.current.playerBitrate}$s", style: TextStyle(color: Colors.white),),
                  Theme(data: ThemeData(
                    unselectedWidgetColor: Colors.white,),
                    child: Radio<int> (
                      value: e["index"],
                      groupValue: this.widget.index,
                      onChanged: (value) {
                        setState(() {
                          this.widget.index = value!;
                        });
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),));
  }
}
