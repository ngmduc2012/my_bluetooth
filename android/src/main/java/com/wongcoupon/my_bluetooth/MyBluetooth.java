package com.wongcoupon.my_bluetooth;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

/** MyBluetooth */
public class MyBluetooth implements
        FlutterPlugin,
        MethodCallHandler,
        PluginRegistry.ActivityResultListener,
        ActivityAware
{

  /**
   * I.Step 1: Setup method
   */
  private Context context;
  private ActivityPluginBinding activityBinding;
  private final Utils utils = new Utils();
  private final TalkingWithFlutter talkingWithFlutter = new TalkingWithFlutter(utils);
  private final Bluetooth bluetooth = new Bluetooth(utils, talkingWithFlutter);
  private final Permission permission = new Permission();

  // Run on background (Learn more: https://docs.flutter.dev/platform-integration/platform-channels?tab=ios-channel-swift-tab#executing-channel-handlers-on-background-threads)
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    context = flutterPluginBinding.getApplicationContext();

    talkingWithFlutter.methodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "my_bluetooth/methods");
    talkingWithFlutter.methodChannel.setMethodCallHandler(this);

    context.registerReceiver(bluetooth.mBluetoothStateReceiver, bluetooth.setupFilter());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {

    context.unregisterReceiver(bluetooth.mBluetoothStateReceiver);
    context = null;
    bluetooth.onDetachedFromEngine();
    talkingWithFlutter.onDetachedFromEngine();

  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
    if (requestCode == Bluetooth.enableBluetoothRequestCode) {
      talkingWithFlutter.onTurnOnResponse(resultCode == Activity.RESULT_OK);
      return true;
    }
    return false;
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activityBinding = binding;
    activityBinding.addRequestPermissionsResultListener(permission);
    activityBinding.addActivityResultListener(this);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
  }

  @Override
  public void onDetachedFromActivity() {
    activityBinding.removeRequestPermissionsResultListener(permission);
    activityBinding = null;
    context.unregisterReceiver(bluetooth.mReceiver);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "getAdapterState": {
        getAdapterState(result);
        break;
      }
      case "turnOn": {
        turnOn(result);
        break;
      }
      case "getBondedDevices": {
        bluetooth.getBondedDevices(result);
        break;
      }
      case "startScan": {
        startScan(call, result);
        break;
      }
      case "stopScan": {
        bluetooth.cancelDiscovery();
        result.success(true);
        break;
      }
      case "connect": {
        connect(call, result);
        break;
      }
      case "isConnected": {
        isConnected(call, result);
        break;
      }
      case "disconnect": {
        bluetooth.disconnect();
        result.success(true);
        break;
      }
      case "sendCommand": {
        sendCommand(call, result);
        break;
      }
      case "sentFile": {
        sentFile(call, result);
        break;
      }
      default:
        result.notImplemented();
        break;
    }
  }


  /**
   * II. Step 2 On/Off Bluetooth
   */
  // Lấy trạng thái hiện tại của adapter
  private void getAdapterState(@NonNull Result result) {
    // get adapterState, if we have permission
    int adapterState = -1; // unknown
    try {
        adapterState = bluetooth.mBluetoothAdapter.getState();
      } catch (Exception ignored) {
    }

    // see: BmBluetoothAdapterState
    HashMap<String, Object> map = new HashMap<>();
    map.put("adapter_state", TalkingWithFlutter.bmAdapterStateEnum(adapterState));

    result.success(map);
  }

  private void turnOn(@NonNull Result result) {
    ArrayList<String> permissions = new ArrayList<>();

    if (Build.VERSION.SDK_INT >= 31) { // Android 12 (October 2021)
      permissions.add(Manifest.permission.BLUETOOTH_CONNECT);
      permissions.add(Manifest.permission.ACCESS_FINE_LOCATION);
    }

    if (Build.VERSION.SDK_INT <= 30) { // Android 11 (September 2020)
      permissions.add(Manifest.permission.BLUETOOTH);
    }

    permission.ensurePermissions(permissions, context, activityBinding,  (granted, perm) -> {

      if (!granted) {
        result.error("turnOn", String.format("FlutterBluePlus requires %s permission", perm), null);
        return;
      }

      // Return do this device have bluetooth
      if (bluetooth.mBluetoothAdapter.isEnabled()) {
        result.success(false); // no work to do
        return;
      }

      activityBinding.getActivity().startActivityForResult(bluetooth.enableBtIntent(), Bluetooth.enableBluetoothRequestCode);

      result.success(true);
    });
  }

  /**
   * IV. Step 4 SCAN
   */



  private void startScan(@NonNull MethodCall call, @NonNull Result result) {
    utils.log( "startScan at onMethodCall");

    HashMap<String, Object> data = call.arguments();
    boolean androidUsesFineLocation = (boolean) data.get("android_uses_fine_location");

    ArrayList<String> permissions = new ArrayList<>();

    if (Build.VERSION.SDK_INT >= 31) { // Android 12 (October 2021)
      permissions.add(Manifest.permission.BLUETOOTH_SCAN);
      if (androidUsesFineLocation) {
        permissions.add(Manifest.permission.ACCESS_FINE_LOCATION);
      }
      // it is unclear why this is needed, but some phones throw a
      // SecurityException AdapterService getRemoteName, without it
      permissions.add(Manifest.permission.BLUETOOTH_CONNECT);
    }

    if (Build.VERSION.SDK_INT <= 30) { // Android 11 (September 2020)
      permissions.add(Manifest.permission.ACCESS_FINE_LOCATION);
    }


    permission.ensurePermissions(permissions, context, activityBinding,  (granted, perm) -> {

      if (!granted) {
        result.error("startScan",
                String.format("FlutterBluePlus requires %s permission", perm), null);
        return;
      }

      // check adapter
      if (!bluetooth.isAdapterOn()) {
        result.error("startScan", "bluetooth must be turned on", null);
        return;
      }

      bluetooth.listDevice.clear();

      // Register for broadcasts when a device is discovered.

      context.registerReceiver(bluetooth.mReceiver, bluetooth.filterSearch());
      boolean resultStartDiscovery = bluetooth.mBluetoothAdapter.startDiscovery();
      if(!resultStartDiscovery) {
        Intent callGPSSettingIntent = new Intent(android.provider.Settings.ACTION_LOCATION_SOURCE_SETTINGS);
        activityBinding.getActivity().startActivityForResult(callGPSSettingIntent, 1);
      }
      result.success(resultStartDiscovery);
    });
  }



  /**
   * V. Step 5 CONNECT
   */

  private void isConnected(@NonNull MethodCall call, @NonNull Result result) {
//    talkingWithFlutter.onConnectConnected();
    boolean isConnect = bluetooth.IsConnect();
    utils.log("bluetooth.IsConnect() | " + isConnect);
    result.success(isConnect);
  }


  private void connect(@NonNull MethodCall call, @NonNull Result result) {
    HashMap<String, Object> args = call.arguments();
    String remoteId = (String) args.get("remote_id");

    ArrayList<String> permissions = new ArrayList<>();

    if (Build.VERSION.SDK_INT >= 31) { // Android 12 (October 2021)
      permissions.add(Manifest.permission.BLUETOOTH_CONNECT);
    }

    permission.ensurePermissions(permissions, context, activityBinding,  (granted, perm) -> {

      if (!granted) {
        result.error("connect",
                String.format("FlutterBluePlus requires %s for new connection", perm), null);
        return;
      }

      // check adapter
      if (!bluetooth.isAdapterOn()) {
        result.error("connect", "bluetooth must be turned on", null);
        return;
      }

      if(bluetooth.connectDevice(remoteId)){
        bluetooth.createConnectThread();
        result.success(true);
      } else {
        talkingWithFlutter.onConnectDisConnected();
        bluetooth.disconnect();
        result.error("connect", "Can not found device", null);
      }

    });
  }

  private void sendCommand(@NonNull MethodCall call, @NonNull Result result){
    try {
      HashMap<String, Object> args = call.arguments();
      List<Integer> data = (List<Integer>) args.get("byte");
      Integer size = (Integer) args.get("size");

//      List<Integer> data = call.arguments(); // Nhận dữ liệu List<int>
      byte[] byteArray = new byte[size]; // Tạo mảng byte với kích thước tương ứng

      for (int i = 0; i < data.size(); i++) {
        byteArray[i] = data.get(i).byteValue(); // Chuyển đổi từng phần tử thành byte
      }
      utils.log("byteArray | " + Utils.printByteArray(byteArray));

      if (bluetooth.IsConnect()) {
        boolean resultSend = bluetooth.SendPacket(byteArray);
        if(!resultSend) bluetooth.disconnect();

        utils.log("result sendCommand | " + resultSend);

        result.success(resultSend);
      } else result.success(false);
    } catch (Exception e) {
      result.error("Error", "Error in sendCommand", e);
    }

  }

  public void sentFile(@NonNull MethodCall call, @NonNull Result result) {
    utils.log( "sentFile()");

    HashMap<String, Object> data = call.arguments();
    String path = (String) data.get("path_image");

    (new Thread((Runnable) (new Runnable() {

      @Override
      public void run() {
        File f_image = new File(path);
        utils.log( "sentFileToPrinter path = " + path);
        utils.log("length of file for sent = " + f_image.length());

        byte[] buffer = new byte[(int) (f_image.length())];

        FileInputStream fis_image = null;
        try {
          fis_image = new FileInputStream(f_image);
        } catch (FileNotFoundException e) {
          e.printStackTrace();
        }

        BufferedInputStream bis_image = new BufferedInputStream(fis_image);
        int totalByte = buffer.length;
        byte[] buffer_send_image = new byte[(int) f_image.length()];

        utils.log( "Send Start RGB : " + buffer_send_image.length);

        while (true) {
          try {
            if (bis_image.read(buffer_send_image) == -1) {
              utils.log( "There is no more data.");
              break;
            }
          } catch (IOException e) {
            e.printStackTrace();
          }

          if (!bluetooth.SendPacket(buffer_send_image)) {
            Thread.interrupted();
          }
        }
        // Add new
        try {
          bis_image.close();

          assert fis_image != null;
          fis_image.close();

          //onStreamLogs("=== End RGB");
          utils.log( "Send End RGB");
        } catch (IOException e) {
          e.printStackTrace();
        }
      }
    }))).start();
    result.success(true);
  }







}
