//
//  MKBluetoothPrinter.m
//  CordovaDemo
//
//  Created by xmk on 2017/6/20.
//
//

#import "MKBluetoothPrinter.h"
#import "HLBLEManager.h"
#import "HLPrinter.h"
#import "MKConst.h"
#import "MKPrinterInfoModel.h"

@interface MKBluetoothPrinter ()
@property (nonatomic, strong) HLBLEManager *manager;
@property (nonatomic, strong) NSMutableArray *peripheralsArray;     /*!< 外设列表 */
@property (nonatomic, copy  ) NSString *scanPeripheralsCallBackId;  /*!< 扫描 接口 callBackId, 用于持续回调JS*/
@property (nonatomic, strong) CBPeripheral *connectPeripheral;      /*!< 连接的外设 */
@property (nonatomic, strong) CBCharacteristic *chatacter;          /*!< 可写入数据的特性 */
@property (nonatomic, strong) NSMutableArray *servicesArray;        /*!< 外设 服务列表 */
@property (nonatomic, strong) HLPrinter *printerInfo;               /*!< 打印数据 */
@property (nonatomic, strong) NSMutableArray *printerModelArray;    /*!< 打印信息数组 主要用于排序*/
@end

@implementation MKBluetoothPrinter

#pragma mark - ***** scan peripherals *****
- (void)scanForPeripherals:(CDVInvokedUrlCommand *)command{
    BOOL bKeepCallBack = NO;
    if (command.arguments.count > 0) {
        bKeepCallBack = [command.arguments[0] integerValue] == 1;
    }
    
    self.scanPeripheralsCallBackId = nil;
    self.scanPeripheralsCallBackId = command.callbackId.copy;
    
    __weak HLBLEManager *weakManager = self.manager;
    __weak MKBluetoothPrinter *weakSelf = self;
    
    self.manager.stateUpdateBlock = nil;
    self.manager.stateUpdateBlock = ^(CBCentralManager *central) {
        NSString *info = nil;
        switch (central.state) {
            case CBCentralManagerStatePoweredOn:{
                [weakManager scanForPeripheralsWithServiceUUIDs:nil options:nil didDiscoverPeripheral:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
                    ELog(@"peripheral.name : %@", peripheral.name);
                    if (peripheral.name.length <= 0) {
                        return ;
                    }
                    BOOL isExist = NO;
                    for (int i = 0; i < weakSelf.peripheralsArray.count; i++) {
                        CBPeripheral *per = weakSelf.peripheralsArray[i];
                        ELog(@"UUIDString %zd :%@",i, per.identifier.UUIDString);
                        if ([per.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
                            isExist = YES;
                            [weakSelf.peripheralsArray replaceObjectAtIndex:i withObject:peripheral];
                            break;
                        }
                    }
                    if (!isExist) {
                        [weakSelf.peripheralsArray addObject:peripheral];
                    }
                    [weakSelf callBackPeripheralsWithKeep:bKeepCallBack];
                    return;
                }];
            }
                return;
            case CBCentralManagerStatePoweredOff:
                info = @"蓝牙可用，未打开";
                break;
            case CBCentralManagerStateUnsupported:
                info = @"SDK不支持";
                break;
            case CBCentralManagerStateUnauthorized:
                info = @"程序未授权";
                break;
            case CBCentralManagerStateResetting:
                info = @"CBCentralManagerStateResetting";
                break;
            case CBCentralManagerStateUnknown:
                info = @"CBCentralManagerStateUnknown";
                break;
            default:
                break;
        }
        [weakSelf callBackSuccess:NO callBackId:command.callbackId message:info keep:YES];
    };
}

- (void)callBackPeripheralsWithKeep:(BOOL)keep{
    NSMutableArray *peripherals = [self getPeripheralList];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray: peripherals];
    [pluginResult setKeepCallbackAsBool:keep];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.scanPeripheralsCallBackId];
}

#pragma mark - ***** get peripherals *****
- (void)getPeripherals:(CDVInvokedUrlCommand *)command{
    NSMutableArray *peripherals = [self getPeripheralList];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray: peripherals];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSMutableArray *)getPeripheralList {
    NSMutableArray *peripherals = @[].mutableCopy;
    for (int i = 0; i < self.peripheralsArray.count; i++) {
        NSMutableDictionary *peripheralDic = @{}.mutableCopy;
        CBPeripheral *p = [self.peripheralsArray objectAtIndex:i];
        
        NSString *uuid = p.identifier.UUIDString;
        [peripheralDic setObject:uuid forKey:@"uuid"];
        [peripheralDic setObject:uuid forKey:@"id"];
        NSString *name = [p name];
        if (!name) {
            name = [peripheralDic objectForKey:@"uuid"];
        }
        [peripheralDic setObject:name forKey:@"name"];
        [peripherals addObject:peripheralDic];
    }
    return peripherals;
}


#pragma mark - ***** connect Peripheral *****
- (void)connectPeripheral:(CDVInvokedUrlCommand *)command{
    if (command.arguments.count == 0) {
        [self callBackSuccess:NO callBackId:command.callbackId message:@"请传入需要链接设备的uuid"];
        return;
    }
    if (command.arguments.count > 0 && [command.arguments[0] isKindOfClass:[NSString class]]) {
        if (command.arguments[0] == nil || [command.arguments[0] length] == 0) {
            [self callBackSuccess:NO callBackId:command.callbackId message:@"请传入需要链接设备的uuid"];
            return;
        }
    }
    
    
    NSString *peripheralId = nil;
    if ([command.arguments[0] isKindOfClass:[NSNumber class]]) {
        NSNumber *pid = command.arguments[0];
        peripheralId = pid.stringValue;
    }else if ([command.arguments[0] isKindOfClass:[NSString class]]){
        peripheralId = command.arguments[0];
    }else{
        [self callBackSuccess:NO callBackId:command.callbackId message:@"传入设备uuid的类型错误"];
        return;
    }
    
    if (peripheralId) {
        ELog(@"peripheralId:%@",peripheralId);
        for (CBPeripheral *per in self.peripheralsArray) {
            ELog(@"UUIDString:%@",per.identifier.UUIDString);
            if ([per.identifier.UUIDString isEqualToString:peripheralId]) {
                self.connectPeripheral = per;
            }
        }
    }
    if (self.connectPeripheral == nil) {
        [self callBackSuccess:NO callBackId:command.callbackId message:@"未找到此uuid的设备"];
        return;
    }
    [self.manager connectPeripheral:self.connectPeripheral
                     connectOptions:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey:@(YES)}
             stopScanAfterConnected:YES
                    servicesOptions:nil
             characteristicsOptions:nil
                      completeBlock:^(HLOptionStage stage, CBPeripheral *peripheral, CBService *service, CBCharacteristic *character, NSError *error) {
                          NSString *statusStr = @"";
                          switch (stage) {
                              case HLOptionStageConnection:{
                                  if (error) {
                                      statusStr = @"连接失败";
                                  } else {
                                      statusStr = @"连接成功";
                                  }
                                  break;
                              }
                              case HLOptionStageSeekServices:{
                                  if (error) {
                                      statusStr = @"查找服务失败";
                                  } else {
                                      statusStr = @"查找服务成功";
                                      [self.servicesArray addObjectsFromArray:peripheral.services];
                                  }
                                  break;
                              }
                              case HLOptionStageSeekCharacteristics:{
                                  // 该block会返回多次，每一个服务返回一次
                                  if (error) {
                                      statusStr = @"查找特性失败";
                                  } else {
                                      statusStr = @"查找特性成功";
                                  }
                                  break;
                              }
                              case HLOptionStageSeekdescriptors:{
                                  // 该block会返回多次，每一个特性返回一次
                                  if (error) {
                                      statusStr = @"查找特性的描述失败";
                                  } else {
                                      statusStr = @"查找特性的描述成功";
                                  }
                                  break;
                              }
                              default:
                                  break;
                          }
                          [self callBackSuccess:NO callBackId:command.callbackId message:statusStr];
                      }];
}




#pragma mark - ***** setup printer info *****
- (void)createPrinterInfo:(CDVInvokedUrlCommand *)command{
    [self.commandDelegate runInBackground:^{
        if (command.arguments.count > 0) {
            NSString *jsonStr = command.arguments[0];
            ELog(@"jsonStr : %@", jsonStr);
//            [self createTestDate];
            if (jsonStr == nil || jsonStr.length == 0) {
                [self callBackSuccess:NO callBackId:command.callbackId message:@"参数异常"];
                return;
            }
            NSArray *array = [jsonStr mk_jsonString2Dictionary];
            if (![array isKindOfClass:[NSArray class]] || array == nil || array.count == 0) {
                [self callBackSuccess:NO callBackId:command.callbackId message:@"参数解析Json错误"];
                return;
            }
            [self.printerModelArray removeAllObjects];
            [self.printerModelArray addObjectsFromArray:array];
            _printerInfo = nil;

            for (NSDictionary *dic in self.printerModelArray) {
                MKPrinterInfoModel *model = [[MKPrinterInfoModel alloc] init];
                if ([dic valueForKey:@"infoType"]) {
                    model.infoType = [[dic valueForKey:@"infoType"] integerValue];
                }
                if ([dic valueForKey:@"text"]){
                    if ([[dic valueForKey:@"text"] isKindOfClass:[NSString class]]) {
                        model.text = [dic valueForKey:@"text"];
                    }else{
                        model.text = [[dic valueForKey:@"text"] stringValue];
                    }
                }
                if ([dic valueForKey:@"textArray"]){
                    model.textArray = [dic valueForKey:@"textArray"];
                }
                if ([dic valueForKey:@"fontType"]){
                    model.fontType = [[dic valueForKey:@"fontType"] integerValue];
                }
                if ([dic valueForKey:@"aligmentType"]){
                    model.aligmentType = [[dic valueForKey:@"aligmentType"] integerValue];
                }
                if ([dic valueForKey:@"maxWidth"]){
                    model.maxWidth = [[dic valueForKey:@"maxWidth"] floatValue];
                }
                if ([dic valueForKey:@"qrCodeSize"]){
                    model.qrCodeSize = [[dic valueForKey:@"qrCodeSize"] floatValue];
                }
                if ([dic valueForKey:@"offset"]){
                    model.offset = [[dic valueForKey:@"offset"] floatValue];
                }
                if ([dic valueForKey:@"isTitle"]){
                    model.isTitle = [[dic valueForKey:@"isTitle"] integerValue];
                }
                
                switch (model.infoType) {
                    case MKBTPrinterInfoType_text:
                        [self.printerInfo appendText:model.text alignment:[model getAlignment] fontSize:[model getFontSize]];
                        break;
                    case MKBTPrinterInfoType_textList:{
                        [self appentTextListWith:model];
                    }
                        break;
                    case MKBTPrinterInfoType_barCode:
                        [self.printerInfo appendBarCodeWithInfo:model.text alignment:[model getAlignment] maxWidth:model.maxWidth];
                        break;
                    case MKBTPrinterInfoType_qrCode:
                        [self.printerInfo appendQRCodeWithInfo:model.text size:model.qrCodeSize alignment:[model getAlignment]];
                        break;
                    case MKBTPrinterInfoType_image:{
                        UIImage *image = [UIImage mk_imageWithBase64:model.text];
                        [self.printerInfo appendImage:image alignment:[model getAlignment] maxWidth:300];
                    }
                        break;
                    case MKBTPrinterInfoType_seperatorLine:
                        [self.printerInfo appendSeperatorLine];
                        break;
                    case MKBTPrinterInfoType_footer:
                        [self.printerInfo appendFooter:model.text];
                        break;
                    default:
                        break;
                }
            }
            [self.printerInfo appendNewLine];
            [self.printerInfo appendNewLine];
        }

        [self callBackSuccess:YES callBackId:command.callbackId message:@"设置打印数据成功"];
    }];
}

- (void)appentTextListWith:(MKPrinterInfoModel *)model{
    NSMutableArray *tempAry = @[].mutableCopy;
    for (id obj in model.textArray) {
        if ([obj isKindOfClass:[NSString class]]) {
            [tempAry addObject:obj];
        }else{
            [tempAry addObject:[obj stringValue]];
        }
    }
    
    if (model.textArray.count == 2) {
        if (model.offset > 0) {
            [self.printerInfo appendTitle:tempAry[0] value:tempAry[1] valueOffset:model.offset fontSize:[model getFontSize]];
        }else{
            [self.printerInfo appendTitle:tempAry[0] value:tempAry[1]];
        }
    }else if (model.textArray.count == 3){
        [self.printerInfo appendLeftText:tempAry[0] middleText:tempAry[1] rightText:tempAry[2] isTitle:model.isTitle == 1];
    }else if (model.textArray.count == 4){
        [self.printerInfo appendTextArray:tempAry isTitle:model.isTitle];
    }
}

#pragma mark - ***** final Printer *****
- (void)finalPrinter:(CDVInvokedUrlCommand *)command{
    [self.commandDelegate runInBackground:^{
        if (self.servicesArray.count > 0) {
            for (CBService *service in self.servicesArray) {
                for (CBCharacteristic *character in service.characteristics) {
                    CBCharacteristicProperties properties = character.properties;
                    if (properties & CBCharacteristicPropertyWrite) {
                        self.chatacter = character;
                    }
                }
            }
        }
        
        if (self.chatacter) {
            NSData *mainData = [self.printerInfo getFinalData];
            if (self.chatacter.properties & CBCharacteristicPropertyWrite) {
                [self.manager writeValue:mainData forCharacteristic:self.chatacter type:CBCharacteristicWriteWithResponse completionBlock:^(CBCharacteristic *characteristic, NSError *error) {
                    if (!error) {
                        ELog(@"写入成功");
                    }
                }];
            } else if (self.chatacter.properties & CBCharacteristicPropertyWriteWithoutResponse) {
                [self.manager writeValue:mainData forCharacteristic:self.chatacter type:CBCharacteristicWriteWithoutResponse];
            }
        }else{
            [self callBackSuccess:NO callBackId:command.callbackId message:@"未能找到可写入的服务"];
        }

    }];
}

/** 断开连接 */
- (void)stopPeripheralConnection:(CDVInvokedUrlCommand *)command{
    [self.manager cancelPeripheralConnection];
    [self callBackSuccess:YES callBackId:command.callbackId message:@"断开连接"];
}



/** 清理打印数据 */
- (void)clearPrinterInfo:(CDVInvokedUrlCommand *)command{
    _printerInfo = nil;
}

#pragma mark - ***** call back *****
- (void)callBackSuccess:(BOOL)success callBackId:(NSString *)callBackId message:(NSString *)message{
    [self callBackSuccess:success callBackId:callBackId message:message keep:NO];
}

- (void)callBackSuccess:(BOOL)success callBackId:(NSString *)callBackId message:(NSString *)message keep:(BOOL)keep{
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:success?CDVCommandStatus_OK:CDVCommandStatus_ERROR messageAsString:message];
    [pluginResult setKeepCallbackAsBool:keep];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callBackId];
}

/** 控制台打印 log */
- (void)printLog:(CDVInvokedUrlCommand *)command{
    NSString *log = @"";
    if (command.arguments.count > 0) {
        for (int i = 0; i < command.arguments.count; i++) {
            if ([command.arguments[i] isKindOfClass:[NSString class]]) {
                log = [log stringByAppendingString:command.arguments[i]];
            }
        }
    }
    ELog(@"%@",log);
}


#pragma mark - ***** lazy *****
- (HLBLEManager *)manager{
    if (!_manager) {
        _manager = [HLBLEManager sharedInstance];
    }
    return _manager;
}

- (HLPrinter *)printerInfo{
    if (!_printerInfo) {
        _printerInfo = [[HLPrinter alloc] init];
    }
    return _printerInfo;
}

- (NSMutableArray *)peripheralsArray{
    if (!_peripheralsArray) {
        _peripheralsArray = @[].mutableCopy;
    }
    return _peripheralsArray;
}

- (NSMutableArray *)servicesArray{
    if (!_servicesArray) {
        _servicesArray = @[].mutableCopy;
    }
    return _servicesArray;
}

- (NSMutableArray *)printerModelArray{
    if (!_printerModelArray) {
        _printerModelArray = @[].mutableCopy;
    }
    return _printerModelArray;
}

@end


