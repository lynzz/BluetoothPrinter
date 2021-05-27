
package cn.sj.cordova.bluetoothprint;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.Typeface;
import android.text.format.Time;
import android.util.Base64;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;
import java.nio.charset.Charset;
import java.util.Set;
import java.util.UUID;

// import android.content.ServiceConnection;
// import android.content.ComponentName;
// import android.content.Context;
// import android.content.Intent;
// import android.os.Bundle;
// import android.os.IBinder;
// import android.content.ContextWrapper;
// import android.os.RemoteException;
// import android.view.ContextThemeWrapper;


public class MKBluetoothPrinter extends CordovaPlugin {

    private BluetoothAdapter mBluetoothAdapter;

    private Activity activity;
    private String boothAddress = "";
    private String oneModel, drawingRev, oneClass, oneCode, chipId, dateTime, specification = "";

    private boolean isConnection = false;//蓝牙是否连接
    private boolean isKeep = false;//蓝牙持续回调
    private BluetoothDevice device = null;
    private static BluetoothSocket bluetoothSocket = null;
    private static OutputStream outputStream = null;
    private static final UUID uuid = UUID
            .fromString("00001101-0000-1000-8000-00805F9B34FB");
    private static  String  uuid_bl ="";
    private static  String name_bl ="";

    /**
     * 复位打印机
     */
    public static final byte[] RESET = {0x1b, 0x40};

    /**
     * 左对齐
     */
    public static final byte[] ALIGN_LEFT = {0x1b, 0x61, 0x00};

    /**
     * 中间对齐
     */
    public static final byte[] ALIGN_CENTER = {0x1b, 0x61, 0x01};

    /**
     * 右对齐
     */
    public static final byte[] ALIGN_RIGHT = {0x1b, 0x61, 0x02};

    /**
     * 选择加粗模式
     */
    public static final byte[] BOLD = {0x1b, 0x45, 0x01};

    /**
     * 取消加粗模式
     */
    public static final byte[] BOLD_CANCEL = {0x1b, 0x45, 0x00};

    /**
     * 宽高加倍
     */
    public static final byte[] DOUBLE_HEIGHT_WIDTH = {0x1d, 0x21, 0x11};

    /**
     * 宽加倍
     */
    public static final byte[] DOUBLE_WIDTH = {0x1d, 0x21, 0x10};

    /**
     * 高加倍
     */
    public static final byte[] DOUBLE_HEIGHT = {0x1d, 0x21, 0x01};

    /**
     * 字体不放大
     */
    public static final byte[] NORMAL = {0x1d, 0x21, 0x00};

    /**
     * 设置默认行间距
     */
    public static final byte[] LINE_SPACING_DEFAULT = {0x1b, 0x32};

    /**
     * 打印纸一行最大的字节
     */
    private static  int LINE_BYTE_SIZE = 48;


    // 对齐方式
    public static final int ALIGN_LEFT_NEW = 0;     // 靠左
    public static final int ALIGN_CENTER_NEW = 1;   // 居中
    public static final int ALIGN_RIGHT_NEW  = 2;    // 靠右

    //字体大小
    public static final int FONT_NORMAL_NEW  = 0;    // 正常
    public static final int FONT_MIDDLE_NEW = 1;    // 中等
    public static final int FONT_BIG_NEW  = 2;       // 大
    public static final int FONT_BIG_NEW3 = 3;    // 字体3
    public static final int FONT_BIG_NEW4  = 4;       // 字体4
    public static final int FONT_BIG_NEW5 = 5;    // 字体5
    public static final int FONT_BIG_NEW6  = 6;       // 字体6
    public static final int FONT_BIG_NEW7  = 7;    // 字体7
    public static final int FONT_BIG_NEW8  = 8;       // 字体8
    //加粗模式
    public static final int FONT_BOLD_NEW  = 0;              // 字体加粗
    public static final int FONT_BOLD_CANCEL_NEW  = 1;       // 取消加粗

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);

        activity = cordova.getActivity();

    }


    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        //自动连接 历史连接过的设备
        if (action.equals("autoConnectPeripheral")) {
            autoConnect(args, callbackContext);
            return true;
        }

        //设置打印机宽度
        if (action.equals("setPrinterPageWidth")) {
            setPrinterPageWidth(args, callbackContext);
            return true;
        }

        //获取当前设置的纸张宽度
        if (action.equals("getCurrentSetPageWidth")) {
            getCurrentSetPageWidth(args, callbackContext);
            return true;
        }

        //是否已连接设备   * 返回： "1":是  "0":否
        if (action.equals("isConnectPeripheral")) {
            isConnectPeripheral(args, callbackContext);
            return true;
        }

        //获取已配对的蓝牙设备 keep：是否持续回调 （0：否， 1：是，default:0） 开始扫描设备 [{"name":"Printer_2EC1","uuid":"9A87E98E-BE88-5BA6-2C31-ED4869300E6E"}]
        if (action.equals("scanForPeripherals")) {
            getPairedDevices(args, callbackContext);
            return true;
        }

        //停止扫描
        if (action.equals("stopScan")) {
            stopScan(args, callbackContext);
            return true;
        }

        //获取已配对的蓝牙设备 开始扫描设备 [{"name":"Printer_2EC1","uuid":"9A87E98E-BE88-5BA6-2C31-ED4869300E6E"}]
        if (action.equals("getPeripherals")) {
            getPairedDevices(args, callbackContext);
            return true;
        }


        //连接选中的蓝牙设备(打印机)
        if (action.equals("connectPeripheral")) {
            connectDevice(args, callbackContext);
            return true;
        }
        //打印
        if (action.equals("setPrinterInfoAndPrinter")) {
            printText(args, callbackContext);
            return true;
        }
        //断开连接
        if (action.equals("stopPeripheralConnection")) {
            closeConnect(args, callbackContext);
            return true;
        }
        //在Xcode控制台打印log
        if (action.equals("printLog")) {
            printLog(args, callbackContext);
            return true;
        }

        return false;
    }


    public void autoConnect(final JSONArray args, final CallbackContext callbackContext) {
        SharedPreferences pref = activity.getSharedPreferences("device", activity.MODE_PRIVATE);
        String deviceAddress = pref.getString("address", "");
        if (deviceAddress != null) {
            mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
            Set<BluetoothDevice> pairedDevices = mBluetoothAdapter
                    .getBondedDevices();// 获取本机已配对设备
            if (pairedDevices.size() > 0) {
                for (BluetoothDevice device1 : pairedDevices) {
                    if (device1.getAddress().equals(deviceAddress)) {
                        device = device1;
                        break;
                    }
                }
            }

            if (!isConnection) {//没有连接
                try {
                    bluetoothSocket = device
                            .createRfcommSocketToServiceRecord(uuid);
                    bluetoothSocket.connect();
                    name_bl=device.getName();
                    uuid_bl=device.getAddress();
                    outputStream = bluetoothSocket.getOutputStream();
                    isConnection = true;
                    callbackContext.success("连接成功");
                } catch (Exception e) {
                    isConnection = false;
                    callbackContext.error("连接失败");
                }
            } else {//连接了
                callbackContext.success("连接成功");
            }
        }
    }

    /*
  *设置打印机宽度
   */
    public void setPrinterPageWidth(final JSONArray args, final CallbackContext callbackContext)  throws JSONException {
        String size = "78";
        try {
            size = args.getString(0);
            if("58".equals(size)){
                LINE_BYTE_SIZE=32;
            }else{
                LINE_BYTE_SIZE=48;
            }
            callbackContext.success("0");
        } catch (Exception e) {
            e.printStackTrace();
            callbackContext.success("1");
        }
    }

    /*
  *获取当前设置的纸张宽度
   */
    public void getCurrentSetPageWidth(final JSONArray args, final CallbackContext callbackContext)  throws JSONException {
        String size = "78";

        if(LINE_BYTE_SIZE==32){
            size="58";
        }
        callbackContext.success(size);

    }
    /*
    *是否已连接设备   * 返回： "1":是  "0":否
     */
    public void isConnectPeripheral(final JSONArray args, final CallbackContext callbackContext)  throws JSONException {
        if (isConnection) {
            JSONArray json = new JSONArray();
                JSONObject jo = new JSONObject();
                jo.put("name", name_bl);
                 jo.put("uuid", uuid_bl);
                json.put(jo);
            callbackContext.success(json);
        } else {
            callbackContext.success("0");
        }
    }

    private void printLog(JSONArray args, CallbackContext callbackContext) {

    }

    private void closeConnect(final JSONArray args, final CallbackContext callbackContext) throws JSONException {
        try {
            bluetoothSocket.close();
            outputStream.close();
            isConnection = false;
            callbackContext.success("断开连接成功！");

        } catch (IOException e) {

            isConnection = true;
            callbackContext.error("断开连接失败！");

        }
    }

    private void connectDevice(final JSONArray args, final CallbackContext callbackContext) throws JSONException {
        final String address = args.getString(0);
        // Get the local Bluetooth adapter
        mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        device = mBluetoothAdapter.getRemoteDevice(address);
        if (!isConnection) {//没有连接
            try {
                bluetoothSocket = device
                        .createRfcommSocketToServiceRecord(uuid);
                bluetoothSocket.connect();
                outputStream = bluetoothSocket.getOutputStream();
                isConnection = true;
                name_bl=device.getName();
                uuid_bl=device.getAddress();
                callbackContext.success("连接成功");
            } catch (Exception e) {
                isConnection = false;
                callbackContext.error("连接失败");
            }
        } else {//连接了
            callbackContext.success("连接成功");
        }

    }

    /*
    *获取已配对的蓝牙设备 keep：是否持续回调 （0：否， 1：是，default:0） 开始扫描设备 [{"name":"Printer_2EC1","uuid":"9A87E98E-BE88-5BA6-2C31-ED4869300E6E"}]
     */
    private void getPairedDevices(final JSONArray args, final CallbackContext callbackContext) throws JSONException {
        // Get the local Bluetooth adapter
        String keep = "0";
        try {
            keep = args.getString(0);
        } catch (Exception e) {
            e.printStackTrace();
        }
        mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        // Get a set of currently paired devices
        Set<BluetoothDevice> pairedDevices = mBluetoothAdapter.getBondedDevices();
        // If there are paired devices, add each one to the ArrayAdapter


        if ("1".equals(keep)) {
            isKeep = true;
        } else {
            isKeep = false;
        }

        while (isKeep && (pairedDevices == null || pairedDevices.size() == 0)) {
            mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
            pairedDevices = mBluetoothAdapter.getBondedDevices();
        }


        if (pairedDevices != null && pairedDevices.size() > 0) {
            JSONArray json = new JSONArray();
            for (BluetoothDevice device : pairedDevices) {
                JSONObject jo = new JSONObject();
                jo.put("name", device.getName());
                jo.put("uuid", device.getAddress());
                json.put(jo);
            }
            callbackContext.success(json);
        } else {
            callbackContext.error("未有配对蓝牙");

        }
    }

    /*
  * 停止扫描
   */
    private void stopScan(final JSONArray args, final CallbackContext callbackContext) throws JSONException {
        // Get the local Bluetooth adapter
        isKeep = false;
        callbackContext.success("停止扫描成功");

    }

    private void printText(final JSONArray args, final CallbackContext callbackContext) throws JSONException {

        String sendData = args.getString(0);

        if (isConnection) {
            try {
               if(sendData!=null&&!"".equals(sendData)) {


                   JSONArray top_array = new JSONArray(sendData);

                   if (top_array != null && top_array.length() > 0) {
                           for (int m = 0; m < top_array.length(); m++) {
                               JSONObject jsonData = (JSONObject) top_array.get(m);
                                sendprint(jsonData);
                           }
                       }

                   if(LINE_BYTE_SIZE==32){
                       MKBluetoothPrinter.printText("\n");
                       MKBluetoothPrinter.printText("\n");
                       MKBluetoothPrinter.printText("\n");
                       MKBluetoothPrinter.printText("\n");
                       MKBluetoothPrinter.printText("\n");
                   }
                   //结束循环时
                    MKBluetoothPrinter.selectCommand(MKBluetoothPrinter.getCutPaperCmd());
//                     JSONObject dataJson = new JSONObject(sendData);
//                   ///获取globalDatatop数据
//                   JSONArray top_array = dataJson.optJSONArray("globalDatatop");
//                   //获取globalDatafoot数据
//                   JSONArray foot_array = dataJson.optJSONArray("globalDatafoot");
//                   //获取personsData数据
//                   JSONArray persons_object = dataJson.optJSONArray("personsData");
//
//
//                    MKBluetoothPrinter.selectCommand(MKBluetoothPrinter.RESET);
//                   MKBluetoothPrinter.selectCommand(MKBluetoothPrinter.LINE_SPACING_DEFAULT);
//
//                   if (persons_object != null && persons_object.length() > 0) {
//                       for (int j = 0; j < persons_object.length(); j++) {
//                           JSONObject person = (JSONObject) persons_object.get(j);
//
//
//                           if(person!=null) {
//                               JSONArray person_arr = person.optJSONArray("person");
//                               if (person_arr != null && person_arr.length() > 0) {
//
//
//                                           //循环打印头部
//                                           if (top_array != null && top_array.length() > 0) {
//                                               for (int m = 0; m < top_array.length(); m++) {
//                                                   JSONObject jsonData = (JSONObject) top_array.get(m);
//                                                    sendprint(jsonData);
//                                               }
//                                           }
//                                           for (int n = 0; n < person_arr.length(); n++) {
//                                               JSONObject jsonData = (JSONObject) person_arr.get(n);
//                                               sendprint(jsonData);
//                                           }
//
//
//                                           //循环打印底部部
//                                           if (foot_array != null && foot_array.length() > 0) {
//                                               for (int h = 0; h < foot_array.length(); h++) {
//                                                   JSONObject jsonData = (JSONObject) foot_array.get(h);
//                                                    sendprint(jsonData);
//                                               }
//                                           }
//                                           MKBluetoothPrinter.printText("\n");
//                                           MKBluetoothPrinter.printText("\n");
//
//                                           //结束循环时
//                                           MKBluetoothPrinter.selectCommand(MKBluetoothPrinter.getCutPaperCmd());
//
//
//                               }
//                           }
//                       }
//                   }
               }
                callbackContext.success("打印成功！");
            } catch (Exception e) {
                e.printStackTrace();
                callbackContext.error("打印失败！" + e.getMessage());
            }
        } else {
            callbackContext.error("设备未连接，请重新连接！");
        }
    }

    public void sendprint(JSONObject jsonData){


        try{
                System.out.println("jsonData:"+jsonData);
                int infoType = jsonData.optInt("infoType");
                String text = jsonData.optString("text");
                int fontType = jsonData.optInt("fontType");
                int aligmentType = jsonData.optInt("aligmentType");
                int isTitle = jsonData.optInt("isTitle");
                int maxWidth = jsonData.optInt("maxWidth");
                int qrCodeSize = jsonData.optInt("qrCodeSize");
                JSONArray textArray = jsonData.optJSONArray("textArray");

                                      /*  类型 infoType text= 0;          textList= 1;         barCode = 2;          qrCode = 3;
                                               image  = 4;         seperatorLine   = 5;            spaceLine       = 6;            footer          = 7;*/


                int fontType_int = fontType;
                int aligmentType_int = aligmentType;
                //                      int fontType_int =0;
                //                       int aligmentType_int =0;
                //                       try{
                //                           fontType_int =Integer.parseInt(fontType);
                //                       }catch (Exception e){
                //
                //                       }
                //
                //                       try{
                //                           aligmentType_int =Integer.parseInt(aligmentType);
                //                       }catch (Exception e){
                //
                //                       }

                if (isTitle == 1) {
                    MKBluetoothPrinter.selectCommand(MKBluetoothPrinter.BOLD);
                } else {
                    MKBluetoothPrinter.selectCommand(MKBluetoothPrinter.BOLD_CANCEL);
                }
               MKBluetoothPrinter.selectCommand(getAlignCmd(aligmentType_int));
                MKBluetoothPrinter.selectCommand(getFontSizeCmd(fontType_int));

                if (infoType == 0) {
                    MKBluetoothPrinter.printText(text);
                } else if (infoType == 1) {
                    if (textArray != null && textArray.length() > 0) {
                        if (textArray.length() == 2) {
                           MKBluetoothPrinter.printText(MKBluetoothPrinter.printTwoData(textArray.get(0).toString(), textArray.get(1).toString()));
                        } else if (textArray.length() == 3) {
                            MKBluetoothPrinter.printText(MKBluetoothPrinter.printThreeData(textArray.get(0).toString(), textArray.get(1).toString(), textArray.get(2).toString()));
                        } else if (textArray.length() == 4) {
                            MKBluetoothPrinter.printText(MKBluetoothPrinter.printFourData(textArray.get(0).toString(), textArray.get(1).toString(), textArray.get(2).toString(), textArray.get(3).toString()));
                        }
                    }
                } else if (infoType == 2) {
                    MKBluetoothPrinter.printText(getBarcodeCmd(text));
                } else if (infoType == 3) {
                    // 发送二维码打印图片前导指令
                    byte[] start = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1B,
                            0x40, 0x1B, 0x33, 0x00};
                   MKBluetoothPrinter.selectCommand(start);
                   MKBluetoothPrinter.selectCommand(getQrCodeCmd(text));
                    // 发送结束指令
                    byte[] end = {0x1d, 0x4c, 0x1f, 0x00};
                    MKBluetoothPrinter.selectCommand(end);
                } else if (infoType == 4) {
                    text = text.replace("data:image/jpeg;base64,", "").replace("data:image/png;base64,", "");


                    /**获取打印图片的数据**/
                    byte[] bitmapArray;
                    bitmapArray = Base64.decode(text, Base64.DEFAULT);
                    for (int n = 0; n < bitmapArray.length; ++n) {
                        if (bitmapArray[n] < 0) {// 调整异常数据
                            bitmapArray[n] += 256;
                        }

                    }

                    Bitmap bitmap = BitmapFactory.decodeByteArray(bitmapArray, 0, bitmapArray.length);


                    bitmap =compressPic(bitmap);

                    if(bitmap!=null) {
                        //图片的长和框必须是大于24*size
                        byte[] draw2PxPoint = draw2PxPoint(bitmap);
                        //发送打印图片前导指令

                        MKBluetoothPrinter.selectCommand(draw2PxPoint);
                    }

                    //图片的长和框必须是大于24*size
                //  byte[] draw2PxPoint = PicFromPrintUtils.draw2PxPoint(bitmap);
                    //发送打印图片前导指令

                 // MKBluetoothPrinter.selectCommand(draw2PxPoint);




                    //MKBluetoothPrinter.selectCommand(draw2PxPoint);
                    //InputStream fin = Bitmap2IS(bitmap);
                   //byte[] buffer = getReadBitMapBytes(bitmap);
                    //发送打印图片前导指令
                   //byte[] start = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1B,
                   //       0x40, 0x1B, 0x33, 0x00 };
                 //  MKBluetoothPrinter.selectCommand(start);
                   //MKBluetoothPrinter.selectCommandByte(buffer);
                      // 发送结束指令
                  //  byte[] end = { 0x1d, 0x4c, 0x1f, 0x00 };
                  //  MKBluetoothPrinter.selectCommand(end);
                    //MKBluetoothPrinter.selectCommand(bitmapArray);
                    // 发送结束指令

                } else if (infoType == 5) {
                    MKBluetoothPrinter.printText(printSeperatorLine());
                } else if (infoType == 6) {
                    MKBluetoothPrinter.printText("\n");
                } else if (infoType == 7) {
                    MKBluetoothPrinter.printText(text);
                }else if(infoType == 8) {
                    //结束循环时
                    MKBluetoothPrinter.selectCommand(MKBluetoothPrinter.getCutPaperCmd());
                }
                MKBluetoothPrinter.printText("\n");


        } catch (Exception e) {
            e.printStackTrace();;
        }

    }

    /**
     * 对图片进行压缩（去除透明度）
     *
     * @param
     */
    public static Bitmap compressPic(Bitmap bitmap) {
        Bitmap targetBmp =null;
        try{
            // 获取这个图片的宽和高
            int width = bitmap.getWidth();
            int height = bitmap.getHeight();
            // 指定调整后的宽度和高度
            //int newWidth = 240;
           // int newHeight = 240;
            int newWidth = bitmap.getWidth();
             int newHeight = bitmap.getHeight();
             targetBmp = Bitmap.createBitmap(newWidth, newHeight, Bitmap.Config.ARGB_8888);
            Canvas targetCanvas = new Canvas(targetBmp);
            targetCanvas.drawColor(0xffffffff);
            targetCanvas.drawBitmap(bitmap, new Rect(0, 0, width, height), new Rect(0, 0, newWidth, newHeight), null);
        }catch (Exception e){

        }
        return targetBmp;
    }

    /**
     * 灰度图片黑白化，黑色是1，白色是0
     *
     * @param x   横坐标
     * @param y   纵坐标
     * @param bit 位图
     * @return
     */
    public static byte px2Byte(int x, int y, Bitmap bit) {
        if (x < bit.getWidth() && y < bit.getHeight()) {
            byte b;
            int pixel = bit.getPixel(x, y);
            int red = (pixel & 0x00ff0000) >> 16; // 取高两位
            int green = (pixel & 0x0000ff00) >> 8; // 取中两位
            int blue = pixel & 0x000000ff; // 取低两位
            int gray = RGB2Gray(red, green, blue);
            if (gray < 128) {
                b = 1;
            } else {
                b = 0;
            }
            return b;
        }
        return 0;
    }

    /**
     * 图片灰度的转化
     */
    private static int RGB2Gray(int r, int g, int b) {
        int gray = (int) (0.29900 * r + 0.58700 * g + 0.11400 * b);  //灰度转化公式
        return gray;
    }

/*************************************************************************
 * 假设一个240*240的图片，分辨率设为24, 共分10行打印
 * 每一行,是一个 240*24 的点阵, 每一列有24个点,存储在3个byte里面。
 * 每个byte存储8个像素点信息。因为只有黑白两色，所以对应为1的位是黑色，对应为0的位是白色
 **************************************************************************/
    /**
     * 把一张Bitmap图片转化为打印机可以打印的字节流
     *
     * @param bmp
     * @return
     */
    public static byte[] draw2PxPoint(Bitmap bmp) {
        //用来存储转换后的 bitmap 数据。为什么要再加1000，这是为了应对当图片高度无法
        //整除24时的情况。比如bitmap 分辨率为 240 * 250，占用 7500 byte，
        //但是实际上要存储11行数据，每一行需要 24 * 240 / 8 =720byte 的空间。再加上一些指令存储的开销，
        //所以多申请 1000byte 的空间是稳妥的，不然运行时会抛出数组访问越界的异常。
        int size = bmp.getWidth() * bmp.getHeight() / 8 + 1000;
        byte[] data = new byte[size];
        int k = 0;
        //设置行距为0的指令
        data[k++] = 0x1B;
        data[k++] = 0x33;
        data[k++] = 0x00;
        // 逐行打印
        for (int j = 0; j < bmp.getHeight() / 24f; j++) {
            //打印图片的指令
            data[k++] = 0x1B;
            data[k++] = 0x2A;
            data[k++] = 33;
            data[k++] = (byte) (bmp.getWidth() % 256); //nL
            data[k++] = (byte) (bmp.getWidth() / 256); //nH
            //对于每一行，逐列打印
            for (int i = 0; i < bmp.getWidth(); i++) {
                //每一列24个像素点，分为3个字节存储
                for (int m = 0; m < 3; m++) {
                    //每个字节表示8个像素点，0表示白色，1表示黑色
                    for (int n = 0; n < 8; n++) {
                        byte b = px2Byte(i, j * 24 + m * 8 + n, bmp);
                        data[k] += data[k] + b;
                    }
                    k++;
                }
            }
            data[k++] = 10;//换行
        }
        return data;
    }


    /**解析图片 获取打印数据**/
    private byte[] getReadBitMapBytes(Bitmap bitmap) {
        /***图片添加水印**/
        //bitmap = createBitmap(bitmap);
        byte[] bytes = null;  //打印数据
        int width = bitmap.getWidth();
        int height = bitmap.getHeight();
        System.out.println("width=" + width + ", height=" + height);
        int heightbyte = (height - 1) / 8 + 1;
        int bufsize = width * heightbyte;
        int m1, n1;
        byte[] maparray = new byte[bufsize];

        byte[] rgb = new byte[3];

        int []pixels = new int[width * height]; //通过位图的大小创建像素点数组

        bitmap.getPixels(pixels, 0, width, 0, 0, width, height);
        /**解析图片 获取位图数据**/
        for (int j = 0;j < height; j++) {
            for (int i = 0; i < width; i++) {
                int pixel = pixels[width * j + i]; /**获取ＲＧＢ值**/
                int r = Color.red(pixel);
                int g = Color.green(pixel);
                int b = Color.blue(pixel);
                //System.out.println("i=" + i + ",j=" + j + ":(" + r + ","+ g+ "," + b + ")");
                rgb[0] = (byte)r;
                rgb[1] = (byte)g;
                rgb[2] = (byte)b;
                if (r != 255 || g != 255 || b != 255){//如果不是空白的话用黑色填充    这里如果童鞋要过滤颜色在这里处理
                    m1 = (j / 8) * width + i;
                    n1 = j - (j / 8) * 8;
                    maparray[m1] |= (byte)(1 << 7 - ((byte)n1));
                }
            }
        }
        byte[] b = new byte[322];
        int line = 0;
        int j = 0;
        ByteArrayOutputStream baos = new ByteArrayOutputStream();

        /**对位图数据进行处理**/
        for (int i = 0; i < maparray.length; i++) {
            b[j] = maparray[i];
            j++;
            if (j == 322) {  /**  322图片的宽 **/
                if (line < ((322 - 1) / 8)) {
                    byte[] lineByte = new byte[329];
                    byte nL = (byte) 322;
                    byte nH = (byte) (322 >> 8);
                    int index = 5;
                    /**添加打印图片前导字符  每行的 这里是8位**/
                    lineByte[0] = 0x1B;
                    lineByte[1] = 0x2A;
                    lineByte[2] = 1;
                    lineByte[3] = nL;
                    lineByte[4] = nH;
                    /**copy 数组数据**/
                    System.arraycopy(b, 0, lineByte, index, b.length);

                    lineByte[lineByte.length - 2] = 0x0D;
                    lineByte[lineByte.length - 1] = 0x0A;
                    baos.write(lineByte, 0, lineByte.length);
                    try {
                        baos.flush();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                    line++;
                }
                j = 0;
            }
        }
        bytes = baos.toByteArray();
        return bytes;
    }


    // 给图片添加水印
    private Bitmap createBitmap(Bitmap src) {
        Time t = new Time();
        t.setToNow();
        int w = src.getWidth();
        int h = src.getHeight();
        String mstrTitle = t.year + " 年 " + (t.month +1) + " 月 " + t.monthDay+" 日";
        Bitmap bmpTemp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bmpTemp);
        Paint p = new Paint();
        String familyName = "宋体";
        Typeface font = Typeface.create(familyName, Typeface.BOLD);
        p.setColor(Color.BLACK);
        p.setTypeface(font);
        p.setTextSize(33);
        canvas.drawBitmap(src, 0, 0, p);
        canvas.drawText(mstrTitle, 20, 310, p);
        canvas.save();
        canvas.restore();
        return bmpTemp;
    }

    private static InputStream Bitmap2IS(Bitmap bm){
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        bm.compress(Bitmap.CompressFormat.PNG, 100, baos);
        InputStream sbs = new ByteArrayInputStream(baos.toByteArray());
        return sbs;
    }
    /**
     * 打印------------------------------------------------
     *
     *
     */
    public static String printSeperatorLine() {
        String seperator="";
       for (int i=0;i<LINE_BYTE_SIZE;i++){
           seperator+="-";
       }
       return seperator;
    }
    /**
     * 打印文字
     *
     * @param text 要打印的文字
     */
    public static void printText(String text) {
        try {
            byte[] data = text.getBytes("gbk");
            outputStream.write(data, 0, data.length);
            outputStream.flush();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * 设置打印格式
     *
     * @param command 格式指令
     */
    public static void selectCommandByte(byte[] command) {
        try {
            outputStream.write(command, 0, command.length);
            outputStream.flush();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * 设置打印格式
     *
     * @param command 格式指令
     */
    public static void selectCommand(byte[] command) {
        try {
            outputStream.write(command);
            outputStream.flush();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * 获取数据长度
     *
     * @param msg
     * @return
     */
    @SuppressLint("NewApi")
    private static int getBytesLength(String msg) {
        return msg.getBytes(Charset.forName("GB2312")).length;
    }


    /**
     * 打印两列
     *
     * @param leftText  左侧文字
     * @param rightText 右侧文字
     * @return
     */
    @SuppressLint("NewApi")
    public static String printTwoData(String leftText, String rightText) {
        StringBuilder sb = new StringBuilder();
        int leftTextLength = getBytesLength(leftText);
        int rightTextLength = getBytesLength(rightText);
        sb.append(leftText);

        // 计算两侧文字中间的空格
        int marginBetweenMiddleAndRight = LINE_BYTE_SIZE - leftTextLength - rightTextLength;

        for (int i = 0; i < marginBetweenMiddleAndRight; i++) {
            sb.append(" ");
        }
        sb.append(rightText);
        return sb.toString();
    }

    /**
     * 打印三列
     *
     * @param leftText   左侧文字
     * @param middleText 中间文字
     * @param rightText  右侧文字
     * @return
     */
    @SuppressLint("NewApi")
    public static String printThreeData(String leftText, String middleText, String rightText) {

        /**
         * 打印三列时，中间一列的中心线距离打印纸左侧的距离
         */
       int LEFT_LENGTH =LINE_BYTE_SIZE/2;

        /**
         * 打印三列时，中间一列的中心线距离打印纸右侧的距离
         */
        int RIGHT_LENGTH = LINE_BYTE_SIZE/2;

        /**
         * 打印三列时，第一列汉字最多显示几个文字
         */
        int LEFT_TEXT_MAX_LENGTH = LEFT_LENGTH/2-2;

        StringBuilder sb = new StringBuilder();
        // 左边最多显示 LEFT_TEXT_MAX_LENGTH 个汉字 + 两个点
        if (leftText.length() > LEFT_TEXT_MAX_LENGTH) {
            //leftText = leftText.substring(0, LEFT_TEXT_MAX_LENGTH) + "..";
        }
        int leftTextLength = getBytesLength(leftText);
        int middleTextLength = getBytesLength(middleText);
        int rightTextLength = getBytesLength(rightText);

        sb.append(leftText);
        // 计算左侧文字和中间文字的空格长度
        int marginBetweenLeftAndMiddle = LEFT_LENGTH - leftTextLength - middleTextLength / 2;

        for (int i = 0; i < marginBetweenLeftAndMiddle; i++) {
            sb.append(" ");
        }
        sb.append(middleText);

        // 计算右侧文字和中间文字的空格长度
        int marginBetweenMiddleAndRight = RIGHT_LENGTH - middleTextLength / 2 - rightTextLength;

        for (int i = 0; i < marginBetweenMiddleAndRight; i++) {
            sb.append(" ");
        }

        // 打印的时候发现，最右边的文字总是偏右一个字符，所以需要删除一个空格
        sb.delete(sb.length() - 1, sb.length()).append(rightText);
        return sb.toString();
    }


    /**
     * 打印四列
     *
     * @param leftText   左侧文字
     * @param middleText1 中间文字
     * @param rightText  右侧文字
     * @return
     */
    @SuppressLint("NewApi")
    public static String printFourData(String leftText, String middleText1, String middleText2, String rightText) {
        StringBuilder sb = new StringBuilder();
        /**
         * 打印三列时，中间一列的中心线距离打印纸左侧的距离
         */
        int LEFT_LENGTH =LINE_BYTE_SIZE;

        /**
         * 打印三列时，中间一列的中心线距离打印纸右侧的距离
         */
      //  int RIGHT_LENGTH_1 = LEFT_LENGTH-20;
        int RIGHT_LENGTH_2 = 6;
        int RIGHT_LENGTH_3 = 6;
        int RIGHT_LENGTH_4 = 8;
        int RIGHT_LENGTH_1 = LEFT_LENGTH-RIGHT_LENGTH_2-RIGHT_LENGTH_3-RIGHT_LENGTH_4;
        /**
         * 打印三列时，第一列汉字最多显示几个文字
         */

        int sub_length=2;
        if(LINE_BYTE_SIZE==32){
            sub_length=0;
        }

        int leftTextLength = getBytesLength(leftText);
        int middle1TextLength = getBytesLength(middleText1);
        int middle2TextLength = getBytesLength(middleText2);
       // int rightTextLength = getBytesLength(rightText);

        sb.append(leftText);

        for (int i = leftTextLength; i < RIGHT_LENGTH_1; i++) {
            sb.append(" ");
        }

        sb.append(middleText1);

        for (int i = RIGHT_LENGTH_1+middle1TextLength; i < RIGHT_LENGTH_1+RIGHT_LENGTH_2; i++) {
            sb.append(" ");
        }
        sb.append(middleText2);

        for (int i = RIGHT_LENGTH_1+RIGHT_LENGTH_2+middle2TextLength; i < RIGHT_LENGTH_1+RIGHT_LENGTH_2+RIGHT_LENGTH_3; i++) {
            sb.append(" ");
        }

        sb.append(rightText);


        // 打印的时候发现，最右边的文字总是偏右一个字符，所以需要删除一个空格
       // sb.delete(sb.length() - 3, sb.length()).append(rightText);
        return sb.toString();
    }
    /**
     * 打印四列
     *
     * @param leftText   左侧文字
     * @param middleText1 中间文字
     * @param rightText  右侧文字
     * @return
     */
    @SuppressLint("NewApi")
    public static String printFourDataOld(String leftText, String middleText1, String middleText2, String rightText) {
        StringBuilder sb = new StringBuilder();
        /**
         * 打印三列时，中间一列的中心线距离打印纸左侧的距离
         */
        int LEFT_LENGTH =LINE_BYTE_SIZE/2;

        /**
         * 打印三列时，中间一列的中心线距离打印纸右侧的距离
         */
        int RIGHT_LENGTH = LINE_BYTE_SIZE/2;

        /**
         * 打印三列时，第一列汉字最多显示几个文字
         */

        int sub_length=2;
        if(LINE_BYTE_SIZE==32){
            sub_length=0;
        }

        int sub_length2=1;
       // if(LINE_BYTE_SIZE==32){
          //  sub_length2=1;
      //  }

        int LEFT_TEXT_MAX_LENGTH = LEFT_LENGTH/2-sub_length;

        // 左边最多显示 LEFT_TEXT_MAX_LENGTH 个汉字 + 两个点
        if (leftText.length() > (LEFT_TEXT_MAX_LENGTH+2)/2) {
            //leftText = leftText.substring(0, (LEFT_TEXT_MAX_LENGTH+2)/2-1) + ".";
        }
        int leftTextLength = getBytesLength(leftText);
        int middle1TextLength = getBytesLength(middleText1);
        int middle2TextLength = getBytesLength(middleText2);
        int rightTextLength = getBytesLength(rightText);

        sb.append(leftText);
        // 计算左侧文字和中间文字的空格长度
        int marginBetweenLeftAndMiddle1 = LEFT_LENGTH- leftTextLength - middle1TextLength ;

        for (int i = LEFT_LENGTH/4-sub_length2; i < marginBetweenLeftAndMiddle1; i++) {
            sb.append(" ");
        }
        sb.append(middleText1);


        // 计算右侧文字和中间文字的空格长度
        int marginBetweenMiddleAndRight = RIGHT_LENGTH- middle2TextLength - rightTextLength;

        for (int i = RIGHT_LENGTH/4-sub_length2; i < marginBetweenMiddleAndRight; i++) {
            sb.append(" ");
        }
        sb.append(middleText2);

        // 计算右侧文字和中间文字的空格长度
        int marginBetweenMiddle2AndRight = RIGHT_LENGTH - middle2TextLength  - rightTextLength;

        for (int i = RIGHT_LENGTH/4-sub_length2; i < marginBetweenMiddle2AndRight; i++) {
            sb.append(" ");
        }
        // 打印的时候发现，最右边的文字总是偏右一个字符，所以需要删除一个空格
        sb.delete(sb.length() - 3, sb.length()).append(rightText);
        return sb.toString();
    }


    /**
     * 向StringBuilder中添加指定数量的相同字符
     *
     * @param printCount   添加的字符数量
     * @param identicalStr 添加的字符
     */

    private static void addIdenticalStrToStringBuilder(StringBuilder builder, int printCount, String identicalStr) {
        for (int i = 0; i < printCount; i++) {
            builder.append(identicalStr);
        }
    }

    /**
     * 根据字符串截取前指定字节数,按照GBK编码进行截取
     *
     * @param str 原字符串
     * @param len 截取的字节数
     * @return 截取后的字符串
     */
    private static String subStringByGBK(String str, int len) {
        String result = null;
        if (str != null) {
            try {
                byte[] a = str.getBytes("GBK");
                if (a.length <= len) {
                    result = str;
                } else if (len > 0) {
                    result = new String(a, 0, len, "GBK");
                    int length = result.length();
                    if (str.charAt(length - 1) != result.charAt(length - 1)) {
                        if (length < 2) {
                            result = null;
                        } else {
                            result = result.substring(0, length - 1);
                        }
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        return result;
    }

    /**
     * 添加换行符
     */
    private static void addLineSeparator(StringBuilder builder) {
        builder.append("\n");
    }

    /**
     * 在GBK编码下，获取其字符串占据的字符个数
     */
    private static int getCharCountByGBKEncoding(String text) {
        try {
            return text.getBytes("GBK").length;
        } catch (Exception e) {
            e.printStackTrace();
            return 0;
        }
    }


    /**
     * 打印相关配置
     */
    public static class PrintConfig {
        public int maxLength = 30;

        public boolean printBarcode = false;  // 打印条码
        public boolean printQrCode = false;   // 打印二维码
        public boolean printEndText = true;   // 打印结束语
        public boolean needCutPaper = false;  // 是否切纸
    }



    /**
     * 打印二维码
     * @param qrCode
     * @return
     */
    public static  byte[]  getQrCodeCmd(String qrCode) {
        byte[] data;
        int store_len = qrCode.length() + 3;
        byte store_pL = (byte) (store_len % 256);
        byte store_pH = (byte) (store_len / 256);

        // QR Code: Select the model
        //              Hex     1D      28      6B      04      00      31      41      n1(x32)     n2(x00) - size of model
        // set n1 [49 x31, model 1] [50 x32, model 2] [51 x33, micro qr code]
        // https://reference.epson-biz.com/modules/ref_escpos/index.php?content_id=140
        byte[] modelQR = {(byte)0x1d, (byte)0x28, (byte)0x6b, (byte)0x04, (byte)0x00, (byte)0x31, (byte)0x41, (byte)0x32, (byte)0x00};

        // QR Code: Set the size of module
        // Hex      1D      28      6B      03      00      31      43      n
        // n depends on the printer
        // https://reference.epson-biz.com/modules/ref_escpos/index.php?content_id=141
        byte[] sizeQR = {(byte)0x1d, (byte)0x28, (byte)0x6b, (byte)0x03, (byte)0x00, (byte)0x31, (byte)0x43, (byte)0x08};

        //          Hex     1D      28      6B      03      00      31      45      n
        // Set n for error correction [48 x30 -> 7%] [49 x31-> 15%] [50 x32 -> 25%] [51 x33 -> 30%]
        // https://reference.epson-biz.com/modules/ref_escpos/index.php?content_id=142
        byte[] errorQR = {(byte)0x1d, (byte)0x28, (byte)0x6b, (byte)0x03, (byte)0x00, (byte)0x31, (byte)0x45, (byte)0x31};

        // QR Code: Store the data in the symbol storage area
        // Hex      1D      28      6B      pL      pH      31      50      30      d1...dk
        // https://reference.epson-biz.com/modules/ref_escpos/index.php?content_id=143
        //                        1D          28          6B         pL          pH  cn(49->x31) fn(80->x50) m(48->x30) d1…dk
        byte[] storeQR = {(byte)0x1d, (byte)0x28, (byte)0x6b, store_pL, store_pH, (byte)0x31, (byte)0x50, (byte)0x30};

        // QR Code: Print the symbol data in the symbol storage area
        // Hex      1D      28      6B      03      00      31      51      m
        // https://reference.epson-biz.com/modules/ref_escpos/index.php?content_id=144
        byte[] printQR = {(byte)0x1d, (byte)0x28, (byte)0x6b, (byte)0x03, (byte)0x00, (byte)0x31, (byte)0x51, (byte)0x30};

        data = byteMerger(modelQR, sizeQR);
        data = byteMerger(data, errorQR);
        data = byteMerger(data, storeQR);
        data = byteMerger(data, qrCode.getBytes());
        data = byteMerger(data, printQR);

        return data;
    }

    /**
     * 打印条码
     * @param barcode
     * @return
     */
    public static String getBarcodeCmd(String barcode) {
        // 打印 Code-128 条码时需要使用字符集前缀
        // "{A" 表示大写字母
        // "{B" 表示所有字母，数字，符号
        // "{C" 表示数字，可以表示 00 - 99 的范围


        byte[] data;

        String btEncode;

        if (barcode.length() < 18) {
            // 字符长度小于15的时候直接输出字符串
            btEncode = "{B" + barcode;
        } else {
            // 否则做一点优化

            int startPos = 0;
            btEncode = "{B";

            for (int i = 0; i < barcode.length(); i++) {
                char curChar = barcode.charAt(i);

                if (curChar < 48 || curChar > 57 || i == (barcode.length() - 1)) {
                    // 如果是非数字或者是最后一个字符

                    if (i - startPos >= 10) {
                        if (startPos == 0) {
                            btEncode = "";
                        }

                        btEncode += "{C";

                        boolean isFirst = true;
                        int numCode = 0;

                        for (int j = startPos; j < i; j++) {

                            if (isFirst) { // 处理第一位
                                numCode = (barcode.charAt(j) - 48) * 10;
                                isFirst = false;
                            } else { // 处理第二位
                                numCode += (barcode.charAt(j) - 48);
                                btEncode += (char) numCode;
                                isFirst = true;
                            }

                        }

                        btEncode += "{B";

                        if (!isFirst) {
                            startPos = i - 1;
                        } else {
                            startPos = i;
                        }
                    }

                    for (int k = startPos; k <= i; k++) {
                        btEncode += barcode.charAt(k);
                    }
                    startPos = i + 1;
                }

            }
        }


        // 设置 HRI 的位置，02 表示下方
        byte[] hriPosition = {(byte) 0x1d, (byte) 0x48, (byte) 0x02};
        // 最后一个参数表示宽度 取值范围 1-6 如果条码超长则无法打印
        byte[] width = {(byte) 0x1d, (byte) 0x77, (byte) 0x02};
        byte[] height = {(byte) 0x1d, (byte) 0x68, (byte) 0xfe};
        // 最后两个参数 73 ： CODE 128 || 编码的长度
        byte[] barcodeType = {(byte) 0x1d, (byte) 0x6b, (byte) 73, (byte) btEncode.length()};
        byte[] print = {(byte) 10, (byte) 0};

        data = byteMerger(hriPosition, width);
        data = byteMerger(data, height);
        data = byteMerger(data, barcodeType);
        data = byteMerger(data, btEncode.getBytes());
        data = byteMerger(data, print);

        return new String(data);
    }

    /**
     * 切纸
     * @return
     */
    public static  byte[] getCutPaperCmd() {
        // 走纸并切纸，最后一个参数控制走纸的长度
        byte[] data = {(byte) 0x1d, (byte) 0x56, (byte) 0x42, (byte) 0x15};

        return data;
    }

    /**
     * 对齐方式
     * @param alignMode
     * @return
     */
    public static  byte[]  getAlignCmd(int alignMode) {
        byte[] data = {(byte) 0x1b, (byte) 0x61, (byte) 0x0};
        if (alignMode == ALIGN_LEFT_NEW ) {
            data[2] = (byte) 0x00;
        } else if (alignMode == ALIGN_CENTER_NEW ) {
            data[2] = (byte) 0x01;
        } else if (alignMode == ALIGN_RIGHT_NEW ) {
            data[2] = (byte) 0x02;
        }

        return data;
    }

    /**
     * 字体大小
     * @param fontSize
     * @return
     */
    public static  byte[]  getFontSizeCmd(int fontSize) {
        byte[] data = {(byte) 0x1d, (byte) 0x21, (byte) 0x0};
        if (fontSize == FONT_NORMAL_NEW ) {
            data[2] = (byte) 0x00;
        } else if (fontSize == FONT_MIDDLE_NEW ) {
            data[2] = (byte) 0x01;
        } else if (fontSize == FONT_BIG_NEW ) {
            data[2] = (byte) 0x11;
        }else if (fontSize == FONT_BIG_NEW3 ) {
            data[2] = (byte) 0x10;
        }else if (fontSize == FONT_BIG_NEW4 ) {
            data[2] = (byte) 0x12;
        }else if (fontSize == FONT_BIG_NEW5 ) {
            data[2] = (byte) 0x21;
        }else if (fontSize == FONT_BIG_NEW6 ) {
            data[2] = (byte) 0x22;
        }else if (fontSize == FONT_BIG_NEW7 ) {
            data[2] = (byte) 0x33;
        }else if (fontSize == FONT_BIG_NEW8 ) {
            data[2] = (byte) 0x44;
        }

        return data;
    }

    /**
     * 加粗模式
     * @param fontBold
     * @return
     */
    public static  byte[]  getFontBoldCmd(int fontBold) {
        byte[] data = {(byte) 0x1b, (byte) 0x45, (byte) 0x0};

        if (fontBold == FONT_BOLD_NEW ) {
            data[2] = (byte) 0x01;
        } else if (fontBold == FONT_BOLD_CANCEL_NEW ) {
            data[2] = (byte) 0x00;
        }

        return data;
    }

    /**
     * 打开钱箱
     * @return
     */
    public static String getOpenDrawerCmd() {
        byte[] data = new byte[4];
        data[0] = 0x10;
        data[1] = 0x14;
        data[2] = 0x00;
        data[3] = 0x00;

        return new String(data);
    }

    /**
     * 字符串转字节数组
     * @param str
     * @return
     */
    public static byte[] stringToBytes(String str) {
        byte[] data = null;

        try {
            byte[] strBytes = str.getBytes("utf-8");

            data = (new String(strBytes, "utf-8")).getBytes("gbk");
        } catch (UnsupportedEncodingException exception) {
            exception.printStackTrace();
        }

        return data;
    }

    /**
     * 字节数组合并
     * @param bytesA
     * @param bytesB
     * @return
     */
    public static byte[] byteMerger(byte[] bytesA, byte[] bytesB) {
        byte[] bytes = new byte[bytesA.length + bytesB.length];
        System.arraycopy(bytesA, 0, bytes, 0, bytesA.length);
        System.arraycopy(bytesB, 0, bytes, bytesA.length, bytesB.length);
        return bytes;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();

    }
}
