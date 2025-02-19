// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

class TXPlayerVideo extends StatefulWidget {
  final TXPlayerController controller;
  final FTXAndroidRenderViewType renderViewType;

  TXPlayerVideo({required this.controller, FTXAndroidRenderViewType? androidRenderType, Key? viewKey})
      : renderViewType = androidRenderType ?? FTXAndroidRenderViewType.TEXTURE_VIEW, super(key: viewKey);

  @override
  TXPlayerVideoState createState() => TXPlayerVideoState();
}

class TXPlayerVideoState extends State<TXPlayerVideo> {
  static const TAG = "TXPlayerVideo";

  int _viewId = -1;
  Completer<int> _viewIdCompleter = Completer();

  @override
  void initState() {
    super.initState();
    if (_viewIdCompleter.isCompleted) {
      _setPlayerView(_viewId);
    }
  }

  @override
  void didUpdateWidget(covariant TXPlayerVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_viewIdCompleter.isCompleted) {
        setState(() {
          _setPlayerView(_viewId);
        });
      } else {
        _waitViewId();
      }
    } else {
      LogUtils.i(TAG, "met a unchanged widget refresh");
      _waitViewId();
    }
  }

  Future<void> _waitViewId() async {
    await _viewIdCompleter.future;
    setState(() {
      _setPlayerView(_viewId);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return IgnorePointer(
        ignoring: true,
        child: AndroidView(
          viewType: _kFTXPlayerRenderViewType,
          layoutDirection: TextDirection.ltr,
          creationParams: {_kFTXAndroidRenderTypeKey: widget.renderViewType.index},
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onCreateAndroidView,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return IgnorePointer(
        ignoring: true,
        child: UiKitView(
            viewType: _kFTXPlayerRenderViewType,
            layoutDirection: TextDirection.ltr,
            creationParams: const {},
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: _onCreateIOSView
        ),
      );
    } else {
      throw ArgumentError("platform not support: $defaultTargetPlatform");
    }
  }

  void _onCreateAndroidView(int id) {
    if (_viewIdCompleter.isCompleted) {
      _viewIdCompleter = Completer();
    }
    _viewId = id;
    _viewIdCompleter.complete(id);
    _setPlayerView(id);
  }

  Future<void> _setPlayerView(int viewId) async {
    await widget.controller.setPlayerView(viewId);
  }

  void _onCreateIOSView(int id) {
    if (_viewIdCompleter.isCompleted) {
      _viewIdCompleter = Completer();
    }
    _viewId = id;
    _viewIdCompleter.complete(id);
    _setPlayerView(id);
  }

  Future<int> getViewId() async {
    await _viewIdCompleter.future;
    return _viewId;
  }

  void resetController() {
    _waitViewId();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
