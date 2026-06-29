// Copyright (c) 2022 Tencent. All rights reserved.

#import "FTXBasePlayer.h"
#import <stdatomic.h>
#import <libkern/OSAtomic.h>

static atomic_int atomicId = 0;

@implementation FTXBasePlayer {
    atomic_bool _destroyed;
}

- (instancetype)init
{
    if (self = [super init]) {
        int pid = atomic_fetch_add(&atomicId, 1);
        _playerId = @(pid);
        atomic_store(&_destroyed, false);
    }

    return self;
}

- (BOOL)isDestroyed {
    return atomic_load(&_destroyed);
}

- (BOOL)markDestroyedIfNeeded {
    bool expected = false;
    return atomic_compare_exchange_strong(&_destroyed, &expected, true);
}

- (void)setRenderView:(FTXTextureView *)renderView {
}

- (void)destroy
{

}
@end
