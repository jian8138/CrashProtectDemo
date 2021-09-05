//
//  NSObject+KVOCrash.m
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/29.
//

#import "NSObject+KVOCrash.h"
#import <objc/runtime.h>
#import "ZJMethodExchange.h"
#import <pthread.h>

// 关联对象KVO代理，维护一张KVO的关系表
@interface ZJKVOProxy : NSObject {
    pthread_mutex_t _mutex; // 考虑多线程操作map表，需要线程安全操作
}

// key为observer, value为observer添加的keyPath
@property (nonatomic, strong) NSMapTable<NSObject *, NSHashTable<NSString *> *> *kvoMap; // NSMapTable可以控制对key value是强引用还是弱引用

@end

@implementation ZJKVOProxy

- (instancetype)init {
    if (self = [super init]) {
        self.kvoMap = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsObjectPersonality valueOptions:NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPersonality capacity:0];
        pthread_mutex_init(&_mutex, NULL);
    }
    return self;
}

- (BOOL)proxy_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    pthread_mutex_lock(&_mutex);
    NSHashTable *table = [self.kvoMap objectForKey:observer];
    if(table && [table containsObject:keyPath]) { // 如果已经添加过这个观察，不重复添加
        pthread_mutex_unlock(&_mutex);
        return false;
    }
    if(!table) { // 未添加过，就增加这个键值对
        table = [NSHashTable weakObjectsHashTable];
    }
    [table addObject:keyPath];
    [self.kvoMap setObject:table forKey:observer];
    pthread_mutex_unlock(&_mutex);
    return  true;
}

- (BOOL)proxy_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    pthread_mutex_lock(&_mutex);
    NSHashTable *table = [self.kvoMap objectForKey:observer];
    if(!table) { // 不包含这个对象的键值对
        pthread_mutex_unlock(&_mutex);
        return false;
    }
    if(![table containsObject:keyPath]) { // 不包含这个keyPath
        pthread_mutex_unlock(&_mutex);
        return false;
    }
    [table removeObject:keyPath];
    if(table.count == 0) {
        [self.kvoMap removeObjectForKey:observer];
    }
    pthread_mutex_unlock(&_mutex);
    return  true;
}

- (void)dealloc {
    NSLog(@"---- %@ dealloc ----", [self class]);
}

@end

// 用于当观察者销毁时，却还没移除掉KVO时，帮助自动移除掉KVO，避免crash

@interface ZJKVORemover : NSObject

@property (nonatomic, strong) NSMapTable<NSObject *, NSHashTable<NSString *> *> *kvoMap;

@end

@implementation ZJKVORemover {
    __unsafe_unretained NSObject *_observer; // 注意要使用__unsafe_unretained，因为_observer销毁后，如果用__weak就直接置为nil，就remove不了了
    pthread_mutex_t _mutex; // 考虑多线程操作map表，需要线程安全操作
}

- (instancetype)initWithObserver:(NSObject *)observer {
    if (self = [super init]) {
        _observer = observer;
        self.kvoMap = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsObjectPersonality valueOptions:NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPersonality capacity:0];
    }
    return self;
}

- (void)addObserverWithObject:(NSObject *)object keyPath:(NSString *)keyPath {
    pthread_mutex_lock(&_mutex);
    NSHashTable *table = [self.kvoMap objectForKey:object];
    if(!table) { // 未添加过，就增加这个键值对
        table = [NSHashTable weakObjectsHashTable];
    }
    [table addObject:keyPath];
    [self.kvoMap setObject:table forKey:object];
    pthread_mutex_unlock(&_mutex);
}

- (void)dealloc {
    @try {
        for (NSObject *obj in self.kvoMap) {
            NSHashTable *table = [self.kvoMap objectForKey:obj];
            for (NSString *keyPath in table) {
                [obj zj_removeObserver:_observer forKeyPath:keyPath]; // 要用系统的KVO方法，因为代理map表里已经被清掉这个键值对了
                NSLog(@"kvo remove dealloc observer");
            }
        }
    } @catch (NSException *exception) {

    }
}

@end

@implementation NSObject (KVOCrash)

+ (void)exchangeKVOMethod {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [ZJMethodExchange exchangeInstanceMehtod:self originMehtod:@selector(addObserver:forKeyPath:options:context:) replaceMethod:@selector(zj_addObserver:forKeyPath:options:context:)];
        [ZJMethodExchange exchangeInstanceMehtod:self originMehtod:@selector(removeObserver:forKeyPath:) replaceMethod:@selector(zj_removeObserver:forKeyPath:)];
    });
}

- (void)zj_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    if (![[self KVOProxy] proxy_addObserver:observer forKeyPath:keyPath]) { // 判断是否有添加过这个KVO键值对
        NSLog(@"repeat add kvo --- ");
        return;
    }
    static const char ZJObserverRemoverKey;
    ZJKVORemover *remover = objc_getAssociatedObject(observer, &ZJObserverRemoverKey);
    if (remover == nil) {
        remover = [[ZJKVORemover alloc] initWithObserver:observer];
        objc_setAssociatedObject(observer, &ZJObserverRemoverKey, remover, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [remover addObserverWithObject:self keyPath:keyPath];
    
    [self zj_addObserver:observer forKeyPath:keyPath options:options context:context];
}

- (void)zj_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    if(![[self KVOProxy] proxy_removeObserver:observer forKeyPath:keyPath]) {
        NSLog(@"repeat remove kvo --- ");
        return;
    }
    [self zj_removeObserver:observer forKeyPath:keyPath];
}

// 关联对象KVO代理，此代理维护一张KVO的关系表
static void *ZJKVOProxyKey = &ZJKVOProxyKey;

- (ZJKVOProxy *)KVOProxy {
    ZJKVOProxy *proxy = objc_getAssociatedObject(self, ZJKVOProxyKey);
    if (proxy == nil) {
        proxy = [[ZJKVOProxy alloc] init];
        self.KVOProxy = proxy;
    }
    return proxy;
}

- (void)setKVOProxy:(ZJKVOProxy *)proxy
{
    objc_setAssociatedObject(self, ZJKVOProxyKey, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
