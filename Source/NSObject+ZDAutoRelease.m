//
//  NSObject+ZDAutoRelease.m
//  ZDFfiHook
//
//  Created by Zero.D.Saber on 2020/6/22.
//  Copyright © 2020 Zero.D.Saber. All rights reserved.
//

#import "NSObject+ZDAutoFree.h"
#import <objc/runtime.h>

//========================================================
#pragma mark ZDWrapSelf
//========================================================
@interface ZDWrapSelf : NSObject

@property (nonatomic, copy, readonly) void(^deallocBlock)(id unsafeSelf);
@property (nonatomic, unsafe_unretained, readonly) id realTarget;

- (instancetype)initWithBlock:(void(^)(id unsafeSelf))deallocBlock realTarget:(id)realTarget;

@end

@implementation ZDWrapSelf

- (instancetype)initWithBlock:(void(^)(id unsafeSelf))deallocBlock realTarget:(id)realTarget {
    self = [super init];
    if (self) {
        //属性设为readonly,并用指针指向方式,是参照RACDynamicSignal中的写法
        self->_deallocBlock = [deallocBlock copy];
        self->_realTarget = realTarget;
    }
    return self;
}

- (void)dealloc {
    if (nil != self.deallocBlock) {
        self.deallocBlock(self.realTarget);
#if DEBUG
        NSLog(@"成功移除对象");
#endif
    }
}

@end

@implementation NSObject (ZDAutoRelease)

- (void)zdAutoFree_deallocBlock:(void(^)(id unsafeSelf))deallocBlock {
    if (!deallocBlock) {
        return;
    }
    
    @autoreleasepool {
        NSMutableArray *blocks = objc_getAssociatedObject(self, _cmd);
        if (!blocks) {
            blocks = [[NSMutableArray alloc] init];
            objc_setAssociatedObject(self, _cmd, blocks, OBJC_ASSOCIATION_RETAIN);
        }
        ZDWrapSelf *blockExecutor = [[ZDWrapSelf alloc] initWithBlock:deallocBlock realTarget:self];
        /// 原理: 当self释放时,它所绑定的属性也自动会释放
        [blocks addObject:blockExecutor];
    }
}

@end
