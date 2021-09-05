//
//  ZJCrashManager.m
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/23.
//

#import "ZJCrashManager.h"
#import "NSObject+SelectorCrash.h"
#import "NSArray+BoundsCrash.h"
#import "NSDictionary+InitCrash.h"
#import "NSMutableDictionary+SetCrash.h"
#import "NSObject+KVCCrash.h"
#import "NSObject+KVOCrash.h"
#import "NSNotificationCenter+Crash.h"
#import "ZJCatchCrash.h"

@implementation ZJCrashManager

+(instancetype)manger {
    static ZJCrashManager *manger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manger = [[ZJCrashManager alloc] init];
    });
    return manger;
}

- (void)startProtectWithOpiton:(ZJCrashProtectOption)option {
    if(option & ZJCrashProtectOptionAll || option & ZJCrashProtectOptionUnrecognizedSelector) {
        [NSObject exchangeMethod];
    }
    if(option & ZJCrashProtectOptionAll || option & ZJCrashProtectOptionArray) {
        [NSArray exchangeMethod];
    }
    if(option & ZJCrashProtectOptionAll || option & ZJCrashProtectOptionDictionary) {
        [NSDictionary exchangeMethod];
        [NSMutableDictionary exchangeMethod];
    }
    if(option & ZJCrashProtectOptionAll || option & ZJCrashProtectOptionKVC) {
        [NSObject exchangeKVCMethod];
    }
    if(option & ZJCrashProtectOptionAll || option & ZJCrashProtectOptionKVO) {
        [NSObject exchangeKVOMethod];
    }
    if(option & ZJCrashProtectOptionAll || option & ZJCrashProtectOptionNotification) {
        [NSNotificationCenter exchangeMethod];
    }
    if(option & ZJCrashProtectOptionAll || option & ZJCrashProtectOptionCatchCrash) {
        [ZJCatchCrash registerCrashHandler];
    }
    
}



@end
