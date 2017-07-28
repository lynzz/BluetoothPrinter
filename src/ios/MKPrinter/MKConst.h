//
//  MKConst.h
//  CordovaDemo
//
//  Created by xmk on 2017/6/20.
//
//

#import <Foundation/Foundation.h>
#import "NSString+MKAdd.h"

#ifdef DEBUG
#   define DLog(...) NSLog(@"%s, %d, %@", __func__, __LINE__, [NSString stringWithFormat:__VA_ARGS__])
#   define ELog(fmt, ...) NSLog((@"[Elog] " fmt), ##__VA_ARGS__);
#   define DebugStatus YES
#else
#   define DLog(...)
#   define ELog(...)
#   define DebugStatus NO
#endif

#define MKBlockExec(block, ...) if (block) { block(__VA_ARGS__); };

typedef NS_ENUM(NSInteger, MKBTPrinterInfoType) {
    MKBTPrinterInfoType_text            = 0,
    MKBTPrinterInfoType_textList        = 1,
    MKBTPrinterInfoType_barCode         = 2,
    MKBTPrinterInfoType_qrCode          = 3,
    MKBTPrinterInfoType_image           = 4,
    MKBTPrinterInfoType_seperatorLine   = 5,
    MKBTPrinterInfoType_spaceLine       = 6,
    MKBTPrinterInfoType_footer          = 7,
    MKBTPrinterInfoType_cutpage         = 8,
};

typedef NS_ENUM(NSInteger, MKBTPrinterFontType) {
    MKBTPrinterFontType_smalle  = 0,
    MKBTPrinterFontType_middle  = 1,
    MKBTPrinterFontType_big     = 2,
};

typedef NS_ENUM(NSInteger, MKBTPrinterAlignmentType) {
    MKBTPrinterAlignmentType_left   = 0,
    MKBTPrinterAlignmentType_center = 1,
    MKBTPrinterAlignmentType_right  = 2,
};
