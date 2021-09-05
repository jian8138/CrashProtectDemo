//
//  NSObject+SelectorCrash.h
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (SelectorCrash)

+ (void)exchangeMethod;

@end

NS_ASSUME_NONNULL_END
