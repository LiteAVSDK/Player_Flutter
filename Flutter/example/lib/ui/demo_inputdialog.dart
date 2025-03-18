// Copyright (c) 2022 Tencent. All rights reserved.
import 'package:flutter/material.dart';
import 'package:super_player_example/res/app_localizations.dart';

typedef void DemoInputDialogFinishCallback(String url, int appId, String fileId, String pSign, bool enableDownload, bool isDrm);

class DemoInputDialog extends StatefulWidget {
  String url = "";
  int appId = 0;
  String fileId = "";
  DemoInputDialogFinishCallback callback;
  bool showFileEdited = true;
  bool needPisgn = false;
  bool needDownload = false;
  bool needDrm = false;

  DemoInputDialog(this.url, this.appId, this.fileId, this.callback,
      {bool showFileEdited = true, bool needPisgn = false, bool needDownload = false, bool needDrm = false})
      : super() {
    this.showFileEdited = showFileEdited;
    this.needPisgn = needPisgn;
    this.needDownload = needDownload;
    this.needDrm = needDrm;
  }

  @override
  _DemoInputDialogState createState() => _DemoInputDialogState();
}

class _DemoInputDialogState extends State<DemoInputDialog> {
  late TextEditingController _urlController;
  late TextEditingController _appIdController;
  late TextEditingController _fileIdController;
  late TextEditingController _pSignController;

  bool isEnableDownload = false;
  bool isNeedDrm = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.url);
    // _appIdController = TextEditingController(text: widget.appId > 0 ? widget.appId.toString() : null);
    // _fileIdController = TextEditingController(text: widget.fileId);
    // _pSignController = TextEditingController(text: "");
    _appIdController = TextEditingController(text: "1500014561");
    _fileIdController = TextEditingController(text: "387702304941991610");
    _pSignController = TextEditingController(text: "eyJhbGciOiJIUzI1NiJ9.eyJhcHBJZCI6MTUwMDAxNDU2MSwiZmlsZUlkIjoiMzg3NzAyMzA0OTQxOTkxNjEwIiwiY3VycmVudFRpbWVTdGFtcCI6MTY2MTE2MzM3MywiZXhwaXJlVGltZVN0YW1wIjoyNjQ4NTU3OTE5LCJwY2ZnIjoic2RtY3BsYXkiLCJEcm1MaWNlbnNlSW5mbyI6eyJFeHBpcmVUaW1lU3RhbXAiOjE5NjA5OTUxNzB9fQ.GGoDBMy-aaN3TmjgOMBGGlI_ujY8b-UXpP9qAoiPnI4");

    // _appIdController = TextEditingController(text: "1500033786");
    // _fileIdController = TextEditingController(text: "1397757895139814378");
    // _pSignController = TextEditingController(text: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBJZCI6MTUwMDAzMzc4NiwiZmlsZUlkIjoiMTM5Nzc1Nzg5NTEzOTgxNDM3OCIsImNvbnRlbnRJbmZvIjp7ImF1ZGlvVmlkZW9UeXBlIjoiUHJvdGVjdGVkQWRhcHRpdmUiLCJkcm1BZGFwdGl2ZUluZm8iOnsicHJpdmF0ZUVuY3J5cHRpb25EZWZpbml0aW9uIjoxMiwid2lkZXZpbmVEZWZpbml0aW9uIjoxMywiZmFpclBsYXlEZWZpbml0aW9uIjoxMX0sImltYWdlU3ByaXRlRGVmaW5pdGlvbiI6MTB9LCJjdXJyZW50VGltZVN0YW1wIjoxNzQxNzcwNzI3LCJleHBpcmVUaW1lU3RhbXAiOjE3NDE3OTIzMjcsInVybEFjY2Vzc0luZm8iOnsidCI6IjY3ZDFhNDQ3IiwicmxpbWl0IjozLCJ1cyI6ImN2OGt2cG9uam5wMjBtNGQxMGxnIiwiZG9tYWluIjoiMTUwMDAzMzc4Ni52b2QtcWNsb3VkLmNvbSIsInNjaGVtZSI6IkhUVFBTIn0sImRybUxpY2Vuc2VJbmZvIjp7InBlcnNpc3RlbnQiOiJPRkYiLCJyZW50YWxEdXJhdGlvbiI6NjAwLCJmb3JjZUwxVHJhY2tUeXBlcyI6WyJIRCIsIlVIRDEiLCJVSEQyIl0sImV4cGlyZVRpbWVTdGFtcCI6MTc0MTc5MjMyN319.IgQFAYFaxgOXcSQQo8h3TVxlQ9UaInYvn68jagMI3uk");
  }

  _buildActionWidget(BuildContext context) {
    List<Widget> actionWidgets = [
      TextButton(
        child: Text(AppLocals.current.playerConfirm),
        onPressed: () {
          Navigator.of(context).pop();
          widget.callback(_urlController.text, _appIdController.text.isNotEmpty ? int.parse(_appIdController.text) : 0,
              _fileIdController.text, _pSignController.text, isEnableDownload, isNeedDrm);
        }, // close dialog
      ),
      TextButton(
        child: Text(AppLocals.current.playerCancel),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    ];
    return actionWidgets;
  }

  _contentWidget(BuildContext context) {
    return Column(
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
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        borderSide: BorderSide(color: Colors.green.withOpacity(0.4), width: 3.0)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        borderSide: BorderSide(color: Colors.green, width: 4.0)),
                    labelText: AppLocals.current.playerInputUrl,
                    labelStyle: TextStyle(color: Colors.grey),
                    suffixIcon: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          _urlController.clear();
                        })),
                onChanged: (text) {},
              )),
        ),
        Padding(padding: EdgeInsets.only(bottom: 15)),
        widget.showFileEdited
            ? Container(
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
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10.0)),
                              borderSide: BorderSide(color: Colors.green.withOpacity(0.4), width: 3.0)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10.0)),
                              borderSide: BorderSide(color: Colors.green, width: 4.0)),
                          labelText: AppLocals.current.playerInputAppId,
                          labelStyle: TextStyle(color: Colors.grey),
                          suffixIcon: IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () {
                                _appIdController.clear();
                              })),
                      onChanged: (text) {},
                    )),
              )
            : Container(),
        widget.showFileEdited ? Padding(padding: EdgeInsets.only(bottom: 15)) : Container(),
        widget.showFileEdited
            ? Container(
                color: Colors.white,
                child: Theme(
                    data: new ThemeData(primaryColor: Colors.green),
                    child: TextField(
                      minLines: 1,
                      maxLines: 10,
                      controller: _fileIdController,
                      cursorColor: Colors.green,
                      decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10.0)),
                              borderSide: BorderSide(color: Colors.green.withOpacity(0.4), width: 3.0)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10.0)),
                              borderSide: BorderSide(color: Colors.green, width: 4.0)),
                          labelText: AppLocals.current.playerInputFileId,
                          labelStyle: TextStyle(color: Colors.grey),
                          suffixIcon: IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () {
                                _fileIdController.clear();
                              })),
                      onChanged: (text) {
                        // _fileId = text;
                      },
                    )),
              )
            : Container(),
        widget.needPisgn ? Padding(padding: EdgeInsets.only(bottom: 15)) : Container(),
        widget.needPisgn
            ? Container(
                color: Colors.white,
                child: Theme(
                    data: new ThemeData(primaryColor: Colors.green),
                    child: TextField(
                      minLines: 1,
                      maxLines: 10,
                      controller: _pSignController,
                      cursorColor: Colors.green,
                      decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10.0)),
                              borderSide: BorderSide(color: Colors.green.withOpacity(0.4), width: 3.0)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10.0)),
                              borderSide: BorderSide(color: Colors.green, width: 4.0)),
                          labelText: AppLocals.current.playerInputSign,
                          labelStyle: TextStyle(color: Colors.grey),
                          suffixIcon: IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () {
                                _pSignController.clear();
                              })),
                      onChanged: (text) {
                        // _fileId = text;
                      },
                    )),
              )
            : Container(),
        widget.needDownload
            ? Row(
                children: [
                  Checkbox(
                      value: isEnableDownload,
                      onChanged: (value) {
                        setState(() {
                          isEnableDownload = value ?? false;
                        });
                      }),
                  Text(AppLocals.current.playerIsEnableDownload)
                ],
              )
            : Container(),
        widget.needDrm
            ? Row(
          children: [
            Checkbox(
                value: isNeedDrm,
                onChanged: (value) {
                  setState(() {
                    isNeedDrm = value ?? false;
                  });
                }),
            Text("是否是 drm")
          ],
        )
            : Container(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(
        child: Text(AppLocals.current.playerInputPlaybackAdd),
      ),
      elevation: 12.0,
      contentPadding: EdgeInsets.fromLTRB(10, 20.0, 10, 0.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
      insetPadding: EdgeInsets.fromLTRB(10, 0, 10, 0),
      actions: _buildActionWidget(context),
      content: _contentWidget(context),
      scrollable: true,
    );
  }
}
