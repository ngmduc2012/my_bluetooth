part of '../my_bluetooth.dart';

class MyBluetooth {
  /// STEP I | setup method

  static const String nameMethod = 'my_bluetooth';
  static const MethodChannel _methods = MethodChannel('$nameMethod/methods');
  final StreamController<MethodCall> _methodStream =
      StreamController.broadcast();

  // 1.1: Create stream method
  bool _initialized = false;
  Future<dynamic> _initFlutterBluePlus() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _methods.setMethodCallHandler((call) async {
      _updateMethodStream(call);
    });
  }

  // 1.2: invoke a platform method
  Future<dynamic> _invokeMethod(String method, [dynamic arguments]) async {
    dynamic out;
    print("_invokeMethod | $method | $arguments");
    try {
      _initFlutterBluePlus();
      out = await _methods.invokeMethod(method, arguments);
    } catch (e) {
      rethrow;
    }
    return out;
  }

  // 1.3: Update Stream _methodStream on flutter
  void _updateMethodStream(MethodCall methodCall) {
    _methodStream.add(methodCall);
  }

  /// II. Step 2: On/Off bluetooth
  // 2.1: turnOn
  // Turn on Bluetooth (Android only),
  Future<void> turnOn() async {
    var responseStream = _methodStream.stream
        .where((m) => m.method == "OnTurnOnResponse")
        .map((m) => m.arguments)
        .map((args) => BmTurnOnResponse.fromMap(args));

    // Start listening now, before invokeMethod, to ensure we don't miss the response
    Future<BmTurnOnResponse> futureResponse = responseStream.first;

    // invoke
    bool changed = await _invokeMethod('turnOn');

    // only wait if bluetooth was off
    if (changed) {
      // wait for response
      BmTurnOnResponse response = await futureResponse;

      // check response
      if (response.userAccepted == false) {
        throw FlutterBluePlusException(ErrorPlatform.fbp, "turnOn",
            FbpErrorCode.userRejected.index, "user rejected");
      }

      // wait for adapter to turn on
      await adapterState.where((s) => s == MPBluetoothAdapterState.on).first;
    }
  }

  // 2.3: adapterState (Lắng nghe trạng thái của bluetooth bằng stream)
  MPBluetoothAdapterState? _adapterStateNow;

  // The current adapter state
  MPBluetoothAdapterState get adapterStateNow => _adapterStateNow != null
      ? _adapterStateNow!
      : MPBluetoothAdapterState.unknown;

  // Gets the current state of the Bluetooth module
  Stream<MPBluetoothAdapterState> get adapterState async* {
    // get current state if needed
    if (_adapterStateNow == null) {
      MPBluetoothAdapterState val = await _invokeMethod('getAdapterState')
          .then((args) => BmBluetoothAdapterState.fromMap(args).adapterState);
      // update _adapterStateNow if it is still null after the await
      _adapterStateNow ??= val;
      yield _adapterStateNow ?? MPBluetoothAdapterState.on;
    }

    yield* _methodStream.stream
        .where((m) => m.method == "OnAdapterStateChanged")
        .map((m) => m.arguments)
        .map((args) => BmBluetoothAdapterState.fromMap(args))
        .map((s) => s.adapterState)
        .newStreamWithInitialValue(_adapterStateNow!);
  }

  /// III. Step 3: Scan device
  // 3.1: Retrieve a list of bonded devices (Android only)
  Future<List<BluetoothDevice>> get bondedDevices async {
    try {
      List<BluetoothDevice> response =
          await _invokeMethod('getBondedDevices').then((args) {
        List<BluetoothDevice> devices = [];
        for (var i = 0; i < args['devices'].length; i++) {
          devices.add(BluetoothDevice.fromMap(args['devices'][i]));
        }
        return devices;
      });
      return response;
    } catch (e) {
      return [];
    }
  }

  // 3.2: Gets the current state of the Bluetooth discovery
  bool isDiscovering = false;
  Stream<bool> get discoveryState async* {
    yield* _methodStream.stream
        .where((m) => m.method == "OnDiscoveryStateChanged")
        .map((m) => m.arguments)
        .map((args) => BluetoothDiscoveryState.fromMap(args))
        .map((s) {
      isDiscovering = s.discoveryState;
      if (!isDiscovering) {
        _scanBuffer?.close();
        _scanSubscription?.cancel();
        for (var subscription in _scanSubscriptions) {
          subscription.cancel();
        }
      }
      return isDiscovering;
    }).newStreamWithInitialValue(isDiscovering);
  }

  // 3.3 Scan device
  // buffers the scan results
  _BufferStream<List<BluetoothDevice>>? _scanBuffer;

  // Get result
  // stream used for the scanResults public api
  final _scanResults =
      _StreamControllerReEmit<List<BluetoothDevice>>(initialValue: []);
  final List<StreamSubscription> _scanSubscriptions = [];
  // the subscription to the merged scan results stream
  StreamSubscription<List<BluetoothDevice>?>? _scanSubscription;

  // the most recent scan results
  List<BluetoothDevice> get lastScanResults => _scanResults.latestValue;

  // a stream of scan results
  Stream<List<BluetoothDevice>> get scanResults => _scanResults.stream;

  // This is the same as scanResults, except:
  Stream<List<BluetoothDevice>> get onScanResults {
    if (isDiscovering) {
      return _scanResults.stream;
    } else {
      // skip previous results & push empty list
      return _scanResults.stream.skip(1).newStreamWithInitialValue([]);
    }
  }

  Future<void> startScan({
    List<String> withNames = const [],
    List<String> withRemoteIds = const [],
    List<String> withKeywords = const [],
    Duration? removeIfGone,
    bool androidUsesFineLocation = true,
  }) async {
    // already scanning?
    if (isDiscovering) {
      // stop existing scan
      await _stopScan();
      return;
    }

    Stream<List<BluetoothDevice>> responseStream = _methodStream.stream
        .where((m) => m.method == "OnScanResponse")
        .map((m) => m.arguments)
        .map((args) {
      // List<BluetoothDevice> advertisements = [];
      // for (var item in args['advertisements']) {
      //   advertisements.add(BluetoothDevice.fromMap(item));
      // }
      // print(args['advertisements']);
      // advertisements = BluetoothDevice.fromJsonToListTypeJson(args['advertisements']);
      // return advertisements;
      return BluetoothDevice.fromJsonToListTypeJson(args['advertisements']);
    });

    // Start listening now, before invokeMethod, so we do not miss any results
    _scanBuffer = _BufferStream.listen(responseStream);

    var settings =
        BmScanSettings(androidUsesFineLocation: androidUsesFineLocation);

    try {
      await _invokeMethod('startScan', settings.toMap()).onError((e, s) {
        print('onError | startScan');
        print(e);
        print(s);
        return _stopScan(invokePlatform: false);
      });
    } catch (e) {
      rethrow;
    }

    // check every 250ms for gone devices?
    late Stream<List<BluetoothDevice>?> outputStream = removeIfGone != null
        ? _mergeStreams([
            _scanBuffer!.stream,
            Stream.periodic(const Duration(milliseconds: 250))
          ])
        : _scanBuffer!.stream;

    // start by pushing an empty array
    _scanResults.add([]);

    // List<BluetoothDevice> output = [];

    // listen & push to `scanResults` stream
    _scanSubscription = outputStream.listen((List<BluetoothDevice>? response) {
      if (response != null) {
        // Filter
        List<BluetoothDevice>? filter = response.toSet().toList();
        filter = filter.where((element) {
          var pass = true;

          if (withRemoteIds.isNotEmpty) {
            pass = withRemoteIds.contains(element.remoteId);
          }

          if (withNames.isNotEmpty) {
            if (element.platformName == null) return false;
            pass = withNames.contains(element.platformName!.trim());
          }
          if (withKeywords.isNotEmpty) {
            pass = false;
            if (element.platformName == null) return false;
            for (final i in withKeywords) {
              var result = element.platformName!.contains(i);
              if (result) {
                pass = result;
                break;
              }
            }
          }
          return pass;
        }).toList();

        _scanResults.add(filter);
      }
    });
  }

  // 3.4: Stop Scan device
  // Stops a scan for Bluetooth Low Energy devices
  Future<bool> stopScan() async {
    return await _stopScan();
  }

  // for internal use
  Future<bool> _stopScan({
    bool invokePlatform = true,
  }) async {
    _scanBuffer?.close();
    _scanSubscription?.cancel();
    for (var subscription in _scanSubscriptions) {
      subscription.cancel();
    }
    if (invokePlatform) {
      return await _invokeMethod('stopScan');
    }
    return true;
  }

  /// IV. Step 4: Connect to device
  Stream<ConnectionStateResponse> get connectionState async* {
    yield* _methodStream.stream
        .where((m) => m.method == "OnConnectionStateChanged")
        .map((m) => m.arguments)
        .map((args) => ConnectionStateResponse.fromMap(args))
        .newStreamWithInitialValue(const ConnectionStateResponse(
            connectionState: MPConnectionStateEnum.disconnected));
  }

  Future<bool> isConnected() async {
    try {
      final result = await _invokeMethod('isConnected');
      MethodCall methodCall = MethodCall("OnConnectionStateChanged", {
        'connection_state': (result
                ? MPConnectionStateEnum.connected
                : MPConnectionStateEnum.disconnected)
            .index,
      });
      _updateMethodStream(methodCall);

      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> connect({
    String? remoteId,
  }) async {
    if (await isConnected()) return false;

    final Map<dynamic, dynamic> data = {};
    data['remote_id'] = remoteId;
    try {
      bool result = await _invokeMethod('connect', data);

      Future.delayed(const Duration(seconds: 5), () async {
        if (await isConnected()) {
          return true;
        } else {
          disconnect();
          return false;
        }
      });
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> disconnect() async {
    try {
      print("ZEUS PLUGIN | disconnect");
      return await _invokeMethod('disconnect');
    } catch (e) {
      rethrow;
    }
  }

  /* Stream<CommandResponse> get cmdResponse async* {
    yield* _methodStream.stream
        .where((m) => m.method == "OnCommandResponse")
        .map((m) => m.arguments)
        .map((args) {
      final result = CommandResponse.fromMap(args);
      final data = result.data;
      if(data.matchesInOrder(Cmd.basePrinter)){
        if(data?.elementAt(6) == ZPCmdIdEnum.accessoryInfo.byte) {
          print("OnCommandResponse | accessoryInfo");
        }

      }
      return result;
    });
  }*/

  Future<bool> sendCmd(List<int> byte, {int size = 34}) async {
    // assert(data.length <= 34);
    if (!await isConnected()) return false;

    final Map<dynamic, dynamic> data = {};
    data['byte'] = byte;
    data['size'] = size;
    try {
      return await _invokeMethod('sendCommand', data);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> sendFile({
    String? pathImage,
  }) async {
    final Map<dynamic, dynamic> data = {};
    data['path_image'] = pathImage;
    return await _invokeMethod('sentFile', data);
  }

  /// 1. GetInfo of Accessory
  Future<bool> sendCmdGetInfoOfAccessory() async {
    try {
      final result = await sendCmd(Cmd.getInfoOfAccessory);
      // print("ZP | sendCmdGetInfoOfAccessory | $result");
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// 2. SetInfo of Accessory
  Future<bool> sendCmdSetInfoOfAccessory({
    ZPAutoExposureEnum autoExposure = ZPAutoExposureEnum.on,
    ZPAutoPowerOffEnum autoPowerOff = ZPAutoPowerOffEnum.off,
    ZPPrintModeSetInfoEnum printModeSetInfo = ZPPrintModeSetInfoEnum.paperFull,
  }) async {
    try {
      final result = await sendCmd([
        ...Cmd.setInfoOfAccessory,
        autoExposure.byte,
        autoPowerOff.byte,
        printModeSetInfo.byte
      ]);
      print("ZP | sendCmdSetInfoOfAccessory | $result");
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// 3. Upgrade Ready
  Future<bool> sendCmdUpgradeReady(
      {required int dataSize,
      ZPDataClassificationEnum dataClassification =
          ZPDataClassificationEnum.tmd}) async {
    try {
      final result = await sendCmd([
        ...Cmd.upgradeReady,
        ((0xff0000 & dataSize) >> 16),
        ((0x00ff00 & dataSize) >> 8),
        (0x0000ff & dataSize),
        dataClassification.byte
      ]);
      print("ZP | sendCmdUpgradeReady | $result");
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// 4. Upgrade Cancel
  Future<bool> sendCmdUpgradeCancel() async {
    try {
      final result = await sendCmd([
        ...Cmd.upgradeCancel,
      ]);
      print("ZP | sendCmdUpgradeCancel | $result");
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// 5. Bulk Transfer
  Future<bool> sendCmdBulkTransfer({
    required int dataSize,
    required List<int> data,
  }) async {
    try {
      final result = await sendCmd([
        ...Cmd.bulkTransfer,
        ((dataSize & 0xff00) >> 8),
        (dataSize & 0xff),
        // ...data.takeWhile((e) => data.indexOf(e) < dataSize)
        ...(data.length >= dataSize
            ? data.sublist(0, dataSize > 20 ? 20 : dataSize)
            : data.length > 20
                ? data.sublist(0, 20)
                : data)
      ], size: 1024);
      print("ZP | sendCmdBulkTransfer | $result");
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// 6. Get BT Name
  Future<bool> sendCmdGetBTName() async {
    try {
      final result = await sendCmd(Cmd.getBTName);
      // print("ZP | sendCmdGetBTName | $result");
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// 7. Send Text
  Future<bool> sendText({required String value}) async {
    try {
      List<int> bytes = [...value.stringToBytes];
      final result = await sendCmd(bytes, size: bytes.length);
      print("MB | sendTextToDevice | $result");
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// 8. Print Ready
  Future<bool> sendCmdPrintReady({
    required int dataSize,
    int printCount = 1,
    ZPSkipEdgeEnhancementEnum skipEdgeEnhancementEnum =
        ZPSkipEdgeEnhancementEnum.eEFromPrinter,
    ZPPrintModeSetInfoEnum printMode = ZPPrintModeSetInfoEnum.imageFull,
  }) async {
    assert(printCount > 0 && printCount < 5, "printCount in [1,...,4]");
    try {
      final result = await sendCmd([
        ...Cmd.printReady,
        ((0xff0000 & dataSize) >> 16),
        ((0x00ff00 & dataSize) >> 8),
        (0x0000ff & dataSize),
        printCount,
        0x00,
        0x00,
        skipEdgeEnhancementEnum.byte,
        printMode.byte
      ]);
      print("ZP | sendCmdPrintReady | $result");
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// 9. Get Job List
  Future<bool> sendCmdGetJobList() async {
    try {
      final result = await sendCmd(Cmd.getJobList);
      print("ZP | sendCmdGetJobList | $result");
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// 10. Clear Job
  Future<bool> sendCmdClearJob({
    required int jobID1,
    required int jobID2,
  }) async {
    try {
      final result = await sendCmd([...Cmd.clearJob, jobID1, jobID2]);
      print("ZP | sendCmdClearJob | $result");
      return result;
    } catch (e) {
      rethrow;
    }
  }
}
