//
//  KeyPair.h
//  SkipChat
//
//  Created by Anish Athalye on 1/17/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyPair : NSObject

@property (nonatomic, strong) NSData *privateKey;
@property (nonatomic, strong) NSData *publicKey;

@end
