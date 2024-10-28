// Copyright (c) 2024 Tencent. All rights reserved.

#import "TXPipAuth.h"
#import "FTXPlayerConstants.h"

#define TUI_RGSKEY_PARAM1     @"KEY_PARAM1"
#define TUI_RETKEY_PARAM1     @"KEY_PARAM1"
#define TUI_ID_CHECK_FEATURE_AUTH  (2)  ///<  校验某个 feature 是否授权

@implementation TXPipAuth

+ (instancetype)shareInstance {
    static TXPipAuth *g_playerAuth = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_playerAuth = [[self alloc] init];
    });
    return g_playerAuth;
}

+ (BOOL)cpa{
    return [TXPipAuth cfa:TUI_FEATURE_PLAYER_PREMIUM];
}

+ (BOOL)cfa:(int)featureId {
    
    // 输入参数
    NSMutableDictionary *inputParams = [NSMutableDictionary dictionary];
    NSString *featureIdStr = [NSString stringWithFormat:@"%@", @(featureId)];
    [inputParams setObject:featureIdStr forKey:TUI_RGSKEY_PARAM1];
    
    // 函数调用
    __block BOOL result = NO;
    Class HostEngineManagerClass = NSClassFromString(@"TXCHostEngineManager");
    SEL sharedManagerSEL = NSSelectorFromString(@"sharedManager");
    IMP sharedManagerIMP = [HostEngineManagerClass methodForSelector:sharedManagerSEL];
    NSObject *(*sharedManagerFunc)(id, SEL) = (void *)sharedManagerIMP;
    NSObject *sharedManagerObj = sharedManagerFunc(HostEngineManagerClass, sharedManagerSEL);
    
    void (^SyncRequestToHostFuncBlock)(NSDictionary *) = ^(NSDictionary *outParams) {
        NSObject *featureAuthObj = [outParams objectForKey:TUI_RETKEY_PARAM1];
        if ([featureAuthObj isKindOfClass:[NSNumber class]]) {
            result = [(NSNumber *)featureAuthObj boolValue];
        }
    };
    
    SEL sendSyncRequestToHostSEL = NSSelectorFromString(@"sendSyncRequestToHostWithFunctionId:inputParams:completionHandler:");
    IMP sendSyncRequestToHostIMP = [sharedManagerObj methodForSelector:sendSyncRequestToHostSEL];
    void (*sendSyncRequestToHostFunc)(id, SEL, NSInteger, NSDictionary *, void (^)(NSDictionary<NSString *, NSObject *> *)) = (void *)sendSyncRequestToHostIMP;
    sendSyncRequestToHostFunc(sharedManagerObj, sendSyncRequestToHostSEL, TUI_ID_CHECK_FEATURE_AUTH, inputParams, SyncRequestToHostFuncBlock);
    return result;
}

@end
