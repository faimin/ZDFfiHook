//
//  ZDFfiHookInfo.m
//  ZDFfiHook
//
//  Created by Zero.D.Saber on 2019/12/20.
//  Copyright © 2019 Zero.D.Saber. All rights reserved.
//

#import "ZDFfiHookInfo.h"
#import "ZDFfiFunctions.h"

@implementation ZDFfiHookInfo

- (void)dealloc {
    printf("%s\n", __PRETTY_FUNCTION__);
    
    if (_cif) {
        free(_cif);
        _cif = NULL;
    }
    if (_closure) {
        ffi_closure_free(_closure);
        _closure = NULL;
    }
    if (_argTypes) {
        free(_argTypes);
        _argTypes = NULL;
    }
}

+ (instancetype)infoWithObject:(id)obj method:(Method)method {
    if (!obj) {
        return nil;
    }
    
    ZDFfiHookInfo *model = [[ZDFfiHookInfo alloc] init];
    model.isBlock = [obj isKindOfClass:objc_lookUpClass("NSBlock")];
    model.obj = obj;
    model.method = method;
    {
        const char *typeEncoding = model.isBlock ? ZDFfi_ReduceBlockSignatureCodingType(ZDFfi_BlockSignatureTypes(obj)).UTF8String : method_getTypeEncoding(method);
        NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:typeEncoding];
        model.signature = signature;
        model.typeEncoding = typeEncoding;
        
        model->_originalIMP = model.isBlock ? ZDFfi_BlockInvokeIMP(obj) : (void *)method_getImplementation(method);
    }
//    if (callback) {
//        model.callbackInfo = [self infoWithObject:callback method:NULL option:ZDHookOption_After callback:nil];
//    }
    
    return model;
}

+ (instancetype)infoWithCallback:(id)callback option:(ZDHookOption)option {
    if (!callback) {
        return nil;
    }
    
    ZDFfiHookInfo *model = [[ZDFfiHookInfo alloc] init];
    model.isBlock = [callback isKindOfClass:objc_lookUpClass("NSBlock")];
    model.callback = callback;
    model.option = option;
    if (model.isBlock) {
        const char *typeEncoding = ZDFfi_ReduceBlockSignatureCodingType(ZDFfi_BlockSignatureTypes(callback)).UTF8String;
        NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:typeEncoding];
        model.signature = signature;
        model.typeEncoding = typeEncoding;
        
        model->_originalIMP = ZDFfi_BlockInvokeIMP(callback);
    }
    
    return model;
}

@end
