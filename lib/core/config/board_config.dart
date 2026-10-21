/// Configurable merge-board dimensions. Do not hard-code sizes elsewhere.
class BoardConfig {
  const BoardConfig({
    this.columns = 7,
    this.rows = 9,
  });

  final int columns;
  final int rows;

  int get cellCount => columns * rows;

  static const BoardConfig standard = BoardConfig();
}
