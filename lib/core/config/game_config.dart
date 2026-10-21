import 'board_config.dart';
import 'chain_config.dart';
import 'economy_config.dart';
import 'generator_config.dart';

/// Root game balancing / content config for Phase 1.
class GameConfig {
  GameConfig({
    this.board = BoardConfig.standard,
    this.economy = EconomyConfig.standard,
    ChainConfig? coffeeChain,
    this.starterGenerator = GeneratorConfig.basicCoffee,
  }) : coffeeChain = coffeeChain ?? ChainConfig.coffee;

  final BoardConfig board;
  final EconomyConfig economy;
  final ChainConfig coffeeChain;
  final GeneratorConfig starterGenerator;

  static final GameConfig phase1 = GameConfig();
}
