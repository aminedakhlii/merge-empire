/// Zero-based cell coordinate on the merge board.
class BoardPosition {
  const BoardPosition(this.column, this.row);

  final int column;
  final int row;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardPosition && column == other.column && row == other.row;

  @override
  int get hashCode => Object.hash(column, row);

  @override
  String toString() => 'BoardPosition($column, $row)';

  Map<String, dynamic> toJson() => {'c': column, 'r': row};

  factory BoardPosition.fromJson(Map<String, dynamic> json) => BoardPosition(
        json['c'] as int,
        json['r'] as int,
      );
}
