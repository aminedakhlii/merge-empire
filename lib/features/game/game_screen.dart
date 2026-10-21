import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/config/game_config.dart';
import '../board/board_widget.dart';
import '../daily_challenges/daily_screen.dart';
import '../economy/sell_controls.dart';
import '../generators/generator_panel.dart';
import '../missions/missions_screen.dart';
import '../orders/orders_screen.dart';
import '../settings/settings_screen.dart';
import '../shop/shop_screen.dart';
import '../tutorial/tutorial_overlay.dart';
import 'game_controller.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.watch(gameControllerProvider);

    if (!ctrl.isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final game = ctrl.game;
    final shop = GameConfig.standard.shop.levelDef(game.shopLevel);
    final xpNeeded = GameConfig.standard.xp.xpToNextLevel(game.playerLevel);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF8EF),
              Color(0xFFF0E0C8),
              Color(0xFFE2C49A),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      coins: game.coins,
                      playerLevel: game.playerLevel,
                      playerXp: game.playerXp,
                      xpNeeded: xpNeeded,
                      shopName: shop.name,
                      decorLabel: shop.decorLabel,
                    ),
                    const SizedBox(height: 6),
                    const _NavRow(),
                    const SizedBox(height: 8),
                    const GeneratorPanel(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: MergeEmpireTheme.espresso.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: MergeEmpireTheme.roast.withValues(alpha: 0.15),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: MergeEmpireTheme.espresso.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: MergeBoard(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SellControls(),
                    if (ctrl.statusMessage != null) ...[
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          ctrl.statusMessage!,
                          key: ValueKey(ctrl.statusMessage),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: MergeEmpireTheme.roast,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              const TutorialOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.coins,
    required this.playerLevel,
    required this.playerXp,
    required this.xpNeeded,
    required this.shopName,
    required this.decorLabel,
  });

  final int coins;
  final int playerLevel;
  final int playerXp;
  final int xpNeeded;
  final String shopName;
  final String decorLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merge Empire',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: MergeEmpireTheme.espresso,
                        ),
                  ),
                  Text(
                    '$shopName · $decorLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MergeEmpireTheme.roast,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: MergeEmpireTheme.coin.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: MergeEmpireTheme.coin.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: MergeEmpireTheme.coin,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$coins',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              'Lv $playerLevel',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: xpNeeded == 0 ? 0 : (playerXp / xpNeeded).clamp(0, 1),
                  minHeight: 8,
                  color: MergeEmpireTheme.leaf,
                  backgroundColor: MergeEmpireTheme.roast.withValues(alpha: 0.15),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$playerXp/$xpNeeded XP',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow();

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, IconData icon, Widget page) {
      return ActionChip(
        avatar: Icon(icon, size: 16, color: MergeEmpireTheme.espresso),
        label: Text(label),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => page),
          );
        },
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('Orders', Icons.receipt_long, const OrdersScreen()),
          const SizedBox(width: 6),
          chip('Shop', Icons.storefront, const ShopScreen()),
          const SizedBox(width: 6),
          chip('Missions', Icons.flag, const MissionsScreen()),
          const SizedBox(width: 6),
          chip('Daily', Icons.today, const DailyScreen()),
          const SizedBox(width: 6),
          chip('Settings', Icons.settings, const SettingsScreen()),
        ],
      ),
    );
  }
}
