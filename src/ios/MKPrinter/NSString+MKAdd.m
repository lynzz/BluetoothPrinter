//
//  NSString+MKAdd.m
//  MKToolsKit
//
//  Created by xiaomk on 16/9/9.
//  Copyright © 2016年 xiaomk. All rights reserved.
//

#import "NSString+MKAdd.h"

@implementation NSString(MKAdd)

- (id)mk_jsonString2Dictionary{
    NSData *jsonData = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        NSLog(@"json解析失败:%@",error);
        return nil;
    }
    return dic;
}

- (NSDictionary *)mk_dictionaryWithJsonString{
    if (self.length == 0) {
        return nil;
    }
    return [self mk_jsonString2Dictionary];
}

@end
