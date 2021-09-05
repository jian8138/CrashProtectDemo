//
//  TestObserver.m
//  ZJProtectCrashDemo
//
//  Created by LZJ_Work on 2021/8/29.
//

#import "TestObserver.h"

@implementation TestObserver

- (void)testMethod {
    NSLog(@"testMethod --- ");
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"%s %@ %@", __FUNCTION__, keyPath, change);
}

- (void)dealloc {
    NSLog(@"---- %@ dealloc ---- %@", [self class], self);
}

@end
