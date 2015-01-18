//
//  KeyPair.m
//  SkipChat
//
//  Created by Anish Athalye on 1/17/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//

#import "KeyPair.h"

@implementation KeyPair

+ (KeyPair *) fromPublicKey:(NSData *) publicKey andPrivateKey:(NSData *) privateKey
{
    KeyPair *pair = [[KeyPair alloc] init];
    pair.privateKey = privateKey;
    pair.publicKey = publicKey;
    return pair;
}

@end
