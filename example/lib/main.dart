import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_bluetooth/my_bluetooth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final XFile? image;

  final _myBluetooth = MyBluetooth();

  MPBluetoothAdapterState _adapterState = MPBluetoothAdapterState.unknown;
  late StreamSubscription<MPBluetoothAdapterState> _adapterStateStateSubscription;

  bool _isScanning = false;
  late StreamSubscription<bool> _isScanningSubscription;

  MPConnectionStateEnum _connectState = MPConnectionStateEnum.disconnected;
  late StreamSubscription<ConnectionStateResponse> _connectStateSubscription;

  late StreamSubscription<List<BluetoothDevice>> _scanResultsSubscription;
  List<BluetoothDevice> _scanResults = [];



  @override
  void initState() {
    super.initState();
    _adapterStateStateSubscription = _myBluetooth.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {});
    _connectStateSubscription = _myBluetooth.connectionState.listen((state) {
      _connectState = state.connectionState;
      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {});

    _isScanningSubscription = _myBluetooth.discoveryState.listen((state) {
      _isScanning = state;
      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {});

    _scanResultsSubscription = _myBluetooth.scanResults.listen((results) {
      _scanResults = results;
      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {});

  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    _scanResultsSubscription.cancel();
    _connectStateSubscription.cancel();
    _isScanningSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app | My Bluetooth'),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Step 1. On/Off Bluetooth"),
                Text("State Bluetooth Adapter: ${_adapterState.toString()}"),
                TextButton(
                    onPressed: () async {
                      await _myBluetooth.turnOn();
                    },
                    child: const Text("turnOn")),
                const Text("Step 2: Scan device"),
                Text(" is Scanning : ${_isScanning.toString()}"),
                const SizedBox(height: 20,),
                const Text("Step 3: Connect"),
                Text("is connecting: ${_connectState}"),
                TextButton(
                    onPressed: () async {
                      print(await _myBluetooth.disconnect());
                    },
                    child: const Text("disconnect")),
                const SizedBox(height: 20,),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          TextButton(
                              onPressed: () async {
                                var bondedDevices = await _myBluetooth.bondedDevices;
                                setState((){
                                  _scanResults = bondedDevices;
                                });
                                print("bondedDevices: ${bondedDevices.length}");
                              },
                              child: const Text("getBondedDevices")),
                          TextButton(
                              onPressed: () async {
                                await _myBluetooth.startScan(
                                    withKeywords: [
                                  // "Nailpop", "Nailpop Pro",
                                  // "Snap# Kiosk", "DMP"
                                  //     "image box"
                                ]);
                              },
                              child: const Text("startScan")),
                          TextButton(
                              onPressed: () async {
                                print(await _myBluetooth.stopScan());
                              },
                              child: const Text("stopScan")),
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width/3*2,
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                                              shrinkWrap: true,
                                              itemCount: _scanResults.length,
                                              itemBuilder: (BuildContext context, int index) {
                      final item = _scanResults[index];
                      return GestureDetector(
                        onTap: ()  async {
                          print("click ${item.remoteId}");
                          print(await _myBluetooth.connect(remoteId:  item.remoteId));
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all( 20),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.2)
                          ),
                          child: Column(
                            mainAxisSize:  MainAxisSize.min,
                            children: [
                              Text("Name: ${item.platformName}", style:  const TextStyle(fontWeight: FontWeight.bold),),
                              Text("ID: ${item.remoteId}"),
                              Text("bondState: ${item.bondState}"),
                              Text("type: ${item.type}"),
                            ],
                          ),
                        ),
                      );
                                              },
                                            ),
                    )
                  ],
                ),




                const Text("SEND TEXT TO DEVICE", style: TextStyle(fontWeight: FontWeight.w800),),
                TextButton(
                    onPressed: () async {
                      await _myBluetooth.sendText(value: "Hello World");
                    },
                    child: const Text("1 | Send text 'Hello World'")),

              //Send File
                const Text(
                  "HOW TO SEND FILE?",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                TextButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      image =
                          await picker.pickImage(source: ImageSource.gallery);

                      print(image?.path);
                    },
                    child: const Text("Step 1 | Choose file")),


                const SizedBox(
                  height: 10,
                ),
                TextButton(
                    onPressed: () async {

                      if (image != null) {
                        print( await _myBluetooth.sendFile(
                            pathImage: image?.path));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text("You need to choose file first")));
                      }
                    },
                    child: const Text("Step 3 | Sent file")),

                //Send File
                const Text(
                  "NOTE!!!! You can use function 'sendCmd' to send any thing.",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
