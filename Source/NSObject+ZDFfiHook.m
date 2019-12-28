//
//  NSObject+ZDFfiHook.m
//  ZDFfiHook
//
//  Created by Zero.D.Saber on 2019/12/20.
//  Copyright © 2019 Zero.D.Saber. All rights reserved.
//

#import "NSObject+ZDFfiHook.h"
#import <objc/runtime.h>
#import "ZDFfiHook.h"

@implementation NSObject (ZDFfiHook)

+ (void)zd_hookInstanceMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback {
    Method method = class_getInstanceMethod(self, selector);
    ZD_CoreHookFunc(self, method, option, callback);
}

+ (void)zd_hookClassMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback {
    Class realClass = object_getClass(self);
    Method method = class_getClassMethod(realClass, selector);
    ZD_CoreHookFunc(realClass, method, option, callback);
}

- (void)zd_hookInstanceMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback {
    Method method = class_getInstanceMethod(self.class, selector);
    ZD_CoreHookFunc(self, method, option, callback);
}

@end
