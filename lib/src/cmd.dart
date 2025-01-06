part of '../my_bluetooth.dart';

class Cmd {
  static const List<int> base = [0x1B, 0x2A, 0x44, 0x53];
  static const int app = 0x00;
  static const int printer = 0x01;
  static const List<int> baseApp = [
    ...base,
    app,
    0x00,
  ];
  static const List<int> basePrinter = [
    ...base,
    printer,
    0x00,
  ];

  /// WRITE

  // GetInfo of Accessory -> AccessoryInfoACK
  static const List<int> getInfoOfAccessory = [...baseApp, 0x01, 0x00];
  static const List<int> setInfoOfAccessory = [...baseApp, 0x01, 0x01];
  static const List<int> upgradeReady = [...baseApp, 0x03, 0x00];
  static const List<int> upgradeCancel = [...baseApp, 0x03, 0x01];
  static const List<int> bulkTransfer = [...baseApp, 0x05, 0x00];
  static const List<int> getBTName = [...baseApp, 0x06, 0x00];
  static const List<int> setBTName = [...baseApp, 0x06, 0x01];
  // Print Ready -> StartOfSendAck with JobID
  static const List<int> printReady = [...baseApp, 0x07, 0x00];
  static const List<int> getJobList = [...baseApp, 0x08, 0x00];
  static const List<int> clearJob = [...baseApp, 0x08, 0x04];

  /// READ
  static const List<int> accessoryInfoACK = [...basePrinter, 0x01, 0x02];
  static const List<int> startOfSendAck = [...basePrinter, 0x02, 0x00];
  static const List<int> endOfReceiveAck = [...basePrinter, 0x02, 0x01];
  static const List<int> startOfSendAckWithJobID = [...basePrinter, 0x02, 0x03];
  static const List<int> endOfReceiveAckWithJobID = [
    ...basePrinter,
    0x02,
    0x04
  ];
  static const List<int> upgradeAck = [...basePrinter, 0x03, 0x02];
  static const List<int> errorMessageAck = [...basePrinter, 0x04, 0x00];
  static const List<int> errorMessageAckWithJobID = [
    ...basePrinter,
    0x04,
    0x01
  ];
  static const List<int> errorNoticeWithJobID = [...basePrinter, 0x04, 0x02];
  static const List<int> connectionFull = [...basePrinter, 0x04, 0x03];
  static const List<int> bTNameAck = [...basePrinter, 0x06, 0x02];
  static const List<int> printStart = [...basePrinter, 0x07, 0x02];
  static const List<int> printFinish = [...basePrinter, 0x07, 0x03];
  static const List<int> jobListAck = [...basePrinter, 0x08, 0x01];
  static const List<int> jobAdded = [...basePrinter, 0x08, 0x02];
  static const List<int> jobRemoved = [...basePrinter, 0x08, 0x03];
}
