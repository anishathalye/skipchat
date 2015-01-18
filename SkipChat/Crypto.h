//
//  Crypto.h
//  SkipChat
//
//  Created by Anish Athalye on 1/17/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//

#import "KeyPair.h"
#import <Foundation/Foundation.h>

@interface Crypto : NSObject

+ (KeyPair *) genKeyPair;

+ (NSData *) sign:(NSData *) message
             with:(NSData *) privateKey
    andEncryptFor:(NSData *) publicKey;

+ (BOOL) decrypt:(NSData *) blob
            with:(NSData *) privateKey
            into:(NSData **) buffer
            from:(NSData **) publicKey
              at:(NSDate **) date;
@end
