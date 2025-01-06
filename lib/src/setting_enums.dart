part of '../my_bluetooth.dart';

enum ZPAutoExposureEnum {
  on(code: 1, byte: 0x01),
  off(code: 0, byte: 0x00);

  const ZPAutoExposureEnum({required this.code, required this.byte});

  final int code;
  final int byte;

  static ZPAutoExposureEnum? findByCode(int? code) {
    if (code == null) return null;
    try {
      return ZPAutoExposureEnum.values.where((e) => e.code == code).first;
    } catch (e) {
      return null;
    }
  }
}

enum ZPAutoPowerOffEnum {
  off(code: 0, byte: 0x00, minute: 0), //(Always On)
  min3(code: 1, byte: 0x04, minute: 3),
  min5(code: 2, byte: 0x08, minute: 5),
  min10(code: 3, byte: 0x0c, minute: 10);

  const ZPAutoPowerOffEnum(
      {required this.code, required this.byte, required this.minute});

  final int code;
  final int byte;
  final int minute;

  static ZPAutoPowerOffEnum? findByCode(int? code) {
    if (code == null) return null;
    try {
      return ZPAutoPowerOffEnum.values.where((e) => e.code == code).first;
    } catch (e) {
      return null;
    }
  }
}

enum ZPPrintModeSetInfoEnum {
  paperFull(code: 0, byte: 0x01),
  imageFull(code: 1, byte: 0x02);

  const ZPPrintModeSetInfoEnum({required this.code, required this.byte});

  final int code;
  final int byte;

  static ZPAutoPowerOffEnum? findByCode(int code) {
    try {
      return ZPAutoPowerOffEnum.values.where((e) => e.code == code).first;
    } catch (e) {
      return null;
    }
  }
}

enum ZPDataClassificationEnum {
  image(code: 0, byte: 0x00),
  tmd(code: 1, byte: 0x01),
  firmware(code: 2, byte: 0x02),
  colorTable(code: 3, byte: 0x03);

  const ZPDataClassificationEnum({required this.code, required this.byte});

  final int code;
  final int byte;

  static ZPDataClassificationEnum? findByCode(int? code) {
    if (code == null) return null;
    try {
      return ZPDataClassificationEnum.values.where((e) => e.code == code).first;
    } catch (e) {
      return null;
    }
  }
}

enum ZPSkipEdgeEnhancementEnum {
  eEFromApp(code: 0, byte: 0x00),
  eEFromPrinter(code: 1, byte: 0x01);

  const ZPSkipEdgeEnhancementEnum({required this.code, required this.byte});

  final int code;
  final int byte;

  static ZPSkipEdgeEnhancementEnum? findByCode(int code) {
    try {
      return ZPSkipEdgeEnhancementEnum.values
          .where((e) => e.code == code)
          .first;
    } catch (e) {
      return null;
    }
  }
}
