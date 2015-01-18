//
//  JsonOps.m
//  SkipChat
//
//  Created by Anish Athalye on 1/17/15.
//  Copyright (c) 2015 SkipChat. All rights reserved.
//

#import "JsonOps.h"

@implementation JsonOps

+ (NSMutableDictionary *) jsonFromData:(NSData *) data
{
    NSError *error;
    id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if ([json isKindOfClass:[NSMutableDictionary class]]) {
        return json;
    }
    return nil;
}

+ (NSData *) dataFromJson:(NSDictionary *) dict
{
    NSError *error;
    if ([NSJSONSerialization isValidJSONObject:dict]) {
        return [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    }
    return nil;
}

@end
