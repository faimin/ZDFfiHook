//
//  ZDFfiHook.h
//  ZDFfiHook
//
//  Created by Zero.D.Saber on 2019/12/20.
//  Copyright © 2019 Zero.D.Saber. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "ZDFfiHookInfo.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT ZDFfiHookInfo *ZD_CoreHookFunc(id obj, Method method, ZDHookOption option, id callback);

FOUNDATION_EXPORT BOOL ZD_RemoveHookTokenFunc(id self, ZDFfiHookInfo *token);

NS_ASSUME_NONNULL_END
