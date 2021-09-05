# CrashProtectDemo
iOS防崩溃的demo，总结多个crash的原因，降低崩溃率，提升APP的用户体验。

##### 1、unrecognized selector 错误

对于这种常见的找不到方法导致的崩溃，可以在方法`objc_msgSend`执行流程的三个步骤（1、消息发送；2、动态方法解析；3、消息转发）中的消息转发步骤里做文章：

- 1、替换NSobject的`forwardingTargetForSelector`方法(该方法可将不可识别的方法转发给其他对象)；

- 2、在自定义的`forwardingTargetForSelector`方法里，动态创建一个新的类，把这个类作为返回值返回出去，用于接收转发的方法；

- 3、让这个新的类动态新增一个方法，让该方法来处理消息，防止崩溃。

##### 2、数组越界错误

常见的数组越界错误，可以通过交换`objectAtIndex:`方法，把方法指向自定义的方法来处理，自定义方法里可以先做安全范围判断，再决定是否执行取值，或者`@try`调用方法，错误再抛出即可。注意点：

- 1、NSArray的并不是数组的直接类型，交换方法时，要传入正确的类。数组的类型为：

```objective-c
// 多元素数组：__NSArrayI
Class _NSArrayI = objc_getClass("__NSArrayI");
// 单元素数组：__NSSingleObjectArrayI
Class _NSSingleObjectArrayI = objc_getClass("__NSSingleObjectArrayI");
// 空数组：__NSArray0
Class _NSArray0 = objc_getClass("__NSArray0");
        
// 使用“@[]”创建数组时，执行-[__NSPlaceholderArray initWithObjects:count:]
Class _NSPlaceholderArray = objc_getClass("__NSPlaceholderArray");

// 可变数组
Class _NSArrayM = objc_getClass("__NSArrayM");
```

- 2、交换`objectAtIndex:`方法时，不止`_NSArrayI`要交换方法，其余的类型也得一一交换这个方法。下标范围取值的方法为`objectAtIndexedSubscript:`，详见demo。

##### 3、字典设置Nil值错误

常见的字典错误，就是设置了为nil的key值或为nil的object值，解决办法主要就是替换`setObject:forKey:`和`setObject:forKeyedSubscript:`方法，先判断key和object是否为nil，再决定是否赋值。注意点：

1、与NSArray一样，NSDictionary和NSMutableDictionary都不是直接类型，正确的类为：

```objc
 // 使用“@{}”创建数组时，执行-[__NSPlaceholderDictionary initWithObjects:forKeys:count:]
 Class _NSPlaceholderDictionary = objc_getClass("__NSPlaceholderDictionary");
 
 // 可变字典
 Class _NSDictionaryM = objc_getClass("__NSDictionaryM");
```

2、在`setObject:forKey:`方法中需要判断`object`和`value`都是否为空，`setObject:forKeyedSubscript:`方法中只需判断key是否为空

```objective-c
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
```

##### 4、KVC错误

使用KVC时，如果`setValue:forKey:`设置了为nil的key值会直接报错，或类里找不到的key时，就会走到方法`setValue:forUndefinedKey:`，然后崩溃报错。

同理，`valueForKey:`方法中，设置了nil的key值，或类里找不到的key时都会报错。解决办法就是先判断key值是否为空，同时替换掉`setValue:forUndefinedKey:`与`valueForUndefinedKey:`方法

```objective-c
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
```

##### 5、KVO错误

常见的KVO错误，有以下两种：

**1、重复移除observer导致的crash**

**解决办法：**

创建一个KVO代理对象，由该代理维护一张map关系表，表里面存放观察该对象的observer与对应的keypath。

1、替换`addObserver:forKeyPath:options:context:`方法，当addObserver时，代理map表添加对应的键值对，当发现重复添加时，不执行操作；

2、替换`removeObserver:forKeyPath:`方法，当removeObserver时，代理map表删除对应的键值对，当发现重复删除时，不执行操作。

**注意：**

1、KVO代理对象中map表要使用`NSMapTable`，因为`NSMapTable`可以控制对`key` `value`是强引用还是弱引用，弱引用observer，不影响observer的生命周期，当observer销毁时，`NSMapTable`表内也会移除响应的键值对；

2、因为可能会涉及到多线程同时操作map表，所以KVO代理对象内对map的操作要使用加锁、解锁操作。

**2、观察者销毁前没有调用removeObserver，keyPath值改变时Crash**

**解决办法：**

为observer动态添加一个关联对象，当observer销毁时，关联对象也会销毁，关联对象销毁时，移除observer添加过的KVO观察。

1、替换`addObserver:forKeyPath:options:context:`方法，当addObserver时，动态为observer添加关联对象，关联对象中也要绑定observer，同时把被观察对象object与对应的keyPath存到关联对象的map中；

2、当关联对象走销毁dealloc方法时，遍历object与keyPath的map表，调用removeObserver，移除observer的观察。

**注意：**

1、与上一个KVO Crash解决办法一样，需要使用`NSMapTable`与加锁操作；

2、关联对象中绑定observer时要使用弱引用，不然会造成循环引用。同时，弱引用要使`__unsafe_unretained`，因为在observer销毁后，还要在关联对象的dealloc方法中再次使用observer来移除KVO。若使用`__weak`，observer销毁后就会置为nil了，就无法再用它来移除KVO；

3、关联对象的dealloc方法中，要直接调用原有的`removeObserver`方法，而不是被替换后的方法。因为替换后的方法会涉及到KVO代理的map表判断，observer销毁后，map表里的键值对就会去除，就导致该判断错误，然后不执行真正的`removeObserver`操作，所以要直接调用原有的`removeObserver`方法。同时，就有可能会重复`removeObserver`，所以要用`@try {}`来调用方法，避免崩溃。

##### 6、Notification错误

当一个对象添加了notification之后，如果dealloc的时候，仍然持有notification，就会出现NSNotification类型的crash。iOS9之后专门针对于这种情况做了处理，所以在iOS9之后，即使开发者没有移除observer，Notification crash也不会再产生了。但是如果观察者被销毁后不移除，仍会执行对应的selector，可能会引起意想不到的Crash，而此类Crash往往难以定位。

**解决办法：**

当notification添加observer时，为observer动态添加一个关联对象，当observer销毁时，关联对象也会销毁，关联对象销毁时，移除notification中的observer。

1、替换`addObserver:selector:name:object:`方法，当addObserver时，动态为observer添加关联对象，关联对象中也要绑定observer，同时把notification存到关联对象的table中；

2、当关联对象走销毁dealloc方法时，遍历table表，找出所有注册的notification，调用`removeObserver:`方法，移除observer。

**注意：**

1、与上面的KVO错误相似，关联对象中要使用`NSHashTable`弱引用notification，observer要使用`__unsafe_unretained`绑定，同时也要多线程加锁操作。

##### 7、Crash捕获

常见的Crash主要分为两大类：

**1、Objective-C Exception**

Objective-C层面的错误，这类错误可以通过`try-catch-finally` 传统方式捕获，也可通过`NSSetUncaughtExceptionHandler`来设置处理器。例如`unrecognized selector`错误、数组越界错误等都属于这种crash，这些错误会导致程序向自身发送了`SIGABRT`信号而崩溃。示例代码：

```objective-c
// 捕获普通的OC错误
+ (void)registerExceptionCatch {
    zj_previousUncaughtExceptionHandler = NSGetUncaughtExceptionHandler(); // 记录之前的exceptionHandler
    NSSetUncaughtExceptionHandler(&ZJHandleException);
}

static void ZJHandleException(NSException *exception) {
    // 异常名称
    NSString *name = [exception name];
    // 出现异常的原因
    NSString *reason = [exception reason];
    // 异常的堆栈信息
    NSArray *stack = [exception callStackSymbols];
    NSString *crashMsg = [NSString stringWithFormat:@"/* Handle Exception --- %@ --- %@ */  \n %@", name, reason, stack];
    NSLog(@"%@", crashMsg);
    
    [[[ZJCatchCrash alloc] init] performSelectorOnMainThread:@selector(handleExceptionAlert:) withObject: crashMsg waitUntilDone:YES]; // 发送错误给弹窗处理
    
    //  处理前者注册的 handler
    if (zj_previousUncaughtExceptionHandler) {
        zj_previousUncaughtExceptionHandler(exception);
    }
}
```

**2、Signal Exception**

系统层面的异常，操作系统向正在运行的程序发送信号，根据信号不同，可以查看崩溃的类型，常见的野指针错误`EXC_BAD_ACCESS()`就通过这种类型抛出。可以通过注册`SignalHandler`来捕获指定的异常信号量。示例代码：

```objective-c
// 捕获异常的信号量
static void registerSignalHandler(void) {
    /*
     SIGABRT--程序中止命令中止信号
     SIGALRM--程序超时信号
     SIGFPE--程序浮点异常信号
     SIGILL--程序非法指令信号
     SIGHUP--程序终端中止信号
     SIGINT--程序键盘中断信号
     SIGKILL--程序结束接收中止信号
     SIGTERM--程序kill中止信号
     SIGSTOP--程序键盘中止信号
     SIGSEGV--程序无效内存中止信号
     SIGBUS--程序内存字节未对齐中止信号
     SIGPIPE--程序Socket发送失败中止信号
     */
    signal(SIGABRT, SignalExceptionHandler);
    signal(SIGALRM, SignalExceptionHandler);
    signal(SIGFPE, SignalExceptionHandler);
    signal(SIGILL, SignalExceptionHandler);
    signal(SIGHUP, SignalExceptionHandler);
    signal(SIGINT, SignalExceptionHandler);
    signal(SIGKILL, SignalExceptionHandler);
    signal(SIGTERM, SignalExceptionHandler);
    signal(SIGSTOP, SignalExceptionHandler);
    signal(SIGSEGV, SignalExceptionHandler);
    signal(SIGSEGV, SignalExceptionHandler);
    signal(SIGBUS, SignalExceptionHandler);
    signal(SIGPIPE, SignalExceptionHandler);
    signal(SIGQUIT, SignalExceptionHandler);
}

void SignalExceptionHandler(int signal)
{
    NSString *crashMsg = [NSString stringWithFormat:@"/* Handle Signal Exception --- signal: %d --- */ \n %@ ", signal, [NSObject zj_callStackSymbols]];
    NSLog(@"%@", crashMsg);

    [[[ZJCatchCrash alloc] init] performSelectorOnMainThread:@selector(handleExceptionAlert:) withObject: crashMsg waitUntilDone:YES]; // 发送错误给弹窗处理
}
```

通过捕获以上两种crash可以自定义错误分析报告，也可以设置拦截弹窗，崩溃时弹出弹窗，而不是直接闪退，用户体验相对好些。基本原理就是，捕获崩溃时，阻止线程退出，继续运行当前runloop。但如果选择crash发生后，仍继续运行程序，可能还会导致一些未知错误发生，所以最好还是崩溃后选择退出程序。

```objective-c
// 显示弹窗
- (void)handleExceptionAlert:(NSString *)crashMsg {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Unhandled exception" message:crashMsg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *quitBtn = [UIAlertAction actionWithTitle:@"Quit" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self->dismissed = YES;
    }];
    // 如果选择continue，就是崩溃后继续让程序运行。但这种运行是不安全的，程序可能还能继续运行，但是不稳定，可能会发生未知错误，最好还是崩溃弹窗后就退出程序
    UIAlertAction *continueBtn = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:quitBtn];
    [alert addAction:continueBtn];
    [[ViewController topViewController] presentViewController:alert animated:YES completion:nil];
    
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);

    while (!dismissed)
    {
        for (NSString *mode in (__bridge NSArray *)allModes)
        {
            //为阻止线程退出，使用 CFRunLoopRunInMode(model, 0.001, false)等待系统消息，false表示RunLoop没有超时时间
            CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
        }
    }

    CFRelease(allModes);
    
    // 移除handler，不然可能会重复弹窗，退出不了程序
    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGALRM, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGHUP, SIG_DFL);
    signal(SIGINT, SIG_DFL);
    signal(SIGKILL, SIG_DFL);
    signal(SIGTERM, SIG_DFL);
    signal(SIGSTOP, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    signal(SIGQUIT, SIG_DFL);
}
```
