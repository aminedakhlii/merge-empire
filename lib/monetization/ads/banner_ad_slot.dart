import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../monetization_providers.dart';

/// Reserved banner layout below game controls — never overlays the board.
/// Renders empty space when no ad is available (not a fake creative).
class BannerAdSlot extends ConsumerWidget {
  const BannerAdSlot({super.key, this.height = 50});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsRemoved = ref.watch(adsRemovedProvider);
    final consentOk = ref.watch(consentAllowsAdsProvider);
    if (adsRemoved || !consentOk) {
      return SizedBox(height: height);
    }

    final ads = ref.watch(adServiceProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final banner = ads.bannerAd(maxWidth: constraints.maxWidth);
        return SizedBox(
          height: height,
          width: double.infinity,
          child: banner ??
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: MergeEmpireTheme.roast.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                child: const SizedBox.expand(),
              ),
        );
      },
    );
  }
}
