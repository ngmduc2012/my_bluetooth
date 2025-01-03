package com.wongcoupon.my_bluetooth;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;

import org.json.JSONArray;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.stream.Collectors;

import io.flutter.plugin.common.MethodChannel;


public class TalkingWithFlutter {

    TalkingWithFlutter(Utils utils){
        this.utils = utils;
    }
    public MethodChannel methodChannel;

    public void remove(){
        methodChannel.setMethodCallHandler(null);
        methodChannel = null;
    }

    private final Utils utils;

    // Send data back to Flutter plugin
    public void invokeMethodUIThread(final String method, HashMap<String, Object> data) {
        new Handler(Looper.getMainLooper()).post(() -> {
            //Could already be teared down at this moment
            if (methodChannel != null) {
                methodChannel.invokeMethod(method, data);
            } else {
                utils.log("invokeMethodUIThread: tried to call method on closed channel: " + method);
            }
        });
    }

    /** STEP 1 | State adapter bluetooth */
    public void onAdapterStateChanged(int state) {
        HashMap<String, Object> map = new HashMap<>();
        map.put("adapter_state", bmAdapterStateEnum(state));
        invokeMethodUIThread("OnAdapterStateChanged", map);
    }

    static int bmAdapterStateEnum(int as) {
        switch (as) {
            case BluetoothAdapter.STATE_OFF:
                return 6;
            case BluetoothAdapter.STATE_ON:
                return 4;
            case BluetoothAdapter.STATE_TURNING_OFF:
                return 5;
            case BluetoothAdapter.STATE_TURNING_ON:
                return 3;
            default:
                return 0;
        }
    }

    public void onTurnOnResponse(boolean result) {
        HashMap<String, Object> map = new HashMap<>();
        map.put("user_accepted", result);
        invokeMethodUIThread("OnTurnOnResponse", map);
    }

    /** STEP 2 | State connect to printer */
   private void onConnectionStateChanged(int state) {
        HashMap<String, Object> response = new HashMap<>();
        response.put("connection_state", state);
        invokeMethodUIThread("OnConnectionStateChanged", response);
    }

    public void onConnectDisConnected(){
        onConnectionStateChanged(0);
    }

    public void onConnectConnected(){
        onConnectionStateChanged(1);
    }

    public void onConnectWaiting(){
        onConnectionStateChanged(2);
    }

    // Can be talk with printer
    public void onConnectCommunicated(){
        onConnectionStateChanged(3);
    }

    /** STEP 3| State scan bluetooth */
    public void onDiscoveryStateChanged(boolean isDiscovery) {
        HashMap<String, Object> map = new HashMap<>();
        map.put("discovery_state", isDiscovery);
        invokeMethodUIThread("OnDiscoveryStateChanged", map);
    }

    public void onScanResponse(ArrayList<BluetoothDevice> device) {
        HashMap<String, Object> response = new HashMap<>();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            response.put("advertisements",
//                    Collections.singletonList(
                    device.stream()
                    .map(this::bmScanAdvertisement) // Chuyển đổi từ String sang Integer
                    .collect(Collectors.toList())
//                    )
            );
        }

        invokeMethodUIThread("OnScanResponse", response);
    }

    HashMap<String, Object> bmScanAdvertisement(BluetoothDevice device) {
        HashMap<String, Object> map = new HashMap<>();
        if (device.getAddress() != null) {
            map.put("remote_id", device.getAddress());
        }
        if (device.getName() != null) {
            map.put("platform_name", device.getName());
        }
        map.put("type", device.getType()); // int
        map.put("bond_state", device.getBondState());//int
        return map;
    }

    /** STEP 4| onDetachedFromEngine */
    public void onDetachedFromEngine() {
        invokeMethodUIThread("OnDetachedFromEngine", new HashMap<>());
        remove();
    }

    public void onCommandResponse(byte[] buffer) {
        byte[] buffer2 = new byte[34];
        System.arraycopy(buffer, 0, buffer2, 0, 34);
        utils.log( "bytes | " + Utils.printByteArray(buffer2));
        Integer[] data = Utils.convertByteArrayToIntArray(buffer2);
        utils.log( "IntArray | " + Arrays.toString(data));

        JSONArray jsonArray = new JSONArray();

        // Thêm mảng Integer vào JSONArray
        for (Integer value : data) {
            jsonArray.put(value);
        }

        HashMap<String, Object> map = new HashMap<>();
        map.put("data", jsonArray.toString());
        invokeMethodUIThread("OnCommandResponse", map);
    }

}
