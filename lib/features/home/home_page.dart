import 'dart:convert';

import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_notifier.dart';
import '../lineup/views/lineup_page.dart';
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
    double totalPoints = 0;
    int? stageId;
    String? stageName;
    bool hasCurrentLineup = false;
    int lineupSelectedCount = 0;
    String? lineupCaptainName;

    final rankingResponse = await ApiClient.instance.get('/api/ranking/global/');
    final List<dynamic> rankingJson = jsonDecode(rankingResponse.body);
    for (final item in rankingJson) {
      if (item is! Map) continue;
      if (item['id']?.toString() == widget.user.id) {
        rankingPosition = (item['position'] as num?)?.toInt();
        break;
      }
    }

    final stagesResponse = await ApiClient.instance.get('/api/stages/');
    final List<dynamic> stagesJson = jsonDecode(stagesResponse.body);
    if (stagesJson.isNotEmpty && stagesJson.first is Map) {
      final currentStage = stagesJson.cast<dynamic>().firstWhere(
            (stage) => stage is Map && stage['is_current'] == true,
            orElse: () => null,
          );
      if (currentStage is Map) {
        stageId = (currentStage['id'] as num?)?.toInt();
        stageName = currentStage['name']?.toString();
      }
    }

    if (stageId != null) {
      try {
        final lineupResponse = await ApiClient.instance.get(
          '/api/lineups/by-stage/$stageId/',
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
              totalPoints =
                  (historyJson['total_points'] as num?)?.toDouble() ?? 0;
            }
          }
        }
      } on ApiException catch (error) {
        if (error.statusCode != 404) rethrow;
      }
    }

    return _HomeApiSummary(
      roundPoints: totalPoints,
      rankingPosition: rankingPosition,
      stageName: stageName,
      hasCurrentLineup: hasCurrentLineup,
      lineupSelectedCount: lineupSelectedCount,
      lineupCaptainName: lineupCaptainName,
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
                icon: Icon(Icons.search),
                label: 'Jogadores',
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
      1 => const LineupPage(),
      2 => const Placeholder(), // Jogadores
      3 => ScorePage(currentUser: widget.user),
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
    required this.roundPoints,
    required this.rankingPosition,
    required this.stageName,
    required this.hasCurrentLineup,
    required this.lineupSelectedCount,
    required this.lineupCaptainName,
  });

  final double roundPoints;
  final int? rankingPosition;
  final String? stageName;
  final bool hasCurrentLineup;
  final int lineupSelectedCount;
  final String? lineupCaptainName;
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
        final pointsText = isLoading
            ? '...'
            : hasError
                ? '--'
                : '${(summary?.roundPoints ?? 0).toStringAsFixed(1)} pts';
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pontuação da rodada',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pointsText,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 48, color: Colors.white24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ranking',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rankingText,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
        final hasStage = summary?.stageName != null;
        final hasLineup = summary?.hasCurrentLineup == true;

        final title = isLoading
            ? 'Carregando seu time...'
            : hasError
                ? 'Não foi possível carregar seu time'
                : !hasStage
                    ? 'Nenhuma rodada atual cadastrada'
                    : hasLineup
                        ? 'Escalação da ${summary!.stageName}'
                        : 'Você não tem escalação para ${summary!.stageName}';
        final subtitle = isLoading
            ? 'Buscando escalação na API'
            : hasError
                ? 'Puxe para atualizar e tente novamente'
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
                onPressed: hasError || !hasStage ? null : onBuildTeam,
                child: Text(
                  hasLineup ? 'Editar' : 'Montar',
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
                : summary?.stageName ?? 'Nenhuma rodada cadastrada';
        final subtitle = isLoading
            ? 'Buscando informações da API'
            : hasError
                ? 'Puxe para atualizar e tente novamente'
                : summary?.stageName == null
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
