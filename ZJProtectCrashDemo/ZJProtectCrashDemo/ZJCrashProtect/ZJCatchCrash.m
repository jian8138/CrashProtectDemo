//
//  ZJCatchCrash.m
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/31.
//

#import "ZJCatchCrash.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>
#import <UIKit/UIKit.h>
#import "ViewController.h"

static NSUncaughtExceptionHandler *zj_previousUncaughtExceptionHandler; // 如果之前就有注册，用来保存之前注册的exceptionHandler

@implementation ZJCatchCrash {
    BOOL dismissed;
}

+ (void)registerCrashHandler {
    [ZJCatchCrash registerExceptionCatch]; // exception 错误
    registerSignalHandler(); // signal 错误
}

#pragma mark - Exception

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
    
    [[[ZJCatchCrash alloc] init] performSelectorOnMainThread:@selector(handleExceptionAlert:) withObject: crashMsg waitUntilDone:YES];
    
    //  处理前者注册的 handler
    if (zj_previousUncaughtExceptionHandler) {
        zj_previousUncaughtExceptionHandler(exception);
    }
}

#pragma mark - SignalException

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
//    ZJSignalRegister(SIGABRT);
//    ZJSignalRegister(SIGALRM);
//    ZJSignalRegister(SIGFPE);
//    ZJSignalRegister(SIGILL);
//    ZJSignalRegister(SIGHUP);
//    ZJSignalRegister(SIGINT);
//    ZJSignalRegister(SIGKILL);
//    ZJSignalRegister(SIGTERM);
//    ZJSignalRegister(SIGSTOP);
//    ZJSignalRegister(SIGSEGV);
//    ZJSignalRegister(SIGBUS);
//    ZJSignalRegister(SIGPIPE);
//    ZJSignalRegister(SIGQUIT);
    
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

    [[[ZJCatchCrash alloc] init] performSelectorOnMainThread:@selector(handleExceptionAlert:) withObject: crashMsg waitUntilDone:YES];
}

//static void ZJSignalRegister(int signal) {
//    struct sigaction action;
//    action.sa_sigaction = ZJSignalHandler;
//    action.sa_flags = SA_NODEFER | SA_SIGINFO;
//    sigemptyset(&action.sa_mask);
//    sigaction(signal, &action, 0);
//}
//
//static void ZJSignalHandler(int signal, siginfo_t* info, void* context) {
//    NSString *crashMsg = [NSString stringWithFormat:@"/* Handle Signal Exception --- signal: %d --- %@ */ \n %@ ", signal, info, [NSObject zj_callStackSymbols]];
//    NSLog(@"%@", crashMsg);
//    [[[ZJCatchCrash alloc] init] performSelectorOnMainThread:@selector(handleExceptionAlert:) withObject: crashMsg waitUntilDone:YES];
//}


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

@end

@implementation NSObject (ZJCrashStack)

+ (NSArray <NSString *>*)zj_callStackSymbols {
    void *callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (i = 0; i < frames; i ++) {
        NSString *stackString = [NSString stringWithUTF8String:strs[i]];
        [backtrace addObject:stackString];
    }
    free(strs);
    return backtrace;
}

@end
