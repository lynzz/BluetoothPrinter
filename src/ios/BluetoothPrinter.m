#import "BluetoothPrinter.h"
#import <Cordova/CDVPluginResult.h>

@implementation BluetoothPrinter

- (void)getAppName : (CDVInvokedUrlCommand *)command
{
    NSString * callbackId = command.callbackId;
    NSString * version =[[[NSBundle mainBundle]infoDictionary]objectForKey :@"CFBundleDisplayName"];
    CDVPluginResult * pluginResult =[CDVPluginResult resultWithStatus : CDVCommandStatus_OK messageAsString : version];
    [self.commandDelegate sendPluginResult : pluginResult callbackId : callbackId];
}

@end
