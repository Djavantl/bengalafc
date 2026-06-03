import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedLineup {
  const SavedLineup({
    required this.isMounted,
    required this.teamName,
    required this.formation,
    required this.captainPlayerId,
    required this.selectedPlayerIdsBySlot,
  });

  final bool isMounted;
  final String teamName;
  final String formation;
  final String? captainPlayerId;
  final Map<String, String> selectedPlayerIdsBySlot;
}

class LineupHomeSummary {
  const LineupHomeSummary({
    required this.isMounted,
    required this.teamName,
    required this.formation,
    required this.selectedCount,
    required this.captainName,
  });

  final bool isMounted;
  final String teamName;
  final String formation;
  final int selectedCount;
  final String? captainName;
}

class LineupLocalStorage {
  static const _isMountedKey = 'lineup_is_mounted';
  static const _teamNameKey = 'lineup_team_name';
  static const _formationKey = 'lineup_formation';
  static const _selectedCountKey = 'lineup_selected_count';
  static const _captainNameKey = 'lineup_captain_name';
  static const _captainPlayerIdKey = 'lineup_captain_player_id';
  static const _selectedPlayersBySlotKey = 'lineup_selected_players_by_slot';

  Future<LineupHomeSummary> loadSummary() async {
    final prefs = await SharedPreferences.getInstance();

    return LineupHomeSummary(
      isMounted: prefs.getBool(_isMountedKey) ?? false,
      teamName: prefs.getString(_teamNameKey) ?? 'Bengala Stars',
      formation: prefs.getString(_formationKey) ?? '4-3-3',
      selectedCount: prefs.getInt(_selectedCountKey) ?? 0,
      captainName: prefs.getString(_captainNameKey),
    );
  }

  Future<void> saveSummary({
    required String teamName,
    required String formation,
    required int selectedCount,
    required String? captainName,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_isMountedKey, true);
    await prefs.setString(_teamNameKey, teamName);
    await prefs.setString(_formationKey, formation);
    await prefs.setInt(_selectedCountKey, selectedCount);

    if (captainName == null) {
      await prefs.remove(_captainNameKey);
    } else {
      await prefs.setString(_captainNameKey, captainName);
    }
  }

  Future<SavedLineup> loadLineup() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedPlayers = prefs.getString(_selectedPlayersBySlotKey);
    final selectedPlayerIdsBySlot = <String, String>{};

    if (encodedPlayers != null && encodedPlayers.isNotEmpty) {
      try {
        final decoded = jsonDecode(encodedPlayers);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            final playerId = entry.value;
            if (playerId is String && playerId.isNotEmpty) {
              selectedPlayerIdsBySlot[entry.key] = playerId;
            }
          }
        }
      } catch (_) {}
    }

    return SavedLineup(
      isMounted: prefs.getBool(_isMountedKey) ?? false,
      teamName: prefs.getString(_teamNameKey) ?? 'Bengala Stars',
      formation: prefs.getString(_formationKey) ?? '4-3-3',
      captainPlayerId: prefs.getString(_captainPlayerIdKey),
      selectedPlayerIdsBySlot: selectedPlayerIdsBySlot,
    );
  }

  Future<void> saveLineup({
    required String teamName,
    required String formation,
    required int selectedCount,
    required String? captainName,
    required String? captainPlayerId,
    required Map<String, String> selectedPlayerIdsBySlot,
  }) async {
    await saveSummary(
      teamName: teamName,
      formation: formation,
      selectedCount: selectedCount,
      captainName: captainName,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _selectedPlayersBySlotKey,
      jsonEncode(selectedPlayerIdsBySlot),
    );

    if (captainPlayerId == null) {
      await prefs.remove(_captainPlayerIdKey);
    } else {
      await prefs.setString(_captainPlayerIdKey, captainPlayerId);
    }
  }
}
