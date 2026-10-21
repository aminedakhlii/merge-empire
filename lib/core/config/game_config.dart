import 'achievements_config.dart';
import 'ads_config.dart';
import 'board_config.dart';
import 'chain_config.dart';
import 'daily_config.dart';
import 'economy_config.dart';
import 'generator_config.dart';
import 'missions_config.dart';
import 'orders_config.dart';
import 'purchases_config.dart';
import 'shop_config.dart';
import 'tutorial_config.dart';
import 'xp_config.dart';

/// Root game balancing / content config.
class GameConfig {
  GameConfig({
    this.board = BoardConfig.standard,
    this.economy = EconomyConfig.standard,
    ChainConfig? coffeeChain,
    ChainConfig? pastryChain,
    this.starterGenerator = GeneratorConfig.basicCoffee,
    this.xp = XpConfig.standard,
    ShopConfig? shop,
    OrdersConfig? orders,
    this.missions = MissionsConfig.standard,
    this.achievements = AchievementsConfig.standard,
    this.daily = DailyConfig.standard,
    this.tutorial = TutorialConfig.standard,
    this.ads = AdsConfig.standard,
    this.purchases = PurchasesConfig.standard,
    this.pastryUnlockShopLevel = 6,
  })  : coffeeChain = coffeeChain ?? ChainConfig.coffee,
        pastryChain = pastryChain ?? ChainConfig.pastry,
        shop = shop ?? ShopConfig.neighborhood,
        orders = orders ?? OrdersConfig.standard;

  final BoardConfig board;
  final EconomyConfig economy;
  final ChainConfig coffeeChain;
  final ChainConfig pastryChain;
  final GeneratorConfig starterGenerator;
  final XpConfig xp;
  final ShopConfig shop;
  final OrdersConfig orders;
  final MissionsConfig missions;
  final AchievementsConfig achievements;
  final DailyConfig daily;
  final TutorialConfig tutorial;
  final AdsConfig ads;
  final PurchasesConfig purchases;
  final int pastryUnlockShopLevel;

  ChainConfig chainById(String id) {
    if (id == coffeeChain.id) return coffeeChain;
    if (id == pastryChain.id) return pastryChain;
    return ChainConfig.byId(id);
  }

  /// Phase 1-compatible alias (includes Phase 2 configs for forward saves).
  static final GameConfig phase1 = GameConfig();

  static final GameConfig standard = GameConfig();
}
