import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../models/lineup_player_model.dart';
import '../viewmodels/lineup_view_model.dart';

class LineupPage extends StatelessWidget {
  const LineupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LineupViewModel(),
      child: const _LineupView(),
    );
  }
}

class _LineupView extends StatelessWidget {
  const _LineupView();

  @override
  Widget build(BuildContext context) {
    return Consumer<LineupViewModel>(
      builder: (context, viewModel, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final horizontalPadding = isWide ? 32.0 : 16.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                28,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (viewModel.isLoading) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 12),
                    ],
                    _LineupHeader(viewModel: viewModel),
                    const SizedBox(height: 16),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _PitchCard(viewModel: viewModel),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 4,
                            child: _SelectedPlayersPanel(viewModel: viewModel),
                          ),
                        ],
                      )
                    else ...[
                      _PitchCard(viewModel: viewModel),
                      const SizedBox(height: 16),
                      _SelectedPlayersPanel(viewModel: viewModel),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LineupHeader extends StatelessWidget {
  const _LineupHeader({required this.viewModel});

  final LineupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewModel.teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${viewModel.roundName} • ${viewModel.marketStatus}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: (viewModel.isComplete && !viewModel.isLoading)
                    ? () async {
                        try {
                          await viewModel.saveLineup();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Escalação salva com sucesso!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao salvar escalação: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                icon: viewModel.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        viewModel.isSaved ? Icons.check_circle : Icons.save_outlined,
                        size: 18,
                      ),
                label: Text(viewModel.isSaved ? 'Salvo' : 'Salvar'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                icon: Icons.groups_2_outlined,
                label: 'Escalados',
                value: '${viewModel.selectedCount}/${viewModel.totalSlots}',
              ),
              _MetricChip(
                icon: Icons.dashboard_customize_outlined,
                label: 'Formação',
                value: viewModel.selectedFormation,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: LineupViewModel.formationOptions
                .map(
                  (formation) => ButtonSegment<String>(
                    value: formation,
                    label: Text(formation),
                  ),
                )
                .toList(growable: false),
            selected: {viewModel.selectedFormation},
            onSelectionChanged: (selection) =>
                viewModel.changeFormation(selection.first),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isWarning ? cs.error : cs.primary;

    return Container(
      constraints: const BoxConstraints(minWidth: 128),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isWarning ? cs.error : cs.onSurface,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PitchCard extends StatelessWidget {
  const _PitchCard({required this.viewModel});

  final LineupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      padding: const EdgeInsets.all(12),
      child: AspectRatio(
        aspectRatio: 0.72,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.65), width: 2),
          ),
          child: Stack(
            children: [
              const _PitchLines(),
              ...viewModel.slots.map(
                (slot) => _PositionedSlot(
                  slot: slot,
                  formation: viewModel.selectedFormation,
                  isCaptain: slot.player?.id == viewModel.captainPlayerId,
                  onTap: () => _showPlayerPicker(context, viewModel, slot),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlayerPicker(
    BuildContext context,
    LineupViewModel viewModel,
    LineupSlot slot,
  ) {
    viewModel.loadPlayersForPosition(slot.position);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ChangeNotifierProvider.value(
          value: viewModel,
          child: Consumer<LineupViewModel>(
            builder: (context, vm, _) {
              final options = vm.optionsForSlot(slot);

              return _PlayerPickerSheet(
                slot: slot,
                options: options,
                isLoading: vm.isPositionLoading(slot.position),
                onSelect: (player) {
                  vm.selectPlayer(slot.id, player);
                  Navigator.of(sheetContext).pop();
                },
                onRemove: slot.player == null
                    ? null
                    : () {
                        vm.clearSlot(slot.id);
                        Navigator.of(sheetContext).pop();
                      },
              );
            },
          ),
        );
      },
    );
  }
}

class _PlayerPickerSheet extends StatefulWidget {
  const _PlayerPickerSheet({
    required this.slot,
    required this.options,
    required this.onSelect,
    this.onRemove,
    this.isLoading = false,
  });

  final LineupSlot slot;
  final List<LineupPlayerModel> options;
  final ValueChanged<LineupPlayerModel> onSelect;
  final VoidCallback? onRemove;
  final bool isLoading;

  @override
  State<_PlayerPickerSheet> createState() => _PlayerPickerSheetState();
}

class _PlayerPickerSheetState extends State<_PlayerPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LineupPlayerModel> get _filteredOptions {
    final normalizedQuery = _normalize(_query);
    if (normalizedQuery.isEmpty) return widget.options;

    return widget.options.where((player) {
      final name = _normalize(player.name);
      final country = _normalize(player.nationalTeam);
      return name.contains(normalizedQuery) ||
          country.contains(normalizedQuery);
    }).toList(growable: false);
  }

  String _normalize(String value) {
    const accents = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'ê': 'e',
      'í': 'i',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    return value
        .trim()
        .toLowerCase()
        .split('')
        .map((char) => accents[char] ?? char)
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final filteredOptions = _filteredOptions;
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Escolher ${widget.slot.label}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar por jogador ou país',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.54,
              ),
              child: widget.isLoading && filteredOptions.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : filteredOptions.isEmpty
                      ? _PlayerPickerEmptyState(colorScheme: cs)
                      : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filteredOptions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final player = filteredOptions[index];
                        final isSelected =
                            player.id == widget.slot.player?.id;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _PlayerAvatar(player: player),
                          title: Text(player.name),
                          subtitle: Text(
                            '${player.nationalTeam} • ${player.averagePoints.toStringAsFixed(1)} pts • ${player.selectedPercentage.toStringAsFixed(0)}%',
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle)
                              : const Icon(Icons.add_circle_outline),
                          onTap: () => widget.onSelect(player),
                        );
                      },
                    ),
            ),
            if (widget.onRemove != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Remover jogador'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayerPickerEmptyState extends StatelessWidget {
  const _PlayerPickerEmptyState({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Text(
          'Nenhum jogador encontrado',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PitchLines extends StatelessWidget {
  const _PitchLines();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PitchPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rect = Offset(size.width * 0.08, size.height * 0.04) &
        Size(size.width * 0.84, size.height * 0.92);
    canvas.drawRect(rect, paint);
    canvas.drawLine(
      Offset(rect.left, size.height * 0.5),
      Offset(rect.right, size.height * 0.5),
      paint,
    );
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 44, paint);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, rect.top),
        width: size.width * 0.36,
        height: size.height * 0.12,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, rect.bottom),
        width: size.width * 0.48,
        height: size.height * 0.14,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PositionedSlot extends StatelessWidget {
  const _PositionedSlot({
    required this.slot,
    required this.formation,
    required this.isCaptain,
    required this.onTap,
  });

  final LineupSlot slot;
  final String formation;
  final bool isCaptain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final position = _slotPositionsByFormation[formation]?[slot.id] ??
        _fallbackSlotPosition(slot);
    final widthFactor = slot.lineSize >= 5 ? 0.18 : 0.22;

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: FractionallySizedBox(
        alignment: Alignment(position.dx * 2 - 1, position.dy * 2 - 1),
        widthFactor: widthFactor,
        heightFactor: 0.15,
        child: _PlayerSlotButton(
          slot: slot,
          isCaptain: isCaptain,
          onTap: onTap,
        ),
      ),
    );
  }

  Offset _fallbackSlotPosition(LineupSlot slot) {
    const topByRow = [0.88, 0.67, 0.45, 0.22];
    final top = topByRow[slot.row];
    final left = slot.lineSize == 1
        ? 0.50
        : 0.12 + (0.76 / (slot.lineSize - 1)) * slot.column;

    return Offset(left, top);
  }
}

const _slotPositionsByFormation = {
  '4-3-3': {
    'gol-1': Offset(0.50, 0.88),
    'ld-1': Offset(0.14, 0.67),
    'zag-1': Offset(0.38, 0.70),
    'zag-2': Offset(0.62, 0.70),
    'le-1': Offset(0.86, 0.67),
    'mei-1': Offset(0.30, 0.47),
    'mei-2': Offset(0.50, 0.54),
    'mei-3': Offset(0.70, 0.47),
    'ata-1': Offset(0.20, 0.23),
    'ata-2': Offset(0.50, 0.18),
    'ata-3': Offset(0.80, 0.23),
  },
  '4-4-2': {
    'gol-1': Offset(0.50, 0.88),
    'ld-1': Offset(0.14, 0.67),
    'zag-1': Offset(0.38, 0.70),
    'zag-2': Offset(0.62, 0.70),
    'le-1': Offset(0.86, 0.67),
    'mei-1': Offset(0.14, 0.45),
    'mei-2': Offset(0.38, 0.51),
    'mei-3': Offset(0.62, 0.51),
    'mei-4': Offset(0.86, 0.45),
    'ata-1': Offset(0.40, 0.20),
    'ata-2': Offset(0.60, 0.20),
  },
  '3-5-2': {
    'gol-1': Offset(0.50, 0.88),
    'zag-1': Offset(0.28, 0.70),
    'zag-2': Offset(0.50, 0.73),
    'zag-3': Offset(0.72, 0.70),
    'mei-1': Offset(0.10, 0.48),
    'mei-2': Offset(0.30, 0.43),
    'mei-3': Offset(0.50, 0.50),
    'mei-4': Offset(0.70, 0.43),
    'mei-5': Offset(0.90, 0.48),
    'ata-1': Offset(0.40, 0.20),
    'ata-2': Offset(0.60, 0.20),
  },
};

class _PlayerSlotButton extends StatelessWidget {
  const _PlayerSlotButton({
    required this.slot,
    required this.isCaptain,
    required this.onTap,
  });

  final LineupSlot slot;
  final bool isCaptain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final player = slot.player;

    return Tooltip(
      message: player == null ? 'Escolher jogador' : 'Trocar ${player.name}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppColors.accent, width: 2),
                      image: (player != null && player.photoUrl != null && player.photoUrl!.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(player.photoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (player != null && player.photoUrl != null && player.photoUrl!.isNotEmpty)
                        ? null
                        : Icon(
                            player == null
                                ? Icons.add
                                : Icons.sports_soccer_outlined,
                            color: AppColors.primaryLight,
                            size: 20,
                          ),
                  ),
                  if (isCaptain)
                    Positioned(
                      right: -4,
                      top: -5,
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          'C',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A221A),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                width: 96,
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.48),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  player?.name ?? slot.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedPlayersPanel extends StatelessWidget {
  const _SelectedPlayersPanel({required this.viewModel});

  final LineupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final players = viewModel.selectedPlayers;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Escalação',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque no jogador para definir o capitão.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          ...players.map(
            (player) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SelectedPlayerTile(
                player: player,
                isCaptain: player.id == viewModel.captainPlayerId,
                onTap: () => viewModel.setCaptain(player.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedPlayerTile extends StatelessWidget {
  const _SelectedPlayerTile({
    required this.player,
    required this.isCaptain,
    required this.onTap,
  });

  final LineupPlayerModel player;
  final bool isCaptain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: isCaptain
          ? AppColors.accent.withOpacity(0.16)
          : cs.surfaceContainerHighest.withOpacity(0.64),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              _PlayerAvatar(player: player),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${player.position} • ${player.nationalTeam} • ${player.selectedPercentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    isCaptain ? Icons.star : Icons.star_border,
                    color: isCaptain ? AppColors.accent : cs.onSurfaceVariant,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.player});

  final LineupPlayerModel player;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = player.photoUrl != null && player.photoUrl!.isNotEmpty;

    return CircleAvatar(
      radius: 18,
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
      backgroundImage: hasPhoto ? NetworkImage(player.photoUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              player.position,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
    );
  }
}
