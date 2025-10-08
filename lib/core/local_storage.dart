import 'package:shared_preferences/shared_preferences.dart';

final LocalStore localStore = LocalStore();

class LocalStore {
  late SharedPreferences prefs;

  init() async {
    prefs = await SharedPreferences.getInstance();
  }

  setValue(String key, value) async {
    await prefs.setString(key, value);
  }

  String? get(String key) {
    return prefs.getString(key);
  }

  setBool(String key, bool value) async {
    await prefs.setBool(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return prefs.getBool(key) ?? defaultValue;
  }
}
