// Copyright (c) 2022 Tencent. All rights reserved.
#ifndef SUPERPLAYER_FLUTTER_IOS_CLASSES_TOOLS_FTXLOG_H_
#define SUPERPLAYER_FLUTTER_IOS_CLASSES_TOOLS_FTXLOG_H_

#import <Foundation/Foundation.h>
#import "FTXLiteAVSDKHeader.h"

NS_ASSUME_NONNULL_BEGIN

#define FTXLOGV(fmt, ...) \
[FTXLog logLevel:LOGLEVEL_VERBOSE \
                     file:__FILE__ \
                     line:__LINE__ \
                 function:__FUNCTION__ \
                     info:[NSString stringWithFormat:fmt, ##__VA_ARGS__]];
#define FTXLOGD(fmt, ...) \
[FTXLog logLevel:LOGLEVEL_DEBUG \
                     file:__FILE__ \
                     line:__LINE__ \
                 function:__FUNCTION__ \
                     info:[NSString stringWithFormat:fmt, ##__VA_ARGS__]];
#define FTXLOGI(fmt, ...) \
[FTXLog logLevel:LOGLEVEL_INFO \
                     file:__FILE__ \
                     line:__LINE__ \
                 function:__FUNCTION__ \
                     info:[NSString stringWithFormat:fmt, ##__VA_ARGS__]];
#define FTXLOGW(fmt, ...) \
[FTXLog logLevel:LOGLEVEL_WARN \
                     file:__FILE__ \
                     line:__LINE__ \
                 function:__FUNCTION__ \
                     info:[NSString stringWithFormat:fmt, ##__VA_ARGS__]];
#define FTXLOGE(fmt, ...) \
[FTXLog logLevel:LOGLEVEL_ERROR \
                     file:__FILE__ \
                     line:__LINE__ \
                 function:__FUNCTION__ \
                     info:[NSString stringWithFormat:fmt, ##__VA_ARGS__]];

@interface FTXLog : NSObject

/**
 * 日志打印
 * @param level 方法
 * @param file 文件名
 * @param line 行
 * @param function 方法
 * @param info 信息
 */
+ (void)logLevel:(TX_Enum_Type_LogLevel)level
               file:(const char *)file
               line:(int)line
           function:(const char *)function
               info:(NSString *)info;

+ (void)setLogLevel:(TX_Enum_Type_LogLevel)level;

@end

NS_ASSUME_NONNULL_END
#endif  // SUPERPLAYER_FLUTTER_IOS_CLASSES_TOOLS_FTXLOG_H_
