/// Configurable object generator definition.
class GeneratorConfig {
  const GeneratorConfig({
    required this.id,
    required this.displayName,
    required this.chainId,
    required this.producedLevel,
    required this.productionIntervalMs,
    required this.maxStoredOutput,
    this.upgradeLevel = 1,
  });

  final String id;
  final String displayName;
  final String chainId;
  final int producedLevel;
  final int productionIntervalMs;
  final int maxStoredOutput;
  final int upgradeLevel;

  static const String basicCoffeeId = 'basic_coffee_generator';

  static const GeneratorConfig basicCoffee = GeneratorConfig(
    id: basicCoffeeId,
    displayName: 'Coffee Roaster',
    chainId: 'coffee',
    producedLevel: 1,
    productionIntervalMs: 3000,
    maxStoredOutput: 5,
  );
}
