//
//  ZJCrashManager.h
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/23.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ZJCrashProtectOption) {
    ZJCrashProtectOptionUnrecognizedSelector = 1 << 1,
    ZJCrashProtectOptionKVC = 1 << 2,
    ZJCrashProtectOptionKVO = 1 << 3,
    ZJCrashProtectOptionNotification = 1 << 4,
    ZJCrashProtectOptionArray = 1 << 10,
    ZJCrashProtectOptionDictionary = 1 << 11,
    ZJCrashProtectOptionCatchCrash = 1 << 12, // 捕获错误
    ZJCrashProtectOptionAll = 1 << 13,
}; // Crash防护的相关选项

NS_ASSUME_NONNULL_BEGIN

@interface ZJCrashManager : NSObject

+ (instancetype)manger;

- (void)startProtectWithOpiton:(ZJCrashProtectOption)option;

@end

NS_ASSUME_NONNULL_END
