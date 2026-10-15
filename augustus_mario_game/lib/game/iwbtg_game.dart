import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'game_constants.dart';
import 'components/player.dart';
import 'components/bullet.dart';
import 'components/blood_particle.dart';
import 'stages/stage_base.dart';
import 'stages/stage_1_orchard.dart';
import 'stages/stage_2_spikes.dart';
import 'stages/stage_3_leap.dart';

class IWBTGGame extends FlameGame with HasCollisionDetection, KeyboardEvents {
  final int initialStage;
  final void Function(int deaths)? onDeathsUpdated;
  final void Function(int stage, String name)? onStageUpdated;
  final VoidCallback? onVictoryTriggered;
  final void Function(bool isDead)? onPlayerStateChanged;

  int currentStageIndex = 1;
  int deathCount = 0;
  Vector2? activeCheckpoint;
  int? activeCheckpointStage;

  StageBase? currentStage;
  Player? player;

  IWBTGGame({
    this.initialStage = 1,
    this.onDeathsUpdated,
    this.onStageUpdated,
    this.onVictoryTriggered,
    this.onPlayerStateChanged,
  }) {
    currentStageIndex = initialStage;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set fixed 800x600 resolution viewport for authentic retro aspect ratio
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(GameConstants.gameWidth, GameConstants.gameHeight),
    );

    await loadStage(currentStageIndex);
  }

  Future<void> loadStage(int stageNumber) async {
    currentStageIndex = stageNumber;

    // Remove existing stage and player if present
    player?.removeFromParent();
    currentStage?.removeFromParent();

    // Clean up bullets and blood particles from previous run
    world.children.whereType<BloodParticleSystem>().forEach((b) => b.removeFromParent());
    world.children.whereType<Bullet>().forEach((b) => b.removeFromParent());

    // Instantiate selected stage
    switch (stageNumber) {
      case 1:
        currentStage = Stage1Orchard();
        break;
      case 2:
        currentStage = Stage2Spikes();
        break;
      case 3:
        currentStage = Stage3Leap();
        break;
      default:
        currentStage = Stage1Orchard();
    }

    await world.add(currentStage!);

    // Check if we have an active checkpoint in this stage
    final spawn = (activeCheckpoint != null && activeCheckpointStage == stageNumber)
        ? activeCheckpoint!
        : currentStage!.defaultSpawnPosition;

    player = Player(initialPosition: spawn);
    await world.add(player!);

    onPlayerStateChanged?.call(false);
    onStageUpdated?.call(currentStageIndex, currentStage!.stageName);
  }

  void updateCheckpoint(Vector2 checkpointPos, int stageNum) {
    activeCheckpoint = checkpointPos.clone();
    activeCheckpointStage = stageNum;
  }

  void onPlayerDied() {
    deathCount++;
    onDeathsUpdated?.call(deathCount);
    onPlayerStateChanged?.call(true);
  }

  void respawnPlayer() {
    if (player == null || currentStage == null) return;

    // Clean up bullets and blood particles from previous run
    world.children.whereType<BloodParticleSystem>().forEach((b) => b.removeFromParent());
    world.children.whereType<Bullet>().forEach((b) => b.removeFromParent());

    // Zero-delay instant respawn: Reset player position to checkpoint
    final respawnPos = (activeCheckpoint != null && activeCheckpointStage == currentStageIndex)
        ? activeCheckpoint!
        : currentStage!.defaultSpawnPosition;

    player!.respawnAt(respawnPos);

    // Reset all traps and trigger zones in the current stage
    currentStage!.resetHazards();
    onPlayerStateChanged?.call(false);
  }

  void onStageCleared(int fromStage) {
    if (fromStage < 3) {
      // Clear checkpoint when advancing to next stage
      activeCheckpoint = null;
      activeCheckpointStage = null;
      loadStage(fromStage + 1);
    } else {
      onVictory();
    }
  }

  void onVictory() {
    onVictoryTriggered?.call();
  }

  // --- Keyboard Controls (Desktop & Web) ---
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (player == null) return KeyEventResult.ignored;

    // When dead, allow instant retry with R, Space, Enter, Up, or W
    if (!player!.isAlive) {
      if (event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.keyR ||
            event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.arrowUp ||
            event.logicalKey == LogicalKeyboardKey.keyW) {
          respawnPlayer();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.handled;
    }

    // Horizontal Movement
    double move = 0.0;
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA)) {
      move -= 1.0;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD)) {
      move += 1.0;
    }
    player!.setMoveInput(move);

    // Jump (Shift or Space or Up Arrow)
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        player!.pressJump();
      }

      // Shoot (Z or J)
      if (event.logicalKey == LogicalKeyboardKey.keyZ ||
          event.logicalKey == LogicalKeyboardKey.keyJ) {
        player!.shoot();
      }

      // Instant Respawn (R)
      if (event.logicalKey == LogicalKeyboardKey.keyR) {
        respawnPlayer();
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        player!.releaseJump();
      }
    }

    return KeyEventResult.handled;
  }
}
