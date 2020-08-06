//
//  ZDFfiFunctions.m
//  ZDFfiHook
//
//  Created by Zero.D.Saber on 2019/12/20.
//  Copyright © 2019 Zero.D.Saber. All rights reserved.
//

#import "ZDFfiFunctions.h"
#import <objc/message.h>

/// 不能直接通过blockRef->descriptor->signature获取签名，因为不同场景下的block结构有差别:
/// 比如当block内部引用了外面的局部变量，并且这个局部变量是OC对象，
/// 或者是`__block`关键词包装的变量，block的结构里面有copy和dispose函数，因为这两种变量都是属于内存管理的范畴的；
/// 其他场景下的block就未必有copy和dispose函数。
/// 所以这里是通过flag判断是否有签名，以及是否有copy和dispose函数，然后通过地址偏移找到signature的。
/// quote: https://github.com/apple/swift-corelibs-libdispatch/blob/master/src/BlocksRuntime/runtime.c
const char *ZDFfi_BlockSignatureTypes(id block) {
    if (!block) return NULL;
    
    ZDBlock *blockRef = (__bridge ZDBlock *)block;
    
    // unsigned long int size = blockRef->descriptor->size;
    ZDBlockDescriptionFlags flags = blockRef->flags;
    
    if ( !(flags & BLOCK_HAS_SIGNATURE) ) return NULL;
    
#if 0
    void *signatureLocation = blockRef->descriptor;
    signatureLocation += sizeof(unsigned long);
    signatureLocation += sizeof(unsigned long);
    if (flags & BLOCK_HAS_COPY_DISPOSE) {
        signatureLocation += sizeof(void(*)(void *dst, void *src));
        signatureLocation += sizeof(void(*)(void *src));
    }
    const char *signature = (*(const char **)signatureLocation);
#else
    uint8_t *desc = (uint8_t *)blockRef->descriptor;
    desc += sizeof(struct ZDBlock_descriptor_1);
    if (flags & BLOCK_HAS_COPY_DISPOSE) {
        desc += sizeof(struct ZDBlock_descriptor_2);
    }
    const char *signature = (*(const char **)desc);
#endif
    
    return signature;
}


ZDBlockIMP ZDFfi_BlockInvokeIMP(id block) {
    if (!block) return NULL;
    
    ZDBlock *blockRef = (__bridge ZDBlock *)block;
    return blockRef->invoke;
}


IMP ZDFfi_MsgForwardIMP(void) {
    IMP msgForwardIMP = _objc_msgForward;
#if !defined(__arm64__)
    msgForwardIMP = (IMP)_objc_msgForward_stret;
#endif
    return msgForwardIMP;
}


NSString *ZDFfi_ReduceBlockSignatureCodingType(const char *signatureCodingType) {
    NSString *charType = [NSString stringWithUTF8String:signatureCodingType];
    if (charType.length == 0) return nil;
    
    NSString *codingType = charType.copy;
    
    NSError *error = nil;
    NSString *regexString = @"\\\"[A-Za-z]+\\\"|\\\"<[A-Za-z]+>\\\"|[0-9]+";// <==> \\"[A-Za-z]+\\"|\d+  <==>  \\"\w+\\"|\\\"<w+>\\\"|\d+
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:0 error:&error];
    
    NSTextCheckingResult *mathResult = nil;
    do {
        mathResult = [regex firstMatchInString:codingType options:NSMatchingReportProgress range:NSMakeRange(0, codingType.length)];
        if (mathResult.range.location != NSNotFound && mathResult.range.length != 0) {
            codingType = [codingType stringByReplacingCharactersInRange:mathResult.range withString:@""];
        }
    } while (mathResult.range.length != 0);
    
    return codingType;
}


id ZDFfi_ArgumentAtIndex(NSMethodSignature *methodSignature, void **args, NSUInteger index) {
#define WRAP_AND_RETURN(type) \
do { \
type val = *((type *)args[index]);\
return @(val); \
} while (0)
    
    const char *originArgType = [methodSignature getArgumentTypeAtIndex:index];
//    NSString *argTypeString = ZD_ReduceBlockSignatureCodingType(originArgType);
//    const char *argType = argTypeString.UTF8String;
    const char *argType = originArgType;
    
    // Skip const type qualifier.
    if (argType[0] == 'r') {
        argType++;
    }
    
    if (strcmp(argType, @encode(id)) == 0 || strcmp(argType, @encode(Class)) == 0) {
        id argValue = (__bridge id)(*((void **)args[index]));
        return argValue;
    } else if (strcmp(argType, @encode(char)) == 0) {
        WRAP_AND_RETURN(char);
    } else if (strcmp(argType, @encode(int)) == 0) {
        WRAP_AND_RETURN(int);
    } else if (strcmp(argType, @encode(short)) == 0) {
        WRAP_AND_RETURN(short);
    } else if (strcmp(argType, @encode(long)) == 0) {
        WRAP_AND_RETURN(long);
    } else if (strcmp(argType, @encode(long long)) == 0) {
        WRAP_AND_RETURN(long long);
    } else if (strcmp(argType, @encode(unsigned char)) == 0) {
        WRAP_AND_RETURN(unsigned char);
    } else if (strcmp(argType, @encode(unsigned int)) == 0) {
        WRAP_AND_RETURN(unsigned int);
    } else if (strcmp(argType, @encode(unsigned short)) == 0) {
        WRAP_AND_RETURN(unsigned short);
    } else if (strcmp(argType, @encode(unsigned long)) == 0) {
        WRAP_AND_RETURN(unsigned long);
    } else if (strcmp(argType, @encode(unsigned long long)) == 0) {
        WRAP_AND_RETURN(unsigned long long);
    } else if (strcmp(argType, @encode(float)) == 0) {
        WRAP_AND_RETURN(float);
    } else if (strcmp(argType, @encode(double)) == 0) {
        WRAP_AND_RETURN(double);
    } else if (strcmp(argType, @encode(BOOL)) == 0) {
        WRAP_AND_RETURN(BOOL);
    } else if (strcmp(argType, @encode(char *)) == 0) {
        WRAP_AND_RETURN(const char *);
    } else if (strcmp(argType, @encode(void (^)(void))) == 0) {
        __unsafe_unretained id block = nil;
        block = (__bridge id)(*((void **)args[index]));
        return [block copy];
    }
    else {
        NSCAssert(NO, @"不支持的类型");
    }
    
    return nil;
#undef WRAP_AND_RETURN
}


ffi_type *ZDFfi_ffiTypeFromTypeEncoding(const char *type) {
    if (strcmp(type, "@?") == 0) { // block
        return &ffi_type_pointer;
    }
    const char *c = type;
    switch (c[0]) {
        case 'v':
            return &ffi_type_void;
        case 'c':
            return &ffi_type_schar;
        case 'C':
            return &ffi_type_uchar;
        case 's':
            return &ffi_type_sshort;
        case 'S':
            return &ffi_type_ushort;
        case 'i':
            return &ffi_type_sint;
        case 'I':
            return &ffi_type_uint;
        case 'l':
            return &ffi_type_slong;
        case 'L':
            return &ffi_type_ulong;
        case 'q':
            return &ffi_type_sint64;
        case 'Q':
            return &ffi_type_uint64;
        case 'f':
            return &ffi_type_float;
        case 'd':
            return &ffi_type_double;
        case 'F':
#if CGFLOAT_IS_DOUBLE
            return &ffi_type_double;
#else
            return &ffi_type_float;
#endif
        case 'B':
            return &ffi_type_uint8;
        case '@':
            return &ffi_type_pointer;
        case ':':
            return &ffi_type_schar;
        case '^':
            return &ffi_type_pointer;
        case '#':
            return &ffi_type_pointer;
        case '*':
            return &ffi_type_pointer;
        case '{':
        default: {
            printf("not support the type: %s", c);
        } break;
    }
    
    NSCAssert(NO, @"can't match a ffi_type of %s", type);
    return NULL;
}

