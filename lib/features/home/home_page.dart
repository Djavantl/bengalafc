import 'dart:convert';

import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_notifier.dart';
import '../lineup/views/lineup_page.dart';
import '../phases/views/phases_page.dart';
import '../scoring/views/score_page.dart';
import '../settings/models/app_user_model.dart';
import '../settings/views/profile_page.dart';
import '../settings/views/widgets/user_avatar.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.user,
    this.onSignOut,
  });

  final AppUserModel user;
  final VoidCallback? onSignOut;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late Future<_HomeApiSummary> _homeApiSummaryFuture;

  @override
  void initState() {
    super.initState();
    _homeApiSummaryFuture = _loadHomeApiSummary();
  }

  Future<_HomeApiSummary> _loadHomeApiSummary() async {
    int? rankingPosition;
    double currentStagePoints = 0;
    double previousStagePoints = 0;
    int? currentStageId;
    int? previousStageId;
    String? currentStageName;
    String? previousStageName;
    bool competitionFinished = false;
    bool hasCurrentLineup = false;
    int lineupSelectedCount = 0;
    String? lineupCaptainName;
    List<_FixtureSummary> currentFixtures = const [];

    final rankingResponse =
        await ApiClient.instance.get('/api/ranking/global/');
    final List<dynamic> rankingJson = jsonDecode(rankingResponse.body);
    for (final item in rankingJson) {
      if (item is! Map) continue;
      if (item['id']?.toString() == widget.user.id) {
        rankingPosition = (item['position'] as num?)?.toInt();
        break;
      }
    }

    final stateResponse = await ApiClient.instance.get('/api/stages/state/');
    final stateJson = jsonDecode(stateResponse.body);
    if (stateJson is Map) {
      competitionFinished = stateJson['competition_finished'] == true;
      final currentStage = stateJson['current_stage'];
      final previousStage = stateJson['previous_stage'];
      if (currentStage is Map) {
        currentStageId = (currentStage['id'] as num?)?.toInt();
        currentStageName = currentStage['name']?.toString();
      }
      if (previousStage is Map) {
        previousStageId = (previousStage['id'] as num?)?.toInt();
        previousStageName = previousStage['name']?.toString();
      }
    }

    if (currentStageId != null) {
      try {
        final lineupResponse = await ApiClient.instance.get(
          '/api/lineups/by-stage/$currentStageId/',
        );
        final lineupJson = jsonDecode(lineupResponse.body);
        if (lineupJson is Map) {
          hasCurrentLineup = true;
          final players = lineupJson['players'];
          lineupSelectedCount = players is List ? players.length : 0;
          final captainDetail = lineupJson['captain_detail'];
          if (captainDetail is Map) {
            lineupCaptainName = captainDetail['name']?.toString();
          }
          final lineupId = lineupJson['id'];
          if (lineupId != null) {
            final historyResponse = await ApiClient.instance.get(
              '/api/lineups/$lineupId/score-history/',
            );
            final historyJson = jsonDecode(historyResponse.body);
            if (historyJson is Map) {
              currentStagePoints =
                  (historyJson['total_points'] as num?)?.toDouble() ?? 0;
            }
          }
        }
      } on ApiException catch (error) {
        if (error.statusCode != 404) rethrow;
      }

      final fixturesResponse = await ApiClient.instance.get(
        '/api/fixtures/?stage=$currentStageId',
      );
      final List<dynamic> fixturesJson = jsonDecode(fixturesResponse.body);
      currentFixtures = fixturesJson
          .whereType<Map>()
          .map((fixture) => _FixtureSummary.fromJson(fixture))
          .toList(growable: false);
    }

    if (previousStageId != null) {
      try {
        final lineupResponse = await ApiClient.instance.get(
          '/api/lineups/by-stage/$previousStageId/',
        );
        final lineupJson = jsonDecode(lineupResponse.body);
        if (lineupJson is Map && lineupJson['id'] != null) {
          final historyResponse = await ApiClient.instance.get(
            '/api/lineups/${lineupJson['id']}/score-history/',
          );
          final historyJson = jsonDecode(historyResponse.body);
          if (historyJson is Map) {
            previousStagePoints =
                (historyJson['total_points'] as num?)?.toDouble() ?? 0;
          }
        }
      } on ApiException catch (error) {
        if (error.statusCode != 404) rethrow;
      }
    }

    return _HomeApiSummary(
      currentStagePoints: currentStagePoints,
      previousStagePoints: previousStagePoints,
      rankingPosition: rankingPosition,
      currentStageName: currentStageName,
      previousStageName: previousStageName,
      competitionFinished: competitionFinished,
      hasCurrentLineup: hasCurrentLineup,
      lineupSelectedCount: lineupSelectedCount,
      lineupCaptainName: lineupCaptainName,
      currentFixtures: currentFixtures,
    );
  }

  Future<void> _reloadHomeData() async {
    if (!mounted) return;
    setState(() {
      _homeApiSummaryFuture = _loadHomeApiSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;

        return Scaffold(
          appBar: AppBar(
            title: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.titleLarge,
                children: [
                  const TextSpan(text: 'Bengala'),
                  const TextSpan(
                    text: 'FC',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: ' Fantasy',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: UserAvatar(
                    user: widget.user,
                    radius: 18,
                    onTap: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(user: widget.user),
                        ),
                      );
                      if (updated == true && mounted) {
                        setState(() {});
                      }
                    },
                  ),
                ),
              ),
              IconButton(
                tooltip: isDark ? 'Modo claro' : 'Modo escuro',
                icon: Icon(
                  isDark ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                ),
                onPressed: themeNotifier.toggle,
              ),
              if (widget.onSignOut != null)
                IconButton(
                  tooltip: 'Sair',
                  icon: const Icon(Icons.logout),
                  onPressed: widget.onSignOut,
                ),
            ],
          ),
          body: _selectedIndex == 0
              ? _HomeBody(
                  userName: widget.user.name,
                  homeApiSummaryFuture: _homeApiSummaryFuture,
                  onBuildTeam: () => setState(() => _selectedIndex = 1),
                  onRefresh: _reloadHomeData,
                )
              : _buildPage(_selectedIndex),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
              if (index == 0) _reloadHomeData();
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: 'Time',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note),
                label: 'Fases',
              ),
              NavigationDestination(
                icon: Icon(Icons.leaderboard_outlined),
                selectedIcon: Icon(Icons.leaderboard),
                label: 'Ranking',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPage(int index) {
    return switch (index) {
      1 => LineupPage(onBack: () => setState(() => _selectedIndex = 0)),
      2 => PhasesPage(onBack: () => setState(() => _selectedIndex = 0)),
      3 => ScorePage(
          currentUser: widget.user,
          onBack: () => setState(() => _selectedIndex = 0),
        ),
      _ => _HomeBody(
          userName: widget.user.name,
          homeApiSummaryFuture: _homeApiSummaryFuture,
          onBuildTeam: () => setState(() => _selectedIndex = 1),
          onRefresh: _reloadHomeData,
        ),
    };
  }
}

class _HomeApiSummary {
  const _HomeApiSummary({
    required this.currentStagePoints,
    required this.previousStagePoints,
    required this.rankingPosition,
    required this.currentStageName,
    required this.previousStageName,
    required this.competitionFinished,
    required this.hasCurrentLineup,
    required this.lineupSelectedCount,
    required this.lineupCaptainName,
    required this.currentFixtures,
  });

  final double currentStagePoints;
  final double previousStagePoints;
  final int? rankingPosition;
  final String? currentStageName;
  final String? previousStageName;
  final bool competitionFinished;
  final bool hasCurrentLineup;
  final int lineupSelectedCount;
  final String? lineupCaptainName;
  final List<_FixtureSummary> currentFixtures;
}

class _FixtureSummary {
  const _FixtureSummary({
    required this.homeTeam,
    required this.awayTeam,
    required this.status,
    this.homeScore,
    this.awayScore,
    this.kickoffAt,
    this.venue,
  });

  final String homeTeam;
  final String awayTeam;
  final String status;
  final int? homeScore;
  final int? awayScore;
  final DateTime? kickoffAt;
  final String? venue;

  String get scoreText {
    if (homeScore == null || awayScore == null) return 'x';
    return '$homeScore x $awayScore';
  }

  String get kickoffText {
    if (kickoffAt == null) return status;
    final local = kickoffAt!.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  factory _FixtureSummary.fromJson(Map<dynamic, dynamic> json) {
    final homeDetail = json['home_team_detail'];
    final awayDetail = json['away_team_detail'];
    final kickoffRaw = json['kickoff_at']?.toString();

    return _FixtureSummary(
      homeTeam: _teamName(homeDetail, json['home_team']),
      awayTeam: _teamName(awayDetail, json['away_team']),
      status: json['status']?.toString() ?? 'NS',
      homeScore: (json['home_score'] as num?)?.toInt(),
      awayScore: (json['away_score'] as num?)?.toInt(),
      kickoffAt: kickoffRaw == null ? null : DateTime.tryParse(kickoffRaw),
      venue: json['venue']?.toString(),
    );
  }

  static String _teamName(dynamic detail, dynamic fallback) {
    if (detail is Map) {
      return detail['code']?.toString() ??
          detail['name']?.toString() ??
          fallback?.toString() ??
          'Seleção';
    }
    return fallback?.toString() ?? 'Seleção';
  }
}

// ─── Home body extraído para widget separado ─────────────────────────────────

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    this.userName,
    required this.homeApiSummaryFuture,
    this.onBuildTeam,
    this.onRefresh,
  });

  final String? userName;
  final Future<_HomeApiSummary> homeApiSummaryFuture;
  final VoidCallback? onBuildTeam;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return RefreshIndicator(
          onRefresh: onRefresh ?? () async {},
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 16,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (userName != null) ...[
                  Text(
                    'Ola, $userName',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
                _ScoreCard(summaryFuture: homeApiSummaryFuture),
                const SizedBox(height: 24),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _MyTeamSection(
                          summaryFuture: homeApiSummaryFuture,
                          onBuildTeam: onBuildTeam,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _RoundSection(
                          summaryFuture: homeApiSummaryFuture,
                        ),
                      ),
                    ],
                  )
                else ...[
                  _MyTeamSection(
                    summaryFuture: homeApiSummaryFuture,
                    onBuildTeam: onBuildTeam,
                  ),
                  const SizedBox(height: 16),
                  _RoundSection(
                    summaryFuture: homeApiSummaryFuture,
                  ),
                ],
                const SizedBox(height: 16),
                _CurrentFixturesSection(summaryFuture: homeApiSummaryFuture),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.summaryFuture});

  final Future<_HomeApiSummary> summaryFuture;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<_HomeApiSummary>(
      future: summaryFuture,
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;
        final currentPointsText = isLoading
            ? '...'
            : hasError
                ? '--'
                : '${(summary?.currentStagePoints ?? 0).toStringAsFixed(1)} pts';
        final previousPointsText = isLoading
            ? '...'
            : hasError
                ? '--'
                : '${(summary?.previousStagePoints ?? 0).toStringAsFixed(1)} pts';
        final rankingText = isLoading
            ? '#...'
            : hasError
                ? '#--'
                : summary?.rankingPosition == null
                    ? '#--'
                    : '#${summary!.rankingPosition}';

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 420;
              final metrics = [
                _ScoreMetricData(
                  label: 'Rodada atual',
                  value: currentPointsText,
                ),
                _ScoreMetricData(
                  label: summary?.previousStageName == null
                      ? 'Fase anterior'
                      : summary!.previousStageName!,
                  value: previousPointsText,
                ),
                _ScoreMetricData(label: 'Ranking', value: rankingText),
              ];

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < metrics.length; i++) ...[
                      _ScoreMetric(metric: metrics[i], fontSize: 30),
                      if (i < metrics.length - 1) ...[
                        const SizedBox(height: 14),
                        Container(height: 1, color: Colors.white24),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < metrics.length; i++) ...[
                    Expanded(child: _ScoreMetric(metric: metrics[i])),
                    if (i < metrics.length - 1)
                      Container(width: 1, height: 48, color: Colors.white24),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ScoreMetricData {
  const _ScoreMetricData({required this.label, required this.value});

  final String label;
  final String value;
}

class _ScoreMetric extends StatelessWidget {
  const _ScoreMetric({required this.metric, this.fontSize = 28});

  final _ScoreMetricData metric;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MyTeamSection extends StatelessWidget {
  const _MyTeamSection({required this.summaryFuture, this.onBuildTeam});

  final Future<_HomeApiSummary> summaryFuture;
  final VoidCallback? onBuildTeam;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Meu Time'),
        const SizedBox(height: 10),
        _MyTeamCard(
          summaryFuture: summaryFuture,
          onBuildTeam: onBuildTeam,
        ),
      ],
    );
  }
}

class _MyTeamCard extends StatelessWidget {
  const _MyTeamCard({required this.summaryFuture, this.onBuildTeam});

  final Future<_HomeApiSummary> summaryFuture;
  final VoidCallback? onBuildTeam;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardBg = Theme.of(context).brightness == Brightness.dark
        ? cs.surfaceContainerHighest
        : const Color(0xFFEEEEEE);

    return FutureBuilder<_HomeApiSummary>(
      future: summaryFuture,
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;
        final hasStage = summary?.currentStageName != null;
        final hasLineup = summary?.hasCurrentLineup == true;
        final competitionFinished = summary?.competitionFinished == true;

        final title = isLoading
            ? 'Carregando seu time...'
            : hasError
                ? 'Não foi possível carregar seu time'
                : competitionFinished
                    ? 'Competição encerrada'
                    : !hasStage
                        ? 'Nenhuma rodada atual cadastrada'
                        : hasLineup
                            ? 'Escalação da ${summary!.currentStageName}'
                            : 'Você não tem escalação para ${summary!.currentStageName}';
        final subtitle = isLoading
            ? 'Buscando escalação na API'
            : hasError
                ? 'Puxe para atualizar e tente novamente'
                : competitionFinished
                    ? 'Veja sua posição final no ranking'
                    : !hasStage
                        ? 'Quando uma fase atual existir, ela aparecerá aqui'
                        : hasLineup
                            ? '${summary!.lineupSelectedCount}/11 escalados'
                                '${summary.lineupCaptainName == null ? '' : ' • Cap: ${summary.lineupCaptainName}'}'
                            : 'Monte seu time para pontuar nesta rodada';

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: cs.primary, width: 4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(Icons.group_outlined, size: 36, color: cs.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: hasError || !hasStage || competitionFinished
                    ? null
                    : onBuildTeam,
                child: Text(
                  competitionFinished
                      ? 'Encerrado'
                      : hasLineup
                          ? 'Editar'
                          : 'Montar',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoundSection extends StatelessWidget {
  const _RoundSection({required this.summaryFuture});

  final Future<_HomeApiSummary> summaryFuture;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Rodada Atual'),
        const SizedBox(height: 10),
        _RoundCard(summaryFuture: summaryFuture),
      ],
    );
  }
}

class _RoundCard extends StatelessWidget {
  const _RoundCard({required this.summaryFuture});

  final Future<_HomeApiSummary> summaryFuture;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardBg = Theme.of(context).brightness == Brightness.dark
        ? cs.surfaceContainerHighest
        : const Color(0xFFEEEEEE);

    return FutureBuilder<_HomeApiSummary>(
      future: summaryFuture,
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;
        final title = isLoading
            ? 'Carregando rodada...'
            : hasError
                ? 'Não foi possível carregar'
                : summary?.competitionFinished == true
                    ? 'Competição encerrada'
                    : summary?.currentStageName ?? 'Nenhuma rodada cadastrada';
        final subtitle = isLoading
            ? 'Buscando informações da API'
            : hasError
                ? 'Puxe para atualizar e tente novamente'
                : summary?.competitionFinished == true
                    ? 'A última fase foi finalizada. Confira sua posição no ranking.'
                    : summary?.currentStageName == null
                        ? 'As fases aparecerão aqui quando forem cadastradas'
                        : 'Fase disponível para escalação e pontuação';

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: cs.secondary, width: 4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(Icons.sports_soccer_outlined, size: 36, color: cs.secondary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CurrentFixturesSection extends StatelessWidget {
  const _CurrentFixturesSection({required this.summaryFuture});

  final Future<_HomeApiSummary> summaryFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeApiSummary>(
      future: summaryFuture,
      builder: (context, snapshot) {
        final summary = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        if (isLoading) {
          return const _FixturesCard(
            title: 'Partidas da fase atual',
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return const _FixturesCard(
            title: 'Partidas da fase atual',
            child: _EmptyFixturesMessage(
              message: 'Não foi possível carregar as partidas agora.',
            ),
          );
        }

        if (summary?.competitionFinished == true) {
          return const _FixturesCard(
            title: 'Competição encerrada',
            child: _EmptyFixturesMessage(
              message:
                  'Todas as fases foram finalizadas. Veja sua posição no ranking.',
            ),
          );
        }

        if (summary?.currentStageName == null) {
          return const _FixturesCard(
            title: 'Partidas da fase atual',
            child: _EmptyFixturesMessage(
              message: 'Nenhuma fase atual cadastrada na API.',
            ),
          );
        }

        final fixtures = summary?.currentFixtures ?? const <_FixtureSummary>[];
        if (fixtures.isEmpty) {
          return _FixturesCard(
            title: 'Partidas da ${summary!.currentStageName}',
            child: const _EmptyFixturesMessage(
              message: 'Nenhuma partida cadastrada para esta fase.',
            ),
          );
        }

        return _FixturesCard(
          title: 'Partidas da ${summary!.currentStageName}',
          child: Column(
            children: fixtures
                .map((fixture) => _FixtureTile(fixture: fixture))
                .toList(growable: false),
          ),
        );
      },
    );
  }
}

class _FixturesCard extends StatelessWidget {
  const _FixturesCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _FixtureTile extends StatelessWidget {
  const _FixtureTile({required this.fixture});

  final _FixtureSummary fixture;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              fixture.homeTeam,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Text(
                  fixture.scoreText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  fixture.kickoffText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              fixture.awayTeam,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFixturesMessage extends StatelessWidget {
  const _EmptyFixturesMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
