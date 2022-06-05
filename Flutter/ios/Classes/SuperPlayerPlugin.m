#import "SuperPlayerPlugin.h"
#import "FTXLivePlayer.h"
#import "FTXVodPlayer.h"
#import "FTXTransformation.h"
#import <TXLiteAVSDK_Professional/TXLiteAVSDK.h>

@interface SuperPlayerPlugin ()

@property (nonatomic, strong) NSObject<FlutterPluginRegistrar>* registrar;
@property (nonatomic, strong) NSMutableDictionary *players;

@end

@implementation SuperPlayerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_super_player"
            binaryMessenger:[registrar messenger]];
  SuperPlayerPlugin* instance = [[SuperPlayerPlugin alloc] initWithRegistrar:registrar];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistrar:
    (NSObject<FlutterPluginRegistrar> *)registrar {
    self = [super init];
    if (self) {
        _registrar = registrar;
        _players = @{}.mutableCopy;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  }else if([@"createLivePlayer" isEqualToString:call.method]){
      FTXLivePlayer* player = [[FTXLivePlayer alloc] initWithRegistrar:self.registrar];
      NSNumber *playerId = player.playerId;
      _players[playerId] = player;
      result(playerId);
  }else if([@"createVodPlayer" isEqualToString:call.method]){
      FTXVodPlayer* player = [[FTXVodPlayer alloc] initWithRegistrar:self.registrar];
      NSNumber *playerId = player.playerId;
      _players[playerId] = player;
      result(playerId);
  }else if([@"releasePlayer" isEqualToString:call.method]){
      NSDictionary *args = call.arguments;
      NSNumber *pid = args[@"playerId"];
      FTXBasePlayer *player = [_players objectForKey:pid];
      [player destory];
      if (player != nil) {
          [_players removeObjectForKey:pid];
      }
      result(nil);
  }else if([@"setConsoleEnabled" isEqualToString:call.method]){
      NSDictionary *args = call.arguments;
      BOOL enabled = [args[@"enabled"] boolValue];
      [TXLiveBase setConsoleEnabled:enabled];
      result(nil);
  }else if([@"setGlobalMaxCacheSize" isEqualToString:call.method]){
      NSDictionary *args = call.arguments;
      int size = [args[@"size"] intValue];
      [FTXTransformation setMaxCacheItemSize:size];
      result(nil);
  }else if([@"setGlobalCacheFolderPath" isEqualToString:call.method]){
      NSDictionary *args = call.arguments;
      NSString* path = args[@"path"];
      [FTXTransformation setCacheFolder:path];
      result(nil);
  }else if([@"setGlobalLicense" isEqualToString:call.method]) {
      NSDictionary *args = call.arguments;
      NSString *licenceUrl = args[@"licenceUrl"];
      NSString *licenceKey = args[@"licenceKey"];
      [TXLiveBase setLicenceURL:licenceUrl key:licenceKey];
  }
  else {
    result(FlutterMethodNotImplemented);
  }
}

@end
