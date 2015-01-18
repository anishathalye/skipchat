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

+ (NSData *) dataForKey:(NSString *)key in:(NSData *)data;

+ (NSString *) stringForKey:(NSString *)key in:(NSData *)data;

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
             with:(KeyPair *) keyPair
    andEncryptFor:(NSData *) publicKey
{
    [self maybeSeedRNG];

    BIO *bio;
    unsigned char *buf;

    // create chunk
    NSMutableDictionary *chunk = [[NSMutableDictionary alloc] init];
    [chunk setObject:[message base64EncodedStringWithOptions:0] forKey:@"message"];
    [chunk setObject:[self stringFromDate:[NSDate date]] forKey:@"timestamp"];
    [chunk setObject:[keyPair.publicKey base64EncodedStringWithOptions:0] forKey:@"sender_public_key"];
    [chunk setObject:[publicKey base64EncodedStringWithOptions:0] forKey:@"public_key"];
    NSData *chunkData = [JsonOps dataFromJson:chunk];

    // create signature
    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256(chunkData.bytes, chunkData.length, hash);
    NSMutableData *mutPrivateKey = [keyPair.privateKey mutableCopy];
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
    [symmetricPlaintext setObject:[chunkData base64EncodedStringWithOptions:0] forKey:@"chunk"];
    [symmetricPlaintext setObject:[signature base64EncodedStringWithOptions:0] forKey:@"signature"];
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
    [symmetricKey setObject:ivData forKey:@"iv"];
    [symmetricKey setObject:keyData forKey:@"key"];
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
    [blob setObject:encryptedKey forKey:@"key_data"];
    [blob setObject:[symmetricEncrypted base64EncodedStringWithOptions:0] forKey:@"encrypted"];
    return [JsonOps dataFromJson:blob];
}

+ (NSData *) dataForKey:(NSString *)key in:(NSData *)data
{
    NSDictionary *json = [JsonOps jsonFromData:data];
    id object = [json objectForKey:key];
    if ([object isKindOfClass:[NSString class]]) {
        NSString *string = object;
        NSData *data = [[NSData alloc] initWithBase64EncodedString:string options:0];
        return data;
    }
    return nil;
}

+ (NSString *) stringForKey:(NSString *)key in:(NSData *)data
{
    NSDictionary *json = [JsonOps jsonFromData:data];
    id object = [json objectForKey:key];
    if ([object isKindOfClass:[NSString class]]) {
        NSString *string = object;
        return string;
    }
    return nil;
}

#define DECODE_OR_DIE(name, key, data) \
    NSData *name = [self dataForKey:key in:data]; \
    if (name == nil) { \
        NSLog(@"Failed to extract key %@", key); \
        return NO; \
    }

+ (NSData *) decrypt:(NSData *) blob
            with:(KeyPair *) keyPair
            from:(NSData **) publicKey
              at:(NSDate **) date
{
    BIO *bio;
    unsigned char *buf;

    // unpack blob
    DECODE_OR_DIE(encryptedKey, @"key_data", blob);
    DECODE_OR_DIE(encryptedSymmetric, @"encrypted", blob);

    // try to recover the secret key using our private key
    NSMutableData *mutPrivateKey = [keyPair.privateKey mutableCopy];
    bio = BIO_new_mem_buf(mutPrivateKey.mutableBytes, mutPrivateKey.length);
    RSA *rsaPrivateKey = PEM_read_bio_RSAPrivateKey(bio, NULL, NULL, NULL);
    BIO_free_all(bio);
    buf = malloc(RSA_size(rsaPrivateKey));
    int bufLength;
    if ((bufLength = RSA_private_decrypt(encryptedKey.length, encryptedKey.bytes, buf, rsaPrivateKey, RSA_PKCS1_PADDING)) < 0) {
        NSLog(@"Failed to decrypt symmetric key");
        return nil;
    }
    NSData *keyData = [NSData dataWithBytes:buf length:bufLength];
    free(buf);

    // unpack key
    DECODE_OR_DIE(iv, @"iv", keyData);
    DECODE_OR_DIE(key, @"key", keyData);

    // decrypt message
    int outLength1, outLength2;
    int maxLength = encryptedSymmetric.length + EVP_MAX_BLOCK_LENGTH; // see docs for calculation
    buf = malloc(maxLength);
    EVP_CIPHER_CTX ctx;
    EVP_CIPHER_CTX_init(&ctx);
    if (EVP_DecryptInit_ex(&ctx, EVP_aes_256_cbc(), NULL, key.bytes, iv.bytes) != 1) {
        NSLog(@"Decrypt init failed");
        return nil;
    }
    if (EVP_DecryptUpdate(&ctx, buf, &outLength1, encryptedSymmetric.bytes, encryptedSymmetric.length) != 1) {
        NSLog(@"Decrypt update failed");
        return nil;
    }
    if (EVP_DecryptFinal_ex(&ctx, buf + outLength1, &outLength2) != 1) {
        NSLog(@"Decrypt final failed");
        return nil;
    }
    EVP_CIPHER_CTX_cleanup(&ctx);
    NSData *symmetric = [NSData dataWithBytes:buf length:(outLength1 + outLength2)];
    free(buf);

    // unpack
    DECODE_OR_DIE(chunk, @"chunk", symmetric);
    DECODE_OR_DIE(signature, @"signature", symmetric);

    // verify signature
    DECODE_OR_DIE(senderPublic, @"sender_public_key", chunk);
    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256(chunk.bytes, chunk.length, hash);
    NSMutableData *mutPublicKey = [senderPublic mutableCopy];
    bio = BIO_new_mem_buf(mutPublicKey.mutableBytes, mutPublicKey.length);
    RSA *rsaPublicKey = PEM_read_bio_RSAPublicKey(bio, NULL, NULL, NULL);
    if (rsaPublicKey == NULL) {
        NSLog(@"Error extracting sender public key");
        return nil;
    }
    BIO_free_all(bio);
    if (RSA_verify(NID_sha256, hash, SHA256_DIGEST_LENGTH, signature.bytes, signature.length, rsaPublicKey) != 1) {
        NSLog(@"Error validating signature");
        return nil;
    }
    RSA_free(rsaPublicKey);

    // verify recipient
    DECODE_OR_DIE(targetPublic, @"public_key", chunk);
    if (![targetPublic isEqualToData:keyPair.publicKey]) {
        NSLog(@"Mismatched recipient (malicious forwarding?)");
        return nil;
    }

    DECODE_OR_DIE(message, @"message", chunk);

    if (date != nil) {
        NSString *timestamp = [self stringForKey:@"timestamp" in:chunk];
        NSDate *time = [self dateFromString:timestamp];
        if (time == nil) {
            NSLog(@"Error extracting timestamp");
            return nil;
        }
        *date = time;
    }
    if (publicKey != nil) {
        *publicKey = senderPublic;
    }

    return message;
}

@end
