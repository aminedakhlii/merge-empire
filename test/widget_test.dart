import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merge_empire/consent/consent_service.dart';
import 'package:merge_empire/core/config/ads_config.dart';
import 'package:merge_empire/core/config/game_config.dart';
import 'package:merge_empire/features/analytics/analytics_service.dart';
import 'package:merge_empire/features/game/game_controller.dart';
import 'package:merge_empire/features/game/game_logic.dart';
import 'package:merge_empire/features/game/game_screen.dart';
import 'package:merge_empire/features/persistence/save_service.dart';
import 'package:merge_empire/features/purchases/purchases_service.dart';
import 'package:merge_empire/features/splash/splash_screen.dart';
import 'package:merge_empire/monetization/ads/frequency_controller.dart';
import 'package:merge_empire/monetization/ads/mock_ad_service.dart';

void main() {
  testWidgets('splash shows brand', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(hold: Duration(days: 1)),
      ),
    );
    await tester.pump();
    expect(find.text('Merge Empire'), findsOneWidget);
    expect(find.text('Neighborhood Coffee Shop'), findsOneWidget);
  });

  testWidgets('game screen shows brand, generator, and coins', (tester) async {
    final logic = GameLogic(config: GameConfig.phase1, clockMs: () => 1);
    final save = InMemorySaveService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameControllerProvider.overrideWith(
            () => GameController(
              logic: logic,
              saveService: save,
              adService: MockAdService(),
              analytics: MockAnalyticsService(),
              consent: MockConsentService(),
              purchases: MockPurchasesService(),
              frequency: const AdFrequencyController(AdsConfig.standard),
              tickInterval: const Duration(hours: 1),
            ),
          ),
        ],
        child: const MaterialApp(home: GameScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Merge Empire'), findsOneWidget);
    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}
