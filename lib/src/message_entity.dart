part of '../my_bluetooth.dart';

/// Step 1: On/Off Bluetooth
enum MPBluetoothAdapterState {
  unknown, // 0
  unavailable, // 1
  unauthorized, // 2
  turningOn, // 3
  on, // 4
  turningOff, // 5
  off, // 6
}

class BmBluetoothAdapterState {
  MPBluetoothAdapterState adapterState;

  BmBluetoothAdapterState({required this.adapterState});

  Map<dynamic, dynamic> toMap() {
    final Map<dynamic, dynamic> data = {};
    data['adapter_state'] = adapterState.index;
    return data;
  }

  factory BmBluetoothAdapterState.fromMap(Map<dynamic, dynamic> json) {
    return BmBluetoothAdapterState(
      adapterState: MPBluetoothAdapterState.values[json['adapter_state']],
    );
  }
}

class BluetoothDiscoveryState {
  bool discoveryState;

  BluetoothDiscoveryState({required this.discoveryState});

  Map<dynamic, dynamic> toMap() {
    final Map<dynamic, dynamic> data = {};
    data['discovery_state'] = discoveryState;
    return data;
  }

  factory BluetoothDiscoveryState.fromMap(Map<dynamic, dynamic> json) {
    return BluetoothDiscoveryState(
      discoveryState: json['discovery_state'],
    );
  }
}

class BmTurnOnResponse {
  bool userAccepted;

  BmTurnOnResponse({
    required this.userAccepted,
  });

  factory BmTurnOnResponse.fromMap(Map<dynamic, dynamic> json) {
    return BmTurnOnResponse(
      userAccepted: json['user_accepted'],
    );
  }
}

enum MPConnectionStateEnum {
  disconnected, // 0
  connected, // 1  == mConnectThread success
  waiting, // 2
  communicated; // 3 == mConnectedThread success && Set Info of Accessory

  bool get isConnected => this == MPConnectionStateEnum.connected;
  bool get isWaiting => this == MPConnectionStateEnum.waiting;
  bool get isDisconnected => this == MPConnectionStateEnum.disconnected;
}

class ConnectionStateResponse {
  final MPConnectionStateEnum connectionState;
  final String? message;

  const ConnectionStateResponse({
    required this.connectionState,
    this.message,
  });

  factory ConnectionStateResponse.fromMap(Map<dynamic, dynamic> json) {
    return ConnectionStateResponse(
      connectionState:
          MPConnectionStateEnum.values[json['connection_state'] as int],
      message: json['message'] as String?,
    );
  }
}

enum MPBondEnum {
  none(code: 10),
  bonding(code: 11),
  bonded(code: 12);

  const MPBondEnum({required this.code});

  final int code;

  static MPBondEnum? findByCode(int code) {
    try {
      return MPBondEnum.values.where((e) => e.code == code).first;
    } catch (e) {
      return null;
    }
  }
}

enum MPDeviceTypeEnum {
  unknown(code: 0),
  classic(code: 1),
  le(code: 2),
  dual(code: 3);

  const MPDeviceTypeEnum({required this.code});

  final int code;

  static MPDeviceTypeEnum? findByCode(int code) {
    try {
      return MPDeviceTypeEnum.values.where((e) => e.code == code).first;
    } catch (e) {
      return null;
    }
  }
}

class BluetoothDevice {
  String remoteId;
  String? platformName;
  MPDeviceTypeEnum? type;
  MPBondEnum? bondState;

  BluetoothDevice({
    required this.remoteId,
    this.platformName,
    this.type,
    this.bondState,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BluetoothDevice &&
          runtimeType == other.runtimeType &&
          remoteId == other.remoteId &&
          platformName == other.platformName &&
          type == other.type &&
          bondState == other.bondState;

  @override
  int get hashCode =>
      remoteId.hashCode ^
      platformName.hashCode ^
      type.hashCode ^
      platformName.hashCode;

  Map<dynamic, dynamic> toMap() {
    final Map<dynamic, dynamic> data = {};
    data['remote_id'] = remoteId;
    data['platform_name'] = platformName;
    data['type'] = type?.code;
    data['bond_state'] = bondState?.code;
    return data;
  }

  factory BluetoothDevice.fromMap(Map<dynamic, dynamic> json) {
    return BluetoothDevice(
      remoteId: json['remote_id'],
      platformName: json['platform_name'],
      type: MPDeviceTypeEnum.findByCode(json['type']),
      bondState: MPBondEnum.findByCode(json['bond_state']),
    );
  }

  /// Handle for list data:
  static List<BluetoothDevice> fromJsonToListTypeJson(dynamic json) =>
      List<BluetoothDevice>.from(
        (json as List<Object?>).map((e) => e == null
            ? null
            : BluetoothDevice.fromMap(e as Map<dynamic, dynamic>)),
      );

  static List<BluetoothDevice> fromJsonToListTypeString(String data) =>
      List<BluetoothDevice>.from(
        (json.decode(data) as List<Object?>).map((e) => e == null
            ? null
            : BluetoothDevice.fromMap(e as Map<dynamic, dynamic>)),
      );

  static List<dynamic>? toListJson(List<BluetoothDevice>? list) =>
      list == null ? null : List<dynamic>.from(list.map((e) => e.toMap()));
}

class CommandResponse {
  final List<int>? data;

  const CommandResponse({
    this.data,
  });

  factory CommandResponse.fromMap(Map<dynamic, dynamic> json) {
    return CommandResponse(
      data: List<int>.from(jsonDecode(json['data'] as String)),
    );
  }
}

enum ErrorPlatform {
  fbp,
  android,
  apple,
}
/*
final ErrorPlatform _nativeError = (() {
  if (Platform.isAndroid) {
    return ErrorPlatform.android;
  } else {
    return ErrorPlatform.apple;
  }
})();*/

enum FbpErrorCode {
  success,
  timeout,
  androidOnly,
  applePlatformOnly,
  createBondFailed,
  removeBondFailed,
  deviceIsDisconnected,
  serviceNotFound,
  characteristicNotFound,
  adapterIsOff,
  connectionCanceled,
  userRejected
}

class FlutterBluePlusException implements Exception {
  /// Which platform did the error occur on?
  final ErrorPlatform platform;

  /// Which function failed?
  final String function;

  /// note: depends on platform
  final int? code;

  /// note: depends on platform
  final String? description;

  FlutterBluePlusException(
      this.platform, this.function, this.code, this.description);

  @override
  String toString() {
    String sPlatform = platform.toString().split('.').last;
    return 'FlutterBluePlusException | $function | $sPlatform-code: $code | $description';
  }

  @Deprecated('Use function instead')
  String get errorName => function;

  @Deprecated('Use code instead')
  int? get errorCode => code;

  @Deprecated('Use description instead')
  String? get errorString => description;
}

class CommandFromNativeResponse {
  final String message;

  const CommandFromNativeResponse({
    required this.message,
  });

  factory CommandFromNativeResponse.fromMap(Map<dynamic, dynamic> json) {
    return CommandFromNativeResponse(message: json['message'] as String);
  }
}
