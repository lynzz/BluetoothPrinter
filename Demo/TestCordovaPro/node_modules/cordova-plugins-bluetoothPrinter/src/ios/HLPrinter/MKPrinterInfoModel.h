//
//  MKPrinterInfoModel.h
//  CordovaDemo
//
//  Created by xmk on 2017/6/22.
//
//

#import <Foundation/Foundation.h>
#import "HLPrinter.h"
#import "MKConst.h"

@interface MKPrinterModel : NSObject
@property (nonatomic, strong) NSArray *infos;

@end

@interface MKPrinterInfoModel : NSObject
@property (nonatomic, assign) MKBTPrinterInfoType infoType;             /*!< MKBTPrinterInfoType_text */
@property (nonatomic, copy  ) NSString *text;
@property (nonatomic, strong) NSArray *textArray;
@property (nonatomic, assign) MKBTPrinterFontType fontType;             /*!< MKBTPrinterFontType_smalle */
@property (nonatomic, assign) MKBTPrinterAlignmentType aligmentType;    /*!< MKBTPrinterAlignmentType_center */
@property (nonatomic, assign) CGFloat maxWidth;     /*!< barCode:maxWidth */
@property (nonatomic, assign) CGFloat qrCodeSize;   /*!< qrCode:size */
@property (nonatomic, assign) CGFloat offset;       /*!< titleValue:offset */
@property (nonatomic, assign) NSInteger isTitle;    /*!< 1:是 0:否 */
- (HLFontSize)getFontSize;
- (HLTextAlignment)getAlignment;
@end

/** 
 * defult:
 * aligmentType : MKBTPrinterAlignmentType_center
 * fontType     : MKBTPrinterFontType_smalle
 * maxWidth     : 300
 * qrCodeSize   : 12
 *
 * MKBTPrinterInfoType_text         aligmentType    fontType
 * MKBTPrinterInfoType_textList     2列  offset      fontType
 *                                  3列  isTitle
 *                                  4列  isTitle
 *
 * MKBTPrinterInfoType_image        aligmentType    maxWidth(default:300)
 * MKBTPrinterInfoType_barCode      aligmentType    maxWidth(default:300)
 * MKBTPrinterInfoType_qrCode       aligmentType    size(1 <= size <= 16,二维码的宽高相等)
 */


//MKBTPrinterInfoType_text            = 0,
//MKBTPrinterInfoType_textList        = 1,
//MKBTPrinterInfoType_barCode         = 2,
//MKBTPrinterInfoType_qrCode          = 3,
//MKBTPrinterInfoType_image           = 4,
//MKBTPrinterInfoType_seperatorLine   = 5,
//MKBTPrinterInfoType_footer          = 6,
