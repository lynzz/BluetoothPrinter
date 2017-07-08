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

/** 自动连接 */
- (void)autoConnectPeripheral:(CDVInvokedUrlCommand *)command{
    [self autoConnectPeripheral];
}

/** 是否已连接 */
- (void)isConnectPeripheral:(CDVInvokedUrlCommand *)command{
    NSString *b = [self isConnectPeripheral] ? @"1" : @"0";
    [self callBackSuccess:YES callBackId:command.callbackId message:b];
}



#pragma mark - ***** scan peripherals *****
- (void)scanForPeripherals:(CDVInvokedUrlCommand *)command{
    [self.commandDelegate runInBackground:^{
        BOOL bKeepCallBack = NO;
        if (command.arguments.count > 0 && command.arguments[0] && command.arguments[0] != [NSNull null]) {
            if ([command.arguments[0] isKindOfClass:[NSNumber class]] || [command.arguments[0] isKindOfClass:[NSString class]]) {
                bKeepCallBack = [command.arguments[0] integerValue] == 1;
            }else{
                ELog(@"warn: param tyep error, if you need keep callback, place input '1'");
            }
        }
        
        self.scanPeripheralsCallBackId = nil;
        self.scanPeripheralsCallBackId = command.callbackId.copy;
        
        __weak MKBluetoothPrinter *weakSelf = self;
        [self scanForPeripheralsWithBlock:^(BOOL success, NSString *message) {
            if (success) {
                [weakSelf callBackPeripheralsWithKeep:bKeepCallBack];
            }else{
                [weakSelf callBackSuccess:success callBackId:command.callbackId message:message keep:YES];
            }
        }];
    }];
}


- (void)callBackPeripheralsWithKeep:(BOOL)keep{
    NSMutableArray *peripherals = [self getPeripheralList];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray: peripherals];
    [pluginResult setKeepCallbackAsBool:keep];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.scanPeripheralsCallBackId];
}

- (void)stopScan:(CDVInvokedUrlCommand *)command{
    [self.manager stopScan];
    [self callBackSuccess:YES callBackId:command.callbackId message:@"stop scan success"];
}


/** get peripherals */
- (void)getPeripherals:(CDVInvokedUrlCommand *)command{
    NSMutableArray *peripherals = [self getPeripheralList];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray: peripherals];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

/** connect Peripheral */
- (void)connectPeripheral:(CDVInvokedUrlCommand *)command{
    if (command.arguments.count <= 0) {
        [self callBackSuccess:NO callBackId:command.callbackId message:@"error: please input the peripheral's uuid or name"];
        return;
    }
 
    NSString *peripheralId = nil;
    if ([command.arguments[0] isKindOfClass:[NSString class]] && [command.arguments[0] length] > 0){
        peripheralId = command.arguments[0];
    }else{
        [self callBackSuccess:NO callBackId:command.callbackId message:@"error: param error"];
        return;
    }
    
    __weak MKBluetoothPrinter *weakSelf = self;
    [self connectPeripheralWith:peripheralId block:^(BOOL success, NSString *message) {
        [weakSelf callBackSuccess:success callBackId:command.callbackId message:message];
    }];
}

/** set printer info and printer */
- (void)setPrinterInfoAndPrinter:(CDVInvokedUrlCommand *)command{
    [self.commandDelegate runInBackground:^{
        if (command.arguments.count > 0 && command.arguments[0] != [NSNull null]) {
            NSString *jsonStr = command.arguments[0];
            __weak MKBluetoothPrinter *weakSelf = self;
            [self setPrinterInfoWithJsonString:jsonStr block:^(BOOL success, NSString *message) {
                if (success) {
                    [weakSelf finalPrinterWithBlock:^(BOOL success, NSString *message) {
                        [weakSelf callBackSuccess:success callBackId:command.callbackId message:message];
                    }];
                }else{
                    [weakSelf callBackSuccess:success callBackId:command.callbackId message:message];
                }
            }];
        }else{
            [self callBackSuccess:NO callBackId:command.callbackId message:@"error: not find param with printer info"];
        }
    }];
}

/** 断开连接 */
- (void)stopPeripheralConnection:(CDVInvokedUrlCommand *)command{
    [self stopPeripheralConnection];
    [self callBackSuccess:YES callBackId:command.callbackId message:@"stop peripheral connection"];
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
    [self consoleLog:log];
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






#pragma mark - **************************************************
#pragma mark - ***** OC method *****
- (BOOL)isConnectPeripheral{
    BOOL b = self.connectPeripheral && self.manager.connectedPerpheral;
    return b;
}

/** 扫描 并连接 设备 历史设备 */
- (void)autoConnectPeripheral{
    if ([self isConnectPeripheral]) {
        ELog(@"已连接");
        return;
    }
    NSString *peripheralName = [self getHistoryPeripheralName];
    if (peripheralName) {
        if (self.peripheralsArray.count > 0){
            __weak MKBluetoothPrinter *weakSelf = self;
            [self connectPeripheralWith:peripheralName block:^(BOOL success, NSString *message) {
                if (success) {
                    ELog(@"autoConnectPeripheral : %@", message);
                }else{
                    [weakSelf scanPeripheralsAndConnectWithPeripheralName:peripheralName];
                }
            }];
            return;
        }
        [self scanPeripheralsAndConnectWithPeripheralName:peripheralName];
    }else{
        ELog(@"无历史连接设备");
    }
}

- (void)scanPeripheralsAndConnectWithPeripheralName:(NSString *)name{
    __weak MKBluetoothPrinter *weakSelf = self;
    [self scanForPeripheralsWithBlock:^(BOOL success, NSString *message) {
        if (success && weakSelf.peripheralsArray.count > 0) {
            [self connectPeripheralWith:name block:nil];
        }
    }];
}

/** 扫描设备 */
- (void)scanForPeripheralsWithBlock:(CommandBlcok)block{
    __weak MKBluetoothPrinter *weakSelf = self;
    if (self.manager.stateUpdateBlock) {
        //已经设置过状态回调，直接开始扫描
        [self starScanWithBlock:block];
    }else{
        //检查蓝牙 状态，开始扫描
        self.manager.stateUpdateBlock = ^(CBCentralManager *central) {
            NSString *info = nil;
            switch (central.state) {
                case CBCentralManagerStatePoweredOn:{
                    [weakSelf starScanWithBlock:block];
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
            ELog(@"%@", info);
            MKBlockExec(block, NO, info);
        };
    }
}
/** 开始扫描 */
- (void)starScanWithBlock:(CommandBlcok)block{
    __weak MKBluetoothPrinter *weakSelf = self;
    [self.manager scanForPeripheralsWithServiceUUIDs:nil options:nil didDiscoverPeripheral:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        ELog(@"peripheral.name : %@", peripheral.name);
        if (peripheral.name.length <= 0) {
            return ;
        }
        BOOL isExist = NO;
        for (int i = 0; i < weakSelf.peripheralsArray.count; i++) {
            CBPeripheral *per = weakSelf.peripheralsArray[i];
//            ELog(@"UUIDString %zd :%@",i, per.identifier.UUIDString);
            if ([per.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
                isExist = YES;
                [weakSelf.peripheralsArray replaceObjectAtIndex:i withObject:peripheral];
                break;
            }
        }
        if (!isExist) {
            [weakSelf.peripheralsArray addObject:peripheral];
        }
        MKBlockExec(block, YES, nil);
        return;
    }];
}

- (NSMutableArray *)getPeripheralList {
    NSMutableArray *peripherals = @[].mutableCopy;
    for (int i = 0; i < self.peripheralsArray.count; i++) {
        NSMutableDictionary *peripheralDic = @{}.mutableCopy;
        CBPeripheral *p = [self.peripheralsArray objectAtIndex:i];
        
        NSString *uuid = p.identifier.UUIDString;
        [peripheralDic setObject:uuid forKey:@"uuid"];
        NSString *name = [p name];
        if (!name) {
            name = [peripheralDic objectForKey:@"uuid"];
        }
        [peripheralDic setObject:name forKey:@"name"];
        [peripherals addObject:peripheralDic];
    }
    return peripherals;
}

/** 连接设备 */
- (void)connectPeripheralWith:(NSString *)string block:(CommandBlcok)block{
    if (string) {
        ELog(@"peripheral:%@",string);
        for (CBPeripheral *per in self.peripheralsArray) {
            if ([per.identifier.UUIDString isEqualToString:string]) {
                self.connectPeripheral = per;
            }else if ([per.name isEqualToString:string]){
                self.connectPeripheral = per;
            }
        }
    }
    if (self.connectPeripheral == nil) {
        MKBlockExec(block, NO, [NSString stringWithFormat:@"error: no find the peripheral : %@", string]);
        return;
    }
    __weak MKBluetoothPrinter *weakSelf = self;
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
                                      statusStr = @"error: connect fail";
                                      weakSelf.connectPeripheral = nil;
                                      MKBlockExec(block, NO, statusStr);
                                  } else {
                                      statusStr = @"connect success";
                                      [weakSelf savePeripheralName:weakSelf.connectPeripheral.name];
                                      MKBlockExec(block, YES, statusStr);
                                      return ;
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
                          ELog(@"connectPeripheral status : %@", statusStr);
                      }];
    
}

/** 设置打印信息 */
- (void)setPrinterInfoWithJsonString:(NSString *)jsonStr block:(CommandBlcok)block{
    ELog(@"jsonStr : %@", jsonStr);
    if (jsonStr == nil || jsonStr.length == 0) {
        MKBlockExec(block, NO, @"error: param invalid");
        return;
    }
    NSArray *array = [jsonStr mk_jsonString2Dictionary];
    if (array == nil || ![array isKindOfClass:[NSArray class]] || array.count == 0) {
        MKBlockExec(block, NO, @"error: json format error");
        return;
    }
    [self setPrinterInfoWithArray:array block:block];
    MKBlockExec(block, YES, @"set printer info success");
}

- (void)setPrinterInfoWithArray:(NSArray *)array block:(CommandBlcok)block{
    [self.printerModelArray removeAllObjects];
    [self.printerModelArray addObjectsFromArray:array];
    [self clearPrinterInfo];
    
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
//                [self.printerInfo appendQRCodeWithInfo:model.text size:model.qrCodeSize alignment:[model getAlignment]];
                [self.printerInfo appendQRCodeWithInfo:model.text];
                break;
            case MKBTPrinterInfoType_image:{
                UIImage *image = [UIImage mk_imageWithBase64:model.text];
                if (image) {
                    [self.printerInfo appendImage:image alignment:[model getAlignment] maxWidth:model.maxWidth];
                }
            }
                break;
            case MKBTPrinterInfoType_seperatorLine:
                [self.printerInfo appendSeperatorLine];
                break;
            case MKBTPrinterInfoType_spaceLine:
                [self.printerInfo appendSpaceLine];
                break;
            case MKBTPrinterInfoType_footer:
                [self.printerInfo appendFooter:model.text];
                break;
            default:
                break;
        }
    }
    [self.printerInfo appendCutPaper];
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
        [self.printerInfo appendTitle:tempAry[0] value:tempAry[1]];
    }else if (model.textArray.count == 3){
        [self.printerInfo appendLeftText:tempAry[0] middleText:tempAry[1] rightText:tempAry[2] isTitle:model.isTitle == 1];
    }else if (model.textArray.count == 4){
        [self.printerInfo appendTextArray:tempAry isTitle:model.isTitle];
    }
}

- (void)finalPrinterWithBlock:(CommandBlcok)block{
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
    
    if (self.chatacter == nil) {
        MKBlockExec(block, NO, @"error: no find the service with can write");
        return;
    }
    
    NSData *mainData = [self.printerInfo getFinalData];
    if (self.chatacter.properties & CBCharacteristicPropertyWrite) {
        [self.manager writeValue:mainData forCharacteristic:self.chatacter type:CBCharacteristicWriteWithResponse completionBlock:^(CBCharacteristic *characteristic, NSError *error) {
            if (!error) {
                MKBlockExec(block, YES, @"printer sucess");
                ELog(@"printer sucess");
            }else{
                MKBlockExec(block, NO, @"printer fail");
            }
        }];
    } else if (self.chatacter.properties & CBCharacteristicPropertyWriteWithoutResponse) {
        [self.manager writeValue:mainData forCharacteristic:self.chatacter type:CBCharacteristicWriteWithoutResponse];
    }
 
}


- (void)stopPeripheralConnection{
    self.connectPeripheral = nil;
    [self.manager cancelPeripheralConnection];
}

- (void)clearPrinterInfo{
    _printerInfo = nil;
}

- (void)consoleLog:(NSString *)log{
    ELog(@"%@",log);
}



    
#pragma mark - ***** save periphera name *****
- (void)savePeripheralName:(NSString *)name{
    [[NSUserDefaults standardUserDefaults] setValue:name forKey:@"PeripheralName"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)getHistoryPeripheralName{
    return [[NSUserDefaults standardUserDefaults] valueForKey:@"PeripheralName"];
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


