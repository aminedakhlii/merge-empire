import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/production_config.dart';
import '../../monetization/monetization_providers.dart';
import '../game/game_controller.dart';
import '../legal/legal_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider).game;
    final notifier = ref.read(gameControllerProvider.notifier);
    final purchasesConfig = ref.watch(purchasesConfigProvider);
    final adsRemoved = ref.watch(adsRemovedProvider);
    const production = ProductionConfig.unconfigured;

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
            title: const Text('Privacy Policy'),
            subtitle: Text(
              production.hasPrivacyPolicyUrl
                  ? production.privacyPolicyUrl
                  : 'PLACEHOLDER — owner must supply URL',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LegalScreen(kind: LegalDocKind.privacy),
              ),
            ),
          ),
          ListTile(
            title: const Text('Terms of Service'),
            subtitle: Text(
              production.hasTermsUrl
                  ? production.termsOfServiceUrl
                  : 'PLACEHOLDER — owner must supply URL',
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LegalScreen(kind: LegalDocKind.terms),
              ),
            ),
          ),
          ListTile(
            title: const Text('Support'),
            subtitle: Text(
              production.hasSupportContact
                  ? production.supportEmail
                  : 'OWNER: set ProductionConfig.supportEmail',
            ),
          ),
          ListTile(
            title: const Text('Remove Ads'),
            subtitle: Text(
              adsRemoved
                  ? 'Ads removed'
                  : purchasesConfig.removeAdsEnabled
                      ? 'Purchase to remove banner & interstitial ads'
                      : 'IAP feature-flagged off — enable after owner pricing',
            ),
            onTap: adsRemoved ? null : () => notifier.purchaseRemoveAds(),
          ),
          const Divider(),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('Merge Empire Phase 4 · 1.0.0+1'),
          ),
          const ListTile(
            title: Text('Ad configuration'),
            subtitle: Text(
              'Using Google test ad unit IDs only. Production IDs must be '
              'owner-supplied in ProductionConfig / AdsConfig — never invent them.',
            ),
          ),
        ],
      ),
    );
  }
}
