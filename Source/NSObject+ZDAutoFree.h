//
//  NSObject+ZDAutoFree.h
//  ZDFfiHook
//
//  Created by Zero.D.Saber on 2020/6/22.
//  Copyright © 2020 Zero.D.Saber. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ZDAutoFree)

- (void)zdAutoFree_deallocBlock:(void(^)(id unsafeSelf))deallocBlock;

@end

NS_ASSUME_NONNULL_END
