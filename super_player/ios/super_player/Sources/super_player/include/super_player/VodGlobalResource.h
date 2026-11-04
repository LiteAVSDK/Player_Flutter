// Copyright (c) 2026 Tencent. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SuperPlayerPlugin;

/**
 * Process-wide shared resources for the SuperPlayer module (iOS).
 *
 * The SuperPlayerPlugin itself stays per-engine (Flutter calls registerWithRegistrar: once per
 * engine), but process-level hooks must only be attached once:
 *   - [TXLiveBase sharedInstance].delegate  (License callback, single-delegate by design)
 *   - UIDeviceOrientationDidChangeNotification
 *
 * This class keeps a weak collection of attached plugins (NSHashTable with weakObjectsHashTable)
 * so that a crash-free teardown path is guaranteed even if a plugin somehow forgets to release.
 * When the first plugin acquires, the hooks are wired up; when the last plugin releases, they
 * are torn down. License-loaded and orientation-changed events are fanned out to every attached
 * plugin so that every Flutter engine gets the same notification.
 */
@interface VodGlobalResource : NSObject

+ (instancetype)sharedInstance;

/** Called from -[SuperPlayerPlugin initWithRegistrar:]. */
- (void)acquire:(SuperPlayerPlugin *)plugin;

/** Called from -[SuperPlayerPlugin destroy] or detachFromEngineForRegistrar:. */
- (void)release:(SuperPlayerPlugin *)plugin;

@end

NS_ASSUME_NONNULL_END
