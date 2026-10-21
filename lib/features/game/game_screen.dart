import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../board/board_widget.dart';
import '../economy/sell_controls.dart';
import '../generators/generator_panel.dart';
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

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF8EF),
              Color(0xFFF0E0C8),
              Color(0xFFE8D2B0),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(coins: ctrl.game.coins),
                const SizedBox(height: 8),
                const GeneratorPanel(),
                const SizedBox(height: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: MergeEmpireTheme.espresso.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: MergeBoard(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const SellControls(),
                if (ctrl.statusMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    ctrl.statusMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MergeEmpireTheme.roast,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                'Neighborhood Coffee Shop',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MergeEmpireTheme.roast,
                    ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: MergeEmpireTheme.coin.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: MergeEmpireTheme.coin.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.monetization_on, color: MergeEmpireTheme.coin, size: 20),
              const SizedBox(width: 6),
              Text(
                '$coins',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
