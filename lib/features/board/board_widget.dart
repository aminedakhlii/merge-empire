import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/board_position.dart';
import '../game/game_controller.dart';
import 'cell_widget.dart';

class MergeBoard extends ConsumerWidget {
  const MergeBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.watch(gameControllerProvider);
    final game = ctrl.game;
    final selected = ctrl.selected;
    final selectedObject =
        selected == null ? null : game.objectAt(selected);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 4.0;
        final cellW =
            (constraints.maxWidth - gap * (game.columns - 1)) / game.columns;
        final cellH =
            (constraints.maxHeight - gap * (game.rows - 1)) / game.rows;
        final size = cellW < cellH ? cellW : cellH;
        final boardWidth = size * game.columns + gap * (game.columns - 1);
        final boardHeight = size * game.rows + gap * (game.rows - 1);

        return Center(
          child: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: Column(
              children: [
                for (var r = 0; r < game.rows; r++) ...[
                  if (r > 0) SizedBox(height: gap),
                  Expanded(
                    child: Row(
                      children: [
                        for (var c = 0; c < game.columns; c++) ...[
                          if (c > 0) SizedBox(width: gap),
                          Expanded(
                            child: Builder(
                              builder: (_) {
                                final pos = BoardPosition(c, r);
                                final object = game.objectAt(pos);
                                final mergeHint = selectedObject != null &&
                                    object != null &&
                                    selected != pos &&
                                    selectedObject.canMergeWith(object);
                                return BoardCell(
                                  position: pos,
                                  object: object,
                                  selected: selected == pos,
                                  mergeHint: mergeHint,
                                  onTap: () => ref
                                      .read(gameControllerProvider.notifier)
                                      .selectCell(pos),
                                  onAcceptDrop: (from) => ref
                                      .read(gameControllerProvider.notifier)
                                      .moveOrMerge(from, pos),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
