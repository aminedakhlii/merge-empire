import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../monetization/monetization_providers.dart';
import '../game/game_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider).game;
    final notifier = ref.read(gameControllerProvider.notifier);
    final purchasesConfig = ref.watch(purchasesConfigProvider);
    final adsRemoved = ref.watch(adsRemovedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Sound'),
            subtitle: const Text('Merge and UI sounds'),
            value: game.soundEnabled,
            onChanged: notifier.setSoundEnabled,
          ),
          SwitchListTile(
            title: const Text('Haptics'),
            value: game.hapticsEnabled,
            onChanged: notifier.setHapticsEnabled,
          ),
          const Divider(),
          ListTile(
            title: const Text('Privacy options'),
            subtitle: const Text(
              'Consent / UMP privacy form (ATT-ready when tracking is used)',
            ),
            onTap: () => notifier.openPrivacyOptions(),
          ),
          ListTile(
            title: const Text('Remove Ads'),
            subtitle: Text(
              adsRemoved
                  ? 'Ads removed'
                  : purchasesConfig.removeAdsEnabled
                      ? 'Purchase to remove banner & interstitial ads'
                      : 'IAP feature-flagged off — interface ready for Phase 4',
            ),
            onTap: adsRemoved ? null : () => notifier.purchaseRemoveAds(),
          ),
          const Divider(),
          const ListTile(
            title: Text('Privacy Policy / Terms / Support'),
            subtitle: Text('Owner URLs deferred — reserved for Phase 4'),
          ),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('Merge Empire Phase 3'),
          ),
          const ListTile(
            title: Text('Ad configuration'),
            subtitle: Text(
              'Using Google test ad unit IDs only. Production IDs must be '
              'owner-supplied in AdsConfig — never invent them.',
            ),
          ),
        ],
      ),
    );
  }
}
