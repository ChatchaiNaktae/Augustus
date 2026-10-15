import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_constants.dart';

class _BloodDrop {
  Vector2 position;
  Vector2 velocity;
  double size;
  Color color;
  double alpha;

  _BloodDrop({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    this.alpha = 1.0,
  });
}

class BloodParticleSystem extends PositionComponent {
  final List<_BloodDrop> _particles = [];
  final Random _rng = Random();
  double _lifeTimer = 0.0;
  static const double maxLifetime = GameConstants.bloodLifetime;

  BloodParticleSystem({
    required Vector2 origin,
    int count = GameConstants.deathBloodParticleCount,
  }) : super(position: origin) {
    final colors = [
      const Color(0xFFE06C75),
      const Color(0xFFBE5046),
      const Color(0xFFFF2A2A),
      const Color(0xFF881111),
      const Color(0xFFFFFFFF), // occasional skull/sparkle
    ];

    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = GameConstants.bloodMinSpeed +
          _rng.nextDouble() * (GameConstants.bloodMaxSpeed - GameConstants.bloodMinSpeed);
      final velocity = Vector2(cos(angle) * speed, sin(angle) * speed);

      _particles.add(
        _BloodDrop(
          position: Vector2((_rng.nextDouble() - 0.5) * 10, (_rng.nextDouble() - 0.5) * 10),
          velocity: velocity,
          size: 2.5 + _rng.nextDouble() * 3.5,
          color: colors[_rng.nextInt(colors.length)],
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTimer += dt;

    final gravity = Vector2(0, 750 * dt);

    for (final p in _particles) {
      p.velocity += gravity;
      p.position += p.velocity * dt;

      if (_lifeTimer > maxLifetime * 0.7) {
        final progress = (_lifeTimer - maxLifetime * 0.7) / (maxLifetime * 0.3);
        p.alpha = (1.0 - progress).clamp(0.0, 1.0);
      }
    }

    if (_lifeTimer >= maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (final p in _particles) {
      if (p.alpha <= 0) continue;
      final paint = Paint()..color = p.color.withValues(alpha: p.alpha);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(p.position.x, p.position.y), width: p.size, height: p.size),
        paint,
      );
    }
  }
}
