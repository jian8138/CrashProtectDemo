//
//  NSObject+KVCCrash.m
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/28.
//

#import "NSObject+KVCCrash.h"
#import <objc/runtime.h>
#import "ZJMethodExchange.h"

@implementation NSObject (KVCCrash)

+ (void)exchangeKVCMethod {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [ZJMethodExchange exchangeInstanceMehtod:self originMehtod:@selector(setValue:forKey:) replaceMethod:@selector(zj_setValue:forKey:)];
        [ZJMethodExchange exchangeInstanceMehtod:self originMehtod:@selector(valueForKey:) replaceMethod:@selector(zj_valueForKey:)];
        [ZJMethodExchange exchangeInstanceMehtod:self originMehtod:@selector(setValue:forUndefinedKey:) replaceMethod:@selector(zj_setValue:forUndefinedKey:)];
        [ZJMethodExchange exchangeInstanceMehtod:self originMehtod:@selector(valueForUndefinedKey:) replaceMethod:@selector(zj_valueForUndefinedKey:)];
    });
}

- (void)zj_setValue:(id)value forKey:(NSString *)key {
    if(!key) {
        NSLog(@"KVC set nil key ");
        return;
    }
    [self zj_setValue:value forKey:key];
}

- (id)zj_valueForKey:(NSString *)key {
    if(!key) {
        NSLog(@"KVC valueForKey nil ");
        return nil;
    }
    return [self zj_valueForKey:key];
}

- (void)zj_setValue:(id)value forUndefinedKey:(NSString *)key {
    NSLog(@"KVC set undefinedKey ");
}

- (id)zj_valueForUndefinedKey:(NSString *)key {
    NSLog(@"KVC valueForUndefinedKey ");
    return nil;
}

@end
