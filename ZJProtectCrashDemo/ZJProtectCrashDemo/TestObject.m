//
//  TestObject.m
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/28.
//

#import "TestObject.h"

@implementation TestObject

- (instancetype)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationMethod) name:@"NSNotificationName" object:nil];
    }
    return self;
}

- (void)notificationMethod {
    NSLog(@"--- %s ---", __func__);
}

- (void)dealloc {
    NSLog(@"---- %@ dealloc ----", [self class]);
}

@end
