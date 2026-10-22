import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../game/game_controller.dart';

class SellControls extends ConsumerWidget {
  const SellControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gameControllerProvider);
    final notifier = ref.read(gameControllerProvider.notifier);
    final value = notifier.selectedSaleValue();
    final canSell = value != null;

    return Row(
      children: [
        Expanded(
          child: Text(
            canSell
                ? 'Sell selected for $value coins'
                : 'Tap an object, then sell it',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        FilledButton.tonal(
          onPressed: !canSell
              ? null
              : () async {
                  if (notifier.selectedIsValuable()) {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sell valuable item?'),
                        content: Text('This sells for $value coins.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sell'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                  }
                  await notifier.sellSelected();
                },
          style: FilledButton.styleFrom(
            foregroundColor: MergeEmpireTheme.espresso,
          ),
          child: const Text('Sell'),
        ),
      ],
    );
  }
}
