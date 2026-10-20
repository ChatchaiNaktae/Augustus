import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class _SparkDrop {
  Vector2 position;
  Vector2 velocity;
  double size;
  Color color;
  double lifeTimer;
  double maxLife;

  _SparkDrop({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    required this.maxLife,
  }) : lifeTimer = 0.0;
}

/// Particle FX when sniper bullet ricochets/hits a solid surface (sparks)
class BulletSparkFX extends PositionComponent {
  final List<_SparkDrop> _sparks = [];
  final Random _rng = Random();

  BulletSparkFX({
    required Vector2 position,
    required Vector2 normal,
    int count = 16,
  }) : super(position: Vector2.zero(), priority: 15) {
    // Surface reflection base angle
    double baseAngle = atan2(normal.y, normal.x);
    if (normal.length < 0.1) {
      baseAngle = -pi / 2; // Default upwards
    }

    final colors = [
      const Color(0xFFFFFFFF), // Hot white center
      const Color(0xFFFFF176), // Bright yellow
      const Color(0xFFFFB74D), // Golden orange
      const Color(0xFFFF7043), // Fiery red-orange
    ];

    for (int i = 0; i < count; i++) {
      // Scatter angle +/- 65 degrees from surface normal
      final angle = baseAngle + (_rng.nextDouble() - 0.5) * (130 * pi / 180);
      final speed = 80.0 + _rng.nextDouble() * 260.0;
      final velocity = Vector2(cos(angle) * speed, sin(angle) * speed);

      _sparks.add(
        _SparkDrop(
          position: Vector2(
            position.x + (_rng.nextDouble() - 0.5) * 4,
            position.y + (_rng.nextDouble() - 0.5) * 4,
          ),
          velocity: velocity,
          size: 1.5 + _rng.nextDouble() * 2.5,
          color: colors[_rng.nextInt(colors.length)],
          maxLife: 0.20 + _rng.nextDouble() * 0.20, // 0.20 - 0.40 seconds
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final gravity = Vector2(0, 600 * dt);

    for (int i = _sparks.length - 1; i >= 0; i--) {
      final s = _sparks[i];
      s.lifeTimer += dt;
      s.velocity += gravity;
      s.position += s.velocity * dt;

      if (s.lifeTimer >= s.maxLife) {
        _sparks.removeAt(i);
      }
    }

    if (_sparks.isEmpty) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in _sparks) {
      final alpha = (1.0 - (s.lifeTimer / s.maxLife)).clamp(0.0, 1.0);
      paint.color = s.color.withValues(alpha: alpha);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(s.position.x, s.position.y),
          width: s.size,
          height: s.size,
        ),
        paint,
      );
    }
  }
}
