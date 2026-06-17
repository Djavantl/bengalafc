import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/services/api_client.dart';

class PhasesPage extends StatefulWidget {
  const PhasesPage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<PhasesPage> createState() => _PhasesPageState();
}

class _PhasesPageState extends State<PhasesPage> {
  late Future<List<_PhaseItem>> _phasesFuture;
  final Map<String, Future<List<_FixtureItem>>> _fixturesFutures = {};

  @override
  void initState() {
    super.initState();
    _phasesFuture = _loadPhases();
  }

  Future<List<_PhaseItem>> _loadPhases() async {
    final response = await ApiClient.instance.get(
      '/api/stages/',
      requireAuth: false,
    );
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => _PhaseItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<_FixtureItem>> _loadFixtures(String stageId) async {
    final response = await ApiClient.instance.get(
      '/api/fixtures/?stage=$stageId',
      requireAuth: false,
    );
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => _FixtureItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _fixturesFutures.clear();
      _phasesFuture = _loadPhases();
    });
    await _phasesFuture;
  }

  Future<List<_FixtureItem>> _fixturesFutureFor(String stageId) {
    return _fixturesFutures.putIfAbsent(
      stageId,
      () => _loadFixtures(stageId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<_PhaseItem>>(
        future: _phasesFuture,
        builder: (context, snapshot) {
          final children = <Widget>[
            _BackHeader(title: 'Fases', onBack: widget.onBack),
            const SizedBox(height: 12),
          ];

          if (snapshot.connectionState == ConnectionState.waiting) {
            // ✅ SEMANTICS: anuncia loading de fases
            children.add(
              Semantics(
                liveRegion: true,
                label: 'Carregando fases',
                child: const SizedBox(
                  height: 320,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            children.add(
              const _MessageState(
                icon: Icons.error_outline,
                title: 'Não foi possível carregar as fases',
                subtitle: 'Puxe para atualizar e tente novamente.',
              ),
            );
          } else {
            final phases = snapshot.data ?? [];
            if (phases.isEmpty) {
              children.add(
                const _MessageState(
                  icon: Icons.event_busy_outlined,
                  title: 'Nenhuma fase cadastrada',
                  subtitle:
                      'As fases aparecerão aqui quando a API retornar dados.',
                ),
              );
            } else {
              for (final phase in phases) {
                children.add(
                  _PhaseTile(
                    phase: phase,
                    loadFixtures: () => _fixturesFutureFor(phase.id),
                  ),
                );
                children.add(const SizedBox(height: 10));
              }
            }
          }

          children.add(const SizedBox(height: 22));

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                children: children,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BackHeader extends StatelessWidget {
  const _BackHeader({required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ✅ tooltip já serve como label acessível
        IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (onBack != null) {
              onBack!();
              return;
            }
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _PhaseTile extends StatefulWidget {
  const _PhaseTile({
    required this.phase,
    required this.loadFixtures,
  });

  final _PhaseItem phase;
  final Future<List<_FixtureItem>> Function() loadFixtures;

  @override
  State<_PhaseTile> createState() => _PhaseTileState();
}

class _PhaseTileState extends State<_PhaseTile> {
  Future<List<_FixtureItem>>? _fixturesFuture;
  bool _isExpanded = false;

  void _handleExpansionChanged(bool expanded) {
    _isExpanded = expanded;
    if (!expanded || _fixturesFuture != null) return;
    setState(() {
      _fixturesFuture = widget.loadFixtures();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final competitionLabel = widget.phase.competitionName != null
        ? ', ${widget.phase.competitionName}'
        : '';

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      // ✅ SEMANTICS: ExpansionTile com label descritivo do estado
      child: Semantics(
        label:
            'Fase ${widget.phase.orderText}, ${widget.phase.name}$competitionLabel. '
            '${_isExpanded ? 'Expandido, toque para recolher' : 'Recolhido, toque para expandir'}',
        child: ExpansionTile(
          onExpansionChanged: _handleExpansionChanged,
          // ✅ SEMANTICS: CircleAvatar com número é decorativo — já incluso no label
          leading: ExcludeSemantics(
            child: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              child: Text(widget.phase.orderText),
            ),
          ),
          title: ExcludeSemantics(
            child: Text(
              widget.phase.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          subtitle: widget.phase.competitionName == null
              ? null
              : ExcludeSemantics(
                  child: Text(
                    widget.phase.competitionName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
          children: [
            FutureBuilder<List<_FixtureItem>>(
              future: _fixturesFuture,
              builder: (context, snapshot) {
                if (_fixturesFuture == null) {
                  return const SizedBox.shrink();
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  // ✅ SEMANTICS: anuncia loading dos jogos da fase
                  return Semantics(
                    liveRegion: true,
                    label: 'Carregando jogos da fase ${widget.phase.name}',
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: LinearProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const _InlineMessage(
                    icon: Icons.error_outline,
                    text: 'Não foi possível carregar os jogos desta fase.',
                  );
                }

                final fixtures = snapshot.data ?? [];
                if (fixtures.isEmpty) {
                  return const _InlineMessage(
                    icon: Icons.sports_soccer_outlined,
                    text: 'Nenhum jogo cadastrado nesta fase.',
                  );
                }

                return Column(
                  children: fixtures
                      .map((fixture) => _FixtureRow(fixture: fixture))
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FixtureRow extends StatelessWidget {
  const _FixtureRow({required this.fixture});

  final _FixtureItem fixture;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ✅ SEMANTICS: jogo lido como frase natural
    return Semantics(
      label:
          '${fixture.homeTeam} ${fixture.scoreText} ${fixture.awayTeam}, ${fixture.status}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    fixture.homeTeam,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    ExcludeSemantics(
                      child: Text(
                        fixture.scoreText,
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    ExcludeSemantics(
                      child: Text(
                        fixture.status,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    fixture.awayTeam,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 96),
        // ✅ SEMANTICS: ícone decorativo — mensagem descrita pelo texto
        Semantics(
          excludeSemantics: true,
          child: Icon(icon, size: 44, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // ✅ SEMANTICS: ícone + texto agrupados, ícone decorativo
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
        child: Row(
          children: [
            Semantics(
              excludeSemantics: true,
              child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseItem {
  const _PhaseItem({
    required this.id,
    required this.name,
    required this.order,
    this.competitionName,
  });

  final String id;
  final String name;
  final int order;
  final String? competitionName;

  String get orderText => order <= 0 ? id : order.toString();

  factory _PhaseItem.fromJson(Map<String, dynamic> json) {
    final competition = json['competition_detail'];
    return _PhaseItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Fase sem nome',
      order: (json['order'] as num?)?.toInt() ?? 0,
      competitionName:
          competition is Map ? competition['name']?.toString() : null,
    );
  }
}

class _FixtureItem {
  const _FixtureItem({
    required this.homeTeam,
    required this.awayTeam,
    required this.status,
    this.homeScore,
    this.awayScore,
  });

  final String homeTeam;
  final String awayTeam;
  final String status;
  final int? homeScore;
  final int? awayScore;

  String get scoreText {
    if (homeScore == null || awayScore == null) return 'x';
    return '$homeScore x $awayScore';
  }

  factory _FixtureItem.fromJson(Map<String, dynamic> json) {
    final homeTeamDetail = json['home_team_detail'];
    final awayTeamDetail = json['away_team_detail'];
    return _FixtureItem(
      homeTeam: _teamName(homeTeamDetail, json['home_team']),
      awayTeam: _teamName(awayTeamDetail, json['away_team']),
      status: json['status']?.toString() ?? '--',
      homeScore: (json['home_score'] as num?)?.toInt(),
      awayScore: (json['away_score'] as num?)?.toInt(),
    );
  }

  static String _teamName(dynamic detail, dynamic fallback) {
    if (detail is Map) {
      return detail['name']?.toString() ??
          detail['code']?.toString() ??
          'Time ${fallback ?? ''}'.trim();
    }
    return 'Time ${fallback ?? ''}'.trim();
  }
}