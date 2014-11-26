//
//  StringB.m
//  BaiyiSpeed
//
//  Created by Pan on 14/11/25.
//  Copyright (c) 2014年 AILK. All rights reserved.
//

#import "StringB.h"

@implementation StringB

//字符串去两边空格
+(NSString*)trim:(NSString *)targetString
{
    return [targetString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
