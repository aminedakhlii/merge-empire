import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/config/game_config.dart';
import '../game/game_controller.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider).game;
    final config = GameConfig.standard;
    final current = config.shop.levelDef(game.shopLevel);
    final canUpgrade = game.shopLevel < config.shop.maxLevel;
    final next = canUpgrade ? config.shop.levelDef(game.shopLevel + 1) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Coffee Shop')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF5C3A21),
                  Color(0xFF8B5E3C),
                  Color(0xFFB8793A),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Level ${current.level} · ${current.decorLabel}',
                  style: const TextStyle(color: Color(0xFFFFF8EF)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Roaster: ${current.generatorIntervalMs}ms · capacity ${current.generatorCapacity}',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  'Max merge level: ${current.unlockMaxObjectLevel}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All shop levels',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          for (final level in config.shop.levels)
            ListTile(
              leading: Icon(
                level.level <= game.shopLevel
                    ? Icons.check_circle
                    : Icons.lock_outline,
                color: level.level <= game.shopLevel
                    ? MergeEmpireTheme.leaf
                    : MergeEmpireTheme.roast,
              ),
              title: Text('L${level.level} ${level.name}'),
              subtitle: Text(level.decorLabel),
              trailing: level.level == game.shopLevel
                  ? const Text('Current',
                      style: TextStyle(fontWeight: FontWeight.w700))
                  : null,
            ),
          const SizedBox(height: 12),
          if (next != null)
            FilledButton(
              onPressed: () =>
                  ref.read(gameControllerProvider.notifier).upgradeShop(),
              child: Text(
                'Upgrade to ${next.name} — ${next.cost} coins'
                '${game.playerLevel < next.minPlayerLevel ? ' (need player Lv${next.minPlayerLevel})' : ''}',
              ),
            )
          else
            const Text('Shop fully upgraded — Empire Flagship!'),
        ],
      ),
    );
  }
}
