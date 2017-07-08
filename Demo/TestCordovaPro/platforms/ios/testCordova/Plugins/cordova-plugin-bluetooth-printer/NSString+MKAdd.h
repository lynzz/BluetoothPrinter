//
//  NSString+MKAdd.h
//  MKToolsKit
//
//  Created by xiaomk on 16/9/9.
//  Copyright © 2016年 xiaomk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString(MKAdd)

/** jsonString 转 dictionary 或者 NSArray */
- (id)mk_jsonString2Dictionary;

- (NSDictionary *)mk_dictionaryWithJsonString;

@end

