import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A utility class to enter to down key reliably on keyboards with or without the number pad
///
class ViesBlockInput {
  static const MethodChannel _channel =
      MethodChannel('com.example.untitled/inputBlocker');

  static Future<void> downKey() async {
    try {
      await _channel.invokeMethod('downKey');
    } catch (e) {
      if (kDebugMode) log("Failed to unblock input: '${e.toString()}'.");
    }
  }
}
