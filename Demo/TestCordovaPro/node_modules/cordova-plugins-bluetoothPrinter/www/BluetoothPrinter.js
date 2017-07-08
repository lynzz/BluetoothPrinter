var exec = require("cordova/exec");

function BluetoothPrinter(){};

//开始扫描设备
BluetoothPrinter.prototype.scanForPeripherals = function(success, fail, keep){
    exec(success, fail, 'MKBluetoothPrinter', 'scanForPeripherals', [keep]);
};

//获取设备列表
BluetoothPrinter.prototype.getDeviceList = function(success, fail){
    exec(success,fail, 'MKBluetoothPrinter', 'getPeripherals',[]);
}

//连接设备
BluetoothPrinter.prototype.connectPeripheral = function(success, fail, uuid){
    exec(success, fail, 'MKBluetoothPrinter', 'connectPeripheral', [uuid]);
}

//设置打印信息
BluetoothPrinter.prototype.setPrinterInfo = function(success, fail, jsonString){
    exec(success, fail, 'MKBluetoothPrinter', 'createPrinterInfo', [jsonString]);
}

//确认打印
 BluetoothPrinter.prototype.finalPrinter = function(success, fail){
    exec(success, fail, 'MKBluetoothPrinter', 'finalPrinter', []);
}

//断开连接
BluetoothPrinter.prototype.stopConnection = function(success, fail){
    exec(success, fail, 'MKBluetoothPrinter', 'stopPeripheralConnection', []);
}

//在Xcode控制台打印log
BluetoothPrinter.prototype.printOCLog = function(success, fail, message){
    exec(success, fail, 'MKBluetoothPrinter', 'printLog', [message]);
}


var printerHelper = new BluetoothPrinter();
module.exports = printerHelper;

