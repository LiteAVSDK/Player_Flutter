#import <Foundation/Foundation.h>
#import <TXLiteAVSDK_Professional/TXLiteAVSDK.h>

static NSString* cacheFolder = nil;
static int maxCacheItems = -1;
@interface FTXTransformation : NSObject

+ (TXVodPlayConfig *)transformToConfig:(NSDictionary*)map;

+ (void)setCacheFolder:(NSString*)path;
+ (void)setMaxCacheItemSize:(int)size;

@end
