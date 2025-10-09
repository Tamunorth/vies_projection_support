import 'package:device_info_plus/device_info_plus.dart';
import 'package:lukehog/lukehog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class Analytics {
  static Analytics? _instance;
  late Lukehog _lukehog;
  static const String _userIdKey = 'anonymous_user_id';
  String? _currentUserId;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  /// Stored device properties to avoid repeated lookups.
  Map<String, dynamic>? _deviceProperties;

  // Private constructor
  Analytics._();

  // Singleton instance
  static Analytics get instance {
    _instance ??= Analytics._();
    return _instance!;
  }

  /// Initializes the Analytics service.
  ///
  /// Must be called once before any other methods are used. Fetches and
  /// stores device information for the session.
  Future<void> initialize(
    String appId, {
    Duration sessionExpiration = const Duration(minutes: 15),
    String baseUrl = 'https://api.lukehog.com',
    LukehogServerType serverType = LukehogServerType.lukehog,
    bool debug = false,
  }) async {
    _lukehog = Lukehog(
      appId,
      sessionExpiration: sessionExpiration,
      baseUrl: baseUrl,
      serverType: serverType,
      debug: debug,
    );
    await _initializeAnonymousUser();
    // Fetch and store device info once upon initialization.
    _deviceProperties = await _getDeviceInfo();
  }

  /// Generates and persists an anonymous user ID.
  Future<void> _initializeAnonymousUser() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString(_userIdKey);

    if (_currentUserId == null) {
      _currentUserId = const Uuid().v4();
      await prefs.setString(_userIdKey, _currentUserId!);
    }

    _lukehog.setUserId(_currentUserId);
  }

  /// Gathers basic device information for Windows.
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final Map<String, dynamic> deviceData = <String, dynamic>{};
    try {
      final info = await _deviceInfoPlugin.windowsInfo;
      deviceData.addAll({
        'computer_name': info.computerName,
        'number_of_cores': info.numberOfCores,
        'system_memory_in_mb': info.systemMemoryInMegabytes,
        'product_name': info.productName,
      });
    } catch (e) {
      deviceData['device_info_error'] = e.toString();
    }
    return deviceData;
  }

  /// A private helper to capture events with common properties.
  Future<void> _capture(
    String eventName, {
    Map<String, dynamic> properties = const {},
    DateTime? timestamp,
  }) async {
    final allProperties = {
      // Use the stored device properties.
      ...?_deviceProperties,
      ...properties,
    };

    await _lukehog.capture(
      eventName,
      properties: allProperties,
      timestamp: timestamp,
    );
  }

  /// Tracks a simple event with a given name.
  Future<void> trackEvent(String eventName) async {
    await _capture(eventName);
  }

  /// Tracks an event with additional custom properties.
  Future<void> trackEventWithProperties(
    String eventName,
    Map<String, dynamic> properties,
  ) async {
    await _capture(eventName, properties: properties);
  }

  /// Tracks a screen view as a 'screen_view' event.
  Future<void> trackScreen(String screenName) async {
    await _capture(
      'screen_view',
      properties: {'screen_name': screenName},
    );
  }

  /// Gets the current user ID.
  String? get userId => _currentUserId;

  /// Resets the current user and generates a new anonymous one.
  Future<void> reset() async {
    _lukehog.setUserId(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);

    await _initializeAnonymousUser();
  }

  /// Sets a custom user ID, replacing the anonymous one.
  Future<void> setCustomUserId(String userId) async {
    _currentUserId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    _lukehog.setUserId(userId);
  }
}
