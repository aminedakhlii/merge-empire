import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/config/game_config.dart';
import '../game/game_controller.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider).game;
    final config = GameConfig.standard;

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Orders')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: game.orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = game.orders[index];
          final chain = config.chainById(order.chainId);
          final def = chain.levelDef(order.requiredLevel);
          final have = game.countObjects(
            chainId: order.chainId,
            level: order.requiredLevel,
          );
          final ready = have >= order.requiredQuantity;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MergeEmpireTheme.foam,
                  MergeEmpireTheme.cream,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ready
                    ? MergeEmpireTheme.leaf
                    : MergeEmpireTheme.roast.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Wants ${order.requiredQuantity}× ${def.displayName} (L${order.requiredLevel})',
                ),
                Text('Have $have / ${order.requiredQuantity}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '+${order.coinReward} coins · +${order.xpReward} XP',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: MergeEmpireTheme.roast,
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: ready
                          ? () => ref
                              .read(gameControllerProvider.notifier)
                              .completeOrder(order.instanceId)
                          : null,
                      child: const Text('Fulfill'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
