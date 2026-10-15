import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_constants.dart';
import 'platform_block.dart';

class Bullet extends PositionComponent with CollisionCallbacks {
  final double direction; // 1 for right, -1 for left
  final double speed;

  Bullet({
    required Vector2 position,
    required this.direction,
    this.speed = GameConstants.bulletSpeed,
  }) : super(
          position: position,
          size: Vector2.all(GameConstants.bulletRadius * 2),
          anchor: Anchor.center,
        ) {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x += direction * speed * dt;

    // Check bounds
    if (position.x < 0 || position.x > GameConstants.gameWidth) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlatformBlock) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = Offset(width / 2, height / 2);

    // Outer glow
    final glowPaint = Paint()..color = GameConstants.retroYellow.withValues(alpha: 0.6);
    canvas.drawCircle(center, width / 2, glowPaint);

    // Inner bright bullet core
    final corePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, width / 4, corePaint);
  }
}
