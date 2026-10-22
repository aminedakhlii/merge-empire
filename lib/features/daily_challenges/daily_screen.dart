import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/config/daily_config.dart';
import '../../core/config/game_config.dart';
import '../game/game_controller.dart';

class DailyScreen extends ConsumerWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider).game;
    final config = GameConfig.standard;
    final daily = game.daily;
    DailyChallengeDef def = config.daily.pool.first;
    for (final d in config.daily.pool) {
      if (d.id == daily.challengeId) {
        def = d;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Challenge')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MergeEmpireTheme.caramel.withValues(alpha: 0.35),
                    MergeEmpireTheme.foam,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today · ${daily.dayKey}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    def.description,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: daily.target == 0
                        ? 0
                        : (daily.progress / daily.target).clamp(0, 1),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(8),
                    color: MergeEmpireTheme.roast,
                    backgroundColor:
                        MergeEmpireTheme.espresso.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 8),
                  Text('${daily.progress} / ${daily.target}'),
                  const SizedBox(height: 8),
                  Text(
                    'Streak: ${daily.activityStreak} day(s) · Active days: ${daily.uniqueActiveDays}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: daily.isComplete && !daily.claimed
                  ? () =>
                      ref.read(gameControllerProvider.notifier).claimDaily()
                  : null,
              child: Text(
                daily.claimed
                    ? 'Already claimed'
                    : daily.isComplete
                        ? 'Claim reward'
                        : 'Keep playing',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Offline clock notes',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Daily challenges use the device local calendar day. '
              'If the clock jumps backward, progress is kept (not reset). '
              'Large forward jumps reset the activity streak. '
              'There is no server authority — clock changes can still be abused.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
