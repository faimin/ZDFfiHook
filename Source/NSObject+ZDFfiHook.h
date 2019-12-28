//
//  NSObject+ZDFfiHook.h
//  ZDFfiHook
//
//  Created by Zero.D.Saber on 2019/12/20.
//  Copyright © 2019 Zero.D.Saber. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZDFfiDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ZDFfiHook)

+ (void)zd_hookInstanceMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback;

+ (void)zd_hookClassMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback;

- (void)zd_hookInstanceMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback;

@end

NS_ASSUME_NONNULL_END
