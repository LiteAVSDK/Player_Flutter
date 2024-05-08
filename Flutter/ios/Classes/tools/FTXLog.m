// Copyright (c) 2022 Tencent. All rights reserved.

#import "FTXLog.h"

extern void tpl_log(int level, const char *file, int line, const char *func, const char *format, ...);

static TX_Enum_Type_LogLevel currentLogLevel = LOGLEVEL_VERBOSE;

@implementation FTXLog

+ (void)setLogLevel:(TX_Enum_Type_LogLevel)level {
    currentLogLevel = level;
}

+ (void)logLevel:(TX_Enum_Type_LogLevel)level file:(const char *)file line:(int)line function:(const char *)function info:(NSString *)info {
    if (level >= currentLogLevel) {
        NSString *finalInfoString = [NSString stringWithFormat:@"[FTXPlayerLog] %@", info];
        const char *finalInfo = [finalInfoString UTF8String];
        [self logL:level
                  file:file
                  line:line
              function:function
                  info:finalInfo];
    }
}

#pragma mark - private methods

//LOGLEVEL_VERBOSE = 0,  //  VERBOSE
//LOGLEVEL_DEBUG   = 1,  //  DEBUG
//LOGLEVEL_INFO    = 2,  //  INFO
//LOGLEVEL_WARN = 3,  //  WARNING
//LOGLEVEL_ERROR   = 4,  //  ERROR
//LOGLEVEL_FATAL   = 5,  //  FATAL
//LOGLEVEL_NULL    = 6,  //  NONE
+ (void)logL:(TX_Enum_Type_LogLevel)level
            file:(const char *)file
            line:(int)line
        function:(const char *)function
            info:(const char *)info {
    switch (level) {
        case LOGLEVEL_VERBOSE:
            {
                tpl_log(0, file, line, function, info);
            }
            break;
        case LOGLEVEL_DEBUG:
            {
                tpl_log(1, file, line, function, info);
            }
            break;
        case LOGLEVEL_INFO:
            {
                tpl_log(2, file, line, function, info);
            }
            break;
        case LOGLEVEL_WARN:
            {
                tpl_log(3, file, line, function, info);
            }
            break;
        case LOGLEVEL_ERROR:
            {
                tpl_log(4, file, line, function, info);
            }
            break;
        case LOGLEVEL_FATAL:
            {
                tpl_log(5, file, line, function, info);
            }
            break;
        case LOGLEVEL_NULL:
            {
                tpl_log(6, file, line, function, info);
            }
            break;
        default:
            break;
    }
    
}

@end
