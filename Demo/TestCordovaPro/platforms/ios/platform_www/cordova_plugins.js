cordova.define('cordova/plugin_list', function(require, exports, module) {
module.exports = [
    {
        "id": "cordova-plugin-app-version.AppVersionPlugin",
        "file": "plugins/cordova-plugin-app-version/www/AppVersionPlugin.js",
        "pluginId": "cordova-plugin-app-version",
        "clobbers": [
            "cordova.getAppVersion"
        ]
    },
    {
        "id": "cordova-plugin-bluetooth-printer.printerHelper",
        "file": "plugins/cordova-plugin-bluetooth-printer/www/BluetoothPrinter.js",
        "pluginId": "cordova-plugin-bluetooth-printer",
        "clobbers": [
            "BluetoothPrinter"
        ]
    }
];
module.exports.metadata = 
// TOP OF METADATA
{
    "cordova-plugin-whitelist": "1.3.2",
    "cordova-plugin-app-version": "0.1.9",
    "cordova-plugin-bluetooth-printer": "1.0.1"
};
// BOTTOM OF METADATA
});