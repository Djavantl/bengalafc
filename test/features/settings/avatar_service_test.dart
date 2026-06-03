import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bengalafc/features/settings/services/avatar_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AvatarService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('should save and retrieve local avatar', () async {
      const userId = 'user_123';
      const base64Image = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...';

      // Verify initially null
      final initial = await AvatarService.getLocalAvatar(userId);
      expect(initial, isNull);

      // Save
      await AvatarService.saveLocalAvatar(userId, base64Image);

      // Retrieve
      final retrieved = await AvatarService.getLocalAvatar(userId);
      expect(retrieved, base64Image);
    });

    test('should clear local avatar', () async {
      const userId = 'user_123';
      const base64Image = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...';

      await AvatarService.saveLocalAvatar(userId, base64Image);
      
      // Clear
      await AvatarService.clearLocalAvatar(userId);

      final retrieved = await AvatarService.getLocalAvatar(userId);
      expect(retrieved, isNull);
    });
  });
}
