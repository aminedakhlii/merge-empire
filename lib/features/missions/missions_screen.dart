import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/config/game_config.dart';
import '../../core/models/mission_progress.dart';
import '../game/game_controller.dart';

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider).game;
    final config = GameConfig.standard;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Missions & Achievements'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Missions'),
              Tab(text: 'Achievements'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: game.missions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final m = game.missions[i];
                final def = config.missions.byId(m.missionId);
                final canClaim = m.status == MissionStatus.completed;
                return _ProgressCard(
                  title: def.description,
                  progressLabel: '${m.progress} / ${def.target}',
                  progress: def.target == 0 ? 0 : m.progress / def.target,
                  trailing: m.status == MissionStatus.claimed
                      ? const Text('Claimed')
                      : FilledButton(
                          onPressed: canClaim
                              ? () => ref
                                  .read(gameControllerProvider.notifier)
                                  .claimMission(m.missionId)
                              : null,
                          child: Text(canClaim ? 'Claim' : 'In progress'),
                        ),
                  subtitle: '+${def.coinReward} coins · +${def.xpReward} XP',
                );
              },
            ),
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: config.achievements.definitions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final def = config.achievements.definitions[i];
                final progress = game.achievements[def.key];
                final unlocked = progress?.unlocked ?? false;
                final claimed = progress?.claimed ?? false;
                return _ProgressCard(
                  title: def.title,
                  progressLabel: unlocked ? 'Unlocked' : 'Locked',
                  progress: unlocked ? 1 : 0,
                  subtitle: def.description,
                  trailing: claimed
                      ? const Text('Claimed')
                      : FilledButton(
                          onPressed: unlocked
                              ? () => ref
                                  .read(gameControllerProvider.notifier)
                                  .claimAchievement(def.key)
                              : null,
                          child: Text(unlocked ? 'Claim' : 'Locked'),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.progressLabel,
    required this.progress,
    required this.trailing,
    this.subtitle,
  });

  final String title;
  final String progressLabel;
  final double progress;
  final Widget trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MergeEmpireTheme.foam.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            color: MergeEmpireTheme.caramel,
            backgroundColor: MergeEmpireTheme.roast.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(progressLabel),
              const Spacer(),
              trailing,
            ],
          ),
        ],
      ),
    );
  }
}
