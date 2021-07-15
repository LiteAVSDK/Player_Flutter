//
//  FTXBasePlayer.h
//  super_player
//
//  Created by Zhirui Ou on 2021/3/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FTXBasePlayer : NSObject

@property(atomic, readonly) NSNumber *playerId;

- (void)destory;

@end

NS_ASSUME_NONNULL_END
