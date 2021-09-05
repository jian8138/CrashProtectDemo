//
//  NSDictionary+InitCrash.m
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/28.
//

#import "NSDictionary+InitCrash.h"
#import <objc/runtime.h>
#import "ZJMethodExchange.h"

@implementation NSDictionary (InitCrash)

+ (void)exchangeMethod {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 使用“@{}”创建数组时，执行-[__NSPlaceholderDictionary initWithObjects:forKeys:count:]
        Class _NSPlaceholderDictionary = objc_getClass("__NSPlaceholderDictionary");
        [ZJMethodExchange exchangeInstanceMehtod:_NSPlaceholderDictionary originMehtod:@selector(initWithObjects:forKeys:count:) replaceMethod:@selector(zj_initWithObjects:forKeys:count:)];
    });
}

- (instancetype)zj_initWithObjects:(id  _Nonnull const [])objects forKeys:(id<NSCopying>  _Nonnull const [])keys count:(NSUInteger)cnt {
    NSUInteger index = 0;
    id  _Nonnull __unsafe_unretained newObjects[cnt];
    id  _Nonnull __unsafe_unretained newkeys[cnt];
    for (int i = 0; i < cnt; i++) {
        id tmpItem = objects[i];
        id tmpKey = keys[i];
        if (tmpItem == nil || tmpKey == nil) {
            NSLog(@"nil key nil object");
            continue;
        }
        newObjects[index] = tmpItem;
        newkeys[index] = tmpKey;
        index++;
    }
    return [self zj_initWithObjects:newObjects forKeys:newkeys count:index];
}

@end
