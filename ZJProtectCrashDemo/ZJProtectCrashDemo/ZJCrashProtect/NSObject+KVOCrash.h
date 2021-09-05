//
//  NSObject+KVOCrash.h
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (KVOCrash)

+ (void)exchangeKVOMethod;

- (void)zj_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;

@end

NS_ASSUME_NONNULL_END
