var exec = require('cordova/exec');

exports.getAppName = function(success, error) {
    exec(success, error, "BluetoothPrinter", "getAppName");
};
