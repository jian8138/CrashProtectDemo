//
//  NSArray+BoundsCrash.m
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/25.
//

#import "NSArray+BoundsCrash.h"
#import "ZJMethodExchange.h"
#import <objc/runtime.h>

@implementation NSArray (BoundsCrash)

+ (void)exchangeMethod {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        // 多元素数组：__NSArrayI
        Class _NSArrayI = objc_getClass("__NSArrayI");
        // 单元素数组：__NSSingleObjectArrayI
        Class _NSSingleObjectArrayI = objc_getClass("__NSSingleObjectArrayI");
        // 空数组：__NSArray0
        Class _NSArray0 = objc_getClass("__NSArray0");

        // 使用“@[]”创建数组时，执行-[__NSPlaceholderArray initWithObjects:count:]
        Class _NSPlaceholderArray = objc_getClass("__NSPlaceholderArray");
        [ZJMethodExchange exchangeInstanceMehtod:_NSPlaceholderArray originMehtod:@selector(initWithObjects:count:) replaceMethod:@selector(zj_initWithObjects:count:)];

        // 交换方法 objectAtIndex
        [ZJMethodExchange exchangeInstanceMehtod:_NSArrayI originMehtod:@selector(objectAtIndex:) replaceMethod:@selector(zj_objectAtIndex:)];
        [ZJMethodExchange exchangeInstanceMehtod:_NSSingleObjectArrayI originMehtod:@selector(objectAtIndex:) replaceMethod:@selector(zj_objectAtIndexedArrayCountOnlyOne:)];
        [ZJMethodExchange exchangeInstanceMehtod:_NSArray0 originMehtod:@selector(objectAtIndex:) replaceMethod:@selector(zj_objectAtIndexedNullarray:)];

        // 交换方法 objectAtIndexedSubscript: 取下标时用到的方法
        [ZJMethodExchange exchangeInstanceMehtod:_NSArrayI originMehtod:@selector(objectAtIndexedSubscript:) replaceMethod:@selector(zj_objectAtIndexedSubscript:)];

    });
}

- (id)zj_initWithObjects:(id  _Nonnull const [])objects count:(NSUInteger)cnt {
    id object = nil;
    @try {
        object = [self zj_initWithObjects:objects count:cnt];
    }
    @catch (NSException *exception) {
        NSLog(@"init error");
    }
    @finally {
        return object;
    }
}

- (id)zj_objectAtIndex:(NSUInteger)index {
    id object = nil;
    @try {
        object = [self zj_objectAtIndex:index];
    }
    @catch (NSException *exception) {
        NSLog(@"index beyond bounds");
    }
    @finally {
        return object;
    }
}

- (id)zj_objectAtIndexedSubscript:(NSUInteger)idx {
    id object = nil;
    @try {
        object = [self zj_objectAtIndexedSubscript:idx];
    }
    @catch (NSException *exception) {
        NSLog(@"subscript beyond bounds");
    }
    @finally {
        return object;
    }
}

- (id)zj_objectAtIndexedArrayCountOnlyOne:(NSUInteger)index {
    id object = nil;
    @try {
        object = [self zj_objectAtIndexedArrayCountOnlyOne:index];
    }
    @catch (NSException *exception) {
        NSLog(@"one beyond bounds");
    }
    @finally {
        return object;
    }
}

- (id)zj_objectAtIndexedNullarray:(NSUInteger)index {
    id object = nil;
    @try {
        object = [self zj_objectAtIndexedNullarray:index];
    }
    @catch (NSException *exception) {
        NSLog(@"empty beyond bounds");
    }
    @finally {
        return object;
    }
}

@end
