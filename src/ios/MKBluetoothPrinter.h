//
//  MKBluetoothPrinter.h
//  CordovaDemo
//
//  Created by xmk on 2017/6/20.
//
//

#import <Cordova/CDVPlugin.h>
#import "MKConst.h"


typedef void(^CommandBlcok)(BOOL success, NSString *message);

@interface MKBluetoothPrinter : CDVPlugin

/*
 * 设置打印机纸张宽度
 */
- (void)setPrinterPageWidth:(CDVInvokedUrlCommand *)command;

/*
 * 获取当前设置的打印机纸张宽度
 */
- (void)getCurrentSetPageWidth:(CDVInvokedUrlCommand *)command;

/** 自动连接 历史设备 */
- (void)autoConnectPeripheral:(CDVInvokedUrlCommand *)command;

/** 
 * 是否已连接 
 * 返回： "1":是  "0":否
 */
- (void)isConnectPeripheral:(CDVInvokedUrlCommand *)command;

/** 
 * 扫描外设
 * 参数：[]，返回扫描到的外设列表信息(有可能为空)，在扫的回调中返回，会有延时。
 * 参数：[1]，调用后持续扫描返回结果。
 * 返回参数： [{"id":"9A87E98E-BE88-5BA6-2C31-ED4869300E6E","name":"Printer_2EC1","uuid":"9A87E98E-BE88-5BA6-2C31-ED4869300E6E"}]
 */
- (void)scanForPeripherals:(CDVInvokedUrlCommand *)command;

/** 停止扫描 */
- (void)stopScan:(CDVInvokedUrlCommand *)command;

/** 
 * 获取 外设列表
 * 参数：[], 调用后马上返回已经扫描到的外设列表。
 * 返回参数： [{"id":"9A87E98E-BE88-5BA6-2C31-ED4869300E6E","name":"Printer_2EC1","uuid":"9A87E98E-BE88-5BA6-2C31-ED4869300E6E"}]
 */
- (void)getPeripherals:(CDVInvokedUrlCommand *)command;

/** 
 * 连接外设
 * 参数:[uuid],  从已经获取到的外设列表，选择要连接的设备信息中获取UUID
 * 连接成功后，停止扫描。
 */
- (void)connectPeripheral:(CDVInvokedUrlCommand *)command;

/**
 * 设置打印信息 并打印
 * 参数： json 数组
 */
- (void)setPrinterInfoAndPrinter:(CDVInvokedUrlCommand *)command;

/** 断开外设连接 */
- (void)stopPeripheralConnection:(CDVInvokedUrlCommand *)command;

/** 打印log */
- (void)printLog:(CDVInvokedUrlCommand *)command;

@end








