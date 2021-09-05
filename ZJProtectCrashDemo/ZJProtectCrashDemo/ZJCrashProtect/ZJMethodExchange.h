//
//  ZJMethodExchange.h
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZJMethodExchange : NSObject

+ (void)exchangeInstanceMehtod:(Class)cls originMehtod:(SEL)originSEL replaceMethod:(SEL)replaceSEL;

+ (void)exchangeClassMehtod:(Class)cls originMehtod:(SEL)originSEL replaceMethod:(SEL)replaceSEL;

@end

NS_ASSUME_NONNULL_END
