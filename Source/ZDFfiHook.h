#ifndef ZDFfiHook_h
#define ZDFfiHook_h

#if __has_include(<ZDFfiHook/ZDFfiDefine.h>)
#import <ZDFfiHook/ZDFfiDefine.h>
#elif __has_include("ZDFfiDefine.h")
#import "ZDFfiDefine.h"
#endif

#if __has_include(<ZDFfiHook/NSObject+ZDFfiHook.h>)
#import <ZDFfiHook/NSObject+ZDFfiHook.h>
#elif __has_include("NSObject+ZDFfiHook.h")
#import "NSObject+ZDFfiHook.h"
#endif

#endif
