import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BlockInput {
  static const MethodChannel _channel =
      MethodChannel('com.example.untitled/inputBlocker');

  // Get battery level.
  String _batteryLevel = 'Unknown battery level.';

  static Future<void> downKey() async {
    try {
      await _channel.invokeMethod('downKey');
    } catch (e) {
      if (kDebugMode) log("Failed to unblock input: '${e.toString()}'.");
    }
  }
}
