import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merge_empire/app/app.dart';
import 'package:merge_empire/core/config/game_config.dart';
import 'package:merge_empire/features/game/game_controller.dart';
import 'package:merge_empire/features/game/game_logic.dart';
import 'package:merge_empire/features/persistence/save_service.dart';

void main() {
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
              tickInterval: const Duration(hours: 1),
            ),
          ),
        ],
        child: const MergeEmpireApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Merge Empire'), findsOneWidget);
    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('0'), findsOneWidget); // starting coins
  });
}
