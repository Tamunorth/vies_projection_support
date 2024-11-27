import 'package:flutter/services.dart';

class BlockInput {
  static const MethodChannel _channel =
      MethodChannel('com.example.untitled/inputBlocker');

  // Get battery level.
  String _batteryLevel = 'Unknown battery level.';

  static Future<void> downKey() async {
    try {
      await _channel.invokeMethod('downKey');

      print("Success to unblock input:");
    } catch (e) {
      print("Failed to unblock input: '${e.toString()}'.");
    }
  }
}
