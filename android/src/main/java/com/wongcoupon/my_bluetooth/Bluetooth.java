package com.wongcoupon.my_bluetooth;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;

import androidx.annotation.NonNull;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

import io.flutter.plugin.common.MethodChannel;

public class Bluetooth {
    Bluetooth(Utils utils, TalkingWithFlutter talkingWithFlutter){
        this.utils = utils;
        this.talkingWithFlutter = talkingWithFlutter;
    }

    static final int enableBluetoothRequestCode = 1879842617;
    static final UUID MY_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");

    public IntentFilter setupFilter(){
        IntentFilter filter = new IntentFilter();
        filter.addAction(BluetoothAdapter.ACTION_STATE_CHANGED);
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED);
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);
        filter.addAction(BluetoothDevice.ACTION_ACL_CONNECTED);
        filter.addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED);
        return  filter;
    }

    public IntentFilter filterSearch(){
        return new IntentFilter(BluetoothDevice.ACTION_FOUND);
    }

    public final Utils utils;
    public final TalkingWithFlutter talkingWithFlutter;


    public BluetoothAdapter mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();


    // Lắng nghe trạng thái của adapter bất cứ khi nào nó thay đổi
    public final BroadcastReceiver mBluetoothStateReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            final String action = intent.getAction();
            switch (Objects.requireNonNull(action)) {
                case BluetoothAdapter.ACTION_STATE_CHANGED: {
                    final int adapterState = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR);

                    if (adapterState == BluetoothAdapter.STATE_TURNING_OFF ||
                            adapterState == BluetoothAdapter.STATE_OFF) {
                        disconnect();
                        talkingWithFlutter.onDiscoveryStateChanged(false);
                    }
                    talkingWithFlutter.onAdapterStateChanged(adapterState);
                    break;
                }
                case BluetoothAdapter.ACTION_CONNECTION_STATE_CHANGED:
                    final int connectState = intent.getIntExtra(BluetoothAdapter.EXTRA_CONNECTION_STATE, BluetoothAdapter.ERROR);
                    if (connectState == BluetoothAdapter.STATE_CONNECTED) {
                        utils.log("BluetoothAdapter.STATE_CONNECTED");
                    } else if(connectState == BluetoothAdapter.STATE_CONNECTING){
                        utils.log("BluetoothAdapter.STATE_CONNECTING");
                    } else if(connectState == BluetoothAdapter.STATE_DISCONNECTED){
                        utils.log("BluetoothAdapter.STATE_DISCONNECTED");
                    } else if(connectState == BluetoothAdapter.STATE_DISCONNECTING){
                        utils.log("BluetoothAdapter.STATE_DISCONNECTING");
                    }
                    break;
                case BluetoothAdapter.ACTION_DISCOVERY_FINISHED:
                    talkingWithFlutter.onDiscoveryStateChanged(false);
                    break;
                case BluetoothAdapter.ACTION_DISCOVERY_STARTED:
                    talkingWithFlutter.onDiscoveryStateChanged(true);
                    break;
                case BluetoothDevice.ACTION_ACL_CONNECTED: {
                    if(mConnectedThread == null){
                        talkingWithFlutter.onConnectConnected();
                    } else {
                        talkingWithFlutter.onConnectCommunicated();
                    }
                    break;
                }
                case BluetoothDevice.ACTION_ACL_DISCONNECTED: {
                    disconnect();
                    break;
                }
            }
        }
    };

    public void onDetachedFromEngine() {
        cancelDiscovery();
        disconnect();
        mBluetoothAdapter = null;
    }

    public Intent enableBtIntent(){
        return new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);

    }

    // get adapterState, if we have permission
    public boolean isAdapterOn() {
        try {
            return mBluetoothAdapter.getState() == BluetoothAdapter.STATE_ON;
        } catch (Exception e) {
            return false;
        }
    }

    // Create a BroadcastReceiver for ACTION_FOUND.
    public final BroadcastReceiver mReceiver = new BroadcastReceiver() {
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if (BluetoothDevice.ACTION_FOUND.equals(action)) {

                BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);

                assert device != null;
                if ((device.getType() != BluetoothDevice.DEVICE_TYPE_CLASSIC) && (device.getType() != BluetoothDevice.DEVICE_TYPE_DUAL))
                    return;

                listDevice.add(device);
                talkingWithFlutter.onScanResponse(listDevice);
            }
        }
    };

    // Lấy danh sách thiết bị đã kết nối
    public void getBondedDevices(@NonNull MethodChannel.Result result) {
        final Set<BluetoothDevice> bondedDevices = mBluetoothAdapter.getBondedDevices();

        List<HashMap<String, Object>> devList = new ArrayList<HashMap<String, Object>>();
        for (BluetoothDevice d : bondedDevices) {
            devList.add(talkingWithFlutter.bmScanAdvertisement(d));
        }

        HashMap<String, Object> response = new HashMap<String, Object>();
        response.put("devices", devList);

        result.success(response);
    }

    // Ngắt tìm kiếm
    public void cancelDiscovery() {
        if (mBluetoothAdapter != null) {
            if (mBluetoothAdapter.isDiscovering()) mBluetoothAdapter.cancelDiscovery();
        }
    }

    // Bắt đầu tìm kiếm
    public final ArrayList<BluetoothDevice> listDevice = new ArrayList<>(); //Lưu trữ các thiết bị tìm kiếm được

    public BluetoothDevice m_SelectedDevice = null;

    public boolean connectDevice(String remoteId){
        BluetoothDevice blueDevice = null;
        for (int i = 0; i < listDevice.size(); i++) {
            if (Objects.equals(listDevice.get(i).getAddress(), remoteId)) {
                blueDevice = listDevice.get(i);
                break;
            }
        }
        if (blueDevice == null) {
            final Set<BluetoothDevice> bondedDevices = mBluetoothAdapter.getBondedDevices();
            for (BluetoothDevice d : bondedDevices) {
                if (Objects.equals(d.getAddress(), remoteId)) {
                    blueDevice = d;
                    break;
                }
            }
        }

        if (blueDevice == null) {
           return  false;
        }

        // Create connect thread
        m_SelectedDevice = blueDevice;
        return  true;
    }

    public ConnectThread mConnectThread = null;
    public ConnectedThread mConnectedThread = null;

    public void createConnectThread() {
        mConnectThread = new ConnectThread(m_SelectedDevice);
        mConnectThread.start();
    }

    public class ConnectThread extends Thread {
        public BluetoothSocket mmSocket;
        public final BluetoothDevice mmDevice;

        public ConnectThread(BluetoothDevice device) {
            // Use a temporary object that is later assigned to mmSocket,
            // because mmSocket is final
            BluetoothSocket tmp = null;
            mmDevice = device;

            try {
                // Get a BluetoothSocket to connect with the given BluetoothDevice.
                // MY_UUID is the app's UUID string, also used in the server code.
                tmp = device.createInsecureRfcommSocketToServiceRecord(MY_UUID);
            } catch (Exception e) {
            }
            mmSocket = tmp;
        }

        public void run() {
            // Cancel discovery because it will slow down the connection
            cancelDiscovery();
            super.run();
            try {
//                mmSocket.close();
                talkingWithFlutter.onConnectWaiting();

                // Connect to the remote device through the socket. This call blocks
                // until it succeeds or throws an exception.
                mmSocket.connect();

                if (mConnectedThread == null) {
                    // Do work to manage the connection (in a separate thread)
                    mConnectedThread = new ConnectedThread(mmSocket, mmDevice.getAddress());

                    mConnectedThread.start();
                    utils.log(" mConnectedThread.start()");
                } else {
                    utils.log(" mConnectedThread != null");
                }

            } catch (IOException connectException) {
                // Unable to connect; close the socket and get out
                try {
                    try {
                        mmSocket.close();
                        try {
                            mmSocket = (BluetoothSocket) mmDevice.getClass().getMethod("createRfcommSocket", int.class).invoke(mmDevice, 2); //1 ios //2 android
                            assert mmSocket != null;
                            mmSocket.connect();

//                            utils.log( "BLUETOOTH_CANNOT_CONNECT mHandler 1");
//                            disconnect();

                        } catch (Exception e) {
                            utils.log( e.toString());
                            mmSocket.close();

                            utils.log( "BLUETOOTH_CANNOT_CONNECT mHandler 2");
                            disconnect();
                            return;
                        }

                    } catch (Exception e) {

                        mmSocket.close();
                        utils.log( "BLUETOOTH_CANNOT_CONNECT mHandler 3");
                        disconnect();
                        return;
                    }

                } catch (IOException closeException) {

                    utils.log( "BLUETOOTH_CANNOT_CONNECT mHandler 4");
                    disconnect();
                }

                return;
            } catch (Exception e) {
                utils.log( e.toString());
                disconnect();
            }


        }

        public void cancel() {
            try {
                if (mmSocket != null) {
                    mmSocket.close();
                }
            } catch (IOException ignored) {
                disconnect();
            }
        }
    }

    public void disconnect() {
        if (mConnectThread != null) {
            mConnectThread.cancel();
            mConnectThread = null;
            utils.log( "disconnect mConnectThread");
//            onStreamLogs( "disconnect mConnectThread");
        }

        if (mConnectedThread != null) {
            mConnectedThread.cancel();
            mConnectedThread = null;
            utils.log( "disconnect mConnectedThread");
        }
//        pathImage = null;
        talkingWithFlutter.onConnectDisConnected();

    }

    public boolean IsConnect() {
        if (mConnectedThread == null || !mConnectedThread.isAlive()) {
            boolean result =  mConnectThread != null && mConnectThread.isAlive();
            return result;
        }
        return true;
    }

    public class ConnectedThread extends Thread {
        private final BluetoothSocket mmSocket;
        private final InputStream mmInStream;
        private final OutputStream mmOutStream;

        public ConnectedThread(BluetoothSocket socket, String strAddress) {
            mmSocket = socket;
            InputStream tmpIn = null;
            OutputStream tmpOut = null;

            // Get the input and output streams, using temp objects because
            // member streams are final
            try {
                tmpIn = socket.getInputStream();
            } catch (IOException e) {
                utils.log( "Error occurred when creating input stream: " + e);
            }
            try {
                tmpOut = socket.getOutputStream();
            } catch (IOException e) {
                utils.log( "Error occurred when creating output stream: " + e);
            }

            mmInStream = tmpIn;
            mmOutStream = tmpOut;

        }

        // Read receive data
        public void run() {
          byte[] buffer = new byte[1024];
          byte[] bufferWorking = new byte[1024];
          int bytes; // bytes returned from read()

            // Keep listening to the InputStream until an exception occurs
            while (true) {
                try {
                    // Read from the InputStream
                    if (mmSocket != null) {
                        if (!mmSocket.isConnected()) {
                            break;
                        }
                    }

                int iReadSize = mmInStream.available();
                    int blockSize = iReadSize / 34;

                    if (iReadSize > 0) {
                        utils.log( "iReadSize = " + iReadSize + ",  blockSize = " + blockSize);
                    }

                    if (iReadSize > 34) {
                        utils.log("BLUE RECEIVED SIZE : " + iReadSize + ", blockSize : " + blockSize);
                        bytes = mmInStream.read(buffer, 0, iReadSize);

                        for (int i = 0, m = 0, k = 0; i < blockSize; i++) {

                            for (; m < iReadSize; ) {
                                bufferWorking[k] = buffer[m++];

                                //Check next packet
                                if ((buffer[m + 0] == 27) && (buffer[m + 1] == 42) && (buffer[m + 2] == 68)) {
                                    break;
                                }
                                k++;
                            }
                            utils.log( "bufferWorking | ");
                            talkingWithFlutter.onCommandResponse(bufferWorking);
                            Thread.sleep(100);
                            k = 0;
                        }
                    } else {
                        if (iReadSize > 0) {
                            bytes = mmInStream.read(buffer);
                            talkingWithFlutter.onCommandResponse(buffer);
                        } else {
                            Thread.sleep(100);
                        }
                    }
                    //----------------------------------------------------------------------------------------------------------------------

                } catch (InterruptedException | IOException e) {
                    break;
                }
            }
        }

        /* Call this from the main activity to send data to the remote device */
        public boolean write(byte[] bytes) {
            try {

                mmOutStream.write(bytes, 0, bytes.length);
                mmOutStream.flush();

                utils.log("bytes" + Utils.printByteArray(bytes));

            } catch (Exception e) {
                cancel();
                e.printStackTrace();
                return false;
            }
            return true;
        }

        /* Call this from the main activity to shutdown the connection */
        public void cancel() {

            try {
                if (mmSocket != null) {
                    mmSocket.close();
                    Thread.sleep(1000);
                }
            } catch (IOException | InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    public boolean SendPacket(byte[] data) {
        if (mConnectedThread == null)
            return false;

        if (!mConnectedThread.write(data)) {
            disconnect();
            return false;
        }
        return true;
    }
    
}
