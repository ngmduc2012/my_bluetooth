

[![GitHub](https://img.shields.io/badge/Nguyen_Duc-GitHub-black?logo=github)](https://github.com/ngmduc2012)
_[![Buy Me A Coffee](https://img.shields.io/badge/Donate-Buy_Me_A_Coffee-blue?logo=buymeacoffee)](https://www.buymeacoffee.com/ducmng12g)_
_[![PayPal](https://img.shields.io/badge/Donate-PayPal-blue?logo=paypal)](https://paypal.me/ngmduc)_
_[![Sponsor](https://img.shields.io/badge/Sponsor-Become_A_Sponsor-blue?logo=githubsponsors)](https://github.com/sponsors/ngmduc2012)_
_[![Support Me on Ko-fi](https://img.shields.io/badge/Donate-Ko_fi-red?logo=ko-fi)](https://ko-fi.com/I2I81AEJG8)_


# Bluetooth Connection Plugin for Flutter
A Flutter plugin for connecting and transferring data to other devices using Bluetooth. This package simplifies Bluetooth communication by providing an easy-to-use API for scanning, connecting, and exchanging 


## Features
- Scan for nearby Bluetooth Device
- Connect to bluetooth device
- Send and receive data
- Customizable connection and transfer


|                                 |       Android       |        iOS         | Description                        |
|:--------------------------------|:-------------------:|:------------------:|:-----------------------------------|
| turnOn()                        | :white_check_mark:  |                    | Turn on Bluetooth                  |
| adapterState                    | :white_check_mark:  | :white_check_mark: | Get the status of adapter          |
| bondedDevices                   | :white_check_mark:  |                    | Get Bonded device                  |
| discoveryState                  | :white_check_mark:  | :white_check_mark: |                                    |
| startScan()                     | :white_check_mark:  | :white_check_mark: | Start scan nearby device           |
| stopScan()                      | :white_check_mark:  |                    | Stop scan while device is scanning |
| lastScanResults                 | :white_check_mark:  |                    |                                    |
| scanResults                     | :white_check_mark:  |                    |                                    |
| connectionState                 | :white_check_mark:  | :white_check_mark: | Device connection status           |
| sendingState                    | :white_check_mark:  | :white_check_mark: |                                    |
| connect() (auto connect in IOS) | :white_check_mark:  | :white_check_mark: |                                    |
| disconnect()                    | :white_check_mark:  | :white_check_mark: |                                    |
| send data                       | :white_check_mark:  | :white_check_mark: |                                    |

## Permission
In this plugin we use permissions: Bluetooth, Bluetooth scan, bluetooth connect, access_fine_location

## Usage
[Example](https://github.com/ngmduc2012/my_bluetooth/blob/master/example/lib/main.dart)

### To use this plugin: 
- Add the dependency to your [pubspec.yaml](https://github.com/ngmduc2012/my_bluetooth/blob/master/example/pubspec.yaml) file.

```` yaml 
dependencies:
    flutter:
        sdk: flutter
    my_bluetooth: ^lastest_version
```` 
- Then, run
```bash
flutter pub get
```

- Import the package
```dart
import 'package:my_bluetooth/my_bluetooth.dart';
```
### Set up for IOS
Due to ios security issue, name of printer must be added in the ios/Runner/Info.plist
```
<key>NSBluetoothAlwaysUsageDescription</key>
	<string>This app always needs Bluetooth to function</string>
	<key>NSBluetoothPeripheralUsageDescription</key>
	<string>This app needs Bluetooth Peripheral to function</string>
	<key>UISupportedExternalAccessoryProtocols</key>
	<array>
		<string>net.dsgl.nailpopPro.protocol</string>
		//use your protocol instead
	</array>
	<key>UIBackgroundModes</key>
	<array>
		<string>bluetooth-central</string>
		<string>external-accessory</string>
		<string>fetch</string>
		<string>remote-notification</string>
	</array>
```
### Scan for Device:
```dart
final _myBluetooth = MyBluetooth();
// The scan function can filter to scan only devices with a given name.
void scan() async{
  await _myBluetooth.startScan(
      withKeywords: [
//     "name bluetooth"
      ]);

}
```
- How to get list device?
Use StreamSubscription to get list device return from function scan()
```dart
 late StreamSubscription<List<BluetoothDevice>> _scanResultsSubscription;
  List<BluetoothDevice> _scanResults = [];
  
  @override
  void initState() {
    super.initState();
    _scanResultsSubscription = _myBluetooth.scanResults.listen((results) {
      _scanResults = results;
      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {});
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    super.dispose();
  }
```
### Connect and disconnect
```dart
await _myBluetooth.connect(remoteId:  _scanResults.first.remoteId);
await _myBluetooth.disconnect();
```
### State
```dart
//  Bluetooth state:
MPBluetoothAdapterState _adapterState = MPBluetoothAdapterState.unknown;
// Connection state
MPConnectionStateEnum _connectState = MPConnectionStateEnum.disconnected;
``` 
### Send data
Use function sendCmd ``` Future<bool> sendCmd(List<int> byte, {int size = 34})``` to send data as bytes
example:
```dart
static const List<int> data = [0x1B, 0x2A, 0x44, 0x53];
_myBluetooth.sendCmd(data);
```
Besides, we have made some functions to send text and image data for convenience.
```dart
await _myBluetooth.sendText(value: "Hello World");
await _myBluetooth.sendFile(pathImage: image?.path)
```
## Contribute
Many thanks to the contribution on the plugin with [ThaoDoan](https://github.com/mia140602) and [DucNguyen](https://github.com/ngmduc2012)