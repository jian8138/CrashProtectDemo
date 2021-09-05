//
//  NSNotificationCenter+Crash.m
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/30.
//

#import "NSNotificationCenter+Crash.h"
#import <objc/runtime.h>
#import "ZJMethodExchange.h"
#import <pthread.h>

@interface ZJNotiRemover : NSObject

@property (nonatomic, strong) NSHashTable<NSNotificationCenter *> *notiTable;

@end

@implementation ZJNotiRemover {
    __unsafe_unretained NSObject *_observer; // 注意要使用__unsafe_unretained，因为_observer销毁后，如果用__weak就直接置为nil，就remove不了了
    pthread_mutex_t _mutex; // 考虑多线程操作table表，需要线程安全操作
}

- (instancetype)initWithObserver:(NSObject *)observer {
    if (self = [super init]) {
        _observer = observer;
        self.notiTable = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)addObserverWithObject:(NSNotificationCenter *)center {
    pthread_mutex_lock(&_mutex);
    [self.notiTable addObject:center];
    pthread_mutex_unlock(&_mutex);
}

- (void)dealloc {
    for (NSNotificationCenter *center in self.notiTable) {
        NSLog(@"remove noti --- %@", _observer);
        [center removeObserver:_observer];
    }
}

@end


@implementation NSNotificationCenter (Crash)

+ (void)exchangeMethod {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [ZJMethodExchange exchangeInstanceMehtod:self originMehtod:@selector(addObserver:selector:name:object:) replaceMethod:@selector(zj_addObserver:selector:name:object:)];
    });
}

- (void)zj_addObserver:(id)observer selector:(SEL)aSelector name:(NSNotificationName)aName object:(id)anObject {
    static const char ZJNotiRemoverKey;
    ZJNotiRemover *remover = objc_getAssociatedObject(observer, &ZJNotiRemoverKey);
    if (remover == nil) {
        remover = [[ZJNotiRemover alloc] initWithObserver:observer];
        objc_setAssociatedObject(observer, &ZJNotiRemoverKey, remover, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [remover addObserverWithObject:self];
    [self zj_addObserver:observer selector:aSelector name:aName object:anObject];
}

@end
