// Copyright (c) 2024 Tencent. All rights reserved.

#import <Foundation/Foundation.h>
#import "FTXPipController.h"
#import "FTXEvent.h"
#import "FTXPipCaller.h"
#import "FTXPipFactory.h"
#import "TXPipAuth.h"
#import "FTXLog.h"
#import <CoreVideo/CoreVideo.h>

@interface FTXPipController()

@property (nonatomic, strong) id<FTXPipCaller> pipImpl;
@property (nonatomic, strong) FTXPipFactory* pipFactory;
@property (atomic, strong) NSObject* controlLock;

@end

static NSString* kPipTag = @"FTXPipController";
static FTXPipController *_shareInstance = nil;

@implementation FTXPipController

+ (instancetype)shareInstance {
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
      _shareInstance = [[FTXPipController alloc] init];
    });
    return _shareInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.pipFactory = [[FTXPipFactory alloc] init];
        self.controlLock = [[NSObject alloc] init];
    }
    return self;
}

- (int)startOpenPip:(V2TXLivePlayer *)livePlayer withSize:(CGSize)size{
    if (![TXPipAuth cpa]) {
        FTXLOGE(@"%@ pip auth is deined when enter", kPipTag);
        if (nil != self.pipDelegate) {
            [self.pipDelegate pictureInPictureErrorDidOccur:FTX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_AUTH_DENIED];
        }
        return ERROR_PIP_AUTH_DENIED;
    }
    if (![TXVodPlayer isSupportPictureInPicture]) {
        FTXLOGE(@"%@ pip is not support", kPipTag);
        if (nil != self.pipDelegate) {
            [self.pipDelegate pictureInPictureErrorDidOccur:FTX_VOD_PLAYER_PIP_ERROR_TYPE_DEVICE_NOT_SUPPORT];
        }
        return ERROR_IOS_PIP_DEVICE_NOT_SUPPORT;
    }
    if (nil != self.pipImpl) {
        TX_VOD_PLAYER_PIP_STATE status = [self.pipImpl getStatus];
        if (status == TX_VOD_PLAYER_PIP_STATE_WILL_START
            || status == TX_VOD_PLAYER_PIP_STATE_DID_START) {
            FTXLOGE(@"%@ pip is running when enter, status %ld", kPipTag, (long)status);
            if (nil != self.pipDelegate) {
                [self.pipDelegate pictureInPictureErrorDidOccur:FTX_VOD_PLAYER_PIP_ERROR_TYPE_PIP_IS_RUNNING];
            }
            return ERROR_IOS_PIP_IS_RUNNING;
        }
    }
    self.pipImpl = [self.pipFactory createPipCaller];
    if (self.pipDelegate != nil) {
        self.pipImpl.pipDelegate = self.pipDelegate;
    }
    if (self.playerDelegate != nil) {
        self.pipImpl.playerDelegate = self.playerDelegate;
    }
    int retCode = [self.pipImpl handleStartPip:size];
    return retCode;
}

- (void)setPipDelegate:(id<FTXLivePipDelegate>)pipDelegate {
    if (nil != self.pipImpl) {
        self.pipImpl.pipDelegate = pipDelegate;
    }
    self->_pipDelegate = pipDelegate;
}

- (void)setPlayerDelegate:(id<FTXPipPlayerDelegate>)playerDelegate {
    if (nil != self.pipImpl) {
        self.pipImpl.playerDelegate = playerDelegate;
    }
    self->_playerDelegate = playerDelegate;
}

- (void)exitPip {
    @synchronized (self.controlLock) {
        if (nil != self.pipImpl) {
            [self.pipImpl exitPip];
            self.pipImpl = nil;
            self.pipDelegate = nil;
            self.playerDelegate = nil;
        }
    }
}

- (void)pausePipVideo {
    if (nil != self.pipImpl) {
        [self.pipImpl pausePipVideo];
    }
}

- (void)resumePipVideo {
    if (nil != self.pipImpl) {
        [self.pipImpl resumePipVideo];
    }
}

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    @synchronized (self.controlLock) {
        if (!pixelBuffer || pixelBuffer == NULL) {
            NSLog(@"Invalid CVPixelBufferRef");
            return;
        }
        if (nil != self.pipImpl) {
            [self.pipImpl displayPixelBuffer:pixelBuffer];
        }
    }
}

@end

