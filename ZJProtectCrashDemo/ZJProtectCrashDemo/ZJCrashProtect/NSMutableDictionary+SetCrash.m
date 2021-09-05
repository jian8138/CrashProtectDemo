//
//  NSMutableDictionary+SetCrash.m
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/28.
//

#import "NSMutableDictionary+SetCrash.h"
#import "ZJMethodExchange.h"
#import <objc/runtime.h>

@implementation NSMutableDictionary (SetCrash)

+ (void)exchangeMethod {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class _NSDictionaryM = objc_getClass("__NSDictionaryM");
        [ZJMethodExchange exchangeInstanceMehtod:_NSDictionaryM originMehtod:@selector(setObject:forKey:) replaceMethod:@selector(zj_setObject:forKey:)];
        [ZJMethodExchange exchangeInstanceMehtod:_NSDictionaryM originMehtod:@selector(setObject:forKeyedSubscript:) replaceMethod:@selector(zj_setObject:forKeyedSubscript:)];
    });
}

- (void)zj_setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    if(!anObject || !aKey) {
        NSLog(@"set nil key nil object");
        return;
    }
    [self zj_setObject:anObject forKey:aKey];
}

- (void)zj_setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key {
    // obj可以为nil，当删除某个键值对时就是设置为nil
    if(!key) {
        NSLog(@"set nil key");
        return;
    }
    [self zj_setObject:obj forKeyedSubscript:key];
}

@end
