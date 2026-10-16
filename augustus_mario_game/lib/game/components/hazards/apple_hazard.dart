import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'hazard_base.dart';
import '../../game_constants.dart';

enum AppleBehavior {
  staticItem,
  fallDown,
  flyUp,
  flyLeft,
  flyRight,
  customVelocity,
}

class AppleHazard extends HazardBase {
  final AppleBehavior behavior;
  final Vector2? customLaunchVelocity;
  final Vector2 _initialPosition;
  Vector2 _velocity = Vector2.zero();
  bool _active = false;
  double _gravity = 0;

  AppleHazard({
    required super.position,
    this.behavior = AppleBehavior.staticItem,
    this.customLaunchVelocity,
    super.hazardId,
    double radius = 12.0,
  })  : _initialPosition = position!.clone(),
        super(size: Vector2.all(radius * 2)) {
    add(CircleHitbox(radius: radius - 1));
  }

  @override
  void trigger() {
    if (_active) return;
    _active = true;

    switch (behavior) {
      case AppleBehavior.fallDown:
        _velocity = Vector2(0, 260); // High initial downward velocity
        _gravity = 3200; // Accelerated rapid gravity drop
        break;
      case AppleBehavior.flyUp:
        // Iconic IWBTG troll: Apple shoots UPWARD! (Masocore 1100 px/s)
        _velocity = Vector2(0, -1100);
        _gravity = 0;
        break;
      case AppleBehavior.flyLeft:
        _velocity = Vector2(-1050, 0); // Masocore fast rusher
        _gravity = 0;
        break;
      case AppleBehavior.flyRight:
        _velocity = Vector2(1050, 0); // Masocore fast rusher
        _gravity = 0;
        break;
      case AppleBehavior.customVelocity:
        _velocity = customLaunchVelocity?.clone() ?? Vector2(0, -700);
        _gravity = 0;
        break;
      case AppleBehavior.staticItem:
        break;
    }
  }

  @override
  void reset() {
    position.setFrom(_initialPosition);
    _velocity.setZero();
    _gravity = 0;
    _active = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) return;

    // Sub-step movement to prevent tunneling against player at high speed (> 1,000 px/s)
    final moveDist = (_velocity.length + (_gravity.abs() * dt)) * dt;
    const double maxStep = 6.0;
    final int steps = (moveDist / maxStep).ceil().clamp(1, 24);
    final double stepDt = dt / steps;

    for (int i = 0; i < steps; i++) {
      _velocity.y += _gravity * stepDt;
      position += _velocity * stepDt;

      if (isDeadly) {
        _checkPlayerCollision();
        if (!isDeadly || !_active) break;
      }
    }
  }

  void _checkPlayerCollision() {
    try {
      final player = game.player;
      if (player == null || !player.isAlive) return;

      final pRect = player.hitboxRect;
      final center = position + size / 2;
      final radius = width / 2 - 1;

      // Circle vs player hitbox distance check
      final closestX = center.x.clamp(pRect.left, pRect.right);
      final closestY = center.y.clamp(pRect.top, pRect.bottom);
      final dx = center.x - closestX;
      final dy = center.y - closestY;

      if (dx * dx + dy * dy <= radius * radius) {
        player.die();
      }
    } catch (_) {
      // In case component is detached from game tree during update
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(width / 2, height / 2 + 1);
    final radius = width / 2 - 2;

    // Apple main body
    final applePaint = Paint()..color = GameConstants.appleRed;
    canvas.drawCircle(center, radius, applePaint);

    // Apple outline
    final strokePaint = Paint()
      ..color = const Color(0xFF6B1D2F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, strokePaint);

    // Retro white pixel shine on top-left
    final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(center.dx - radius * 0.4, center.dy - radius * 0.4), radius * 0.25, shinePaint);

    // Green stem / leaf at top
    final stemPaint = Paint()..color = GameConstants.appleGreen;
    final leafPath = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx + 4, center.dy - radius - 5, center.dx + 6, center.dy - radius - 2)
      ..close();
    canvas.drawPath(leafPath, stemPaint);
  }
}
