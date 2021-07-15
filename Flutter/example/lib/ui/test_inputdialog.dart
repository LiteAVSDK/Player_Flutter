import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

typedef void TestInputDialogFinishCallback(
    String url, int appId, String fileId);

class TestInputDialog extends StatefulWidget {
  String url = "";
  int appId = 0;
  String fileId = "";
  TestInputDialogFinishCallback callback;
  bool showFileEdited;

  TestInputDialog(this.url, this.appId, this.fileId, this.callback, {bool showFileEdited = true}) : super () {this.showFileEdited = showFileEdited;}

  @override
  _TestInputDialogState createState() => _TestInputDialogState();
}

class _TestInputDialogState extends State<TestInputDialog> {
  TextEditingController _urlController;
  TextEditingController _appIdController;
  TextEditingController _fileIdController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _urlController = TextEditingController(text: widget.url);
    _appIdController = TextEditingController(
        text: widget.appId > 0 ? widget.appId.toString() : null);
    _fileIdController = TextEditingController(text: widget.fileId);
    //        p.appId = 1252463788;
    //         p.fileId = @"5285890781763144364";
  }

  _buildActionWidget(BuildContext context) {
    List<Widget> actionWidgets = [
      FlatButton(
        child: Text("确定"),
        onPressed: () {
          Navigator.of(context).pop();
          widget.callback(
              _urlController.text,
              _appIdController.text.isNotEmpty
                  ? int.parse(_appIdController.text)
                  : 0,
              _fileIdController.text);
          }, // 关闭对话框
      ),
      // Padding(padding: EdgeInsets.only(left: 15)),
      FlatButton(
        child: Text("取消"),
        onPressed: (){
          Navigator.of(context).pop();
          }, // 关闭对话框
      ),
      // GestureDetector(
      //   child: Container(
      //       color: Colors.white,
      //       height: 50,
      //       child: Center(
      //         child: Text("确定", style: TextStyle(fontSize: 16)),
      //       )),
      //   onTap: () {
      //     Navigator.pop(context);
      //     widget.callback(
      //         _urlController.text,
      //         _appIdController.text.isNotEmpty
      //             ? int.parse(_appIdController.text)
      //             : 0,
      //         _fileIdController.text);
      //   },
      // ),

      // RaisedButton(
      //     onPressed: (){},
      //   child: Text("取消", style: TextStyle(fontSize: 16)),
      // ),
      // GestureDetector(
      //   child: Container(
      //       color: Colors.white,
      //       height: 50,
      //       child: Center(
      //         child: Text("取消", style: TextStyle(fontSize: 16)),
      //       )),
      //   onTap: () {
      //     Navigator.pop(context);
      //   },
      // ),
      // Padding(padding: EdgeInsets.only(left: 15)),
    ];
    return actionWidgets;
  }

  _contentWidget(BuildContext context) {
    return  Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: Colors.white,
          child: Theme(
              data: new ThemeData(primaryColor: Colors.green),
              child: TextField(
                minLines: 1,
                maxLines: 10,
                controller: _urlController,
                cursorColor: Colors.green,
                decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)), borderSide: BorderSide(color: Colors.green.withOpacity(0.4), width: 3.0)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)), borderSide: BorderSide(color: Colors.green, width: 4.0)),
                    labelText:"请输入url", labelStyle: TextStyle(color: Colors.grey),
                    suffixIcon: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          _urlController.clear();
                        })),
                onChanged: (text) {
                  // _url = text;
                },
              )),
        ),
        Padding(padding: EdgeInsets.only(bottom: 15)),
        widget.showFileEdited?Container(
          color: Colors.white,
          child: Theme(
              data: new ThemeData(primaryColor: Colors.green),
              child: TextField(
                minLines: 1,
                maxLines: 10,
                controller: _appIdController,
                keyboardType: TextInputType.number,
                cursorColor: Colors.green,
                decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)), borderSide: BorderSide(color: Colors.green.withOpacity(0.4), width: 3.0)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)), borderSide: BorderSide(color: Colors.green, width: 4.0)),
                    labelText:"请输入appid", labelStyle: TextStyle(color: Colors.grey),
                    suffixIcon: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          _appIdController.clear();
                        })),
                onChanged: (text) {
                  // _appId = int.parse(text);
                },
              )),
        ):Container(),
        widget.showFileEdited?Padding(padding: EdgeInsets.only(bottom: 15)):Container(),
        widget.showFileEdited?Container(
          color: Colors.white,
          child: Theme(
              data: new ThemeData(primaryColor: Colors.green),
              child: TextField(
                minLines: 1,
                maxLines: 10,
                controller: _fileIdController,
                cursorColor: Colors.green,
                decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)), borderSide: BorderSide(color: Colors.green.withOpacity(0.4), width: 3.0)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)), borderSide: BorderSide(color: Colors.green, width: 4.0)),
                    labelText:"请输入fileId", labelStyle: TextStyle(color: Colors.grey),
                    suffixIcon: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          _fileIdController.clear();
                        })),
                onChanged: (text) {
                  // _fileId = text;
                },
              )),
        ):Container(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    // return AlertDialog(
    //     backgroundColor: Colors.transparent,
    //     // elevation: 12.0,
    //     //titlePadding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 12),
    //     contentPadding: EdgeInsets.fromLTRB(0, 0, 0, 0.0),
    //     // shape: RoundedRectangleBorder(
    //     //   borderRadius: BorderRadius.all(Radius.circular(8.0)),
    //     // ),
    //     content: Center(
    //       child: Container(
    //         //color: Colors.red,
    //         //margin: EdgeInsets.all(20.6),
    //         // padding: EdgeInsets.fromLTRB(30.4, 0, 0, 80),
    //         decoration: BoxDecoration(
    //           color: Colors.black,
    //           border: Border.all(
    //             color: Colors.grey,
    //             width: 1.0,
    //           ),
    //         ),
    //         child: Column(
    //           mainAxisSize: MainAxisSize.min,
    //           children: [
    //             Container(
    //               height: 50,
    //                 margin: EdgeInsets.fromLTRB(10, 5, 10, 5),
    //               child: Align (
    //                 alignment: Alignment.centerLeft,
    //                 child: Text("请设置播放地址", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 20)),
    //               )
    //             ),
    //             Container(
    //               height: 0.5,
    //               color: Colors.grey,
    //             ),
    //             Container(
    //               margin: EdgeInsets.fromLTRB(10, 5, 10, 5),
    //               // color: Colors.grey,
    //               decoration: BoxDecoration(
    //                 color: Colors.blueGrey,
    //                 borderRadius: BorderRadius.all(Radius.circular(4.0)),
    //                 // border: Border.all(
    //                 //   color: Colors.grey,
    //                 //   width: 1.0,
    //                 // ),
    //               ),
    //               child: Theme(
    //                   data: new ThemeData(primaryColor: Colors.black),
    //                   child: TextField(
    //                     minLines: 1,
    //                     maxLines: 10,
    //                     controller: _urlController,
    //                     cursorColor: Colors.black,
    //                     onChanged: (text) {
    //                       // _url = text;
    //                     },
    //                   )),
    //             ),
    //             Theme(
    //                 data: new ThemeData(primaryColor: Colors.black),
    //                 child: TextField(
    //                   minLines: 1,
    //                   maxLines: 10,
    //                   controller: _urlController,
    //                   decoration: InputDecoration(
    //                       border: OutlineInputBorder(
    //                           gapPadding: 10.0, borderRadius: BorderRadius.all(Radius.circular(10.0)),
    //                           borderSide: BorderSide(
    //                               color: Colors.purple, width: 4.0, style: BorderStyle.solid
    //                           ))
    //                   ),
    //                   onChanged: (text) {
    //                     // _url = text;
    //                   },
    //                 )),
    //
    //             FlatButton(
    //               child: Text("取消"),
    //               onPressed: (){
    //                 Navigator.of(context).pop();
    //               }, // 关闭对话框
    //             ),
    //             FlatButton(
    //               child: Text("取消"),
    //               onPressed: (){
    //                 Navigator.of(context).pop();
    //               }, // 关闭对话框
    //             ),
    //           ],
    //         ),
    //       ),
    //     ));

    return AlertDialog(
        title: Center(
          child: Text("请设置播放地址"),
        ),
        elevation: 12.0,
        //titlePadding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 12),
        contentPadding: EdgeInsets.fromLTRB(10, 20.0, 10, 0.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
        insetPadding: EdgeInsets.fromLTRB(10, 0, 10, 0),
        actions: _buildActionWidget(context),
        content: _contentWidget(context),
        scrollable: true,);
  }
}
