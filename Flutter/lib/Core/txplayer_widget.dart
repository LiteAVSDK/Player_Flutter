// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

class TXPlayerVideo extends StatefulWidget {
  final TXPlayerController controller;

  TXPlayerVideo({required this.controller, Key? viewKey}) : super(key: viewKey);

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
      widget.controller.setPlayerView(_viewId);
    }
  }

  @override
  void didUpdateWidget(covariant TXPlayerVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_viewIdCompleter.isCompleted) {
        setState(() {
          widget.controller.setPlayerView(_viewId);
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
      widget.controller.setPlayerView(_viewId);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return IgnorePointer(
        ignoring: true,
        child: PlatformViewLink(
            surfaceFactory: (context, controller) {
              return AndroidViewSurface(
                controller: controller as AndroidViewController,
                gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
                hitTestBehavior: PlatformViewHitTestBehavior.opaque,
              );
            },
            onCreatePlatformView: _onCreateAndroidView,
            viewType: _kFTXPlayerRenderViewType),
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

  PlatformViewController _onCreateAndroidView(PlatformViewCreationParams params) {
    if (_viewIdCompleter.isCompleted) {
      _viewIdCompleter = Completer();
    }
    _viewId = params.id;
    _viewIdCompleter.complete(params.id);
    widget.controller.setPlayerView(params.id);
    return PlatformViewsService.initSurfaceAndroidView(
      id: params.id,
      viewType: _kFTXPlayerRenderViewType,
      layoutDirection: TextDirection.ltr,
      creationParams: {},
      creationParamsCodec: const StandardMessageCodec(),
      onFocus: () {
        params.onFocusChanged(true);
      },
    )
      ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
      ..create();
  }

  void _onCreateIOSView(int id) {
    if (_viewIdCompleter.isCompleted) {
      _viewIdCompleter = Completer();
    }
    _viewId = id;
    _viewIdCompleter.complete(id);
    widget.controller.setPlayerView(id);
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
