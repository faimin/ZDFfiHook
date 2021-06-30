#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "NSObject+ZDFfiHook.h"
#import "ZDFfiDefine.h"
#import "ZDFfiHookKit.h"
#import "NSObject+ZDAutoFree.h"
#import "NSObject+ZDFfiHook.h"
#import "ZDFfiDefine.h"
#import "ZDFfiFunctions.h"
#import "ZDFfiHook.h"
#import "ZDFfiHookInfo.h"
#import "ZDFfiHookKit.h"
#import "ffi.h"
#import "ffitarget.h"
#import "ffitarget_arm64.h"
#import "ffitarget_armv7.h"
#import "ffitarget_x86_64.h"
#import "ffi_arm64.h"
#import "ffi_armv7.h"
#import "ffi_x86_64.h"

FOUNDATION_EXPORT double ZDFfiHookKitVersionNumber;
FOUNDATION_EXPORT const unsigned char ZDFfiHookKitVersionString[];

