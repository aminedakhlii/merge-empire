enum TutorialStep {
  welcome,
  generate,
  merge,
  sellOrOrder,
  complete,
}

class TutorialConfig {
  const TutorialConfig({
    this.enabled = true,
  });

  final bool enabled;

  String messageFor(TutorialStep step) {
    switch (step) {
      case TutorialStep.welcome:
        return 'Welcome to your neighborhood coffee shop! Let’s brew the basics.';
      case TutorialStep.generate:
        return 'Tap Generate to place a Coffee Bean on the board.';
      case TutorialStep.merge:
        return 'Drag two matching items together to merge into a higher level.';
      case TutorialStep.sellOrOrder:
        return 'Sell an item for coins, or fill a customer order for bigger rewards.';
      case TutorialStep.complete:
        return 'You’re ready — grow the shop, complete missions, and come back daily!';
    }
  }

  static const TutorialConfig standard = TutorialConfig();
}
