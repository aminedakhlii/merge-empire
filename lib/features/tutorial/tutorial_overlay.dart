import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/config/game_config.dart';
import '../../core/config/tutorial_config.dart';
import '../game/game_controller.dart';

class TutorialOverlay extends ConsumerWidget {
  const TutorialOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider).game;
    if (game.tutorialCompleted || game.tutorialStep == TutorialStep.complete) {
      return const SizedBox.shrink();
    }

    final message = GameConfig.standard.tutorial.messageFor(game.tutorialStep);

    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        color: MergeEmpireTheme.espresso,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quick start',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: MergeEmpireTheme.caramel,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: const TextStyle(color: Colors.white, height: 1.35),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton(
                    onPressed: () => ref
                        .read(gameControllerProvider.notifier)
                        .dismissTutorial(),
                    child: const Text('Skip', style: TextStyle(color: Colors.white70)),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: MergeEmpireTheme.caramel,
                      foregroundColor: MergeEmpireTheme.espresso,
                    ),
                    onPressed: () => ref
                        .read(gameControllerProvider.notifier)
                        .advanceTutorial(),
                    child: Text(
                      game.tutorialStep == TutorialStep.sellOrOrder
                          ? 'Done'
                          : 'Next',
                    ),
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
