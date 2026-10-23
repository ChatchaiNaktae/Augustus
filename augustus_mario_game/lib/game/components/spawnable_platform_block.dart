import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'platform_block.dart';
import '../game_constants.dart';
import '../iwbtg_game.dart';

/// Platform that starts inactive/invisible/non-solid, and spawns into existence
/// when triggered by a troll trigger event. Can optionally oscillate left and right.
class SpawnablePlatformBlock extends PlatformBlock with HasGameReference<IWBTGGame> {
  final Vector2 initialPosition;
  final bool isOscillating;
  final double minX;
  final double maxX;
  final double moveSpeed;

  bool isActive = false;
  int _moveDir = 1;
  double _spawnAnimationTimer = 0.0;
  static const double spawnAnimDuration = 0.30;

  SpawnablePlatformBlock({
    required super.position,
    required super.size,
    this.isOscillating = false,
    double? minX,
    double? maxX,
    this.moveSpeed = 110.0,
    super.fillColor = GameConstants.tileColor,
    super.borderColor = GameConstants.retroCyan,
    super.priority,
  })  : initialPosition = position.clone(),
        minX = minX ?? position.x,
        maxX = maxX ?? position.x {
    isSolid = false;
  }

  void activate() {
    if (!isActive) {
      isActive = true;
      isSolid = true;
      _spawnAnimationTimer = spawnAnimDuration;
    }
  }

  void deactivate() {
    isActive = false;
    isSolid = false;
    _spawnAnimationTimer = 0.0;
    position.setFrom(initialPosition);
    _moveDir = 1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_spawnAnimationTimer > 0) {
      _spawnAnimationTimer = max(0.0, _spawnAnimationTimer - dt);
    }

    if (isActive && isOscillating) {
      final double deltaX = _moveDir * moveSpeed * dt;
      position.x += deltaX;

      if (position.x >= maxX) {
        position.x = maxX;
        _moveDir = -1;
      } else if (position.x <= minX) {
        position.x = minX;
        _moveDir = 1;
      }

      _carryPlayer(Vector2(deltaX, 0));
    }
  }

  void _carryPlayer(Vector2 deltaMove) {
    try {
      final player = game.player;
      if (player != null && player.isAlive && player.isOnGround) {
        final pRect = player.toRect();
        final bRect = toRect();
        // Check if player's feet are resting on top of this block
        if ((pRect.bottom - bRect.top).abs() <= 4.0 &&
            pRect.right > bRect.left &&
            pRect.left < bRect.right) {
          player.position.x += deltaMove.x;
          player.position.y += deltaMove.y;
        }
      }
    } catch (_) {}
  }

  @override
  void render(Canvas canvas) {
    if (!isActive) return;

    super.render(canvas);

    // Neon 8-bit spawn flash
    final double animProgress = _spawnAnimationTimer / spawnAnimDuration;
    if (animProgress > 0) {
      final flashPaint = Paint()
        ..color = Colors.white.withValues(alpha: animProgress * 0.7)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), flashPaint);
    }

    // Glowing cyan cyber border accent
    final accentPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), accentPaint);
  }
}
