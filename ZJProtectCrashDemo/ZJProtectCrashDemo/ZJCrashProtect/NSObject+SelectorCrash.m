//
//  NSObject+SelectorCrash.m
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/23.
//

#import "NSObject+SelectorCrash.h"
#import <objc/runtime.h>
#import "ZJMethodExchange.h"
#import "ZJCatchCrash.h"

@interface ZJSelectorObject : NSObject

@end

@implementation ZJSelectorObject

+ (instancetype)shared {
    static ZJSelectorObject *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[ZJSelectorObject alloc] init];
    });
    return obj;
}

+ (void)addUnrecognizedSelector:(SEL)aSelector {
    if ([self respondsToSelector:aSelector]) { // 已经可以处理
        return;
    }
    Method method = class_getInstanceMethod(self, @selector(backupClassMethod));
    Class metaCls = object_getClass(self);
    class_addMethod(metaCls, aSelector, method_getImplementation(method), method_getTypeEncoding(method));
}

- (void)addUnrecognizedSelector:(SEL)aSelector {
    if ([self respondsToSelector:aSelector]) { // 已经可以处理
        return;
    }
    Method method = class_getInstanceMethod([self class], @selector(backupMethod));
    class_addMethod([self class], aSelector, method_getImplementation(method), method_getTypeEncoding(method));
}

- (void)backupMethod {
    NSLog(@"backupMethod --- %@ ", [NSObject zj_callStackSymbols]);
}

- (void)backupClassMethod {
    NSLog(@"backupClassMethod --- ");
}

@end


@implementation NSObject (SelectorCrash)

+ (void)exchangeMethod {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 交换方法
        [ZJMethodExchange exchangeInstanceMehtod:self originMehtod:@selector(forwardingTargetForSelector:) replaceMethod:@selector(zj_forwardingTargetForSelector:)];
        // 交换类方法
        [ZJMethodExchange exchangeClassMehtod:self originMehtod:@selector(forwardingTargetForSelector:) replaceMethod:@selector(zj_forwardingTargetForSelector:)];
    });
}

// 对象方法处理
- (id)zj_forwardingTargetForSelector:(SEL)aSelector {
    if ([self respondsToSelector:aSelector] || [self methodSignatureForSelector:aSelector]) {
        // 如果自己本身能处理，还是交给本类处理
        return  self;
    }
    ZJSelectorObject *obj = [ZJSelectorObject shared];
    [obj addUnrecognizedSelector:aSelector];
    return obj;
}

// 类方法处理
+ (id)zj_forwardingTargetForSelector:(SEL)aSelector {
    if ([self respondsToSelector:aSelector] || [self methodSignatureForSelector:aSelector]) {
        // 如果自己本身能处理，还是交给本类处理
        return  self;
    }
    [ZJSelectorObject addUnrecognizedSelector:aSelector];
    return [ZJSelectorObject class];
}

@end
