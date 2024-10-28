// Copyright (c) 2024 Tencent. All rights reserved.

#import "FTXPipFactory.h"
#import "FTXPipGlobalImpl.h"

@implementation FTXPipFactory

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (nonnull id<FTXPipCaller>)createPipCaller {
    id<FTXPipCaller> pipCalled = [[FTXPipGlobalImpl alloc] init];
    return pipCalled;
}

@end
