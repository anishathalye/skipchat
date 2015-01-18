//
//  JsonOps.h
//  SkipChat
//
//  Created by Anish Athalye on 1/17/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JsonOps : NSObject

+ (NSDictionary *) jsonFromData:(NSData *) data;
+ (NSData *) dataFromJson:(NSDictionary *) dict;

@end
