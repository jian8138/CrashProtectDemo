//
//  ViewController.m
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/23.
//

#import "ViewController.h"
#import "ZJCrashManager.h"
#import "TestObject.h"
#import "TestObserver.h"

@interface ViewController () {
    __unsafe_unretained TestObject *_unsafeObj;
}

@property (nonatomic, strong) TestObject *test;

@property (nonatomic, strong) TestObserver *testObserver;

@end

typedef struct Test
{
    int a;
    int b;
}Test;


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    ZJCrashManager *manager = [ZJCrashManager manger];
    [manager startProtectWithOpiton:ZJCrashProtectOptionAll]; // 开始防止崩溃

    TestObject *obj = [[TestObject alloc] init];
    obj.number = 10086;
    _unsafeObj = obj;
//    [self performSelector:@selector(performMethod)];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 50)];
    [btn setTitle:@"alert" forState:UIControlStateNormal];
    [btn setBackgroundColor:[UIColor purpleColor]];
    [btn addTarget:self action:@selector(alertBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *crashBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, 200, 50)];
    [crashBtn setTitle:@"Catch Crash" forState:UIControlStateNormal];
    [crashBtn setBackgroundColor:[UIColor purpleColor]];
    [crashBtn addTarget:self action:@selector(crashBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:crashBtn];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self  performMethod];
    });
}

+ (UIViewController *)topViewController {
    UIViewController *resultVC;
    resultVC = [self _topViewController:[[UIApplication sharedApplication].keyWindow rootViewController]];
    while (resultVC.presentedViewController) {
        resultVC = [self _topViewController:resultVC.presentedViewController];
    }
    return resultVC;
}

+ (UIViewController *)_topViewController:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self _topViewController:[(UINavigationController *)vc topViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self _topViewController:[(UITabBarController *)vc selectedViewController]];
    } else {
        return vc;
    }
    return nil;
}

- (void)alertBtnAction:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"标题" message:@"这是一些信息" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *conform = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:nil];
    //2.2 取消按钮
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];

    //3.将动作按钮 添加到控制器中
    [alert addAction:conform];
    [alert addAction:cancel];

    //4.显示弹框
    [[ViewController topViewController] presentViewController:alert animated:YES completion:nil];
}

- (void)crashBtnAction:(UIButton *)sender {
    // Exception SIGABRT
//    [self performSelector:@selector(abc)];
//    NSArray *arr2 = @[@"1", @"2"];
//    [arr2 objectAtIndex:100];
    
    // SignalHandler不要在debug环境下测试。因为系统的debug会优先去拦截。要运行一次后，关闭debug状态。应该直接在模拟器上点击build上去的app去运行。
    // SIGSEGV
//    _unsafeObj.number = 100;
//    NSLog(@"unsafe --- %d", _unsafeObj.number); // 这可能会触发野指针崩溃 EXC_BAD_ACCESS()
    
    // SIGABRT
//    Test *pTest = {1,2};
//    free(pTest);//导致SIGABRT的错误，因为内存中根本就没有这个空间，哪来的free，就在栈中的对象而已
//    pTest->a = 5;
    
    //SIGBUS，内存地址未对齐
    //EXC_BAD_ACCESS(code=1,address=0x1000dba58)
    char *s = "hello world";
    *s = 'H';
}

- (void)performMethod {
    [self testNoSelectorCrash];
    [self testArrayCrash];
    [self testDictionaryCrash];
    [self testKVCCrash];
    [self testKVOCrash];
    [self testNotificationCrash];
}

- (void)testNoSelectorCrash {
    [self performSelector:@selector(abc)];
    [[self class] performSelector:@selector(def)];
}

- (void)testArrayCrash {
    NSObject *obj = nil;
    NSArray *arr1 = @[@"1", @"2", obj];
    NSArray *arr2 = @[@"1", @"2"];
    [arr2 objectAtIndex:100];
    arr2[101];
}

- (void)testDictionaryCrash {
    NSObject *obj = nil;
    NSObject *key = nil;
    NSDictionary *dict = @{ @"obj": obj, key: @"key", @"any" : @"object" };
    NSLog(@"dict --- %@", dict);
    
    NSMutableDictionary *mutDict = [NSMutableDictionary dictionaryWithDictionary:dict];
    [mutDict setObject:nil forKey:@"a"];
    mutDict[key] = @"b";
}

- (void)testKVCCrash {
    NSObject *objc = [[NSObject alloc] init];
    [objc setValue:nil forKey:nil];
    [objc valueForKey:nil];
    [objc setValue:@1 forKey:@"abc"];
    [objc valueForKey:@"def"];
}

- (void)testKVOCrash {
    TestObject *obj = [[TestObject alloc] init];
    TestObserver *observer = [[TestObserver alloc] init];
    [obj addObserver:observer forKeyPath:@"number" options:NSKeyValueObservingOptionNew context:nil];
    [obj addObserver:observer forKeyPath:@"number" options:NSKeyValueObservingOptionNew context:nil];
    obj.number = 1;
    [obj removeObserver:observer forKeyPath:@"number"];
    [obj removeObserver:observer forKeyPath:@"number"]; // 重复移除就会报错
    obj.number = 2;
    
    self.test = obj;
//    self.testObserver = observer;
}

- (void)testNotificationCrash {
    TestObject *obj = [[TestObject alloc] init]; // init的时候就添加通知，销毁时，不移除通知
    // iOS9.0后，即使不移除也不会crash了，但还是有可能会导致各种无法预测的错误发生
    self.test = obj;
//    [[NSNotificationCenter defaultCenter] removeObserver:obj]; // 重复移除不会报错
//    [[NSNotificationCenter defaultCenter] removeObserver:obj];
//    [[NSNotificationCenter defaultCenter] removeObserver:obj];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"--- %s ---", __FUNCTION__);
    self.test.number = 2; // 如果observer已经销毁，但没有移除KVO，会报错
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NSNotificationName" object:nil userInfo:nil];
}


@end
