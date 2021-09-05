//
//  ZJMethodExchange.m
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/24.
//

#import "ZJMethodExchange.h"
#import <objc/runtime.h>

@implementation ZJMethodExchange

+ (void)exchangeInstanceMehtod:(Class)cls originMehtod:(SEL)originSEL replaceMethod:(SEL)replaceSEL {
    Method originMethod = class_getInstanceMethod(cls, originSEL);
    Method replaceMethod = class_getInstanceMethod(cls, replaceSEL);

    if (!originMethod)  { // 防止originMethod为空，添加一个空方法与替换方法交换
        class_addMethod(cls, originSEL, method_getImplementation(replaceMethod), method_getTypeEncoding(replaceMethod));
        method_setImplementation(replaceMethod, imp_implementationWithBlock(^(id self, SEL _cmd){ }));
        return;
    }

    method_exchangeImplementations(originMethod, replaceMethod);
}

+ (void)exchangeClassMehtod:(Class)cls originMehtod:(SEL)originSEL replaceMethod:(SEL)replaceSEL {
    Method originMethod = class_getClassMethod(cls, originSEL);
    Method replaceMethod = class_getClassMethod(cls, replaceSEL);
    
    Class metaCls = object_getClass(cls);
    if (!originMethod)  { // 防止originMethod为空，添加一个空方法与替换方法交换
        class_addMethod(metaCls, originSEL, method_getImplementation(replaceMethod), method_getTypeEncoding(replaceMethod));
        method_setImplementation(replaceMethod, imp_implementationWithBlock(^(id self, SEL _cmd){ }));
        return;
    }

    method_exchangeImplementations(originMethod, replaceMethod);
}

@end
