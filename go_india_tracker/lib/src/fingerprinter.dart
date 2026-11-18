import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';

class Fingerprinter {
  static Future<String> getDeviceFingerprint() async {
    // 1. JS getTimezoneOffset() returns minutes west of UTC.
    final jsTimezoneOffset = -DateTime.now().timeZoneOffset.inMinutes;
    
    // 2. JS language base (e.g. 'en')
    final langBase = Platform.localeName.split('_')[0].split('-')[0];
    
    // 3. Platform
    final platform = Platform.isIOS ? 'iOS' : 'Android';
    
    // 4. Extra device metrics
    final deviceInfo = DeviceInfoPlugin();
    String deviceModel = 'unknown';
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceModel = androidInfo.model;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceModel = iosInfo.utsname.machine;
    }

    // Build raw fingerprint matching JS format: timezoneOffset | langBase | platform | model
    // Note: The JS side needs to match this exactly if we add deviceModel.
    // Since our backend JS only does: timezoneOffset | langBase | platform, we should stick to that to maintain compatibility!
    
    final rawString = '$jsTimezoneOffset|$langBase|$platform';
    final bytes = utf8.encode(rawString);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }
}
