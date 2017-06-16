#import "BluetoothPrinter.h"
#import <Cordova/CDV.h>

@interface BluetoothPrinter()
@property (nonatomic, readwrite) NSInteger              sendDataIndex;
@end

#define NOTIFY_MTU      128

@implementation BluetoothPrinter

@synthesize _centralManager;
@synthesize _peripherals;
@synthesize _activePeripheral;

- (void)pluginInitialize {
    [super pluginInitialize];
    
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    _peripherals = [[NSMutableArray alloc] init];
}

#pragma mark - Cordova Plugin Methods

- (void)open:(CDVInvokedUrlCommand *)command {
    
    NSLog(@"connect");
    NSString *uuid = [command.arguments objectAtIndex:0];
    
    [self connectToUUID:uuid];
    
    _connectCallbackId = [command.callbackId copy];
}

- (void)close:(CDVInvokedUrlCommand*)command {
    
    NSLog(@"disconnect");
    
    _connectCallbackId = nil;
    CDVPluginResult *pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"蓝牙连接关闭"];
    
    if (self._activePeripheral) {
        if(self._activePeripheral.state == CBPeripheralStateConnected) {
            [[self _centralManager] cancelPeripheralConnection:[self _activePeripheral]];
        }
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)print:(CDVInvokedUrlCommand*)command {
    NSLog(@"print");
    
    CDVPluginResult *pluginResult = nil;
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    _printData = [[command.arguments objectAtIndex:0] dataUsingEncoding:enc];
    
    if (_printData != nil) {
        [self getAllCharacteristicsFromPeripheral:self._activePeripheral];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"打印数据发送成功"];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"打印数据不能为空"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)list:(CDVInvokedUrlCommand*)command {
    if (self._centralManager.state == CBCentralManagerStatePoweredOff) {
        CDVPluginResult *pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"蓝牙未开启"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    if (self._centralManager.state != CBCentralManagerStatePoweredOn) {
        _listCallbackId = command.callbackId;
    } else {
        [self scanForPeripherals:3];
        [NSTimer scheduledTimerWithTimeInterval:(float)3
                                         target:self
                                       selector:@selector(listPeripheralsTimer:)
                                       userInfo:[command.callbackId copy]
                                        repeats:NO];
    }
}

#pragma mark - timers

-(void)listPeripheralsTimer:(NSTimer *)timer {
    NSString *callbackId = [timer userInfo];
    NSMutableArray *peripherals = [self getPeripheralList];
    
    CDVPluginResult *pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray: peripherals];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

-(void)connectUuidTimer:(NSTimer *)timer {
    
    NSString *uuid = [timer userInfo];
    
    CBPeripheral *peripheral = [self findPeripheralByUUID:uuid];
    
    if (peripheral) {
        
        NSLog(@"Connecting to peripheral with UUID : %@", peripheral.identifier.UUIDString);
        
        self._activePeripheral = peripheral;
        [self._centralManager connectPeripheral:self._activePeripheral
                                         options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
        
    } else {
        NSString *error = [NSString stringWithFormat:@"Could not find peripheral %@.", uuid];
        NSLog(@"%@", error);
        CDVPluginResult *pluginResult;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallbackId];
    }
}

- (void) scanTimer:(NSTimer *)timer
{
    [self._centralManager stopScan];
    NSLog(@"Stopped Scanning");
    NSLog(@"Known peripherals : %lu", (unsigned long)[self._peripherals count]);
    [self printKnownPeripherals];
}

#pragma mark - internal implemetation

- (NSMutableArray*) getPeripheralList {
    
    NSMutableArray *peripherals = [NSMutableArray array];
    
    for (int i = 0; i < self._peripherals.count; i++) {
        NSMutableDictionary *peripheral = [NSMutableDictionary dictionary];
        CBPeripheral *p = [self._peripherals objectAtIndex:i];
        
        NSString *uuid = p.identifier.UUIDString;
        [peripheral setObject: uuid forKey: @"uuid"];
        [peripheral setObject: uuid forKey: @"id"];
        NSString *name = [p name];
        if (!name) {
            name = [peripheral objectForKey:@"uuid"];
        }
        [peripheral setObject: name forKey: @"name"];
        
        [peripherals addObject:peripheral];
    }
    
    return peripherals;
}

- (void)scanForPeripherals:(int)timeout {
    
    NSLog(@"Scanning for Peripherals");
    
    // disconnect
    if (self._activePeripheral) {
        if(self._activePeripheral.state == CBPeripheralStateConnected) {
            [[self _centralManager] cancelPeripheralConnection:[self _activePeripheral]];
            return;
        }
    }
    
    // remove existing peripherals
    if (self._peripherals) {
        self._peripherals = nil;
    }
    
    [self findPeripherals:timeout];
}

- (int) findPeripherals:(int) timeout
{
    if (self._centralManager.state != CBCentralManagerStatePoweredOn)
    {
        NSLog(@"CoreBluetooth not correctly initialized !");
        NSLog(@"State = (%s)\r\n", [self centralManagerStateToString:self._centralManager.state]);
        return -1;
    }
    
    [NSTimer scheduledTimerWithTimeInterval:(float)timeout target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
    
    [self._centralManager scanForPeripheralsWithServices:nil options:nil]; // Start scanning
    
    NSLog(@"scanForPeripheralsWithServices");
    
    return 0; // Started scanning OK !
}

- (void) printKnownPeripherals
{
    NSLog(@"List of currently known peripherals :");
    
    for (int i = 0; i < self._peripherals.count; i++)
    {
        CBPeripheral *p = [self._peripherals objectAtIndex:i];
        
        if (p.identifier != NULL)
            NSLog(@"%d  |  %@", i, p.identifier.UUIDString);
        else
            NSLog(@"%d  |  NULL", i);
        
        [self printPeripheralInfo:p];
    }
}

- (void) printPeripheralInfo:(CBPeripheral*)peripheral
{
    NSLog(@"------------------------------------");
    NSLog(@"Peripheral Info :");
    
    if (peripheral.identifier != NULL)
        NSLog(@"UUID : %@", peripheral.identifier.UUIDString);
    else
        NSLog(@"UUID : NULL");
    
    NSLog(@"Name : %@", peripheral.name);
    NSLog(@"-------------------------------------");
}

/** Required protocol method.  A full app should take care of all the possible states,
 *  but we're just waiting for  to know when the CBPeripheralManager is ready
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    // Opt out from any other state
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        return;
    }
    
    // We're in CBPeripheralManagerStatePoweredOn state...
    NSLog(@"self.peripheralManager powered on.");
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"Status of CoreBluetooth central manager changed (%s)", [self centralManagerStateToString:central.state]);
}

- (const char *) centralManagerStateToString: (int)state
{
    switch(state)
    {
        case CBCentralManagerStateUnknown:
            return "State unknown (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateResetting:
            return "State resetting (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateUnsupported:
            return "State BLE unsupported (CBCentralManagerStateResetting)";
        case CBCentralManagerStateUnauthorized:
            return "State unauthorized (CBCentralManagerStateUnauthorized)";
        case CBCentralManagerStatePoweredOff:
            if (_listCallbackId != nil) {
                CDVPluginResult *pluginResult = nil;
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"蓝牙未开启"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:_listCallbackId];
                _listCallbackId = nil;
            }
            return "State BLE powered off (CBCentralManagerStatePoweredOff)";
        case CBCentralManagerStatePoweredOn:
            if (_listCallbackId != nil) {
                [self scanForPeripherals:3];
                [NSTimer scheduledTimerWithTimeInterval:(float)3
                                                 target:self
                                               selector:@selector(listPeripheralsTimer:)
                                               userInfo:[_listCallbackId copy]
                                                repeats:NO];
                _listCallbackId = nil;
            }
            return "State powered up and ready (CBCentralManagerStatePoweredOn)";
        default:
            return "State unknown";
    }
    
    return "Unknown state";
}

- (void)connectToUUID:(NSString *)uuid {
    
    int interval = 0;
    
    if (self._peripherals.count < 1) {
        interval = 3;
        [self scanForPeripherals:interval];
    }
    
    [NSTimer scheduledTimerWithTimeInterval:interval
                                     target:self
                                   selector:@selector(connectUuidTimer:)
                                   userInfo:uuid
                                    repeats:NO];
}

- (BOOL) UUIDSAreEqual:(NSUUID *)UUID1 UUID2:(NSUUID *)UUID2
{
    if ([UUID1.UUIDString isEqualToString:UUID2.UUIDString])
        return TRUE;
    else
        return FALSE;
}

- (CBPeripheral*)findPeripheralByUUID:(NSString*)uuid {
    
    NSMutableArray *peripherals = [self _peripherals];
    CBPeripheral *peripheral = nil;
    
    for (CBPeripheral *p in peripherals) {
        
        NSString *other = p.identifier.UUIDString;
        
        if ([uuid isEqualToString:other]) {
            peripheral = p;
            break;
        }
    }
    return peripheral;
}

-(void) getAllCharacteristicsFromPeripheral:(CBPeripheral *)p
{
    for (int i=0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        [p discoverCharacteristics:nil forService:s];
    }
}

-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2
{
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1];
    [UUID2.data getBytes:b2];
    
    if (memcmp(b1, b2, UUID1.data.length) == 0)
        return 1;
    else
        return 0;
}

-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p
{
    for(int i = 0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        if ([self compareCBUUID:s.UUID UUID2:UUID])
            return s;
    }
    
    return nil; //Service not found on this peripheral
}

-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service
{
    for(int i=0; i < service.characteristics.count; i++)
    {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([self compareCBUUID:c.UUID UUID2:UUID]) return c;
    }
    
    return nil; //Characteristic not found on this service
}

-(NSString *) CBUUIDToString:(CBUUID *) cbuuid;
{
    NSData *data = cbuuid.data;
    
    if ([data length] == 2)
    {
        const unsigned char *tokenBytes = [data bytes];
        return [NSString stringWithFormat:@"%02x%02x", tokenBytes[0], tokenBytes[1]];
    }
    else if ([data length] == 16)
    {
        NSUUID* nsuuid = [[NSUUID alloc] initWithUUIDBytes:[data bytes]];
        return [nsuuid UUIDString];
    }
    
    return [cbuuid description];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (!self._peripherals)
        self._peripherals = [[NSMutableArray alloc] initWithObjects:peripheral,nil];
    else
    {
        for(int i = 0; i < self._peripherals.count; i++)
        {
            CBPeripheral *p = [self._peripherals objectAtIndex:i];
            
            if ((p.identifier == NULL) || (peripheral.identifier == NULL))
                continue;
            
            if ([self UUIDSAreEqual:p.identifier UUID2:peripheral.identifier])
            {
                [self._peripherals replaceObjectAtIndex:i withObject:peripheral];
                NSLog(@"Duplicate UUID found updating...");
                return;
            }
        }
        
        [self._peripherals addObject:peripheral];
        
        NSLog(@"New UUID, adding");
    }
    
    NSLog(@"didDiscoverPeripheral");
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    if (peripheral.identifier != NULL)
        NSLog(@"Connected to %@ successful", peripheral.identifier.UUIDString);
    else
        NSLog(@"Connected to NULL successful");
    
    self._activePeripheral = peripheral;
    [self._activePeripheral setDelegate:self];
    [self._activePeripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    CDVPluginResult *pluginResult;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"connect failure"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallbackId];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (!error)
    {
        CDVPluginResult *pluginResult;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"查找蓝牙打印服务成功"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallbackId];
    }
    else
    {
        NSLog(@"Service discovery was unsuccessful!");
        CDVPluginResult *pluginResult;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"查找蓝牙服务出现异常"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:_connectCallbackId];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error)
    {
        NSLog(@"Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    
    NSLog(@"服务：%@",service.UUID);
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        NSLog(@"监听：%@",characteristic);
        NSString *s = [self getPropertiesString:characteristic.properties];
        NSLog(@"%@",s);
        if ([s isEqualToString:@" Read Write Notify Indicate"]) {
            NSLog(@"Write Data");
            self.sendDataIndex = 0;
            [self sendData:characteristic];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    [self sendData:characteristic];
}

/** Sends the next amount of data to the connected central
 */
- (void)sendData:(CBCharacteristic *)characteristic
{
    if (self.sendDataIndex >= _printData.length) {
        return;
    }
    //    while (self.sendDataIndex < _printData.length) {
    NSInteger amountToSend = _printData.length - self.sendDataIndex;
    
    // Can't be longer than 20 bytes
    if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
    
    // Copy out the data we want
    NSData *chunk = [NSData dataWithBytes:_printData.bytes+self.sendDataIndex length:amountToSend];
    // Send it
    [self._activePeripheral writeValue:chunk forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    
    // It did send, so update our index
    self.sendDataIndex += amountToSend;
    //    }
}

-(NSString *)getPropertiesString:(CBCharacteristicProperties)properties
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendString:@""];
    
    if ((properties & CBCharacteristicPropertyBroadcast) == CBCharacteristicPropertyBroadcast) {
        [s appendString:@" Broadcast"];
    }
    if ((properties & CBCharacteristicPropertyRead) == CBCharacteristicPropertyRead) {
        [s appendString:@" Read"];
    }
    if ((properties & CBCharacteristicPropertyWriteWithoutResponse) == CBCharacteristicPropertyWriteWithoutResponse) {
        [s appendString:@" WriteWithoutResponse"];
    }
    if ((properties & CBCharacteristicPropertyWrite) == CBCharacteristicPropertyWrite) {
        [s appendString:@" Write"];
    }
    if ((properties & CBCharacteristicPropertyNotify) == CBCharacteristicPropertyNotify) {
        [s appendString:@" Notify"];
    }
    if ((properties & CBCharacteristicPropertyIndicate) == CBCharacteristicPropertyIndicate) {
        [s appendString:@" Indicate"];
    }
    if ((properties & CBCharacteristicPropertyAuthenticatedSignedWrites) == CBCharacteristicPropertyAuthenticatedSignedWrites) {
        [s appendString:@" AuthenticatedSignedWrites"];
    }
    if ((properties & CBCharacteristicPropertyExtendedProperties) == CBCharacteristicPropertyExtendedProperties) {
        [s appendString:@" ExtendedProperties"];
    }
    if ((properties & CBCharacteristicPropertyNotifyEncryptionRequired) == CBCharacteristicPropertyNotifyEncryptionRequired) {
        [s appendString:@" NotifyEncryptionRequired"];
    }
    if ((properties & CBCharacteristicPropertyIndicateEncryptionRequired) == CBCharacteristicPropertyIndicateEncryptionRequired) {
        [s appendString:@" IndicateEncryptionRequired"];
    }
    
    if ([s length]<2) {
        [s appendString:@"unknow"];
    }
    return s;
}

@end
