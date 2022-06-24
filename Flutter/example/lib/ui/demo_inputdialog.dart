// Copyright (c) 2022 Tencent. All rights reserved.
import 'package:flutter/material.dart';

typedef void DemoInputDialogFinishCallback(
    String url, int appId, String fileId,String pSign);

class DemoInputDialog extends StatefulWidget {
  String url = "";
  int appId = 0;
  String fileId = "";
  DemoInputDialogFinishCallback callback;
  bool showFileEdited = true;
  bool needPisgn = false;

  DemoInputDialog(this.url, this.appId, this.fileId, this.callback, {bool showFileEdited = true, bool needPisgn = false})
      : super () {this.showFileEdited = showFileEdited;this.needPisgn = needPisgn;}

  @override
  _DemoInputDialogState createState() => _DemoInputDialogState();
}

class _DemoInputDialogState extends State<DemoInputDialog> {
  late TextEditingController _urlController;
  late TextEditingController _appIdController;
  late TextEditingController _fileIdController;
  late TextEditingController _pSignController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _urlController = TextEditingController(text: widget.url);
    _appIdController = TextEditingController(
        text: widget.appId > 0 ? widget.appId.toString() : null);
    _fileIdController = TextEditingController(text: widget.fileId);
    _pSignController = TextEditingController(text: "");
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
              _fileIdController.text,
              _pSignController.text);
          }, // 关闭对话框
      ),
      // Padding(padding: EdgeInsets.only(left: 15)),
      FlatButton(
        child: Text("取消"),
        onPressed: (){
          Navigator.of(context).pop();
          }, // 关闭对话框
      ),
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
        widget.needPisgn?Padding(padding: EdgeInsets.only(bottom: 15)):Container(),
        widget.needPisgn?Container(
          color: Colors.white,
          child: Theme(
              data: new ThemeData(primaryColor: Colors.green),
              child: TextField(
                minLines: 1,
                maxLines: 10,
                controller: _pSignController,
                cursorColor: Colors.green,
                decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)), borderSide: BorderSide(color: Colors.green.withOpacity(0.4), width: 3.0)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10.0)), borderSide: BorderSide(color: Colors.green, width: 4.0)),
                    labelText:"请输入pSign(加密视频必填）", labelStyle: TextStyle(color: Colors.grey),
                    suffixIcon: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          _pSignController.clear();
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
    return AlertDialog(
        title: Center(
          child: Text("请设置播放地址"),
        ),
        elevation: 12.0,
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
