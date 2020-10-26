//
//  ZDFfiFunctions.h
//  ZDFfiHook
//
//  Created by Zero.D.Saber on 2019/12/20.
//  Copyright © 2019 Zero.D.Saber. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libffi-core/ffi.h>
#import "ZDFfiDefine.h"

NS_ASSUME_NONNULL_BEGIN

/// 获取block方法签名
FOUNDATION_EXPORT const char *_Nullable ZDFfi_BlockSignatureTypes(id block);

/// 获取block的函数指针
FOUNDATION_EXPORT ZDBlockIMP _Nullable ZDFfi_BlockInvokeIMP(id block);

/// 消息转发专用的IMP
FOUNDATION_EXPORT IMP ZDFfi_MsgForwardIMP(void);

/// 简化block的方法签名
FOUNDATION_EXPORT NSString *ZDFfi_ReduceBlockSignatureCodingType(const char *signatureCodingType);

/// 方法签名转化为ffi-type
FOUNDATION_EXPORT ffi_type *_Nullable ZDFfi_ffiTypeFromTypeEncoding(const char *type);

/// 获取参数
FOUNDATION_EXPORT id _Nullable ZDFfi_ArgumentAtIndex(NSMethodSignature *methodSignature, void *_Nullable* _Nullable args, NSUInteger index);

NS_ASSUME_NONNULL_END
