//
//  ZJCatchCrash.h
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZJCatchCrash : NSObject

// 注册捕获错误
+ (void)registerCrashHandler;

@end

@interface NSObject (ZJCrashStack)

// 获取当前的堆栈信息
+ (NSArray <NSString *>*)zj_callStackSymbols;

@end

NS_ASSUME_NONNULL_END
