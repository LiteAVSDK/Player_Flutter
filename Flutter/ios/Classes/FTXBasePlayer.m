//
//  FTXBasePlayer.m
//  super_player
//
//  Created by Zhirui Ou on 2021/3/23.
//

#import "FTXBasePlayer.h"
#import <stdatomic.h>
#import <libkern/OSAtomic.h>

static atomic_int atomicId = 0;

@implementation FTXBasePlayer

- (instancetype)init
{
    if (self = [super init]) {
        int pid = atomic_fetch_add(&atomicId, 1);
        _playerId = @(pid);
    }
    
    return self;
}

- (void)destory
{
    
}

@end
