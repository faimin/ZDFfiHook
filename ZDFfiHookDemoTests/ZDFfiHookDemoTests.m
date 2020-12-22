//
//  ZDFfiHookDemoTests.m
//  ZDFfiHookDemoTests
//
//  Created by Zero.D.Saber on 2020/10/26.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "ZDModelTests.h"
#import <ZDFfiHook/NSObject+ZDFfiHook.h>
#import <Aspects/Aspects.h>

#define TestKVO (1)

@interface ZDFfiHookDemoTests : XCTestCase
@property (nonatomic, strong) ZDModelTests *model;
@end

@implementation ZDFfiHookDemoTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.model = [ZDModelTests new];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSString *newValue = change[NSKeyValueChangeNewKey];
    NSLog(@"kvo name = %@", newValue);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
#if TestKVO
    @try {
        [self.model removeObserver:self forKeyPath:@"name"];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
    } @finally {
        //
    }
#endif
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
}

- (void)testKVO {
    Class cls = object_getClass(self.model);
    printf("真实class = %s\n", object_getClassName(cls));
    
    self.model.name = @"小明";
    
    {
        [self.model zd_hookInstanceMethod:@selector(setName:) option:ZDHookOption_After callback:^(NSString *name){
            NSLog(@"hooked name = %@", name);
        }];
        
        Class cls1 = object_getClass(self.model);
        printf("真实class1 = %s\n", object_getClassName(cls1));
    }
    
    {
        // KVO
        [self.model addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
        
        Class cls3 = object_getClass(self.model);
        printf("真实class3 = %s\n", object_getClassName(cls3));
    }
    
    {
#if TestKVO
        [self.model zd_hookInstanceMethod:@selector(setAge:) option:ZDHookOption_After callback:^(NSInteger age){
            NSLog(@"hooked age = %zd", age);
        }];
        
        Class cls2 = object_getClass(self.model);
        printf("真实class2 = %s\n", object_getClassName(cls2));
#endif
    }
    
    self.model.name = @"小黑";
    self.model.age = 19;
}

- (void)testAspectHook {
    [self.model aspect_hookSelector:@selector(setName:) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo, NSString *name) {
        NSLog(@"aspectname = %@", name);
    } error:nil];
    
    Class cls1 = object_getClass(self.model);
    printf("真实class1 = %s\n", object_getClassName(cls1));
    
    [self.model zd_hookInstanceMethod:@selector(setName:) option:ZDHookOption_After callback:^(NSString *name){
        NSLog(@"hooked name = %@", name);
    }];
    
    Class cls2 = object_getClass(self.model);
    printf("真实class2 = %s\n", object_getClassName(cls2));
    
    self.model.name = @"小明";
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
