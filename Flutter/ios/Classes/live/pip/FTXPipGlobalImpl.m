// Copyright (c) 2024 Tencent. All rights reserved.

#import "FTXPipGlobalImpl.h"
#import "TXPipAuth.h"
#import <AVKit/AVKit.h>
#import "FTXEvent.h"
#import "FTXLog.h"
#import "FTXPlayerConstants.h"
#import "FTXPipRenderView.h"
#import "FTXBackPlayer.h"

@interface FTXPipGlobalImpl()<AVPictureInPictureControllerDelegate>

@property (nonatomic, strong)AVPictureInPictureController *pipController;
@property (nonatomic, assign)TX_VOD_PLAYER_PIP_STATE pipStatus;
@property (nonatomic, assign)FTX_LIVE_PIP_ERROR pipError;
/// app传入的videoView在父view上的约束，恢复view的时候要重新加上之前的约束
@property (nonatomic, strong)NSMutableArray *constraintArray;
@property (nonatomic, strong)UIView* backgroundPlayerView;
/// 传入的videoView在移动view(coverVideoViewToPIPView)之前的父view
@property (nonatomic, weak)UIView* superViewOfVideoView;
@property (nonatomic, strong)FTXPipRenderView* videoView;
@property (nonatomic, strong) NSArray *tempConstraintArray;
@property (nonatomic, strong) FTXBackPlayer* backPlayer;

@end

static NSString* kPipTag = @"FTXPipCaller";

@implementation FTXPipGlobalImpl

@synthesize pipDelegate;
@synthesize playerDelegate;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.pipStatus = TX_VOD_PLAYER_PIP_STATE_UNDEFINED;
        self.pipError = FTX_VOD_PLAYER_PIP_ERROR_TYPE_NONE;
        self.constraintArray = [[NSMutableArray alloc] init];
        self.videoView = [self createVideoView];
    }
    return self;
}

- (int)handleStartPip:(CGSize)size {
    if (![TXPipAuth cpa]) {
        FTXLOGE(@"%@ pip auth is deined when handle", kPipTag);
        [self changeStatus:TX_VOD_PLAYER_PIP_STATE_UNDEFINED];
        [self onPipError:FTX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_AUTH_DENIED];
        return ERROR_PIP_AUTH_DENIED;
    }
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *resourcePath = [mainBundle pathForResource:@"tx_vod_seamless_pip_backgroud_video" ofType:@"mp4" inDirectory:@"TXVodPlayer.bundle"];
    // 获取文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // 判断资源是否存在
    BOOL resourceExists = [fileManager fileExistsAtPath:resourcePath];
    if (resourceExists) {
        FTXLOGI(@"%@ Resource exists at path: %@", kPipTag, resourcePath);
        [self prepareWithURL:[NSURL fileURLWithPath:resourcePath] withSize:size withDurationSec:100
                   isReplace:NO];
    } else {
        FTXLOGE(@"%@ Resource does not exist at path: %@", kPipTag, resourcePath);
        [self onPipError:FTX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_MISS_RESOURCE];
    }
    return NO_ERROR;
}

- (void)exitPip {
    if (![TXPipAuth cpa]) {
        FTXLOGE(@"%@ pip auth is deined when closed", kPipTag);
        [self changeStatus:TX_VOD_PLAYER_PIP_STATE_UNDEFINED];
        [self onPipError:FTX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_AUTH_DENIED];
        return;
    }
    if (nil != self.pipController) {
        [self.pipController stopPictureInPicture];
    }
    if (self.backgroundPlayerView && self.backgroundPlayerView.superview) {
        [self.backgroundPlayerView removeFromSuperview];
        self.backgroundPlayerView = nil;
    }
    if (self.backPlayer) {
        // 停止播放并释放资源
        [self.backPlayer stop];
    }
}

- (FTXPipRenderView *)getVideoView {
    return self.videoView;
}

- (TX_VOD_PLAYER_PIP_STATE)getStatus {
    return self.pipStatus;
}

- (void)pausePipVideo {
    if (nil != self.backPlayer) {
        [self.backPlayer pause];
    }
}

- (void)resumePipVideo {
    if (nil != self.backPlayer) {
        [self.backPlayer play];
    }
}

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    [self.videoView displayPixelBuffer:pixelBuffer];
}

#pragma mark - AVPictureInPictureControllerDelegate

- (void)pictureInPictureControllerWillStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    if ([TXPipAuth cpa]) {
        FTXLOGI(@"%@ pictureInPictureControllerWillStartPictureInPicture", kPipTag);
        [self changeStatus:TX_VOD_PLAYER_PIP_STATE_WILL_START];
        UIView* pipView = self.pipView;
        FTXPipRenderView* videoView = self.videoView;
        if (!pipView) {
            FTXLOGE(@"[%@] coverVideoViewToPIPView, pipView is nil, videoView is: %p", kPipTag, videoView);
            return;
        }
        if (!videoView) {
            FTXLOGE(@"[%@] coverVideoViewToPIPView, videoView is nil", kPipTag);
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            // 把当前videoView和父view记下来
            self.superViewOfVideoView = videoView.superview;
            
            // 把当前videoView在其父view上的约束记下来，等恢复的时候重新加上这些约束
            [self.constraintArray removeAllObjects]; // 移除旧的约束
            for (NSLayoutConstraint *constraint in self.superViewOfVideoView.constraints) {
                if (constraint.firstItem == self.videoView) {
                    [self.constraintArray addObject:constraint];
                }
            }

            videoView.translatesAutoresizingMaskIntoConstraints = NO;
            [videoView removeFromSuperview];
            [pipView addSubview:self.videoView];
            // 添加约束 使videoview撑满pipview
            NSLayoutConstraint *contraintTop = [NSLayoutConstraint constraintWithItem:videoView
                                                                          attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
                                                                             toItem:pipView
                                                                          attribute:NSLayoutAttributeTop
                                                                         multiplier:1.0
                                                                           constant:0];
            NSLayoutConstraint *contraintLeft = [NSLayoutConstraint constraintWithItem:videoView
                                                                          attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual
                                                                             toItem:pipView
                                                                          attribute:NSLayoutAttributeLeft
                                                                         multiplier:1.0
                                                                           constant:0];
            NSLayoutConstraint *contraintBottom = [NSLayoutConstraint constraintWithItem:videoView
                                                                          attribute:NSLayoutAttributeBottom
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:pipView
                                                                          attribute:NSLayoutAttributeBottom
                                                                         multiplier:1.0
                                                                           constant:0];
            NSLayoutConstraint *contraintRight = [NSLayoutConstraint constraintWithItem:videoView
                                                                          attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual
                                                                             toItem:pipView
                                                                          attribute:NSLayoutAttributeRight
                                                                         multiplier:1.0
                                                                           constant:0];
            // 把约束添加到父视图pipview上
            self.tempConstraintArray = [NSArray arrayWithObjects:contraintTop, contraintLeft, contraintBottom, contraintRight, nil];
            [NSLayoutConstraint activateConstraints:self.tempConstraintArray]; // activateConstraints 效率更高
            [videoView setNeedsLayout];
            [videoView layoutIfNeeded];
            FTXLOGI(@"[%@] coverVideoViewToPIPView finished, videoView's superview is: %p", kPipTag, videoView.superview);
        });
    } else {
        [self changeStatus:TX_VOD_PLAYER_PIP_STATE_UNDEFINED];
        [self onPipError:FTX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_AUTH_DENIED];
        FTXLOGE(@"%@ pip auth is deined when opened", kPipTag);
    }
}

- (void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    FTXLOGI(@"%@ pictureInPictureControllerDidStartPictureInPicture", kPipTag);
    [self changeStatus:TX_VOD_PLAYER_PIP_STATE_DID_START];
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController failedToStartPictureInPictureWithError:(NSError *)error {
    FTXLOGI(@"%@ failedToStartPictureInPictureWithError:%@", kPipTag, error);
}

- (void)pictureInPictureControllerWillStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    FTXLOGI(@"%@ pictureInPictureControllerWillStopPictureInPicture", kPipTag);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.pipController removeObserver:self forKeyPath:@"pictureInPicturePossible"];
    [self.backPlayer stop];
    [self changeStatus:TX_VOD_PLAYER_PIP_STATE_WILL_STOP];
    [self exitPip];
}

- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    FTXLOGI(@"%@ pictureInPictureControllerDidStopPictureInPicture", kPipTag);
    [self changeStatus:TX_VOD_PLAYER_PIP_STATE_DID_STOP];
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler {
    FTXLOGI(@"%@ restoreUserInterfaceForPictureInPictureStopWithCompletionHandler", kPipTag);
    [self changeStatus:TX_VOD_PLAYER_PIP_STATE_RESTORE_UI];
}

#pragma mark - private method

- (FTXPipRenderView *)createVideoView {
    if (!_videoView) {
        // Set the size to 1 pixel to ensure proper display in PIP.
        _videoView = [[FTXPipRenderView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
    }
    return _videoView;
}

- (void)changeStatus:(TX_VOD_PLAYER_PIP_STATE)status{
    self.pipStatus = status;
    FTXLOGE(@"%@ pip met status changed %ld", kPipTag, status);
    if (self.pipDelegate) {
        [self.pipDelegate pictureInPictureStateDidChange:status];
    }
}

- (void)onPipError:(FTX_LIVE_PIP_ERROR)error{
    self.pipError = error;
    FTXLOGE(@"%@ pip met error %ld", kPipTag, error);
    if (self.pipDelegate) {
        [self.pipDelegate pictureInPictureErrorDidOccur:error];
    }
}

/// 获取系统画中画view
- (UIView *)pipView {
    ///画中画view是windos列表里最后一个PGHostWindow类型的view。单实例的情况下，就是列表里第一个view，多实例的情况下，要取最后一个PGHostWindow类型的view
    UIView *pipView = [UIApplication sharedApplication].windows.firstObject;
    Class pgHostWindowClass = NSClassFromString(@"PGHostedWindow");
    if (!pgHostWindowClass) {
        return pipView;
    }
    // 取最后一个PGHostWindow类型的view
    for (UIView *view in [UIApplication sharedApplication].windows) {
        if ([view isKindOfClass:pgHostWindowClass]) {
            pipView = view;
        }
    }
    return pipView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.pipController) {
        if ([keyPath isEqualToString:@"pictureInPicturePossible"]) {
            if (self.pipController.pictureInPicturePossible && !self.pipController.pictureInPictureActive) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.pipController.isPictureInPictureActive) {
                        [self.pipController stopPictureInPicture];
                    } else {
                        [self.pipController startPictureInPicture];
                    }
                });
            }
        }
    }
}

/// 1 将输入视频url, resize到指定大小，2 拼接到指定长度，3 用新的视频资源初始化avplayer（3需要在主线程中做，但耗时非常少可以忽略）
/// @param inputURL 输入视频url
/// @param size 指定视频尺寸
/// @param durationSec 指定视频时长
/// @param isReplace 是否是换源 换源的话只换播放资源 不重新创建播放器
- (void)prepareWithURL:(NSURL *)inputURL withSize:(CGSize)size withDurationSec:(NSTimeInterval)durationSec isReplace:(BOOL)isReplace {
    if (!inputURL) {
        return;
    }
    AVAsset *videoAsset = [[AVURLAsset alloc] initWithURL:inputURL options:nil];
    AVMutableComposition *composition = [AVMutableComposition composition];
    // 视频类型的的Track，这个方法里只添加视频track，不需要音频
    AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                           preferredTrackID:kCMPersistentTrackID_Invalid];
    // 拼接视频
    int localVideoDurationSec = CMTimeGetSeconds(videoAsset.duration); // 本地视频时长
    if (localVideoDurationSec == 0) {
        FTXLOGW(@"%@ prepareWithURL failed, local video duration is 0, return", kPipTag);
        return;
    }
    CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    int counts = (durationSec / localVideoDurationSec);
    for (int i = 0; i < counts; i++) {
        [compositionTrack insertTimeRange:timeRange ofTrack:[videoAsset tracksWithMediaType:AVMediaTypeVideo][0] atTime:kCMTimeZero error:nil];
    }
    // 拼最后一段视频
    int lastVideoDurationSec = (int)durationSec % localVideoDurationSec;
    if (lastVideoDurationSec != 0) {
        CMTime lastVideoTime = CMTimeMake(lastVideoDurationSec, 1);
        CMTimeRange lastVideoTimeRange = CMTimeRangeMake(kCMTimeZero, lastVideoTime);
        [compositionTrack insertTimeRange:lastVideoTimeRange
                                  ofTrack:[videoAsset tracksWithMediaType:AVMediaTypeVideo][0]
                                   atTime:kCMTimeZero error:nil];
    }

    // resize
    AVMutableVideoCompositionLayerInstruction *videoCompositionLayerIns =
        [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionTrack];
    [videoCompositionLayerIns setTransform:compositionTrack.preferredTransform atTime:kCMTimeZero];  //得到视频素材
    AVMutableVideoCompositionInstruction *videoCompositionIns = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    [videoCompositionIns setTimeRange:CMTimeRangeMake(kCMTimeZero, compositionTrack.timeRange.duration)];
    //得到视频轨道
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = @[videoCompositionIns];
    if (size.width <= 0 || size.height <= 0) {
        FTXLOGE(@"%@ prepareWithURL failed, wrong video size, bgPlayer: %p, return ", kPipTag, self.backPlayer);
        return;
    }
    videoComposition.renderSize = size;  //指定尺寸
    videoComposition.frameDuration = CMTimeMake(2, 2);
    // 视频裁剪拼接成功后开始prepare
    NSArray *requestedKeys = @[@"playable"];
    [composition loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // NOTE:移除旧的PlayerView,防止旧BG页面残留
            if (self.backgroundPlayerView && self.backgroundPlayerView.superview) {
                [self.backgroundPlayerView removeFromSuperview];
                self.backgroundPlayerView = nil;
            }
            
            self.backgroundPlayerView = [[UIView alloc] initWithFrame:CGRectZero];
            self.backgroundPlayerView.backgroundColor = [UIColor clearColor];
            self.backgroundPlayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.backgroundPlayerView.frame = self.pipView.bounds;
            AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:composition];
              playerItem.videoComposition = videoComposition;
              if (isReplace && self.backPlayer != nil) {
                  [self.backPlayer replaceCurrentItemWithPlayerItem:playerItem];
                  [self.backPlayer play];
              } else {
                  self.backPlayer = [[FTXBackPlayer alloc] init];
                  [self.backPlayer prepareVideo:playerItem];
                  [self.backPlayer setContainerView:self.backgroundPlayerView];
                  [self.backPlayer getPlayerLayer].frame = self.videoView.bounds;
                  [self.pipView addSubview:self.backgroundPlayerView];
                  self.backPlayer.playerDelegate = self.playerDelegate;
                  [self.backPlayer setLoopback:YES];
                  [self.backPlayer play];
                  self.pipController = [[AVPictureInPictureController alloc] initWithPlayerLayer:[self.backPlayer getPlayerLayer]];
                  self.pipController.delegate = self;
                  // 使用 KVC，隐藏播放按钮、快进快退按钮
                  [self.pipController setValue:[NSNumber numberWithInt:1] forKey:@"controlsStyle"];
                  [self setRequiresLinearPlayback:YES];
                  [self.pipController addObserver:self forKeyPath:@"pictureInPicturePossible" options:NSKeyValueObservingOptionNew context:nil];
              }
        });
    }];
}

- (void)setRequiresLinearPlayback:(BOOL)requiresLinearPlayback {
    if (@available(iOS 14.0, macOS 11.0, *)) {
        //requiresLinearPlayback:  NO：画中画小窗会显示快进快退按钮  YES:不会显示快进快退按钮
        self.pipController.requiresLinearPlayback = requiresLinearPlayback;
    }
}

- (void)setPlayerDelegate:(id<FTXPipPlayerDelegate>)playerDelegate {
    if (self.backPlayer != nil) {
        self.backPlayer.playerDelegate = playerDelegate;
    }
    self->playerDelegate = playerDelegate;
}

@end
