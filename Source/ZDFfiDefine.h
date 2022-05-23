//
//  ZDFfiDefine.h
//  ZDLibffi
//
//  Created by Zero.D.Saber on 2019/12/12.
//  Copyright © 2019 Zero.D.Saber. All rights reserved.
//

#ifndef ZDBlockDefine_h
#define ZDBlockDefine_h

#pragma mark - Block Define
#pragma mark -

// http://clang.llvm.org/docs/Block-ABI-Apple.html#high-level
// https://github.com/apple/swift-corelibs-libdispatch/blob/main/src/BlocksRuntime/Block_private.h
// Values for Block_layout->flags to describe block objects
typedef NS_OPTIONS(NSUInteger, ZDBlockDescriptionFlags) {
    BLOCK_DEALLOCATING =      (0x0001),  // runtime
    BLOCK_REFCOUNT_MASK =     (0xfffe),  // runtime
    BLOCK_NEEDS_FREE =        (1 << 24), // runtime
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25), // compiler
    BLOCK_HAS_CTOR =          (1 << 26), // compiler: helpers have C++ code
    BLOCK_IS_GC =             (1 << 27), // runtime
    BLOCK_IS_GLOBAL =         (1 << 28), // compiler
    BLOCK_USE_STRET =         (1 << 29), // compiler: undefined if !BLOCK_HAS_SIGNATURE
    BLOCK_HAS_SIGNATURE  =    (1 << 30), // compiler
    BLOCK_HAS_EXTENDED_LAYOUT=(1 << 31)  // compiler
};

// revised new layout

#define ZDBLOCK_DESCRIPTOR_1 1
struct ZDBlock_descriptor_1 {
    unsigned long int reserved;
    unsigned long int size;
};

#define ZDBLOCK_DESCRIPTOR_2 1
struct ZDBlock_descriptor_2 {
    // requires BLOCK_HAS_COPY_DISPOSE
    void (*copy)(void *dst, const void *src);
    void (*dispose)(const void *);
};

#define ZDBLOCK_DESCRIPTOR_3 1
struct ZDBlock_descriptor_3 {
    // requires BLOCK_HAS_SIGNATURE
    const char *signature;
    const char *layout;     // contents depend on BLOCK_HAS_EXTENDED_LAYOUT
};

struct ZDBlock_layout {
    void *isa;  // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    volatile int flags; // contains ref count
    int reserved;
    void (*invoke)(void *, ...);
    struct ZDBlock_descriptor_1 *descriptor;
    // imported variables
};

//*******************************************************

typedef struct ZDBlock_layout ZDBlock;
typedef void * ZDBlockIMP;

//*******************************************************

/*
typedef NS_ENUM(NSInteger, ZDHookMethodType) {
    ZDHookMethodType_None           = 0,
    ZDHookMethodType_Instance       = 1,        // 类的实例方法
    ZDHookMethodType_Class          = 2,        // 类方法
    ZDHookMethodType_SingleInstance = 3,        // 单个实例
};
 */

typedef NS_OPTIONS(NSInteger, ZDHookOption) {
    ZDHookOption_None               = 0,
    ZDHookOption_Default            = 1 << 0,
    ZDHookOption_After              = ZDHookOption_Default,// Called after the original implementation
    ZDHookOption_Instead            = 1 << 1,        // Will replace the original implementation.
    ZDHookOption_Befor              = 1 << 2,        // Called before the original implementation.
    //ZDHookOption_AutoRemoval        = 1 << 3,        // Will remove the hook after the first execution.
};

//*******************************************************

#endif /* ZDBlockDefine_h */
