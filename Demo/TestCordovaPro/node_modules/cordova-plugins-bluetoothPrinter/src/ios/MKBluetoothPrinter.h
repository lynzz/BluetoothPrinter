//
//  MKBluetoothPrinter.h
//  CordovaDemo
//
//  Created by xmk on 2017/6/20.
//
//

#import <Cordova/CDVPlugin.h>
#import "MKConst.h"

@interface MKBluetoothPrinter : CDVPlugin

/** 
 * 扫描外设
 * 参数：[]，返回扫描到的外设列表信息(有可能为空)，在扫的回调中返回，会有延时。
 * 参数：[1]，调用后持续扫描返回结果。
 * 返回参数： [{"id":"9A87E98E-BE88-5BA6-2C31-ED4869300E6E","name":"Printer_2EC1","uuid":"9A87E98E-BE88-5BA6-2C31-ED4869300E6E"}]
 */
- (void)scanForPeripherals:(CDVInvokedUrlCommand *)command;


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
 * 设置打印信息
 * 参数： json 数组
 */
- (void)createPrinterInfo:(CDVInvokedUrlCommand *)command;

/** 确认打印 */
- (void)finalPrinter:(CDVInvokedUrlCommand *)command;

/** 断开外设连接 */
- (void)stopPeripheralConnection:(CDVInvokedUrlCommand *)command;

/** 清除打印数据 */
- (void)clearPrinterInfo:(CDVInvokedUrlCommand *)command;

/** 打印log */
- (void)printLog:(CDVInvokedUrlCommand *)command;

@end








