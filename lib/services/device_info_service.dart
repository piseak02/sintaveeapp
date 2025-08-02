// lib/services/device_info_service.dart

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  static Future<String?> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo =
            await _deviceInfoPlugin.androidInfo;
        return androidInfo.id; // ใช้ androidId สำหรับ Android
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
        return iosInfo
            .identifierForVendor; // ใช้ identifierForVendor สำหรับ iOS
      }
    } on PlatformException {
      // ไม่สามารถดึงข้อมูลได้
      return null;
    }
    return null;
  }
}
