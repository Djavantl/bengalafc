import 'package:shared_preferences/shared_preferences.dart';

class AvatarService {
  static const String _avatarKeyPrefix = 'user_avatar_base64_';

  static Future<String?> getLocalAvatar(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_avatarKeyPrefix$userId');
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveLocalAvatar(String userId, String base64Image) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_avatarKeyPrefix$userId', base64Image);
    } catch (_) {}
  }

  static Future<void> clearLocalAvatar(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_avatarKeyPrefix$userId');
    } catch (_) {}
  }
}
