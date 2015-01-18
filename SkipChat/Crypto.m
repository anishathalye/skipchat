//
//  Crypto.m
//  SkipChat
//
//  Created by Anish Athalye on 1/17/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//

#import "Crypto.h"
#import "JsonOps.h"
#import <openssl/rand.h>
#import <openssl/evp.h>
#import <openssl/bio.h>
#import <openssl/rsa.h>
#import <openssl/pem.h>

#define RNG_SEED_BYTES (20)
#define RSA_BITS (4096)
#define RSA_EXPONENT (65537) // see docs for recommendations, or http://en.wikipedia.org/wiki/Coppersmith%27s_Attack

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

    KeyPair *kp = [[KeyPair alloc] init];

    RSA *rsa = RSA_generate_key(RSA_BITS, RSA_EXPONENT, NULL, NULL);
    BIO *bio;
    int keyLength;

    // serialize private key
    bio = BIO_new(BIO_s_mem());
    if (PEM_write_bio_RSAPrivateKey(bio, rsa, NULL, NULL, 0, NULL, NULL) != 1) {
        NSLog(@"Failed to write RSA private key");
        return nil;
    }
    keyLength = BIO_pending(bio);
    NSMutableData *privateKey = [[NSMutableData alloc] initWithLength:(keyLength + 1)]; // reserve space for '\0'
    BIO_read(bio, privateKey.mutableBytes, keyLength);
    BIO_free_all(bio);
    kp.privateKey = [NSData dataWithData:privateKey]; // immutable copy

    // serialize public key
    bio = BIO_new(BIO_s_mem());
    if (PEM_write_bio_RSAPublicKey(bio, rsa) != 1) {
        NSLog(@"Failed to write RSA public key");
        return nil;
    }
    keyLength = BIO_pending(bio);
    NSMutableData *publicKey = [[NSMutableData alloc] initWithLength:(keyLength + 1)]; // reserve space for '\0'
    BIO_read(bio, publicKey.mutableBytes, keyLength);
    BIO_free_all(bio);
    kp.publicKey = [NSData dataWithData:publicKey]; // immutable copy

    RSA_free(rsa);

    return kp;
}

+ (NSData *) sign:(NSData *) message with:(NSData *) privateKey andEncryptFor:(NSData *) publicKey
{
    [self maybeSeedRNG];
    return nil;
}

+ (BOOL) decrypt:(NSData *) blob with:(NSData *)privateKey into:(NSData **) buffer from:(NSData **) publicKey
{
    [self maybeSeedRNG];
    return NO;
}

@end
