
// Copyright (c) 2022 Tencent. All rights reserved.
part of SuperPlayer;

/// pigeon原始原件，由此文件生成messages原生通信代码
/// 生成命令如下，使用生成命令的时候，需要实现注释掉以上两个import导入
class PlayerMsg {
  PlayerMsg({
    this.playerId,
  });

  int? playerId;

  Object encode() {
    return <Object?>[
      playerId,
    ];
  }

  static PlayerMsg decode(Object result) {
    result as List<Object?>;
    return PlayerMsg(
      playerId: result[0] as int?,
    );
  }
}

class LicenseMsg {
  LicenseMsg({
    this.licenseUrl,
    this.licenseKey,
  });

  String? licenseUrl;

  String? licenseKey;

  Object encode() {
    return <Object?>[
      licenseUrl,
      licenseKey,
    ];
  }

  static LicenseMsg decode(Object result) {
    result as List<Object?>;
    return LicenseMsg(
      licenseUrl: result[0] as String?,
      licenseKey: result[1] as String?,
    );
  }
}

class TXPlayInfoParamsPlayerMsg {
  TXPlayInfoParamsPlayerMsg({
    this.playerId,
    this.appId,
    this.fileId,
    this.psign,
  });

  int? playerId;

  int? appId;

  String? fileId;

  String? psign;

  Object encode() {
    return <Object?>[
      playerId,
      appId,
      fileId,
      psign,
    ];
  }

  static TXPlayInfoParamsPlayerMsg decode(Object result) {
    result as List<Object?>;
    return TXPlayInfoParamsPlayerMsg(
      playerId: result[0] as int?,
      appId: result[1] as int?,
      fileId: result[2] as String?,
      psign: result[3] as String?,
    );
  }
}

class PipParamsPlayerMsg {
  PipParamsPlayerMsg({
    this.playerId,
    this.backIconForAndroid,
    this.playIconForAndroid,
    this.pauseIconForAndroid,
    this.forwardIconForAndroid,
  });

  int? playerId;

  String? backIconForAndroid;

  String? playIconForAndroid;

  String? pauseIconForAndroid;

  String? forwardIconForAndroid;

  Object encode() {
    return <Object?>[
      playerId,
      backIconForAndroid,
      playIconForAndroid,
      pauseIconForAndroid,
      forwardIconForAndroid,
    ];
  }

  static PipParamsPlayerMsg decode(Object result) {
    result as List<Object?>;
    return PipParamsPlayerMsg(
      playerId: result[0] as int?,
      backIconForAndroid: result[1] as String?,
      playIconForAndroid: result[2] as String?,
      pauseIconForAndroid: result[3] as String?,
      forwardIconForAndroid: result[4] as String?,
    );
  }
}

class StringListPlayerMsg {
  StringListPlayerMsg({
    this.playerId,
    this.vvtUrl,
    this.imageUrls,
  });

  int? playerId;

  String? vvtUrl;

  List<String?>? imageUrls;

  Object encode() {
    return <Object?>[
      playerId,
      vvtUrl,
      imageUrls,
    ];
  }

  static StringListPlayerMsg decode(Object result) {
    result as List<Object?>;
    return StringListPlayerMsg(
      playerId: result[0] as int?,
      vvtUrl: result[1] as String?,
      imageUrls: (result[2] as List<Object?>?)?.cast<String?>(),
    );
  }
}

class BoolPlayerMsg {
  BoolPlayerMsg({
    this.playerId,
    this.value,
  });

  int? playerId;

  bool? value;

  Object encode() {
    return <Object?>[
      playerId,
      value,
    ];
  }

  static BoolPlayerMsg decode(Object result) {
    result as List<Object?>;
    return BoolPlayerMsg(
      playerId: result[0] as int?,
      value: result[1] as bool?,
    );
  }
}

class StringIntPlayerMsg {
  StringIntPlayerMsg({
    this.playerId,
    this.strValue,
    this.intValue,
  });

  int? playerId;

  String? strValue;

  int? intValue;

  Object encode() {
    return <Object?>[
      playerId,
      strValue,
      intValue,
    ];
  }

  static StringIntPlayerMsg decode(Object result) {
    result as List<Object?>;
    return StringIntPlayerMsg(
      playerId: result[0] as int?,
      strValue: result[1] as String?,
      intValue: result[2] as int?,
    );
  }
}

class StringPlayerMsg {
  StringPlayerMsg({
    this.playerId,
    this.value,
  });

  int? playerId;

  String? value;

  Object encode() {
    return <Object?>[
      playerId,
      value,
    ];
  }

  static StringPlayerMsg decode(Object result) {
    result as List<Object?>;
    return StringPlayerMsg(
      playerId: result[0] as int?,
      value: result[1] as String?,
    );
  }
}

class DoublePlayerMsg {
  DoublePlayerMsg({
    this.playerId,
    this.value,
  });

  int? playerId;

  double? value;

  Object encode() {
    return <Object?>[
      playerId,
      value,
    ];
  }

  static DoublePlayerMsg decode(Object result) {
    result as List<Object?>;
    return DoublePlayerMsg(
      playerId: result[0] as int?,
      value: result[1] as double?,
    );
  }
}

class IntPlayerMsg {
  IntPlayerMsg({
    this.playerId,
    this.value,
  });

  int? playerId;

  int? value;

  Object encode() {
    return <Object?>[
      playerId,
      value,
    ];
  }

  static IntPlayerMsg decode(Object result) {
    result as List<Object?>;
    return IntPlayerMsg(
      playerId: result[0] as int?,
      value: result[1] as int?,
    );
  }
}

class FTXVodPlayConfigPlayerMsg {
  FTXVodPlayConfigPlayerMsg({
    this.playerId,
    this.connectRetryCount,
    this.connectRetryInterval,
    this.timeout,
    this.playerType,
    this.headers,
    this.enableAccurateSeek,
    this.autoRotate,
    this.smoothSwitchBitrate,
    this.cacheMp4ExtName,
    this.progressInterval,
    this.maxBufferSize,
    this.maxPreloadSize,
    this.firstStartPlayBufferTime,
    this.nextStartPlayBufferTime,
    this.overlayKey,
    this.overlayIv,
    this.extInfoMap,
    this.enableRenderProcess,
    this.preferredResolution,
  });

  int? playerId;

  int? connectRetryCount;

  int? connectRetryInterval;

  int? timeout;

  int? playerType;

  Map<String?, String?>? headers;

  bool? enableAccurateSeek;

  bool? autoRotate;

  bool? smoothSwitchBitrate;

  String? cacheMp4ExtName;

  int? progressInterval;

  int? maxBufferSize;

  int? maxPreloadSize;

  int? firstStartPlayBufferTime;

  int? nextStartPlayBufferTime;

  String? overlayKey;

  String? overlayIv;

  Map<String?, Object?>? extInfoMap;

  bool? enableRenderProcess;

  int? preferredResolution;

  Object encode() {
    return <Object?>[
      playerId,
      connectRetryCount,
      connectRetryInterval,
      timeout,
      playerType,
      headers,
      enableAccurateSeek,
      autoRotate,
      smoothSwitchBitrate,
      cacheMp4ExtName,
      progressInterval,
      maxBufferSize,
      maxPreloadSize,
      firstStartPlayBufferTime,
      nextStartPlayBufferTime,
      overlayKey,
      overlayIv,
      extInfoMap,
      enableRenderProcess,
      preferredResolution,
    ];
  }

  static FTXVodPlayConfigPlayerMsg decode(Object result) {
    result as List<Object?>;
    return FTXVodPlayConfigPlayerMsg(
      playerId: result[0] as int?,
      connectRetryCount: result[1] as int?,
      connectRetryInterval: result[2] as int?,
      timeout: result[3] as int?,
      playerType: result[4] as int?,
      headers: (result[5] as Map<Object?, Object?>?)?.cast<String?, String?>(),
      enableAccurateSeek: result[6] as bool?,
      autoRotate: result[7] as bool?,
      smoothSwitchBitrate: result[8] as bool?,
      cacheMp4ExtName: result[9] as String?,
      progressInterval: result[10] as int?,
      maxBufferSize: result[11] as int?,
      maxPreloadSize: result[12] as int?,
      firstStartPlayBufferTime: result[13] as int?,
      nextStartPlayBufferTime: result[14] as int?,
      overlayKey: result[15] as String?,
      overlayIv: result[16] as String?,
      extInfoMap: (result[17] as Map<Object?, Object?>?)?.cast<String?, Object?>(),
      enableRenderProcess: result[18] as bool?,
      preferredResolution: result[19] as int?,
    );
  }
}

class FTXLivePlayConfigPlayerMsg {
  FTXLivePlayConfigPlayerMsg({
    this.playerId,
    this.cacheTime,
    this.maxAutoAdjustCacheTime,
    this.minAutoAdjustCacheTime,
    this.videoBlockThreshold,
    this.connectRetryCount,
    this.connectRetryInterval,
    this.autoAdjustCacheTime,
    this.enableAec,
    this.enableMessage,
    this.enableMetaData,
    this.flvSessionKey,
  });

  int? playerId;

  double? cacheTime;

  double? maxAutoAdjustCacheTime;

  double? minAutoAdjustCacheTime;

  int? videoBlockThreshold;

  int? connectRetryCount;

  int? connectRetryInterval;

  bool? autoAdjustCacheTime;

  bool? enableAec;

  bool? enableMessage;

  bool? enableMetaData;

  String? flvSessionKey;

  Object encode() {
    return <Object?>[
      playerId,
      cacheTime,
      maxAutoAdjustCacheTime,
      minAutoAdjustCacheTime,
      videoBlockThreshold,
      connectRetryCount,
      connectRetryInterval,
      autoAdjustCacheTime,
      enableAec,
      enableMessage,
      enableMetaData,
      flvSessionKey,
    ];
  }

  static FTXLivePlayConfigPlayerMsg decode(Object result) {
    result as List<Object?>;
    return FTXLivePlayConfigPlayerMsg(
      playerId: result[0] as int?,
      cacheTime: result[1] as double?,
      maxAutoAdjustCacheTime: result[2] as double?,
      minAutoAdjustCacheTime: result[3] as double?,
      videoBlockThreshold: result[4] as int?,
      connectRetryCount: result[5] as int?,
      connectRetryInterval: result[6] as int?,
      autoAdjustCacheTime: result[7] as bool?,
      enableAec: result[8] as bool?,
      enableMessage: result[9] as bool?,
      enableMetaData: result[10] as bool?,
      flvSessionKey: result[11] as String?,
    );
  }
}

class TXVodDownloadMediaMsg {
  TXVodDownloadMediaMsg({
    this.playPath,
    this.progress,
    this.downloadState,
    this.userName,
    this.duration,
    this.playableDuration,
    this.size,
    this.downloadSize,
    this.url,
    this.appId,
    this.fileId,
    this.pSign,
    this.quality,
    this.token,
    this.speed,
    this.isResourceBroken,
  });

  /// 缓存地址
  String? playPath;

  /// 下载进度
  double? progress;

  /// 下载状态
  int? downloadState;

  /// 账户名称,用于url下载设置账户名称
  String? userName;

  /// 总时长
  int? duration;

  /// 已下载的可播放时长
  int? playableDuration;

  /// 文件总大小，单位：byte
  int? size;

  /// 已下载大小，单位：byte
  int? downloadSize;

  /// 需要下载的视频url，url下载必填
  /// <h1>
  /// url下载不支持嵌套m3u8和mp4下载
  /// </h1>
  String? url;

  /// 下载文件对应的appId，fileId下载必填
  int? appId;

  /// 下载文件Id，fileId下载必填
  String? fileId;

  /// 加密签名，加密视频必填
  String? pSign;

  /// 清晰度ID
  int? quality;

  /// 加密token
  String? token;

  /// 下载速度，单位：KByte/秒
  int? speed;

  /// 资源是否已损坏, 如：资源被删除了
  bool? isResourceBroken;

  Object encode() {
    return <Object?>[
      playPath,
      progress,
      downloadState,
      userName,
      duration,
      playableDuration,
      size,
      downloadSize,
      url,
      appId,
      fileId,
      pSign,
      quality,
      token,
      speed,
      isResourceBroken,
    ];
  }

  static TXVodDownloadMediaMsg decode(Object result) {
    result as List<Object?>;
    return TXVodDownloadMediaMsg(
      playPath: result[0] as String?,
      progress: result[1] as double?,
      downloadState: result[2] as int?,
      userName: result[3] as String?,
      duration: result[4] as int?,
      playableDuration: result[5] as int?,
      size: result[6] as int?,
      downloadSize: result[7] as int?,
      url: result[8] as String?,
      appId: result[9] as int?,
      fileId: result[10] as String?,
      pSign: result[11] as String?,
      quality: result[12] as int?,
      token: result[13] as String?,
      speed: result[14] as int?,
      isResourceBroken: result[15] as bool?,
    );
  }
}

class TXDownloadListMsg {
  TXDownloadListMsg({
    this.infoList,
  });

  List<TXVodDownloadMediaMsg?>? infoList;

  Object encode() {
    return <Object?>[
      infoList,
    ];
  }

  static TXDownloadListMsg decode(Object result) {
    result as List<Object?>;
    return TXDownloadListMsg(
      infoList: (result[0] as List<Object?>?)?.cast<TXVodDownloadMediaMsg?>(),
    );
  }
}

class UInt8ListMsg {
  UInt8ListMsg({
    this.value,
  });

  Uint8List? value;

  Object encode() {
    return <Object?>[
      value,
    ];
  }

  static UInt8ListMsg decode(Object result) {
    result as List<Object?>;
    return UInt8ListMsg(
      value: result[0] as Uint8List?,
    );
  }
}

class ListMsg {
  ListMsg({
    this.value,
  });

  List<Object?>? value;

  Object encode() {
    return <Object?>[
      value,
    ];
  }

  static ListMsg decode(Object result) {
    result as List<Object?>;
    return ListMsg(
      value: result[0] as List<Object?>?,
    );
  }
}

class BoolMsg {
  BoolMsg({
    this.value,
  });

  bool? value;

  Object encode() {
    return <Object?>[
      value,
    ];
  }

  static BoolMsg decode(Object result) {
    result as List<Object?>;
    return BoolMsg(
      value: result[0] as bool?,
    );
  }
}

class IntMsg {
  IntMsg({
    this.value,
  });

  int? value;

  Object encode() {
    return <Object?>[
      value,
    ];
  }

  static IntMsg decode(Object result) {
    result as List<Object?>;
    return IntMsg(
      value: result[0] as int?,
    );
  }
}

class StringMsg {
  StringMsg({
    this.value,
  });

  String? value;

  Object encode() {
    return <Object?>[
      value,
    ];
  }

  static StringMsg decode(Object result) {
    result as List<Object?>;
    return StringMsg(
      value: result[0] as String?,
    );
  }
}

class DoubleMsg {
  DoubleMsg({
    this.value,
  });

  double? value;

  Object encode() {
    return <Object?>[
      value,
    ];
  }

  static DoubleMsg decode(Object result) {
    result as List<Object?>;
    return DoubleMsg(
      value: result[0] as double?,
    );
  }
}

class PreLoadMsg {
  PreLoadMsg({
    this.playUrl,
    this.preloadSizeMB,
    this.preferredResolution,
  });

  String? playUrl;

  int? preloadSizeMB;

  int? preferredResolution;

  Object encode() {
    return <Object?>[
      playUrl,
      preloadSizeMB,
      preferredResolution,
    ];
  }

  static PreLoadMsg decode(Object result) {
    result as List<Object?>;
    return PreLoadMsg(
      playUrl: result[0] as String?,
      preloadSizeMB: result[1] as int?,
      preferredResolution: result[2] as int?,
    );
  }
}

class MapMsg {
  MapMsg({
    this.map,
  });

  Map<String?, String?>? map;

  Object encode() {
    return <Object?>[
      map,
    ];
  }

  static MapMsg decode(Object result) {
    result as List<Object?>;
    return MapMsg(
      map: (result[0] as Map<Object?, Object?>?)?.cast<String?, String?>(),
    );
  }
}

class _TXFlutterSuperPlayerPluginAPICodec extends StandardMessageCodec {
  const _TXFlutterSuperPlayerPluginAPICodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is BoolMsg) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else if (value is IntMsg) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else if (value is LicenseMsg) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    } else if (value is PlayerMsg) {
      buffer.putUint8(131);
      writeValue(buffer, value.encode());
    } else if (value is StringMsg) {
      buffer.putUint8(132);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128: 
        return BoolMsg.decode(readValue(buffer)!);
      case 129: 
        return IntMsg.decode(readValue(buffer)!);
      case 130: 
        return LicenseMsg.decode(readValue(buffer)!);
      case 131: 
        return PlayerMsg.decode(readValue(buffer)!);
      case 132: 
        return StringMsg.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class TXFlutterSuperPlayerPluginAPI {
  /// Constructor for [TXFlutterSuperPlayerPluginAPI].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  TXFlutterSuperPlayerPluginAPI({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = _TXFlutterSuperPlayerPluginAPICodec();

  Future<StringMsg> getPlatformVersion() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterSuperPlayerPluginAPI.getPlatformVersion', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as StringMsg?)!;
    }
  }

  /// 创建点播播放器
  Future<PlayerMsg> createVodPlayer() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterSuperPlayerPluginAPI.createVodPlayer', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as PlayerMsg?)!;
    }
  }

  /// 创建直播播放器
  Future<PlayerMsg> createLivePlayer() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterSuperPlayerPluginAPI.createLivePlayer', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as PlayerMsg?)!;
    }
  }

  /// 开关log输出
  Future<void> setConsoleEnabled(BoolMsg arg_enabled) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterSuperPlayerPluginAPI.setConsoleEnabled', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_enabled]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 释放播放器资源
  Future<void> releasePlayer(PlayerMsg arg_playerId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterSuperPlayerPluginAPI.releasePlayer', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerId]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 设置播放引擎的最大缓存大小。设置后会根据设定值自动清理Cache目录的文件
  /// @param size 最大缓存大小（单位：MB)
  Future<void> setGlobalMaxCacheSize(IntMsg arg_size) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterSuperPlayerPluginAPI.setGlobalMaxCacheSize', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_size]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 在短视频播放场景中，视频文件的本地缓存是很刚需的一个特性，对于普通用户而言，一个已经看过的视频再次观看时，不应该再消耗一次流量。
  ///  @格式支持：SDK 支持 HLS(m3u8) 和 MP4 两种常见点播格式的缓存功能。
  ///  @开启时机：SDK 并不默认开启缓存功能，对于用户回看率不高的场景，也并不推荐您开启此功能。
  ///  @开启方式：全局生效，在使用播放器开启。开启此功能需要配置两个参数：本地缓存目录及缓存大小。
  ///
  /// 该缓存路径默认设置到app沙盒目录下，postfixPath只需要传递相对缓存目录即可，不需要传递整个绝对路径。
  /// e.g. postfixPath = 'testCache'
  /// Android 平台：视频将会缓存到sdcard的Android/data/your-pkg-name/files/testCache 目录。
  /// iOS 平台：视频将会缓存到沙盒的Documents/testCache 目录。
  /// @param postfixPath 缓存目录
  /// @return true 设置成功 false 设置失败
  Future<BoolMsg> setGlobalCacheFolderPath(StringMsg arg_postfixPath) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterSuperPlayerPluginAPI.setGlobalCacheFolderPath', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_postfixPath]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as BoolMsg?)!;
    }
  }

  /// 设置全局license
  Future<void> setGlobalLicense(LicenseMsg arg_licenseMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterSuperPlayerPluginAPI.setGlobalLicense', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_licenseMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 设置log输出级别 [TXLogLevel]
  Future<void> setLogLevel(IntMsg arg_logLevel) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterSuperPlayerPluginAPI.setLogLevel', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_logLevel]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 获取依赖Native端的 LiteAVSDK 的版本
  Future<StringMsg> getLiteAVSDKVersion() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterSuperPlayerPluginAPI.getLiteAVSDKVersion', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as StringMsg?)!;
    }
  }

  ///
  /// 设置 liteav SDK 接入的环境。
  /// 腾讯云在全球各地区部署的环境，按照各地区政策法规要求，需要接入不同地区接入点。
  ///
  /// @param envConfig 需要接入的环境，SDK 默认接入的环境是：默认正式环境。
  /// @return 0：成功；其他：错误
  /// @note 目标市场为中国大陆的客户请不要调用此接口，如果目标市场为海外用户，请通过技术支持联系我们，了解 env_config 的配置方法，以确保 App 遵守 GDPR 标准。
  ///
  Future<IntMsg> setGlobalEnv(StringMsg arg_envConfig) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterSuperPlayerPluginAPI.setGlobalEnv', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_envConfig]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as IntMsg?)!;
    }
  }

  ///
  /// 开始监听设备旋转方向，开启之后，如果设备自动旋转打开，播放器会自动根据当前设备方向来旋转视频方向。
  /// <h1>该接口目前只适用安卓端，IOS端会自动开启该能力</h1>
  /// 在调用该接口前，请务必向用户告知隐私风险。
  /// 如有需要，请确认是否有获取旋转sensor的权限。
  /// @return true : 开启成功
  ///         false : 开启失败，如开启过早，还未等到上下文初始化、获取sensor失败等原因
  Future<BoolMsg> startVideoOrientationService() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterSuperPlayerPluginAPI.startVideoOrientationService', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as BoolMsg?)!;
    }
  }
}

class _TXFlutterNativeAPICodec extends StandardMessageCodec {
  const _TXFlutterNativeAPICodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is DoubleMsg) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else if (value is IntMsg) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128: 
        return DoubleMsg.decode(readValue(buffer)!);
      case 129: 
        return IntMsg.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class TXFlutterNativeAPI {
  /// Constructor for [TXFlutterNativeAPI].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  TXFlutterNativeAPI({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = _TXFlutterNativeAPICodec();

  /// 修改当前界面亮度
  Future<void> setBrightness(DoubleMsg arg_brightness) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterNativeAPI.setBrightness', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_brightness]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 恢复当前界面亮度
  Future<void> restorePageBrightness() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterNativeAPI.restorePageBrightness', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 获得当前界面亮度 0.0 ~ 1.0
  Future<DoubleMsg> getBrightness() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterNativeAPI.getBrightness', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as DoubleMsg?)!;
    }
  }

  /// 获取系统界面亮度，IOS系统与界面亮度一致，安卓可能会有差异
  Future<DoubleMsg> getSysBrightness() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterNativeAPI.getSysBrightness', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as DoubleMsg?)!;
    }
  }

  /// 设置当前系统音量，0.0 ~ 1.0
  Future<void> setSystemVolume(DoubleMsg arg_volume) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterNativeAPI.setSystemVolume', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_volume]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 获得当前系统音量，范围：0.0 ~ 1.0
  Future<DoubleMsg> getSystemVolume() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterNativeAPI.getSystemVolume', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as DoubleMsg?)!;
    }
  }

  /// 释放音频焦点，只用于安卓端
  Future<void> abandonAudioFocus() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterNativeAPI.abandonAudioFocus', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 请求获得音频焦点，只用于安卓端
  Future<void> requestAudioFocus() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterNativeAPI.requestAudioFocus', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 当前设备是否支持画中画模式
  /// @return [TXVodPlayEvent]
  ///  0 可开启画中画模式
  ///  -101  android版本过低
  ///  -102  画中画权限关闭/设备不支持画中画
  ///  -103  当前界面已销毁
  Future<IntMsg> isDeviceSupportPip() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterNativeAPI.isDeviceSupportPip', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as IntMsg?)!;
    }
  }
}

class _TXFlutterVodPlayerApiCodec extends StandardMessageCodec {
  const _TXFlutterVodPlayerApiCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is BoolMsg) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else if (value is BoolPlayerMsg) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else if (value is DoubleMsg) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    } else if (value is DoublePlayerMsg) {
      buffer.putUint8(131);
      writeValue(buffer, value.encode());
    } else if (value is FTXVodPlayConfigPlayerMsg) {
      buffer.putUint8(132);
      writeValue(buffer, value.encode());
    } else if (value is IntMsg) {
      buffer.putUint8(133);
      writeValue(buffer, value.encode());
    } else if (value is IntPlayerMsg) {
      buffer.putUint8(134);
      writeValue(buffer, value.encode());
    } else if (value is ListMsg) {
      buffer.putUint8(135);
      writeValue(buffer, value.encode());
    } else if (value is PipParamsPlayerMsg) {
      buffer.putUint8(136);
      writeValue(buffer, value.encode());
    } else if (value is PlayerMsg) {
      buffer.putUint8(137);
      writeValue(buffer, value.encode());
    } else if (value is StringListPlayerMsg) {
      buffer.putUint8(138);
      writeValue(buffer, value.encode());
    } else if (value is StringPlayerMsg) {
      buffer.putUint8(139);
      writeValue(buffer, value.encode());
    } else if (value is TXPlayInfoParamsPlayerMsg) {
      buffer.putUint8(140);
      writeValue(buffer, value.encode());
    } else if (value is UInt8ListMsg) {
      buffer.putUint8(141);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128: 
        return BoolMsg.decode(readValue(buffer)!);
      case 129: 
        return BoolPlayerMsg.decode(readValue(buffer)!);
      case 130: 
        return DoubleMsg.decode(readValue(buffer)!);
      case 131: 
        return DoublePlayerMsg.decode(readValue(buffer)!);
      case 132: 
        return FTXVodPlayConfigPlayerMsg.decode(readValue(buffer)!);
      case 133: 
        return IntMsg.decode(readValue(buffer)!);
      case 134: 
        return IntPlayerMsg.decode(readValue(buffer)!);
      case 135: 
        return ListMsg.decode(readValue(buffer)!);
      case 136: 
        return PipParamsPlayerMsg.decode(readValue(buffer)!);
      case 137: 
        return PlayerMsg.decode(readValue(buffer)!);
      case 138: 
        return StringListPlayerMsg.decode(readValue(buffer)!);
      case 139: 
        return StringPlayerMsg.decode(readValue(buffer)!);
      case 140: 
        return TXPlayInfoParamsPlayerMsg.decode(readValue(buffer)!);
      case 141: 
        return UInt8ListMsg.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class TXFlutterVodPlayerApi {
  /// Constructor for [TXFlutterVodPlayerApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  TXFlutterVodPlayerApi({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = _TXFlutterVodPlayerApiCodec();

  /// 播放器初始化，创建共享纹理、初始化播放器
  /// @param onlyAudio 是否是纯音频模式
  Future<IntMsg> initialize(BoolPlayerMsg arg_onlyAudio) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.initialize', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_onlyAudio]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as IntMsg?)!;
    }
  }

  /// 通过url开始播放视频
  /// 10.7版本开始，startPlay变更为startVodPlay，需要通过 {@link SuperPlayerPlugin#setGlobalLicense} 设置 Licence 后方可成功播放，
  /// 否则将播放失败（黑屏），全局仅设置一次即可。直播 Licence、短视频 Licence 和视频播放 Licence 均可使用，若您暂未获取上述 Licence ，
  /// 可[快速免费申请测试版 Licence](https://cloud.tencent.com/act/event/License) 以正常播放，正式版 License 需[购买]
  /// (https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96.B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license)。
  /// @param url : 视频播放地址
  /// return 是否播放成功
  Future<BoolMsg> startVodPlay(StringPlayerMsg arg_url) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.startVodPlay', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_url]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as BoolMsg?)!;
    }
  }

  /// 通过fileId播放视频
  /// 10.7版本开始，startPlayWithParams变更为startVodPlayWithParams，需要通过 {@link SuperPlayerPlugin#setGlobalLicense} 设置 Licence 后方可成功播放，
  /// 否则将播放失败（黑屏），全局仅设置一次即可。直播 Licence、短视频 Licence 和视频播放 Licence 均可使用，若您暂未获取上述 Licence ，
  /// 可[快速免费申请测试版 Licence](https://cloud.tencent.com/act/event/License) 以正常播放，正式版 License 需[购买]
  /// (https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96.B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license)。
  /// @params : 见[TXPlayInfoParams]
  /// return 是否播放成功
  Future<void> startVodPlayWithParams(TXPlayInfoParamsPlayerMsg arg_params) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.startVodPlayWithParams', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_params]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 设置是否自动播放
  Future<void> setAutoPlay(BoolPlayerMsg arg_isAutoPlay) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.setAutoPlay', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_isAutoPlay]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 停止播放
  /// return 是否停止成功
  Future<BoolMsg> stop(BoolPlayerMsg arg_isNeedClear) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.stop', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_isNeedClear]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as BoolMsg?)!;
    }
  }

  /// 视频是否处于正在播放中
  Future<BoolMsg> isPlaying(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.isPlaying', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as BoolMsg?)!;
    }
  }

  /// 视频暂停，必须在播放器开始播放的时候调用
  Future<void> pause(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.pause', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 继续播放，在暂停的时候调用
  Future<void> resume(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.resume', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 设置是否静音
  Future<void> setMute(BoolPlayerMsg arg_mute) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.setMute', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_mute]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 设置是否循环播放
  Future<void> setLoop(BoolPlayerMsg arg_loop) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.setLoop', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_loop]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 将视频播放进度定位到指定的进度进行播放
  /// progress 要定位的视频时间，单位 秒
  Future<void> seek(DoublePlayerMsg arg_progress) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.seek', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_progress]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 设置播放速率，默认速率 1
  Future<void> setRate(DoublePlayerMsg arg_rate) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.setRate', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_rate]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 获得播放视频解析出来的码率信息
  /// return List<Map>
  /// Bitrate键值：index 码率序号，width 码率对应视频宽度，
  ///             height 码率对应视频高度, bitrate 码率值
  Future<ListMsg> getSupportedBitrate(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.getSupportedBitrate', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as ListMsg?)!;
    }
  }

  /// 获得当前设置的码率序号
  Future<IntMsg> getBitrateIndex(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.getBitrateIndex', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as IntMsg?)!;
    }
  }

  /// 设置码率序号
  Future<void> setBitrateIndex(IntPlayerMsg arg_index) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.setBitrateIndex', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_index]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 设置视频播放开始时间，单位 秒
  Future<void> setStartTime(DoublePlayerMsg arg_startTime) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.setStartTime', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_startTime]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 设置视频声音 0~100
  Future<void> setAudioPlayOutVolume(IntPlayerMsg arg_volume) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.setAudioPlayOutVolume', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_volume]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 请求获得音频焦点
  Future<BoolMsg> setRequestAudioFocus(BoolPlayerMsg arg_focus) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.setRequestAudioFocus', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_focus]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as BoolMsg?)!;
    }
  }

  /// 设置播放器配置
  /// config @see [FTXVodPlayConfigPlayerMsg]
  Future<void> setConfig(FTXVodPlayConfigPlayerMsg arg_config) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.setConfig', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_config]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 获得当前已经播放的时间，单位 秒
  Future<DoubleMsg> getCurrentPlaybackTime(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.getCurrentPlaybackTime', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as DoubleMsg?)!;
    }
  }

  /// 获得当前视频已缓存的时间
  Future<DoubleMsg> getBufferDuration(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.getBufferDuration', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as DoubleMsg?)!;
    }
  }

  /// 获得当前视频的可播放时间
  Future<DoubleMsg> getPlayableDuration(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.getPlayableDuration', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as DoubleMsg?)!;
    }
  }

  /// 获得当前播放视频的宽度
  Future<IntMsg> getWidth(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.getWidth', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as IntMsg?)!;
    }
  }

  /// 获得当前播放视频的高度
  Future<IntMsg> getHeight(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.getHeight', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as IntMsg?)!;
    }
  }

  /// 设置播放视频的token
  Future<void> setToken(StringPlayerMsg arg_token) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.setToken', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_token]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 当前播放的视频是否循环播放
  Future<BoolMsg> isLoop(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.isLoop', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as BoolMsg?)!;
    }
  }

  /// 开启/关闭硬件编码
  Future<BoolMsg> enableHardwareDecode(BoolPlayerMsg arg_enable) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.enableHardwareDecode', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_enable]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as BoolMsg?)!;
    }
  }

  /// 进入画中画模式，进入画中画模式，需要适配画中画模式的界面，安卓只支持7.0以上机型
  /// <h1>
  /// 由于android系统限制，传递的图标大小不得超过1M，否则无法显示
  /// </h1>
  /// @param backIcon playIcon pauseIcon forwardIcon 为播放后退、播放、暂停、前进的图标，如果赋值的话，将会使用传递的图标，否则
  /// 使用系统默认图标，只支持flutter本地资源图片，传递的时候，与flutter使用图片资源一致，例如： images/back_icon.png
  Future<IntMsg> enterPictureInPictureMode(PipParamsPlayerMsg arg_pipParamsMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.enterPictureInPictureMode', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_pipParamsMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as IntMsg?)!;
    }
  }

  /// 退出画中画，如果该播放器处于画中画模式
  Future<void> exitPictureInPictureMode(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.exitPictureInPictureMode', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<void> initImageSprite(StringListPlayerMsg arg_spriteInfo) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.initImageSprite', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_spriteInfo]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  Future<UInt8ListMsg> getImageSprite(DoublePlayerMsg arg_time) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.getImageSprite', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_time]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as UInt8ListMsg?)!;
    }
  }

  /// 获取总时长
  Future<DoubleMsg> getDuration(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterVodPlayerApi.getDuration', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as DoubleMsg?)!;
    }
  }
}

class _TXFlutterLivePlayerApiCodec extends StandardMessageCodec {
  const _TXFlutterLivePlayerApiCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is BoolMsg) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else if (value is BoolPlayerMsg) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else if (value is DoublePlayerMsg) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    } else if (value is FTXLivePlayConfigPlayerMsg) {
      buffer.putUint8(131);
      writeValue(buffer, value.encode());
    } else if (value is IntMsg) {
      buffer.putUint8(132);
      writeValue(buffer, value.encode());
    } else if (value is IntPlayerMsg) {
      buffer.putUint8(133);
      writeValue(buffer, value.encode());
    } else if (value is PipParamsPlayerMsg) {
      buffer.putUint8(134);
      writeValue(buffer, value.encode());
    } else if (value is PlayerMsg) {
      buffer.putUint8(135);
      writeValue(buffer, value.encode());
    } else if (value is StringIntPlayerMsg) {
      buffer.putUint8(136);
      writeValue(buffer, value.encode());
    } else if (value is StringPlayerMsg) {
      buffer.putUint8(137);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128: 
        return BoolMsg.decode(readValue(buffer)!);
      case 129: 
        return BoolPlayerMsg.decode(readValue(buffer)!);
      case 130: 
        return DoublePlayerMsg.decode(readValue(buffer)!);
      case 131: 
        return FTXLivePlayConfigPlayerMsg.decode(readValue(buffer)!);
      case 132: 
        return IntMsg.decode(readValue(buffer)!);
      case 133: 
        return IntPlayerMsg.decode(readValue(buffer)!);
      case 134: 
        return PipParamsPlayerMsg.decode(readValue(buffer)!);
      case 135: 
        return PlayerMsg.decode(readValue(buffer)!);
      case 136: 
        return StringIntPlayerMsg.decode(readValue(buffer)!);
      case 137: 
        return StringPlayerMsg.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class TXFlutterLivePlayerApi {
  /// Constructor for [TXFlutterLivePlayerApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  TXFlutterLivePlayerApi({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = _TXFlutterLivePlayerApiCodec();

  /// 播放器初始化，创建共享纹理、初始化播放器
  /// @param onlyAudio 是否是纯音频模式
  Future<IntMsg> initialize(BoolPlayerMsg arg_onlyAudio) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.initialize', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_onlyAudio]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as IntMsg?)!;
    }
  }

  ///
  /// 当设置[LivePlayer] 类型播放器时，需要参数[playType]
  /// 参考: [PlayType.LIVE_RTMP] ...
  /// 10.7版本开始，startPlay变更为startLivePlay，需要通过 {@link SuperPlayerPlugin#setGlobalLicense} 设置 Licence 后方可成功播放，
  /// 否则将播放失败（黑屏），全局仅设置一次即可。直播 Licence、短视频 Licence 和视频播放 Licence 均可使用，若您暂未获取上述 Licence ，
  /// 可[快速免费申请测试版 Licence](https://cloud.tencent.com/act/event/License) 以正常播放，正式版 License 需[购买]
  /// (https://cloud.tencent.com/document/product/881/74588#.E8.B4.AD.E4.B9.B0.E5.B9.B6.E6.96.B0.E5.BB.BA.E6.AD.A3.E5.BC.8F.E7.89.88-license)。
  Future<BoolMsg> startLivePlay(StringIntPlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.startLivePlay', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as BoolMsg?)!;
    }
  }

  /// 设置是否自动播放
  Future<void> setAutoPlay(BoolPlayerMsg arg_isAutoPlay) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.setAutoPlay', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_isAutoPlay]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 停止播放
  /// return 是否停止成功
  Future<BoolMsg> stop(BoolPlayerMsg arg_isNeedClear) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.stop', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_isNeedClear]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as BoolMsg?)!;
    }
  }

  /// 视频是否处于正在播放中
  Future<BoolMsg> isPlaying(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.isPlaying', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as BoolMsg?)!;
    }
  }

  /// 视频暂停，必须在播放器开始播放的时候调用
  Future<void> pause(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.pause', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 继续播放，在暂停的时候调用
  Future<void> resume(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.resume', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 设置直播模式，see TXPlayerLiveMode
  Future<void> setLiveMode(IntPlayerMsg arg_mode) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.setLiveMode', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_mode]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 设置视频声音 0~100
  Future<void> setVolume(IntPlayerMsg arg_volume) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.setVolume', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_volume]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 设置是否静音
  Future<void> setMute(BoolPlayerMsg arg_mute) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.setMute', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_mute]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 切换播放流
  Future<IntMsg> switchStream(StringPlayerMsg arg_url) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.switchStream', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_url]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as IntMsg?)!;
    }
  }

  /// 将视频播放进度定位到指定的进度进行播放
  /// progress 要定位的视频时间，单位 秒
  Future<void> seek(DoublePlayerMsg arg_progress) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.seek', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_progress]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 设置appId
  Future<void> setAppID(StringPlayerMsg arg_appId) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.setAppID', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_appId]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 时移 暂不支持
  /// @param domain
  /// @param bizId
  Future<void> prepareLiveSeek(StringIntPlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.prepareLiveSeek', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 停止时移播放，返回直播
  Future<IntMsg> resumeLive(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.resumeLive', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as IntMsg?)!;
    }
  }

  /// 设置播放速率,暂不支持
  Future<void> setRate(DoublePlayerMsg arg_rate) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.setRate', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_rate]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 设置播放器配置
  /// config @see [FTXLivePlayConfig]
  Future<void> setConfig(FTXLivePlayConfigPlayerMsg arg_config) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.setConfig', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_config]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 开启/关闭硬件编码
  Future<BoolMsg> enableHardwareDecode(BoolPlayerMsg arg_enable) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.enableHardwareDecode', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_enable]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as BoolMsg?)!;
    }
  }

  /// 进入画中画模式，进入画中画模式，需要适配画中画模式的界面，安卓只支持7.0以上机型
  /// <h1>
  /// 由于android系统限制，传递的图标大小不得超过1M，否则无法显示
  /// </h1>
  /// @param backIcon playIcon pauseIcon forwardIcon 为播放后退、播放、暂停、前进的图标，仅适用于android，如果赋值的话，将会使用传递的图标，否则
  /// 使用系统默认图标，只支持flutter本地资源图片，传递的时候，与flutter使用图片资源一致，例如： images/back_icon.png
  Future<IntMsg> enterPictureInPictureMode(PipParamsPlayerMsg arg_pipParamsMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.enterPictureInPictureMode', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_pipParamsMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as IntMsg?)!;
    }
  }

  /// 退出画中画，如果该播放器处于画中画模式
  Future<void> exitPictureInPictureMode(PlayerMsg arg_playerMsg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterLivePlayerApi.exitPictureInPictureMode', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_playerMsg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }
}

class _TXFlutterDownloadApiCodec extends StandardMessageCodec {
  const _TXFlutterDownloadApiCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is BoolMsg) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else if (value is IntMsg) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else if (value is MapMsg) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    } else if (value is PreLoadMsg) {
      buffer.putUint8(131);
      writeValue(buffer, value.encode());
    } else if (value is TXDownloadListMsg) {
      buffer.putUint8(132);
      writeValue(buffer, value.encode());
    } else if (value is TXVodDownloadMediaMsg) {
      buffer.putUint8(133);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128: 
        return BoolMsg.decode(readValue(buffer)!);
      case 129: 
        return IntMsg.decode(readValue(buffer)!);
      case 130: 
        return MapMsg.decode(readValue(buffer)!);
      case 131: 
        return PreLoadMsg.decode(readValue(buffer)!);
      case 132: 
        return TXDownloadListMsg.decode(readValue(buffer)!);
      case 133: 
        return TXVodDownloadMediaMsg.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class TXFlutterDownloadApi {
  /// Constructor for [TXFlutterDownloadApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  TXFlutterDownloadApi({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = _TXFlutterDownloadApiCodec();

  /// 启动预下载。
  /// playUrl: 要预下载的url
  /// preloadSizeMB: 预下载的大小（单位：MB）
  /// preferredResolution 期望分辨率，long类型，值为高x宽。可参考如720*1080。不支持多分辨率或不需指定时，传-1。
  /// 返回值：任务ID，可用这个任务ID停止预下载 [stopPreload]
  Future<IntMsg> startPreLoad(PreLoadMsg arg_msg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterDownloadApi.startPreLoad', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_msg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as IntMsg?)!;
    }
  }

  /// 停止预下载。
  /// taskId： 任务id
  Future<void> stopPreLoad(IntMsg arg_msg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterDownloadApi.stopPreLoad', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_msg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 开始下载
  /// videoDownloadModel: 下载构造体
  Future<void> startDownload(TXVodDownloadMediaMsg arg_msg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterDownloadApi.startDownload', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_msg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 继续下载，与开始下载接口有区别，该接口会寻找对应的缓存，复用之前的缓存来续点下载，
  /// 而开始下载接口会启动一个全新的下载
  /// videoDownloadModel: 下载构造体
  Future<void> resumeDownload(TXVodDownloadMediaMsg arg_msg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterDownloadApi.resumeDownload', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_msg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 停止下载
  /// videoDownloadModel: 下载构造体
  Future<void> stopDownload(TXVodDownloadMediaMsg arg_msg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterDownloadApi.stopDownload', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_msg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 设置下载请求头
  Future<void> setDownloadHeaders(MapMsg arg_headers) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterDownloadApi.setDownloadHeaders', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_headers]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else {
      return;
    }
  }

  /// 获取所有视频下载列表
  Future<TXDownloadListMsg> getDownloadList() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterDownloadApi.getDownloadList', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(null) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as TXDownloadListMsg?)!;
    }
  }

  /// 获得指定视频的下载信息
  Future<TXVodDownloadMediaMsg> getDownloadInfo(TXVodDownloadMediaMsg arg_msg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterDownloadApi.getDownloadInfo', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_msg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as TXVodDownloadMediaMsg?)!;
    }
  }

  /// 删除下载任务
  Future<BoolMsg> deleteDownloadMediaInfo(TXVodDownloadMediaMsg arg_msg) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.TXFlutterDownloadApi.deleteDownloadMediaInfo', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
        await channel.send(<Object?>[arg_msg]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as BoolMsg?)!;
    }
  }
}
