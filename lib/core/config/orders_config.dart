/// Template for a customer order. Runtime instances copy rewards once.
class OrderTemplate {
  const OrderTemplate({
    required this.id,
    required this.customerName,
    required this.chainId,
    required this.requiredLevel,
    required this.requiredQuantity,
    required this.coinReward,
    required this.xpReward,
    required this.minShopLevel,
    this.difficulty = 1,
  });

  final String id;
  final String customerName;
  final String chainId;
  final int requiredLevel;
  final int requiredQuantity;
  final int coinReward;
  final int xpReward;
  final int minShopLevel;
  final int difficulty;
}

class OrdersConfig {
  const OrdersConfig({
    this.activeSlots = 3,
    required this.templates,
  });

  final int activeSlots;
  final List<OrderTemplate> templates;

  /// Templates the player can receive given unlocks.
  List<OrderTemplate> attainable({
    required int shopLevel,
    required int maxObjectLevelSeen,
  }) {
    return templates
        .where(
          (t) =>
              t.minShopLevel <= shopLevel &&
              t.requiredLevel <= maxObjectLevelSeen,
        )
        .toList();
  }

  static final OrdersConfig standard = OrdersConfig(
    templates: const [
      OrderTemplate(
        id: 'ord_bean_1',
        customerName: 'Maya',
        chainId: 'coffee',
        requiredLevel: 1,
        requiredQuantity: 2,
        coinReward: 12,
        xpReward: 8,
        minShopLevel: 1,
      ),
      OrderTemplate(
        id: 'ord_grounds_1',
        customerName: 'Luis',
        chainId: 'coffee',
        requiredLevel: 2,
        requiredQuantity: 1,
        coinReward: 18,
        xpReward: 10,
        minShopLevel: 1,
      ),
      OrderTemplate(
        id: 'ord_filter_1',
        customerName: 'Ava',
        chainId: 'coffee',
        requiredLevel: 3,
        requiredQuantity: 1,
        coinReward: 28,
        xpReward: 14,
        minShopLevel: 1,
      ),
      OrderTemplate(
        id: 'ord_cup_1',
        customerName: 'Noah',
        chainId: 'coffee',
        requiredLevel: 4,
        requiredQuantity: 1,
        coinReward: 40,
        xpReward: 18,
        minShopLevel: 2,
      ),
      OrderTemplate(
        id: 'ord_espresso_1',
        customerName: 'Priya',
        chainId: 'coffee',
        requiredLevel: 5,
        requiredQuantity: 1,
        coinReward: 60,
        xpReward: 24,
        minShopLevel: 3,
      ),
      OrderTemplate(
        id: 'ord_latte_1',
        customerName: 'Ken',
        chainId: 'coffee',
        requiredLevel: 7,
        requiredQuantity: 1,
        coinReward: 120,
        xpReward: 40,
        minShopLevel: 5,
      ),
      OrderTemplate(
        id: 'ord_pastry_1',
        customerName: 'Sofia',
        chainId: 'pastry',
        requiredLevel: 1,
        requiredQuantity: 2,
        coinReward: 22,
        xpReward: 12,
        minShopLevel: 6,
      ),
      OrderTemplate(
        id: 'ord_pastry_2',
        customerName: 'Omar',
        chainId: 'pastry',
        requiredLevel: 3,
        requiredQuantity: 1,
        coinReward: 55,
        xpReward: 22,
        minShopLevel: 6,
      ),
    ],
  );
}
