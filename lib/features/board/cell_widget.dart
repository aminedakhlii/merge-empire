import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/config/chain_config.dart';
import '../../core/models/board_position.dart';
import '../../core/models/game_object.dart';

class BoardCell extends StatelessWidget {
  const BoardCell({
    super.key,
    required this.position,
    required this.object,
    required this.selected,
    required this.mergeHint,
    required this.onTap,
    required this.onAcceptDrop,
    this.onDragStarted,
    this.onDragEnd,
  });

  final BoardPosition position;
  final GameObject? object;
  final bool selected;
  final bool mergeHint;
  final VoidCallback onTap;
  final void Function(BoardPosition from) onAcceptDrop;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

  @override
  Widget build(BuildContext context) {
    return DragTarget<BoardPosition>(
      onWillAcceptWithDetails: (details) => details.data != position,
      onAcceptWithDetails: (details) => onAcceptDrop(details.data),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: hovering
                  ? MergeEmpireTheme.caramel.withValues(alpha: 0.35)
                  : MergeEmpireTheme.foam.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? MergeEmpireTheme.caramel
                    : mergeHint
                        ? MergeEmpireTheme.leaf
                        : MergeEmpireTheme.roast.withValues(alpha: 0.2),
                width: selected || mergeHint ? 2.5 : 1,
              ),
            ),
            child: object == null
                ? const SizedBox.expand()
                : _DraggableObject(
                    position: position,
                    object: object!,
                    selected: selected,
                    onDragStarted: onDragStarted,
                    onDragEnd: onDragEnd,
                  ),
          ),
        );
      },
    );
  }
}

class _DraggableObject extends StatelessWidget {
  const _DraggableObject({
    required this.position,
    required this.object,
    required this.selected,
    this.onDragStarted,
    this.onDragEnd,
  });

  final BoardPosition position;
  final GameObject object;
  final bool selected;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

  @override
  Widget build(BuildContext context) {
    final chain = ChainConfig.byId(object.chainId);
    final def = chain.levelDef(object.level);
    final color = MergeEmpireTheme.levelColor(
      object.level,
      chainId: object.chainId,
    );

    final child = _ObjectTile(
      label: def.shortLabel,
      level: object.level,
      color: color,
      selected: selected,
    );

    return Draggable<BoardPosition>(
      data: position,
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnd?.call(),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Opacity(opacity: 0.9, child: child),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: child),
      child: child,
    );
  }
}

class _ObjectTile extends StatelessWidget {
  const _ObjectTile({
    required this.label,
    required this.level,
    required this.color,
    required this.selected,
  });

  final String label;
  final int level;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.95),
                color.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: MergeEmpireTheme.espresso.withValues(alpha: 0.18),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'L$level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
