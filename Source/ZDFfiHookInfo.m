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

- (void)addHookInfo:(ZDFfiHookInfo *)callbackInfo {
    if (!callbackInfo) {
        return;
    }
    
    switch (callbackInfo.option) {
        case ZDHookOption_Befor: {
            self.beforeCallbacks = [(self.beforeCallbacks ?: @[]) arrayByAddingObject:callbackInfo];
        } break;
        case ZDHookOption_Instead: {
            self.insteadCallbacks = [(self.insteadCallbacks ?: @[]) arrayByAddingObject:callbackInfo];
        } break;
        case ZDHookOption_After:
        default: {
            self.afterCallbacks = [(self.afterCallbacks ?: @[]) arrayByAddingObject:callbackInfo];
        } break;
    }
}

- (BOOL)removeHookInfo:(ZDFfiHookInfo *)callbackInfo {
    __block BOOL finded = NO;
    __auto_type block = ^(NSString *keyPath){
        NSArray *targetArray = [self valueForKey:keyPath];
        NSMutableArray *mutBeforInfos = [NSMutableArray arrayWithArray:targetArray];
        NSUInteger targetIndex = [mutBeforInfos indexOfObjectIdenticalTo:callbackInfo];
        if (targetIndex != NSNotFound) {
            [mutBeforInfos removeObjectAtIndex:targetIndex];
            [self setValue:mutBeforInfos forKey:keyPath];
            finded = YES;
        }
    };
    switch (callbackInfo.option) {
        case ZDHookOption_Befor: {
            block(NSStringFromSelector(@selector(beforeCallbacks)));
        } break;
        case ZDHookOption_Instead: {
            block(NSStringFromSelector(@selector(insteadCallbacks)));
        } break;
        case ZDHookOption_After:
        default: {
            block(NSStringFromSelector(@selector(afterCallbacks)));
        } break;
    }
    return finded;
}

@end
