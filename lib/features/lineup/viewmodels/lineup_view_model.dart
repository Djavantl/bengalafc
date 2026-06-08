import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../core/services/api_client.dart';
import '../data/lineup_local_storage.dart';
import '../models/lineup_player_model.dart';

class LineupSlot {
  const LineupSlot({
    required this.id,
    required this.position,
    required this.label,
    required this.row,
    required this.column,
    required this.lineSize,
    this.player,
  });

  final String id;
  final String position;
  final String label;
  final int row;
  final int column;
  final int lineSize;
  final LineupPlayerModel? player;

  LineupSlot copyWith({LineupPlayerModel? player, bool clearPlayer = false}) {
    return LineupSlot(
      id: id,
      position: position,
      label: label,
      row: row,
      column: column,
      lineSize: lineSize,
      player: clearPlayer ? null : player ?? this.player,
    );
  }
}

class LineupViewModel extends ChangeNotifier {
  static const formationOptions = ['4-3-3', '4-4-2', '3-5-2'];

  final LineupLocalStorage _storage;

  String teamName = 'Bengala Stars';
  String selectedFormation = '4-3-3';
  String roundName = 'Rodada 1 - Fase de grupos';
  String marketStatus = 'Mercado aberto';
  String? captainPlayerId;
  bool isSaved = false;

  bool isLoading = false;
  String? errorMessage;
  int? activeStageId;
  int? lineupId;

  late List<LineupSlot> _slots;
  late List<LineupPlayerModel> _availablePlayers;

  LineupViewModel({LineupLocalStorage? storage})
      : _storage = storage ?? LineupLocalStorage() {
    _loadMockLineup();
    _loadSavedLineup();
    loadData();
  }

  List<LineupSlot> get slots => List.unmodifiable(_slots);

  List<LineupPlayerModel> get availablePlayers =>
      List.unmodifiable(_availablePlayers);

  List<LineupPlayerModel> get selectedPlayers => _slots
      .where((slot) => slot.player != null)
      .map((slot) => slot.player!)
      .toList(growable: false);

  int get selectedCount => selectedPlayers.length;

  int get totalSlots => _slots.length;

  bool get isComplete => selectedCount == totalSlots;

  String? get captainName {
    for (final player in selectedPlayers) {
      if (player.id == captainPlayerId) return player.name;
    }
    return null;
  }

  LineupSlot? slotById(String slotId) {
    for (final slot in _slots) {
      if (slot.id == slotId) return slot;
    }
    return null;
  }

  String _mapBackendPosition(String? backendPos) {
    if (backendPos == null) return 'ZAG';
    final pos = backendPos.toLowerCase();
    if (pos.contains('goalkeeper') || pos == 'goleiro') {
      return 'GOL';
    } else if (pos.contains('midfielder') || pos == 'meia') {
      return 'MEI';
    } else if (pos.contains('attacker') || pos.contains('forward') || pos == 'atacante') {
      return 'ATA';
    } else {
      return 'ZAG';
    }
  }

  bool _isPositionCompatible(String playerPos, String slotPos) {
    if (playerPos == slotPos) return true;
    if ((playerPos == 'ZAG' || playerPos == 'LD' || playerPos == 'LE') &&
        (slotPos == 'ZAG' || slotPos == 'LD' || slotPos == 'LE')) {
      return true;
    }
    return false;
  }

  String _deduceFormation(List<LineupPlayerModel> players) {
    int defenders = 0;
    int midfielders = 0;
    int attackers = 0;
    for (final p in players) {
      final pos = p.position;
      if (pos == 'ZAG' || pos == 'LD' || pos == 'LE') {
        defenders++;
      } else if (pos == 'MEI') {
        midfielders++;
      } else if (pos == 'ATA') {
        attackers++;
      }
    }
    final candidate = '$defenders-$midfielders-$attackers';
    if (formationOptions.contains(candidate)) {
      return candidate;
    }
    return '4-3-3';
  }

  Future<void> loadData() async {
    if (!ApiClient.instance.isAuthenticated) {
      debugPrint('User is not authenticated. Skipping API load.');
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await loadAvailablePlayers();
      await loadLineup();
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('Error loading API data: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAvailablePlayers() async {
    try {
      final response = await ApiClient.instance.get('/api/players/');
      final List<dynamic> playersJson = jsonDecode(response.body);

      _availablePlayers = playersJson.map((data) {
        final id = data['id']?.toString() ?? '';
        final name = data['name']?.toString() ?? '';
        final nationalTeam = (data['team_detail']?['code'] ?? data['team_detail']?['name'] ?? data['nationality'] ?? 'BRA').toString().toUpperCase();
        final position = _mapBackendPosition(data['position']?.toString());
        const averagePoints = 0.0;
        const selectedPercentage = 0.0;
        final photoUrl = data['photo']?.toString();

        return LineupPlayerModel(
          id: id,
          name: name,
          nationalTeam: nationalTeam,
          position: position,
          averagePoints: averagePoints,
          selectedPercentage: selectedPercentage,
          isStarter: false,
          photoUrl: photoUrl,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading available players: $e');
      rethrow;
    }
  }

  Future<void> loadLineup() async {
    try {
      final stagesResponse = await ApiClient.instance.get('/api/stages/');
      final List<dynamic> stagesJson = jsonDecode(stagesResponse.body);
      
      int stageId = 3;
      if (stagesJson.isNotEmpty) {
        stageId = stagesJson[0]['id'] as int;
      }
      activeStageId = stageId;

      try {
        final lineupResponse = await ApiClient.instance.get('/api/lineups/by-stage/$activeStageId/');
        final Map<String, dynamic> lineupJson = jsonDecode(lineupResponse.body);
        
        lineupId = lineupJson['id'] as int?;
        final List<dynamic> players = lineupJson['players'] ?? [];
        final captainIdVal = lineupJson['captain']?.toString();

        final List<LineupPlayerModel> loadedPlayers = [];
        for (final p in players) {
          final detail = p['player_detail'];
          if (detail != null) {
            final id = detail['id']?.toString() ?? '';
            final name = detail['name']?.toString() ?? '';
            final nationalTeam = (detail['team_detail']?['code'] ?? detail['team_detail']?['name'] ?? detail['nationality'] ?? 'BRA').toString().toUpperCase();
            final position = _mapBackendPosition(detail['position']?.toString());
            final photoUrl = detail['photo']?.toString();

            loadedPlayers.add(
              LineupPlayerModel(
                id: id,
                name: name,
                nationalTeam: nationalTeam,
                position: position,
                averagePoints: 0.0,
                selectedPercentage: 0.0,
                isStarter: true,
                photoUrl: photoUrl,
              )
            );
          }
        }

        if (loadedPlayers.isNotEmpty) {
          selectedFormation = _deduceFormation(loadedPlayers);
          _slots = _buildSlotsForFormation(selectedFormation);

          for (final player in loadedPlayers) {
            final slotIndex = _slots.indexWhere((slot) => slot.player == null && _isPositionCompatible(player.position, slot.position));
            if (slotIndex != -1) {
              _slots[slotIndex] = _slots[slotIndex].copyWith(player: player);
            }
          }

          captainPlayerId = captainIdVal;
          isSaved = isComplete;
        }
      } on ApiException catch (e) {
        if (e.statusCode == 404) {
          lineupId = null;
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('Error loading lineup: $e');
      rethrow;
    }
  }

  List<LineupPlayerModel> optionsForSlot(LineupSlot slot) {
    return _availablePlayers
        .where((player) => _isPositionCompatible(player.position, slot.position))
        .where(
          (player) =>
              player.id == slot.player?.id ||
              !_slots.any((selectedSlot) => selectedSlot.player?.id == player.id),
        )
        .toList(growable: false)
      ..sort((a, b) => b.averagePoints.compareTo(a.averagePoints));
  }

  void selectPlayer(String slotId, LineupPlayerModel player) {
    final index = _slots.indexWhere((slot) => slot.id == slotId);
    if (index == -1) return;

    final slot = _slots[index];
    if (!_isPositionCompatible(player.position, slot.position)) return;

    final repeatedPlayerIndex = _slots.indexWhere(
      (otherSlot) => otherSlot.id != slotId && otherSlot.player?.id == player.id,
    );
    if (repeatedPlayerIndex != -1) return;

    _slots[index] = slot.copyWith(player: player.copyWith(isStarter: true));
    captainPlayerId ??= player.id;
    isSaved = false;
    notifyListeners();
  }

  void clearSlot(String slotId) {
    final index = _slots.indexWhere((slot) => slot.id == slotId);
    if (index == -1) return;

    final removedPlayerId = _slots[index].player?.id;
    _slots[index] = _slots[index].copyWith(clearPlayer: true);
    if (captainPlayerId == removedPlayerId) {
      captainPlayerId =
          selectedPlayers.isEmpty ? null : selectedPlayers.first.id;
    }
    isSaved = false;
    notifyListeners();
  }

  void setCaptain(String playerId) {
    if (!selectedPlayers.any((player) => player.id == playerId)) return;

    captainPlayerId = playerId;
    isSaved = false;
    notifyListeners();
  }

  void changeFormation(String formation) {
    if (!formationOptions.contains(formation)) return;

    selectedFormation = formation;
    _slots = _buildSlotsForFormation(
      formation,
      previousSlots: _slots,
    );
    if (!selectedPlayers.any((player) => player.id == captainPlayerId)) {
      captainPlayerId =
          selectedPlayers.isEmpty ? null : selectedPlayers.first.id;
    }
    isSaved = false;
    notifyListeners();
  }

  Future<void> saveLineup() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final playerIds = selectedPlayers.map((p) => int.parse(p.id)).toList();
      final captainIdVal = captainPlayerId != null ? int.parse(captainPlayerId!) : null;

      if (activeStageId == null) {
        final stagesResponse = await ApiClient.instance.get('/api/stages/');
        final List<dynamic> stagesJson = jsonDecode(stagesResponse.body);
        if (stagesJson.isNotEmpty) {
          activeStageId = stagesJson[0]['id'] as int;
        } else {
          activeStageId = 3;
        }
      }

      final body = {
        'stage': activeStageId,
        'captain_id': captainIdVal,
        'player_ids': playerIds,
      };

      if (lineupId == null) {
        final response = await ApiClient.instance.post('/api/lineups/', body);
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        lineupId = responseJson['id'] as int?;
      } else {
        await ApiClient.instance.patch('/api/lineups/$lineupId/', body);
      }

      // Also save to local storage as fallback
      await _storage.saveLineup(
        teamName: teamName,
        formation: selectedFormation,
        selectedCount: selectedCount,
        captainName: captainName,
        captainPlayerId: captainPlayerId,
        selectedPlayerIdsBySlot: {
          for (final slot in _slots)
            if (slot.player != null) slot.id: slot.player!.id,
        },
      );

      isSaved = true;
    } catch (e) {
      errorMessage = e.toString();
      isSaved = false;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSavedLineup() async {
    final savedLineup = await _storage.loadLineup();
    if (!savedLineup.isMounted) return;

    teamName = savedLineup.teamName;
    selectedFormation = formationOptions.contains(savedLineup.formation)
        ? savedLineup.formation
        : selectedFormation;
    _slots = _buildSlotsForFormation(selectedFormation);

    for (var index = 0; index < _slots.length; index++) {
      final slot = _slots[index];
      final playerId = savedLineup.selectedPlayerIdsBySlot[slot.id];
      if (playerId == null) continue;

      final player = _playerById(playerId);
      if (player == null || !_isPositionCompatible(player.position, slot.position)) continue;

      _slots[index] = slot.copyWith(player: player.copyWith(isStarter: true));
    }

    captainPlayerId = selectedPlayers.any(
      (player) => player.id == savedLineup.captainPlayerId,
    )
        ? savedLineup.captainPlayerId
        : selectedPlayers.isEmpty
            ? null
            : selectedPlayers.first.id;
    isSaved = isComplete;
    notifyListeners();
  }

  LineupPlayerModel? _playerById(String id) {
    for (final player in _availablePlayers) {
      if (player.id == id) return player;
    }
    return null;
  }

  void _loadMockLineup() {
    _slots = _buildSlotsForFormation(selectedFormation);

    _availablePlayers = const [
      LineupPlayerModel(
        id: 'emi-martinez',
        name: 'E. Martinez',
        nationalTeam: 'ARG',
        position: 'GOL',
        averagePoints: 6.8,
        selectedPercentage: 31,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'alisson',
        name: 'Alisson',
        nationalTeam: 'BRA',
        position: 'GOL',
        averagePoints: 6.4,
        selectedPercentage: 24,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'hakimi',
        name: 'Hakimi',
        nationalTeam: 'MAR',
        position: 'LD',
        averagePoints: 5.9,
        selectedPercentage: 21,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'cancelo',
        name: 'Cancelo',
        nationalTeam: 'POR',
        position: 'LD',
        averagePoints: 5.3,
        selectedPercentage: 16,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'van-dijk',
        name: 'Van Dijk',
        nationalTeam: 'HOL',
        position: 'ZAG',
        averagePoints: 5.7,
        selectedPercentage: 18,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'marquinhos',
        name: 'Marquinhos',
        nationalTeam: 'BRA',
        position: 'ZAG',
        averagePoints: 5.4,
        selectedPercentage: 26,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'theo',
        name: 'Theo Hernandez',
        nationalTeam: 'FRA',
        position: 'LE',
        averagePoints: 5.5,
        selectedPercentage: 19,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'nuno-mendes',
        name: 'Nuno Mendes',
        nationalTeam: 'POR',
        position: 'LE',
        averagePoints: 5.2,
        selectedPercentage: 15,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'gvardiol',
        name: 'Gvardiol',
        nationalTeam: 'CRO',
        position: 'ZAG',
        averagePoints: 5.1,
        selectedPercentage: 14,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'bellingham',
        name: 'Bellingham',
        nationalTeam: 'ING',
        position: 'MEI',
        averagePoints: 7.2,
        selectedPercentage: 39,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'de-bruyne',
        name: 'De Bruyne',
        nationalTeam: 'BEL',
        position: 'MEI',
        averagePoints: 6.9,
        selectedPercentage: 28,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'valverde',
        name: 'Valverde',
        nationalTeam: 'URU',
        position: 'MEI',
        averagePoints: 5.8,
        selectedPercentage: 17,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'musiala',
        name: 'Musiala',
        nationalTeam: 'ALE',
        position: 'MEI',
        averagePoints: 6.5,
        selectedPercentage: 22,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'rodri',
        name: 'Rodri',
        nationalTeam: 'ESP',
        position: 'MEI',
        averagePoints: 5.6,
        selectedPercentage: 16,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'mbappe',
        name: 'Mbappe',
        nationalTeam: 'FRA',
        position: 'ATA',
        averagePoints: 8.1,
        selectedPercentage: 52,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'vinicius',
        name: 'Vini Jr',
        nationalTeam: 'BRA',
        position: 'ATA',
        averagePoints: 7.8,
        selectedPercentage: 48,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'haaland',
        name: 'Haaland',
        nationalTeam: 'NOR',
        position: 'ATA',
        averagePoints: 7.4,
        selectedPercentage: 34,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'lautaro',
        name: 'Lautaro',
        nationalTeam: 'ARG',
        position: 'ATA',
        averagePoints: 6.2,
        selectedPercentage: 23,
        isStarter: false,
      ),
      LineupPlayerModel(
        id: 'son',
        name: 'Son',
        nationalTeam: 'COR',
        position: 'ATA',
        averagePoints: 6.1,
        selectedPercentage: 20,
        isStarter: false,
      ),
    ];

    captainPlayerId = null;
  }

  List<LineupSlot> _buildSlotsForFormation(
    String formation, {
    List<LineupSlot> previousSlots = const [],
  }) {
    final parts = formation.split('-').map(int.parse).toList(growable: false);

    return [
      _buildSlot(
        line: const _FormationLine(
          position: 'GOL',
          label: 'GOL',
          row: 0,
          count: 1,
        ),
        column: 0,
        previousSlots: previousSlots,
      ),
      ..._buildDefensiveSlots(
        count: parts[0],
        previousSlots: previousSlots,
      ),
      for (var column = 0; column < parts[1]; column++)
        _buildSlot(
          line: _FormationLine(
            position: 'MEI',
            label: 'MEI',
            row: 2,
            count: parts[1],
          ),
          column: column,
          previousSlots: previousSlots,
        ),
      for (var column = 0; column < parts[2]; column++)
        _buildSlot(
          line: _FormationLine(
            position: 'ATA',
            label: 'ATA',
            row: 3,
            count: parts[2],
          ),
          column: column,
          previousSlots: previousSlots,
        ),
    ];
  }

  List<LineupSlot> _buildDefensiveSlots({
    required int count,
    required List<LineupSlot> previousSlots,
  }) {
    final positions = count == 4
        ? const ['LD', 'ZAG', 'ZAG', 'LE']
        : List<String>.filled(count, 'ZAG');
    final positionCounts = <String, int>{};

    return [
      for (var column = 0; column < positions.length; column++)
        _buildSlot(
          line: _FormationLine(
            position: positions[column],
            label: positions[column],
            row: 1,
            count: positions.length,
          ),
          column: column,
          idNumber: positionCounts.update(
            positions[column],
            (count) => count + 1,
            ifAbsent: () => 1,
          ),
          previousSlots: previousSlots,
        ),
    ];
  }

  LineupSlot _buildSlot({
    required _FormationLine line,
    required int column,
    required List<LineupSlot> previousSlots,
    int? idNumber,
  }) {
    final id = '${line.position.toLowerCase()}-${idNumber ?? column + 1}';
    LineupSlot? previousSlot;

    for (final slot in previousSlots) {
      if (slot.id == id && slot.position == line.position) {
        previousSlot = slot;
        break;
      }
    }

    return LineupSlot(
      id: id,
      position: line.position,
      label: line.label,
      row: line.row,
      column: column,
      lineSize: line.count,
      player: previousSlot?.player,
    );
  }
}

class _FormationLine {
  const _FormationLine({
    required this.position,
    required this.label,
    required this.row,
    required this.count,
  });

  final String position;
  final String label;
  final int row;
  final int count;
}
