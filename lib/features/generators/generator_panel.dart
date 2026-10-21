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
    final logic = ref.read(gameControllerProvider.notifier).logic;
    final gens = ctrl.game.generators;
    final coffee =
        gens.where((g) => g.configId == GeneratorConfig.basicCoffeeId);
    final pastry = gens.where((g) => g.configId == GeneratorConfig.pastryOvenId);
    final stored = coffee.isEmpty ? 0 : coffee.first.storedOutput;
    final max = logic.generatorCapacity(ctrl.game);
    final ready = stored > 0 && !ctrl.game.isFull;
    final pastryStored = pastry.isEmpty ? 0 : pastry.first.storedOutput;
    final pastryReady =
        pastry.isNotEmpty && pastryStored > 0 && !ctrl.game.isFull;

    return Column(
      children: [
        _GeneratorRow(
          title: GeneratorConfig.basicCoffee.displayName,
          icon: Icons.coffee_maker,
          readyLabel: 'Ready: $stored / $max',
          enabled: ready,
          onGenerate: () => ref
              .read(gameControllerProvider.notifier)
              .collectFromGenerator(),
        ),
        if (pastry.isNotEmpty) ...[
          const SizedBox(height: 8),
          _GeneratorRow(
            title: GeneratorConfig.pastryOven.displayName,
            icon: Icons.bakery_dining,
            readyLabel:
                'Ready: $pastryStored / ${GeneratorConfig.pastryOven.maxStoredOutput}',
            enabled: pastryReady,
            buttonLabel: 'Bake',
            onGenerate: () => ref
                .read(gameControllerProvider.notifier)
                .collectFromGenerator(
                  generatorId: GeneratorConfig.pastryOvenId,
                ),
          ),
        ],
      ],
    );
  }
}

class _GeneratorRow extends StatelessWidget {
  const _GeneratorRow({
    required this.title,
    required this.icon,
    required this.readyLabel,
    required this.enabled,
    required this.onGenerate,
    this.buttonLabel = 'Generate',
  });

  final String title;
  final IconData icon;
  final String readyLabel;
  final bool enabled;
  final VoidCallback onGenerate;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: MergeEmpireTheme.roast,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(readyLabel, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          FilledButton(
            onPressed: enabled ? onGenerate : null,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
