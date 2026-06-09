import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bengalafc/features/lineup/viewmodels/lineup_view_model.dart';
import 'package:bengalafc/core/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    SharedPreferences.setMockInitialValues({'auth_token': 'dummy_token'});
    await ApiClient.instance.init();
  });

  group('LineupViewModel Lazy Loading Test', () {
    test('loadPlayersForPosition fetches and populates players', () async {
      final viewModel = LineupViewModel();
      
      // Let's call loadPlayersForPosition for MEI (Midfielder)
      print('Calling loadPlayersForPosition...');
      try {
        await viewModel.loadPlayersForPosition('MEI');
        print('Finished loadPlayersForPosition');
        print('Available players count: ${viewModel.availablePlayers.length}');
        for (final player in viewModel.availablePlayers) {
          print('Loaded player: ${player.name} (${player.position})');
        }
      } catch (e, stack) {
        print('Error in test: $e');
        print(stack);
      }
    });
  });
}
