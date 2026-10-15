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
    required Vector2 position,
    this.behavior = AppleBehavior.staticItem,
    this.customLaunchVelocity,
    super.hazardId,
    double radius = 12.0,
  })  : _initialPosition = position.clone(),
        super(position: position, size: Vector2.all(radius * 2)) {
    add(CircleHitbox(radius: radius - 1));
  }

  @override
  void trigger() {
    if (_active) return;
    _active = true;

    switch (behavior) {
      case AppleBehavior.fallDown:
        _velocity = Vector2(0, 50);
        _gravity = 1100;
        break;
      case AppleBehavior.flyUp:
        // Iconic IWBTG troll: Apple shoots UPWARD!
        _velocity = Vector2(0, -480);
        _gravity = 0;
        break;
      case AppleBehavior.flyLeft:
        _velocity = Vector2(-380, 0);
        _gravity = 0;
        break;
      case AppleBehavior.flyRight:
        _velocity = Vector2(380, 0);
        _gravity = 0;
        break;
      case AppleBehavior.customVelocity:
        _velocity = customLaunchVelocity?.clone() ?? Vector2(0, -300);
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
    if (_active) {
      _velocity.y += _gravity * dt;
      position += _velocity * dt;
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
