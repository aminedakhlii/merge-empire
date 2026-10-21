class OrderInstance {
  const OrderInstance({
    required this.instanceId,
    required this.templateId,
    required this.customerName,
    required this.chainId,
    required this.requiredLevel,
    required this.requiredQuantity,
    required this.coinReward,
    required this.xpReward,
    this.claimed = false,
  });

  final String instanceId;
  final String templateId;
  final String customerName;
  final String chainId;
  final int requiredLevel;
  final int requiredQuantity;
  final int coinReward;
  final int xpReward;
  final bool claimed;

  OrderInstance copyWith({bool? claimed}) => OrderInstance(
        instanceId: instanceId,
        templateId: templateId,
        customerName: customerName,
        chainId: chainId,
        requiredLevel: requiredLevel,
        requiredQuantity: requiredQuantity,
        coinReward: coinReward,
        xpReward: xpReward,
        claimed: claimed ?? this.claimed,
      );

  Map<String, dynamic> toJson() => {
        'instanceId': instanceId,
        'templateId': templateId,
        'customerName': customerName,
        'chainId': chainId,
        'requiredLevel': requiredLevel,
        'requiredQuantity': requiredQuantity,
        'coinReward': coinReward,
        'xpReward': xpReward,
        'claimed': claimed,
      };

  factory OrderInstance.fromJson(Map<String, dynamic> json) => OrderInstance(
        instanceId: json['instanceId'] as String,
        templateId: json['templateId'] as String,
        customerName: json['customerName'] as String,
        chainId: json['chainId'] as String,
        requiredLevel: json['requiredLevel'] as int,
        requiredQuantity: json['requiredQuantity'] as int,
        coinReward: json['coinReward'] as int,
        xpReward: json['xpReward'] as int,
        claimed: json['claimed'] as bool? ?? false,
      );
}
