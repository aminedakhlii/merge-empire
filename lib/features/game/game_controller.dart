import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/game_config.dart';
import '../../core/models/board_position.dart';
import '../../core/models/game_state.dart';
import '../persistence/save_service.dart';
import 'game_logic.dart';

class GameControllerState {
  const GameControllerState({
    required this.game,
    this.selected,
    this.statusMessage,
    this.isReady = false,
  });

  final GameState game;
  final BoardPosition? selected;
  final String? statusMessage;
  final bool isReady;

  GameControllerState copyWith({
    GameState? game,
    BoardPosition? selected,
    String? statusMessage,
    bool clearSelected = false,
    bool clearStatus = false,
    bool? isReady,
  }) =>
      GameControllerState(
        game: game ?? this.game,
        selected: clearSelected ? null : (selected ?? this.selected),
        statusMessage:
            clearStatus ? null : (statusMessage ?? this.statusMessage),
        isReady: isReady ?? this.isReady,
      );
}

class GameController extends Notifier<GameControllerState> {
  GameController({
    GameLogic? logic,
    SaveService? saveService,
    this.autoSave = true,
    this.tickInterval = const Duration(seconds: 1),
  })  : _logicOverride = logic,
        _saveOverride = saveService;

  final GameLogic? _logicOverride;
  final SaveService? _saveOverride;
  final bool autoSave;
  final Duration tickInterval;

  late GameLogic _logic;
  late SaveService _save;
  Timer? _tickTimer;

  @override
  GameControllerState build() {
    _logic = _logicOverride ?? GameLogic(config: GameConfig.standard);
    _save = _saveOverride ?? SharedPreferencesSaveService();

    final initial = _logic.createInitialState();
    Future.microtask(_bootstrap);

    ref.onDispose(() {
      _tickTimer?.cancel();
    });

    return GameControllerState(game: initial, isReady: false);
  }

  Future<void> _bootstrap() async {
    final loaded = await _save.load();
    var game = loaded ?? _logic.createInitialState();
    // Ensure Phase 1 saves migrated to v2 get seed missions/orders if empty.
    if (game.missions.isEmpty || game.achievements.isEmpty) {
      final fresh = _logic.createInitialState(nowMs: game.updatedAtMs);
      game = game.copyWith(
        missions: game.missions.isEmpty ? fresh.missions : game.missions,
        achievements:
            game.achievements.isEmpty ? fresh.achievements : game.achievements,
        orders: game.orders.isEmpty ? fresh.orders : game.orders,
        daily: game.daily.dayKey.isEmpty ? fresh.daily : game.daily,
      );
    }
    final ticked = _logic.tickGenerators(game);
    state = GameControllerState(game: ticked, isReady: true);
    await _persist();
    _startTicker();
  }

  void _startTicker() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(tickInterval, (_) {
      final next = _logic.tickGenerators(state.game);
      if (next.generators != state.game.generators ||
          next.daily.dayKey != state.game.daily.dayKey) {
        state = state.copyWith(game: next);
        unawaited(_persist());
      } else {
        state = state.copyWith(game: next);
      }
    });
  }

  Future<void> _persist() async {
    if (!autoSave) return;
    await _save.save(state.game);
  }

  Future<void> _apply(ActionResult result) async {
    switch (result) {
      case ActionSuccess(:final state, :final message):
        this.state = GameControllerState(
          game: state,
          statusMessage: message,
          isReady: true,
        );
        await _persist();
      case ActionFailure(:final reason):
        state = state.copyWith(statusMessage: reason);
    }
  }

  void selectCell(BoardPosition pos) {
    final object = state.game.objectAt(pos);
    if (object == null) {
      state = state.copyWith(clearSelected: true, clearStatus: true);
      return;
    }
    if (state.selected == pos) {
      state = state.copyWith(clearSelected: true);
      return;
    }
    state = state.copyWith(selected: pos, clearStatus: true);
  }

  Future<void> collectFromGenerator({
    String generatorId = 'basic_coffee_generator',
  }) async {
    await _apply(
      _logic.collectFromGenerator(state.game, generatorId: generatorId),
    );
  }

  Future<void> moveOrMerge(BoardPosition from, BoardPosition to) async {
    await _apply(_logic.moveOrMerge(state.game, from, to));
  }

  Future<void> sellSelected() async {
    final selected = state.selected;
    if (selected == null) {
      state = state.copyWith(statusMessage: 'Select an object to sell');
      return;
    }
    await _apply(_logic.sellObject(state.game, selected));
  }

  Future<void> sellAt(BoardPosition pos) async {
    await _apply(_logic.sellObject(state.game, pos));
  }

  Future<void> completeOrder(String instanceId) async {
    await _apply(_logic.completeOrder(state.game, instanceId));
  }

  Future<void> upgradeShop() async {
    await _apply(_logic.upgradeShop(state.game));
  }

  Future<void> claimMission(String missionId) async {
    await _apply(_logic.claimMission(state.game, missionId));
  }

  Future<void> claimAchievement(String achievementId) async {
    await _apply(_logic.claimAchievement(state.game, achievementId));
  }

  Future<void> claimDaily() async {
    await _apply(_logic.claimDaily(state.game));
  }

  Future<void> dismissTutorial() async {
    await _apply(_logic.dismissTutorial(state.game));
  }

  Future<void> advanceTutorial() async {
    await _apply(_logic.advanceTutorialManual(state.game));
  }

  Future<void> setSoundEnabled(bool enabled) async {
    state = state.copyWith(game: state.game.copyWith(soundEnabled: enabled));
    await _persist();
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    state = state.copyWith(game: state.game.copyWith(hapticsEnabled: enabled));
    await _persist();
  }

  int? selectedSaleValue() {
    final selected = state.selected;
    if (selected == null) return null;
    final object = state.game.objectAt(selected);
    if (object == null) return null;
    return _logic.saleValue(object);
  }

  bool selectedIsValuable() {
    final selected = state.selected;
    if (selected == null) return false;
    final object = state.game.objectAt(selected);
    if (object == null) return false;
    return _logic.isValuableSale(object);
  }

  GameLogic get logic => _logic;
}

final gameControllerProvider =
    NotifierProvider<GameController, GameControllerState>(GameController.new);
