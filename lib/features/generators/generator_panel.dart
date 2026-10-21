import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/config/generator_config.dart';
import '../game/game_controller.dart';

class GeneratorPanel extends ConsumerWidget {
  const GeneratorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.watch(gameControllerProvider);
    final gens = ctrl.game.generators;
    final gen = gens.where((g) => g.configId == GeneratorConfig.basicCoffeeId);
    final stored = gen.isEmpty ? 0 : gen.first.storedOutput;
    final max = GeneratorConfig.basicCoffee.maxStoredOutput;
    final ready = stored > 0 && !ctrl.game.isFull;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MergeEmpireTheme.roast.withValues(alpha: 0.12),
            MergeEmpireTheme.caramel.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: MergeEmpireTheme.roast,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.coffee_maker, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  GeneratorConfig.basicCoffee.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'Ready: $stored / $max',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: ready
                ? () => ref
                    .read(gameControllerProvider.notifier)
                    .collectFromGenerator()
                : null,
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}
