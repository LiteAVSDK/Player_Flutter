// Copyright (c) 2022 Tencent. All rights reserved.

#import <Foundation/Foundation.h>

@protocol FlutterPluginRegistrar;

@interface FTXDownloadManager : NSObject

- (instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar;

- (void)destroy;
@end


