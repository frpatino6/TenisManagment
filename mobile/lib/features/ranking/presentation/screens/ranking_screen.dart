import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/ranking_providers.dart';
import '../widgets/ranking_podium.dart';
import '../widgets/ranking_tile.dart';
import '../widgets/my_position_bar.dart';
import '../../domain/models/user_ranking.dart';
import '../../../../core/widgets/empty_state_widget.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Rankings CourtHub'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFCCFF00),
          labelColor: const Color(0xFFCCFF00),
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Nivel (ELO)'),
            Tab(text: 'La Raza (Mensual)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RankingList(type: RankingType.elo),
          _RankingList(type: RankingType.race),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _tabController,
        builder: (context, child) {
          final type = _tabController.index == 0
              ? RankingType.elo
              : RankingType.race;
          final userRanking = ref.watch(currentUserRankingProvider(type));
          return MyPositionBar(userRanking: userRanking);
        },
      ),
    );
  }
}

class _RankingList extends ConsumerWidget {
  final RankingType type;

  const _RankingList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = type == RankingType.elo
        ? ref.watch(eloRankingProvider)
        : ref.watch(raceRankingProvider);

    return rankingAsync.when(
      data: (players) {
        if (players.isEmpty) {
          return const EmptyStateWidget(
            message: 'No hay datos de ranking disponibles.',
            icon: Icons.emoji_events_outlined,
          );
        }

        final top3 = players.where((p) => p.position <= 3).toList();
        final others = players.where((p) => p.position > 3).toList();

        return ListView.builder(
          itemCount: others.length + 1, // +1 para el podio
          itemBuilder: (context, index) {
            if (index == 0) {
              return RankingPodium(topPlayers: top3);
            }
            return RankingTile(player: others[index - 1]);
          },
        );
      },
      loading: () => const _RankingLoadingShimmer(),
      error: (error, _) => Center(
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}

class _RankingLoadingShimmer extends StatelessWidget {
  const _RankingLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: ListView.builder(
        itemCount: 8,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _PodiumShimmer(height: 100, size: 50),
                  _PodiumShimmer(height: 130, size: 70),
                  _PodiumShimmer(height: 80, size: 40),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PodiumShimmer extends StatelessWidget {
  final double height;
  final double size;

  const _PodiumShimmer({required this.height, required this.size});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Container(width: 40, height: 10, color: Colors.white),
        const SizedBox(height: 4),
        Container(width: 30, height: 10, color: Colors.white),
      ],
    );
  }
}
