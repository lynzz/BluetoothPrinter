var exec = require('cordova/exec');

var printer = {
   list: function(fnSuccess, fnError){
      exec(fnSuccess, fnError, "BluetoothPrinter", "list", []);
   },
   open: function(fnSuccess, fnError, name){
      exec(fnSuccess, fnError, "BluetoothPrinter", "open", [name]);
   },
   close: function(fnSuccess, fnError){
      exec(fnSuccess, fnError, "BluetoothPrinter", "close", []);
   },
   print: function(fnSuccess, fnError, str){
      exec(fnSuccess, fnError, "BluetoothPrinter", "print", [str]);
   },
   connect: function (success, failure, name) {
      exec(success, failure, "BluetoothPrinter", "connect", [name]);
   }
};

module.exports = printer;
