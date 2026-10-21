/// Runtime state for one object generator.
class GeneratorState {
  const GeneratorState({
    required this.configId,
    required this.storedOutput,
    required this.lastTickMs,
    this.upgradeLevel = 1,
  });

  final String configId;
  final int storedOutput;
  final int lastTickMs;
  final int upgradeLevel;

  GeneratorState copyWith({
    String? configId,
    int? storedOutput,
    int? lastTickMs,
    int? upgradeLevel,
  }) =>
      GeneratorState(
        configId: configId ?? this.configId,
        storedOutput: storedOutput ?? this.storedOutput,
        lastTickMs: lastTickMs ?? this.lastTickMs,
        upgradeLevel: upgradeLevel ?? this.upgradeLevel,
      );

  Map<String, dynamic> toJson() => {
        'configId': configId,
        'storedOutput': storedOutput,
        'lastTickMs': lastTickMs,
        'upgradeLevel': upgradeLevel,
      };

  factory GeneratorState.fromJson(Map<String, dynamic> json) => GeneratorState(
        configId: json['configId'] as String,
        storedOutput: json['storedOutput'] as int,
        lastTickMs: json['lastTickMs'] as int,
        upgradeLevel: json['upgradeLevel'] as int? ?? 1,
      );
}
