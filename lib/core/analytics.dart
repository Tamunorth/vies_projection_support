import 'package:lukehog/lukehog.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Analytics {
  static Analytics? _instance;
  late Lukehog _lukehog;
  static const String _userIdKey = 'anonymous_user_id';
  String? _currentUserId;

  // Private constructor
  Analytics._();

  // Singleton instance
  static Analytics get instance {
    _instance ??= Analytics._();
    return _instance!;
  }

  // Initialize analytics with API key
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
  }

  // Generate and persist anonymous user ID
  Future<void> _initializeAnonymousUser() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString(_userIdKey);

    // Generate new ID if doesn't exist
    if (_currentUserId == null) {
      _currentUserId = const Uuid().v4();
      await prefs.setString(_userIdKey, _currentUserId!);
    }

    // Set user ID with LukeHog
    _lukehog.setUserId(_currentUserId);
  }

  // Track a simple event
  Future<void> trackEvent(String eventName) async {
    await _lukehog.capture(eventName, properties: {
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': _currentUserId,
    });
  }

  // Track event with properties
  Future<void> trackEventWithProperties(
    String eventName,
    Map<String, dynamic> properties,
  ) async {
    await _lukehog.capture(eventName, properties: {
      ...properties,
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': _currentUserId,
    });
  }

  // Track event with custom timestamp
  Future<void> trackEventWithTimestamp(
    String eventName,
    DateTime timestamp, {
    Map<String, dynamic> properties = const {},
  }) async {
    await _lukehog.capture(
      eventName,
      properties: properties,
      timestamp: timestamp,
    );
  }

  // Track screen views (as regular events)
  Future<void> trackScreen(String screenName) async {
    await _lukehog.capture(
      'screen_view',
      properties: {'screen_name': screenName},
    );
  }

  // Get current user ID
  String? get userId => _currentUserId;

  // Reset user (generates new anonymous ID)
  Future<void> reset() async {
    // Clear user ID in LukeHog (generates new anonymous ID)
    _lukehog.setUserId(null);

    // Remove stored ID
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);

    // Generate and set new ID
    await _initializeAnonymousUser();
  }

  // Advanced: Set custom user ID (if you want to switch from anonymous)
  Future<void> setCustomUserId(String userId) async {
    _currentUserId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    _lukehog.setUserId(userId);
  }
}
