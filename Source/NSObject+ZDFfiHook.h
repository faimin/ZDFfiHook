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

@class ZDFfiHookInfo;
@interface NSObject (ZDFfiHook)

+ (ZDFfiHookInfo *)zd_hookInstanceMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback;

+ (ZDFfiHookInfo *)zd_hookClassMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback;

- (ZDFfiHookInfo *)zd_hookInstanceMethod:(SEL)selector option:(ZDHookOption)option callback:(id)callback;

+ (BOOL)zd_removeHookToken:(ZDFfiHookInfo *)token;

/// normaly don't need remove instance hook manually, it will auto remove at dealloc
- (BOOL)zd_removeHookToken:(ZDFfiHookInfo *)token;

@end

NS_ASSUME_NONNULL_END
