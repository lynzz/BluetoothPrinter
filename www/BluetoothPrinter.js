var exec = require("cordova/exec");

function BluetoothPrinter(){};

/*
 * 开始扫描设备
 * keep：是否持续回调 （0：否， 1：是，default:0）
 *
 * 返回的设备列表json数组
 * [{"id":"9A87E98E-BE88-5BA6-2C31-ED4869300E6E","name":"Printer_2EC1","uuid":"9A87E98E-BE88-5BA6-2C31-ED4869300E6E"}]
 * 返回扫描到的外设列表信息(有可能为空)，在扫描的回调中返回，会有延时
 */
BluetoothPrinter.prototype.scanForPeripherals = function(success, fail, keep){
    exec(success, fail, 'MKBluetoothPrinter', 'scanForPeripherals', [keep]);
}

/**
 * 获取 外设列表
 * 调用后马上返回已经扫描到的外设列表。
 * 返回的设备列表json数组：
 * [{"id":"9A87E98E-BE88-5BA6-2C31-ED4869300E6E","name":"Printer_2EC1","uuid":"9A87E98E-BE88-5BA6-2C31-ED4869300E6E"}]
 */
BluetoothPrinter.prototype.getDeviceList = function(success, fail){
    exec(success,fail, 'MKBluetoothPrinter', 'getPeripherals',[]);
}

/**
 * 连接外设
 * 参数:[uuid],  从已经获取到的外设列表，选择要连接的设备信息中获取UUID
 * 连接成功后，停止扫描。
 */
BluetoothPrinter.prototype.connectPeripheral = function(success, fail, uuid){
    exec(success, fail, 'MKBluetoothPrinter', 'connectPeripheral', [uuid]);
}

/**
 * 设置打印信息
 * 参数jsonString， json数组字符串
 */
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




//=================================================
//enum
//  信息类型
if (typeof BTPInfoType == "undefined"){
    var BTPInfoType = {};
    BTPInfoType.text            = 0;
    BTPInfoType.textList        = 1;
    BTPInfoType.barCode         = 2;
    BTPInfoType.qrCode          = 3;
    BTPInfoType.image           = 4;
    BTPInfoType.seperatorLine   = 5;
    BTPInfoType.footer          = 6;
}
//  字号大小 default:smalle
if (typeof BTPFontType == "undefined"){
    var BTPFontType = {};
    BTPFontType.smalle  = 0;
    BTPFontType.middle  = 1;
    BTPFontType.big     = 2;
}
//  对齐方式  default:center
if (typeof BTPAlignmentType == "undefined"){
    var BTPAlignmentType = {};
    BTPAlignmentType.left   = 0;
    BTPAlignmentType.center = 1;
    BTPAlignmentType.right  = 2;
}





//=================================================
//PrinterInfoHelper
/* 所有参数
 var infoModel = new Object();
 infoModel.infoType = BTPInfoType.text;                 信息类型
 infoModel.text = text;                                 信息
 infoModel.textArray = ["铅笔刀","2.00","5","10.00"];    信息列表
 infoModel.fontType = MKBTPFontType.middle;             字号（小，中，大）
 infoModel.aligmentType = MKBTPAlignmentType.center;    对齐方式
 infoModel.maxWidth = 300;                              图片宽度
 infoModel.qrCodeSize = 12;                             二维码大小（1-16）
 infoModel.offset = 150;                                实际偏移值
 infoModel.isTitle = 0;                                 是否标题
 */

var _printerInfos = []; //保存信息的列表

function PrinterInfoHelper(){};

/*
 * 重置信息列表
 */
PrinterInfoHelper.prototype.resetInfos = function(){
    _printerInfos = [];
}

/* 文本信息
 * text         : 信息
 * alignment    : 对齐方式  optional   default: center
 * fontType     : 字号     optional    default: smalle
 */
PrinterInfoHelper.prototype.appendText = function (text, alignment, fontType) {
    var infoModel = new Object();
    infoModel.infoType = BTPInfoType.text;
    infoModel.text = text;
    infoModel.fontType = fontType;
    infoModel.aligmentType = alignment;
    _printerInfos.push(infoModel);
}

/* 列表信息
 * textList     : 信息列表，
 * isTitle      : 是否标题       optional   1是，0否，  default：0
 * offset       : 实际值偏移量    optional （只有在 2列的情况下有效）
 */
PrinterInfoHelper.prototype.appendTextList = function (textList, isTitle, offset) {
    var infoModel = new Object();
    infoModel.infoType = BTPInfoType.textList;
    infoModel.textArray = textList;
    infoModel.isTitle = isTitle
    infoModel.offset = offset;
    _printerInfos.push(infoModel);
}

/* 条形码
 * text: 条形码 字符串，
 * maxWidth     : 图片宽    optional   default:300
 * alignment    : 对齐方式  optional   default:center
 */
PrinterInfoHelper.prototype.appendBarCode = function (text, maxWidth, alignment){
    var infoModel = new Object();
    infoModel.infoType = BTPInfoType.barCode;
    infoModel.text = text;
    infoModel.aligmentType = alignment;
    infoModel.maxWidth = maxWidth;
    _printerInfos.push(infoModel);
}

/* 二维码
 * text: 二维码 字符串，
 * size(1-16)   : 图片大小  optional   default:12
 * alignment    : 对齐方式  optional   default:center
 */
PrinterInfoHelper.prototype.appendQrCode = function (text, size, alignment){
    var infoModel = new Object();
    infoModel.infoType = BTPInfoType.qrCode;
    infoModel.text = text;
    infoModel.aligmentType = alignment;
    infoModel.qrCodeSize = size;
    _printerInfos.push(infoModel);
}

/* 图片
 * text: image 转成的 base64 字符串，
 * maxWidth     : 图片宽    optional   default:300
 * alignment    : 对齐方式  optional   default:center
 */
PrinterInfoHelper.prototype.appendImage = function (text, maxWidth, alignment){
    var infoModel = new Object();
    infoModel.infoType = BTPInfoType.image;
    infoModel.text = text;
    infoModel.aligmentType = alignment;
    infoModel.maxWidth = maxWidth;
    _printerInfos.push(infoModel);
}

//分割线  ---------------------------
PrinterInfoHelper.prototype.appendSeperatorLine = function(){
    var infoModel = new Object();
    infoModel.infoType = BTPInfoType.seperatorLine;
    _printerInfos.push(infoModel);
}


PrinterInfoHelper.prototype.appendFooter = function(text){
    var infoModel = new Object();
    infoModel.infoType = BTPInfoType.footer;
    infoModel.text = text;
    _printerInfos.push(infoModel);
}

// 获取打印信息的 json 字符串
PrinterInfoHelper.prototype.getPrinterInfoJsonString = function(){
    var jsonStr = JSON.stringify(_printerInfos);
    return jsonStr;
}

var printerHelper = new BluetoothPrinter();
var printerInfoHelper = new PrinterInfoHelper();

window.printerHelper = printerHelper;
window.printerInfoHelper = printerInfoHelper;
window.BTPInfoType = BTPInfoType;
window.BTPFontType = BTPFontType;
window.BTPAlignmentType = BTPAlignmentType;


module.exports.printerHelper = printerHelper;
module.exports.printerInfoHelper = printerInfoHelper;
module.exports.BTPInfoType = BTPInfoType;
module.exports.BTPFontType = BTPFontType;
module.exports.BTPAlignmentType = BTPAlignmentType;
