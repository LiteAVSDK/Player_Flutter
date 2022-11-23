// Copyright (c) 2022 Tencent. All rights reserved.
part of demo_super_player_lib;

typedef OnJumpToPipPlayer = void Function(Map params);
typedef OnPopCurrent = void Function();

///
/// 画中画控制器，单例，只能存在一个画中画
///
class TXPipController {
  static const ARGUMENT_PIP_START_TIME = "argumentStartTime";

  static TXPipController? _instance;

  static TXPipController get instance => _sharedInstance();

  /// 画中画播放器实例，同时只能存在一个
  TXPipPlayerData? _playerData;
  final Map<String, dynamic> _extParams = {};
  TXPipPlayerRestorePage? _onPipEnterListener;
  OnJumpToPipPlayer? _onJumpToPipPlayer;
  StreamSubscription? _pipEventSubscription;

  /// TXPipController
  static TXPipController _sharedInstance() {
    _instance ??= TXPipController._internal();
    return _instance!;
  }

  TXPipController._internal();

  Future<int> enterPip(TXPlayerController playerController, BuildContext context,
      {String? backIconForAndroid,
      String? playIconForAndroid,
      String? pauseIconForAndroid,
      String? forwardIconForAndroid}) async {
    if (_playerData != null) {
      await exitAndReleaseCurrentPip();
    }
    _playerData = TXPipPlayerData(playerController);
    _pipEventSubscription = SuperPlayerPlugin.instance.onExtraEventBroadcast.listen((event) async {
      int eventCode = event["event"];
      if ((Platform.isIOS && eventCode == TXVodPlayEvent.EVENT_PIP_MODE_ALREADY_ENTER) ||
          (Platform.isAndroid && eventCode == TXVodPlayEvent.EVENT_PIP_MODE_REQUEST_START)) {
        _onPipEnterListener?.onNeedSavePipPageState(_extParams);
        Navigator.of(context).pop();
      } else if ((Platform.isIOS && eventCode == TXVodPlayEvent.EVENT_IOS_PIP_MODE_WILL_EXIT)
      || (Platform.isAndroid && eventCode == TXVodPlayEvent.EVENT_PIP_MODE_ALREADY_EXIT)) {
        await exitAndReleaseCurrentPip();
      } else if (eventCode == TXVodPlayEvent.EVENT_IOS_PIP_MODE_RESTORE_UI) {
        _extParams[ARGUMENT_PIP_START_TIME] = event["playTime"];
        await exitAndReleaseCurrentPip();
        _onJumpToPipPlayer?.call(_extParams);
      } else if(eventCode < 0) {
        // pip enter failed
        _pipEventSubscription?.cancel();
        _playerData = null;
      }
    });
    int enterResult = await _playerData!._playerController.enterPictureInPictureMode(
        backIconForAndroid: backIconForAndroid,
        playIconForAndroid: playIconForAndroid,
        pauseIconForAndroid: pauseIconForAndroid,
        forwardIconForAndroid: forwardIconForAndroid);
    if (enterResult != TXVodPlayEvent.NO_ERROR) {
      _playerData = null;
      _pipEventSubscription?.cancel();
    }
    return enterResult;
  }

  Future<void> exitAndReleaseCurrentPip() async {
    if (null != _playerData && _playerData?._playerController != null) {
      if(Platform.isAndroid) {
        await _playerData?._playerController.exitPictureInPictureMode();
      }
      await _playerData?._playerController.stop();
      _playerData?._playerController.dispose();
    }
    _pipEventSubscription?.cancel();
    _playerData = null;
  }

  /// 传入的controller是否处于画中画模式
  bool isPlayerInPip(TXPlayerController playerController) {
    if (null != _playerData) {
      return _playerData!._playerController == playerController;
    }
    return false;
  }

  void setPipPlayerPage(Type a, TXPipPlayerRestorePage listener) {
    _onPipEnterListener = listener;
  }

  void setNavigatorHandle(OnJumpToPipPlayer onJumpToPipPlayer) {
    _onJumpToPipPlayer = onJumpToPipPlayer;
  }
}

abstract class TXPipPlayerRestorePage {
  /// 当需要保存画中画界面相关元素的时候，会回调该方法
  void onNeedSavePipPageState(Map<String, dynamic> params);
}
