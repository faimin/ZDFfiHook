//
//  ZDFfiHookTests.m
//  ZDFfiHookTests
//
//  Created by Zero.D.Saber on 2019/12/20.
//  Copyright © 2019 Zero.D.Saber. All rights reserved.
//

#import <XCTest/XCTest.h>
@import ObjectiveC;
@import Messages;
#import "NSObject+ZDFfiHook.h"

@interface ZDFfiHookTests : XCTestCase

@end

@implementation ZDFfiHookTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    Class a = NSObject.class;
    id b = NSArray.new;
    XCTAssertTrue(object_isClass(a));
    XCTAssertFalse(object_isClass(b));
    id xxx = object_getClass(NSArray.class);
    XCTAssertTrue(object_isClass(xxx));
    XCTAssertTrue(class_isMetaClass(xxx));
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

#pragma mark -

- (void)testHookClassInstance {
    // hook class
    [self.class zd_hookInstanceMethod:@selector(exeA:b:c:) option:ZDHookOption_After callback:^(NSInteger a, NSString *b, id c){
        NSLog(@"~~~~~~后hook");
    }];
    
    [self.class zd_hookInstanceMethod:@selector(exeA:b:c:) option:ZDHookOption_Befor callback:^(NSInteger a, NSString *b, id c){
        NSLog(@"~~~~~~先hook");
    }];
    
    id v = [self exeA:100 b:@"啦啦啦" c:NSObject.new];
    NSLog(@"***************** %@", v);
}

- (void)testHookInstance {
    [self zd_hookInstanceMethod:@selector(exeA:b:c:) option:ZDHookOption_After callback:^(NSInteger a, NSString *b, id c){
        NSLog(@"后hook instance");
    }];
    
    [self.class zd_hookInstanceMethod:@selector(exeA:b:c:) option:ZDHookOption_Befor callback:^(NSInteger a, NSString *b, id c){
        NSLog(@"先hook instance");
    }];
    
    id v = [self exeA:100 b:@"啦啦啦" c:NSObject.new];
    NSLog(@"***************** %@", v);
}

#pragma mark - Method

- (id)exeA:(NSInteger)a b:(NSString *)b c:(id)c {
    NSString *ret = [NSString stringWithFormat:@"结果 = %zd， %@， %@", a, b, c];
    return ret;
}

@end
