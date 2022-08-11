//
//  NSObject+ZDAutoFree.m
//  ZDFfiHook
//
//  Created by Zero.D.Saber on 2020/6/22.
//  Copyright © 2020 Zero.D.Saber. All rights reserved.
//

#import "NSObject+ZDAutoFree.h"
#import <objc/runtime.h>

@interface ZD_AVOID_ALL_LOAD_FLAG_FOR_CATEGORY_NSObject_ZDAutoFree : NSObject @end
@implementation ZD_AVOID_ALL_LOAD_FLAG_FOR_CATEGORY_NSObject_ZDAutoFree @end

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
    if (self = [super init]) {
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

@implementation NSObject (ZDAutoFree)

- (void)zdAutoFree_deallocBlock:(void(^)(id unsafeSelf))deallocBlock {
    if (!deallocBlock) {
        return;
    }
    
    NSMutableArray<ZDWrapSelf *> *blocks = objc_getAssociatedObject(self, _cmd);
    if (!blocks) {
        blocks = [[NSMutableArray alloc] init];
        objc_setAssociatedObject(self, _cmd, blocks, OBJC_ASSOCIATION_RETAIN);
    }
    ZDWrapSelf *blockExecutor = [[ZDWrapSelf alloc] initWithBlock:deallocBlock realTarget:self];
    [blocks addObject:blockExecutor];
}

@end
