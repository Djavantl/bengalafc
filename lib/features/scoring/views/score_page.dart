import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/ranking_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../ranking/models/ranking_user_score.dart';
import '../../settings/models/app_user_model.dart';
import '../../settings/views/widgets/user_avatar.dart';
import '../models/user_phase_score.dart';
import '../viewmodels/scoring_notifier.dart';

class ScorePage extends StatefulWidget {
  const ScorePage({
    super.key,
    required this.currentUser,
  });

  final AppUserModel currentUser;

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  final _rankingService = RankingService();
  late Future<List<RankingUserScore>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    _rankingFuture = _rankingService.getGlobalRanking(
      currentUser: widget.currentUser,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScoringNotifier>().load(widget.currentUser.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ScoringNotifier>();
    final cs = Theme.of(context).colorScheme;
    return _buildBody(notifier, cs);
  }

  Widget _buildBody(ScoringNotifier notifier, ColorScheme cs) {
    switch (notifier.status) {
      case ScoringStatus.loading:
        return const _LoadingState();
      case ScoringStatus.error:
        return _ErrorState(
          message: notifier.errorMessage ?? 'Erro desconhecido.',
          onRetry: _reload,
        );
      case ScoringStatus.success:
        return _ScoreContent(
          notifier: notifier,
          rankingFuture: _rankingFuture,
          onRetryRanking: _reloadRanking,
        );
      case ScoringStatus.idle:
        return const SizedBox.shrink();
    }
  }

  void _reload() {
    context.read<ScoringNotifier>().load(widget.currentUser.id);
    _reloadRanking();
  }

  void _reloadRanking() {
    setState(() {
      _rankingFuture = _rankingService.getGlobalRanking(
        currentUser: widget.currentUser,
      );
    });
  }
}

class _ScoreContent extends StatelessWidget {
  final ScoringNotifier notifier;
  final Future<List<RankingUserScore>> rankingFuture;
  final VoidCallback onRetryRanking;

  const _ScoreContent({
    required this.notifier,
    required this.rankingFuture,
    required this.onRetryRanking,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 32 : 16,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitle(
                title: 'Ranking geral',
                trailing: IconButton(
                  tooltip: 'Atualizar ranking',
                  onPressed: onRetryRanking,
                  icon: const Icon(Icons.refresh),
                ),
              ),
              const SizedBox(height: 12),
              _RankingList(rankingFuture: rankingFuture),
              const SizedBox(height: 24),
              _SectionTitle(
                title: 'Histórico por fase',
              ),
              const SizedBox(height: 12),
              if (notifier.scores.isEmpty)
                const _EmptyState()
              else
                ...notifier.scores.map((s) => _PhaseCard(score: s)),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({required this.rankingFuture});

  final Future<List<RankingUserScore>> rankingFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RankingUserScore>>(
      future: rankingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              for (int i = 0; i < 4; i++) ...[
                _SkeletonBox(height: 72, radius: 16),
                const SizedBox(height: 10),
              ],
            ],
          );
        }

        if (snapshot.hasError) {
          return const _RankingError();
        }

        final ranking = snapshot.data ?? [];
        if (ranking.isEmpty) {
          return const _RankingEmpty();
        }

        return Column(
          children: [
            for (final entry in ranking) _RankingRow(entry: entry),
          ],
        );
      },
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry});

  final RankingUserScore entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCurrentUser = entry.isCurrentUser;
    final backgroundColor = isCurrentUser
        ? cs.primaryContainer.withOpacity(isDark ? 0.5 : 0.8)
        : isDark
            ? cs.surfaceContainerHighest
            : const Color(0xFFEEEEE8);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser ? cs.primary : Colors.transparent,
          width: isCurrentUser ? 1.5 : 0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.position}',
              style: TextStyle(
                color: isCurrentUser ? cs.primary : cs.onSurfaceVariant,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          UserAvatar(user: entry.user, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.user.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      _CurrentUserPill(colorScheme: cs),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  entry.user.email ?? 'Pontuação geral',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${entry.totalPoints.toStringAsFixed(1)} pts',
            style: TextStyle(
              color: isCurrentUser ? cs.primary : cs.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentUserPill extends StatelessWidget {
  const _CurrentUserPill({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Voce',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RankingError extends StatelessWidget {
  const _RankingError();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Nao foi possivel carregar o ranking.',
        style: TextStyle(color: cs.onErrorContainer),
      ),
    );
  }
}

class _RankingEmpty extends StatelessWidget {
  const _RankingEmpty();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Nenhum usuario encontrado para o ranking.',
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final UserPhaseScore score;
  const _PhaseCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? cs.surfaceContainerHighest
        : const Color(0xFFEEEEE8);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${score.phaseNumber}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score.phaseName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  score.rankPosition > 0
                      ? 'Ranking: #${score.rankPosition}'
                      : 'Ranking por fase indisponível',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${score.totalPoints.toStringAsFixed(1)} pts',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SkeletonBox(height: 18, radius: 6, width: 140),
          const SizedBox(height: 12),
          for (int i = 0; i < 4; i++) ...[
            _SkeletonBox(height: 68, radius: 16),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double radius;
  final double? width;
  const _SkeletonBox({required this.height, required this.radius, this.width});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 56, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Nenhuma pontuação ainda',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Suas pontuações por fase aparecerão aqui assim que a competição começar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: cs.error),
            const SizedBox(height: 16),
            Text(
              'Ops! Algo deu errado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
