//
//  Crypto.m
//  SkipChat
//
//  Created by Anish Athalye on 1/17/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//

#import "Crypto.h"
#import <openssl/rand.h>
#import <openssl/rsa.h>

#define RNG_SEED_BYTES (20)

@interface Crypto ()

+ (void) maybeSeedRNG;

@end

@implementation Crypto

+ (void) maybeSeedRNG
{
    static BOOL seeded = NO;
    if (!seeded) {
        uint8_t bytes[RNG_SEED_BYTES];
        SecRandomCopyBytes(kSecRandomDefault, RNG_SEED_BYTES, bytes);
        RAND_seed(bytes, RNG_SEED_BYTES);
        seeded = YES;
    }
}

+ (KeyPair *) genKeyPair
{
    [self maybeSeedRNG];
    return nil;
}

+ (NSData *) sign:(NSData *) message with:(NSData *) privateKey andEncryptFor:(NSData *) publicKey
{
    return nil;
}

+ (BOOL) decrypt:(NSData *) blob with:(NSData *)privateKey into:(NSData **) buffer from:(NSData **) publicKey
{
    return NO;
}

@end
