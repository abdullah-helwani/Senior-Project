import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  // Singleton initialization
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Save string (e.g. token)
  static Future<bool> saveString(String key, String value) async {
    await init();
    return _prefs!.setString(key, value);
  }

  // Get string
  static Future<String?> getString(String key) async {
    await init();
    return _prefs!.getString(key);
  }

  // Remove key
  static Future<bool> remove(String key) async {
    await init();
    return _prefs!.remove(key);
  }

  // Clear all data (optional)
  static Future<bool> clearAll() async {
    await init();
    return _prefs!.clear();
  }
}


//! Examples of Using 
//? ex of save 
// await StorageService.saveString('auth_token', token);
//? ex of read or get
//final token = await StorageService.getString('auth_token');
//? ex of Removing 
//await StorageService.remove('auth_token');
