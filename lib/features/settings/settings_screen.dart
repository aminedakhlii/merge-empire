import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider).game;
    final notifier = ref.read(gameControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Sound'),
            subtitle: const Text('Merge and UI sounds (Phase 2 toggle; SFX assets later)'),
            value: game.soundEnabled,
            onChanged: notifier.setSoundEnabled,
          ),
          SwitchListTile(
            title: const Text('Haptics'),
            value: game.hapticsEnabled,
            onChanged: notifier.setHapticsEnabled,
          ),
          const Divider(),
          const ListTile(
            title: Text('Privacy / Terms / Support'),
            subtitle: Text('Owner URLs deferred — screens reserved for Phase 4'),
          ),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('Merge Empire Phase 2'),
          ),
        ],
      ),
    );
  }
}
