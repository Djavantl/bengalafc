import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../core/services/api_client.dart';
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

  LineupViewModel() {
    _slots = _buildSlotsForFormation(selectedFormation);
    _availablePlayers = [];
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
    if (backendPos == null || backendPos.isEmpty) return 'ZAG';
    
    final parts = backendPos.split(',');
    final mapped = <String>{};
    
    for (final part in parts) {
      final pos = part.trim().toLowerCase();
      if (pos == 'gk' || pos.contains('goalkeeper') || pos == 'goleiro' || pos == 'gol') {
        mapped.add('GOL');
      } else if (pos == 'mf' || pos.contains('midfielder') || pos == 'meia' || pos == 'mei') {
        mapped.add('MEI');
      } else if (pos == 'fw' || pos.contains('attacker') || pos.contains('forward') || pos == 'atacante' || pos == 'ata') {
        mapped.add('ATA');
      } else if (pos == 'ld') {
        mapped.add('LD');
      } else if (pos == 'le') {
        mapped.add('LE');
      } else if (pos == 'df' || pos.contains('defender') || pos == 'zagueiro' || pos == 'lateral' || pos == 'zag') {
        mapped.add('ZAG');
      } else {
        mapped.add('ZAG');
      }
    }
    
    return mapped.join(',');
  }

  bool _isPositionCompatible(String playerPos, String slotPos) {
    final playerPositions = playerPos.split(',');
    for (final pPos in playerPositions) {
      if (pPos == slotPos) return true;
      if ((pPos == 'ZAG' || pPos == 'LD' || pPos == 'LE') &&
          (slotPos == 'ZAG' || slotPos == 'LD' || slotPos == 'LE')) {
        return true;
      }
    }
    return false;
  }

  String _deduceFormation(List<LineupPlayerModel> players) {
    int defenders = 0;
    int midfielders = 0;
    int attackers = 0;
    for (final p in players) {
      final pos = p.position;
      final parts = pos.split(',');
      if (parts.any((x) => x == 'ZAG' || x == 'LD' || x == 'LE')) {
        defenders++;
      } else if (parts.any((x) => x == 'MEI')) {
        midfielders++;
      } else if (parts.any((x) => x == 'ATA')) {
        attackers++;
      }
    }
    final candidate = '$defenders-$midfielders-$attackers';
    if (formationOptions.contains(candidate)) {
      return candidate;
    }
    return '4-3-3';
  }

  final Set<String> _loadedPositions = {};
  final Set<String> _loadingPositions = {};

  bool isPositionLoading(String slotPos) => _loadingPositions.contains(slotPos);

  String _mapSlotPosToApiPos(String slotPos) {
    switch (slotPos) {
      case 'GOL':
        return 'GK';
      case 'ZAG':
      case 'LD':
      case 'LE':
        return 'DF';
      case 'MEI':
        return 'MF';
      case 'ATA':
        return 'FW';
      default:
        return 'DF';
    }
  }

  Future<void> loadPlayersForPosition(String slotPos) async {
    if (activeStageId == null) {
      errorMessage = 'Nenhuma rodada atual cadastrada no servidor.';
      notifyListeners();
      return;
    }

    if (_loadedPositions.contains(slotPos) || _loadingPositions.contains(slotPos)) {
      return;
    }

    _loadingPositions.add(slotPos);
    notifyListeners();

    try {
      final apiPos = _mapSlotPosToApiPos(slotPos);
      final urlPath = '/api/players/?position=$apiPos&stage=$activeStageId';
      final response = await ApiClient.instance.get(urlPath);
      
      final List<dynamic> playersJson = jsonDecode(response.body);

      final List<LineupPlayerModel> loadedList = playersJson.map<LineupPlayerModel>((data) {
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

      final existingIds = _availablePlayers.map((p) => p.id).toSet();
      for (final p in loadedList) {
        if (!existingIds.contains(p.id)) {
          _availablePlayers.add(p);
        }
      }

      _loadedPositions.add(slotPos);
    } catch (e, stack) {
      debugPrint('Error loading players for position $slotPos: $e');
      debugPrint(stack.toString());
    } finally {
      _loadingPositions.remove(slotPos);
      notifyListeners();
    }
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
      await loadLineup();
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('Error loading API data: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLineup() async {
    try {
      final stagesResponse = await ApiClient.instance.get('/api/stages/');
      final List<dynamic> stagesJson = jsonDecode(stagesResponse.body);
      
      if (stagesJson.isEmpty) {
        errorMessage = 'Nenhuma rodada/fase cadastrada no servidor.';
        _clearLocalLineupState();
        notifyListeners();
        return;
      }
      
      final currentStage = stagesJson.cast<dynamic>().firstWhere(
            (stage) => stage is Map && stage['is_current'] == true,
            orElse: () => null,
          );
      if (currentStage is! Map) {
        activeStageId = null;
        errorMessage = 'Nenhuma rodada atual cadastrada no servidor.';
        _clearLocalLineupState();
        notifyListeners();
        return;
      }

      final stageId = currentStage['id'] as int;
      if (activeStageId != null && activeStageId != stageId) {
        _availablePlayers.clear();
        _loadedPositions.clear();
        _loadingPositions.clear();
      }
      activeStageId = stageId;
      roundName = currentStage['name']?.toString() ?? roundName;

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
        } else {
          _clearLocalLineupState(keepStage: true);
        }
      } on ApiException catch (e) {
        if (e.statusCode == 404) {
          _clearLocalLineupState(keepStage: true);
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
    final filteredByPos = _availablePlayers
        .where((player) => _isPositionCompatible(player.position, slot.position))
        .toList();
    
    final finalOptions = filteredByPos.where(
          (player) =>
              player.id == slot.player?.id ||
              !_slots.any((selectedSlot) => selectedSlot.player?.id == player.id),
        )
        .toList(growable: false)
      ..sort((a, b) => b.averagePoints.compareTo(a.averagePoints));
    return finalOptions;
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
        final currentStage = stagesJson.cast<dynamic>().firstWhere(
              (stage) => stage is Map && stage['is_current'] == true,
              orElse: () => null,
            );
        if (currentStage is Map) {
          activeStageId = currentStage['id'] as int;
        } else {
          throw Exception('Nenhuma rodada atual cadastrada no servidor para salvar a escalação.');
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

  Future<void> clearLineup() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (lineupId != null) {
        await ApiClient.instance.delete('/api/lineups/$lineupId/');
      }
      _clearLocalLineupState(keepStage: true);
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _clearLocalLineupState({bool keepStage = false}) {
    lineupId = null;
    captainPlayerId = null;
    selectedFormation = '4-3-3';
    _slots = _buildSlotsForFormation(selectedFormation);
    isSaved = false;
    if (!keepStage) {
      activeStageId = null;
      roundName = 'Rodada 1 - Fase de grupos';
      _availablePlayers.clear();
      _loadedPositions.clear();
      _loadingPositions.clear();
    }
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
