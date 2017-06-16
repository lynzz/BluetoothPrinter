#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBService.h>
#import <Cordova/CDV.h>

@interface BluetoothPrinter : CDVPlugin <CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate> {
    NSString* _connectCallbackId;
    NSString* _listCallbackId;
    NSData* _printData;
}

@property (strong, nonatomic) CBCentralManager *_centralManager;
@property (strong, nonatomic) NSMutableArray *_peripherals;
@property (strong, nonatomic) CBPeripheral *_activePeripheral;

- (void)open:(CDVInvokedUrlCommand *)command;
- (void)close:(CDVInvokedUrlCommand *)command;
- (void)print:(CDVInvokedUrlCommand *)command;
- (void)list:(CDVInvokedUrlCommand *)command;

@end
