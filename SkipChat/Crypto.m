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
#import <openssl/sha.h>
#import <openssl/pem.h>

#define RNG_SEED_BYTES (20)
#define RSA_BITS (4096)
#define RSA_EXPONENT (65537) // see docs for recommendations, or http://en.wikipedia.org/wiki/Coppersmith%27s_Attack

@interface Crypto ()

+ (void) maybeSeedRNG;

+ (NSDate *) dateFromString:(NSString *) string;

+ (NSString *) stringFromDate:(NSDate *) date;

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

+ (NSDate *) dateFromString:(NSString *) string
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";
    return [dateFormatter dateFromString:string];
}

+ (NSString *) stringFromDate:(NSDate *) date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";
    return [dateFormatter stringFromDate:date];
}

+ (NSData *) sign:(NSData *) message
             with:(NSData *) privateKey
    andEncryptFor:(NSData *) publicKey
{
    [self maybeSeedRNG];

    BIO *bio;
    unsigned char *buf;

    // create chunk
    NSMutableDictionary *chunk = [[NSMutableDictionary alloc] init];
    [chunk setValue:[message base64EncodedStringWithOptions:0] forKey:@"message"];
    [chunk setValue:[self stringFromDate:[NSDate date]] forKey:@"timestamp"];
    [chunk setValue:[publicKey base64EncodedStringWithOptions:0] forKey:@"public_key"];
    NSData *chunkData = [JsonOps dataFromJson:chunk];

    // create signature
    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256(chunkData.bytes, chunkData.length, hash);
    NSMutableData *mutPrivateKey = [privateKey mutableCopy];
    bio = BIO_new_mem_buf(mutPrivateKey.mutableBytes, mutPrivateKey.length);
    RSA *rsaPrivateKey = PEM_read_bio_RSAPrivateKey(bio, NULL, NULL, NULL);
    BIO_free_all(bio);
    buf = malloc(RSA_size(rsaPrivateKey));
    unsigned int sigLength;
    if (RSA_sign(NID_sha256, hash, SHA256_DIGEST_LENGTH, buf, &sigLength, rsaPrivateKey) != 1) {
        NSLog(@"Error signing");
        return nil;
    }
    RSA_free(rsaPrivateKey);
    NSData *signature = [NSData dataWithBytes:buf length:sigLength];
    free(buf);

    // create data to be symmetric encrypted
    NSMutableDictionary *symmetricPlaintext = [[NSMutableDictionary alloc] init];
    [symmetricPlaintext setValue:chunk forKey:@"chunk"];
    [symmetricPlaintext setValue:signature forKey:@"signature"];
    NSData *symmetricPlaintextData = [JsonOps dataFromJson:symmetricPlaintext];

    // perform symmetric cipher
    unsigned char key[EVP_MAX_KEY_LENGTH], iv[EVP_MAX_IV_LENGTH];
    int outLength1, outLength2;
    if (!RAND_bytes(key, sizeof(key))) {
        NSLog(@"Failed to generate random key");
        return nil;
    }
    if (!RAND_bytes(iv, sizeof(iv))) {
        NSLog(@"Failed to generate random iv");
        return nil;
    }
    int maxLength = symmetricPlaintextData.length + EVP_MAX_BLOCK_LENGTH - 1; // see docs for calculation
    buf = malloc(maxLength);
    EVP_CIPHER_CTX ctx;
    EVP_CIPHER_CTX_init(&ctx);
    EVP_EncryptInit_ex(&ctx, EVP_aes_256_cbc(), NULL, key, iv);
    EVP_EncryptUpdate(&ctx, buf, &outLength1, symmetricPlaintextData.bytes, symmetricPlaintextData.length);
    EVP_EncryptFinal_ex(&ctx, buf + outLength1, &outLength2);
    EVP_CIPHER_CTX_cleanup(&ctx);
    NSData *symmetricEncrypted = [NSData dataWithBytes:buf length:(outLength1 + outLength2)];
    free(buf);

    // encrypt symmetric key
    NSString *ivData = [[NSData dataWithBytes:iv length:sizeof(iv)] base64EncodedStringWithOptions:0];
    NSString *keyData = [[NSData dataWithBytes:key length:sizeof(key)] base64EncodedStringWithOptions:0];
    NSMutableDictionary *symmetricKey = [[NSMutableDictionary alloc] init];
    [symmetricKey setValue:ivData forKey:@"iv"];
    [symmetricKey setValue:keyData forKey:@"key"];
    NSData *symmetricKeyData = [JsonOps dataFromJson:symmetricKey];
    NSMutableData *mutPublicKey = [publicKey mutableCopy];
    bio = BIO_new_mem_buf(mutPublicKey.mutableBytes, mutPublicKey.length);
    RSA *rsaPublicKey = PEM_read_bio_RSAPublicKey(bio, NULL, NULL, NULL);
    BIO_free_all(bio);
    buf = malloc(RSA_size(rsaPublicKey));
    int outLength;
    if ((outLength = RSA_public_encrypt(symmetricKeyData.length, symmetricKeyData.bytes, buf, rsaPublicKey, RSA_PKCS1_PADDING)) < 0) {
        NSLog(@"Error encrypting symmetric key");
        return nil;
    }
    NSString *encryptedKey = [[NSData dataWithBytes:buf length:outLength] base64EncodedStringWithOptions:0];
    free(buf);
    RSA_free(rsaPublicKey);

    // create blob
    NSMutableDictionary *blob = [[NSMutableDictionary alloc] init];
    [blob setValue:encryptedKey forKey:@"key_data"];
    [blob setValue:[symmetricEncrypted base64EncodedStringWithOptions:0] forKey:@"encrypted"];
    return [JsonOps dataFromJson:blob];
}

+ (BOOL) decrypt:(NSData *) blob
            with:(NSData *) privateKey
            into:(NSData **) buffer
            from:(NSData **) publicKey
              at:(NSDate **) date
{
    return NO;
}

@end
