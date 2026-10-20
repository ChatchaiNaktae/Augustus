import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'platform_block.dart';
import '../game_constants.dart';

/// Platform that starts inactive/invisible/non-solid, and spawns into existence
/// when triggered by a troll trigger event.
class SpawnablePlatformBlock extends PlatformBlock {
  bool isActive = false;
  double _spawnAnimationTimer = 0.0;
  static const double spawnAnimDuration = 0.30;

  SpawnablePlatformBlock({
    required super.position,
    required super.size,
    super.fillColor = GameConstants.tileColor,
    super.borderColor = GameConstants.retroCyan,
    super.priority,
  }) {
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
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_spawnAnimationTimer > 0) {
      _spawnAnimationTimer = max(0.0, _spawnAnimationTimer - dt);
    }
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
