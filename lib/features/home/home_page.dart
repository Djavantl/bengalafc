import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_notifier.dart';
import '../lineup/data/lineup_local_storage.dart';
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
  final _lineupStorage = LineupLocalStorage();

  int _selectedIndex = 0;
  LineupHomeSummary? _lineupSummary;

  @override
  void initState() {
    super.initState();
    _loadLineupSummary();
  }

  Future<void> _loadLineupSummary() async {
    final summary = await _lineupStorage.loadSummary();
    if (!mounted) return;

    setState(() => _lineupSummary = summary);
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
                  lineupSummary: _lineupSummary,
                  onBuildTeam: () => setState(() => _selectedIndex = 1),
                )
              : _buildPage(_selectedIndex),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
              if (index == 0) _loadLineupSummary();
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
      _ => const _HomeBody(),
    };
  }
}

// ─── Home body extraído para widget separado ─────────────────────────────────

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    this.userName,
    this.lineupSummary,
    this.onBuildTeam,
  });

  final String? userName;
  final LineupHomeSummary? lineupSummary;
  final VoidCallback? onBuildTeam;

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
              if (userName != null) ...[
                Text(
                  'Ola, $userName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
              ],
              const _ScoreCard(),
              const SizedBox(height: 24),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _MyTeamSection(
                        lineupSummary: lineupSummary,
                        onBuildTeam: onBuildTeam,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _RoundSection()),
                  ],
                )
              else ...[
                _MyTeamSection(
                  lineupSummary: lineupSummary,
                  onBuildTeam: onBuildTeam,
                ),
                const SizedBox(height: 16),
                _RoundSection(),
              ],
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                const Text(
                  '— pts',
                  style: TextStyle(
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
                  const Text(
                    '#—',
                    style: TextStyle(
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
  }
}

class _MyTeamSection extends StatelessWidget {
  const _MyTeamSection({this.lineupSummary, this.onBuildTeam});

  final LineupHomeSummary? lineupSummary;
  final VoidCallback? onBuildTeam;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Meu Time'),
        const SizedBox(height: 10),
        _MyTeamCard(
          lineupSummary: lineupSummary,
          onBuildTeam: onBuildTeam,
        ),
      ],
    );
  }
}

class _MyTeamCard extends StatelessWidget {
  const _MyTeamCard({this.lineupSummary, this.onBuildTeam});

  final LineupHomeSummary? lineupSummary;
  final VoidCallback? onBuildTeam;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardBg = Theme.of(context).brightness == Brightness.dark
        ? cs.surfaceContainerHighest
        : const Color(0xFFEEEEEE);
    final mountedSummary = lineupSummary?.isMounted == true
        ? lineupSummary
        : null;

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
                  mountedSummary?.teamName ?? 'Você ainda não montou seu time',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mountedSummary == null
                      ? 'Escolha 11 jogadores para começar'
                      : '${mountedSummary.selectedCount}/11 escalados • ${mountedSummary.formation}'
                          '${mountedSummary.captainName == null ? '' : ' • Cap: ${mountedSummary.captainName}'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onBuildTeam,
            child: Text(
              mountedSummary == null ? 'Montar' : 'Editar',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Rodada Atual'),
        SizedBox(height: 10),
        _RoundCard(),
      ],
    );
  }
}

class _RoundCard extends StatelessWidget {
  const _RoundCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardBg = Theme.of(context).brightness == Brightness.dark
        ? cs.surfaceContainerHighest
        : const Color(0xFFEEEEEE);

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
                  'Nenhuma rodada em andamento',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Os jogos da fase aparecerão aqui',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
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
