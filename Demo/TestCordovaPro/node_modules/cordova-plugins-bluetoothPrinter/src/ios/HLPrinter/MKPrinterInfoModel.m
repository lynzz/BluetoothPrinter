//
//  MKPrinterInfoModel.m
//  CordovaDemo
//
//  Created by xmk on 2017/6/22.
//
//

#import "MKPrinterInfoModel.h"
#import "MJExtension.h"

@implementation MKPrinterModel
+ (NSDictionary *)mj_objectClassInArray{
    return @{
             @"infos" : @"MKPrinterInfoModel"
             };
}

@end

@implementation MKPrinterInfoModel
MJCodingImplementation
- (id)init{
    if (self = [super init]) {
        _infoType = MKBTPrinterInfoType_text;
        _fontType = MKBTPrinterFontType_smalle;
        _aligmentType = MKBTPrinterAlignmentType_center;
        _maxWidth = 300;
        _qrCodeSize = 12;
    }
    return self;
}

- (HLFontSize)getFontSize{
    if (self.fontType == MKBTPrinterFontType_smalle) {
        return HLFontSizeTitleSmalle;
    }else if (self.fontType == MKBTPrinterFontType_middle){
        return HLFontSizeTitleMiddle;
    }else if (self.fontType == MKBTPrinterFontType_big){
        return HLFontSizeTitleBig;
    }else{
        return HLFontSizeTitleSmalle;
    }
}

- (HLTextAlignment)getAlignment{
    if (_aligmentType == MKBTPrinterAlignmentType_left) {
        return HLTextAlignmentLeft;
    }else if (_aligmentType == MKBTPrinterAlignmentType_center){
        return HLTextAlignmentCenter;
    }else if (_aligmentType == MKBTPrinterAlignmentType_right){
        return HLTextAlignmentRight;
    }else{
        return HLTextAlignmentCenter;
    }
}

@end
