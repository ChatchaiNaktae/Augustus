import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'hazard_base.dart';
import '../../game_constants.dart';

enum SpikeDirection { up, down, left, right }

class SpikeHazard extends HazardBase {
  final SpikeDirection direction;
  final Vector2? triggerVelocity;
  final bool isTriggered;
  final Vector2 _initialPosition;
  Vector2 _velocity = Vector2.zero();
  bool _active = false;

  SpikeHazard({
    required Vector2 position,
    this.direction = SpikeDirection.up,
    this.triggerVelocity,
    this.isTriggered = false,
    super.hazardId,
    double size = 32.0,
  })  : _initialPosition = position.clone(),
        super(position: position, size: Vector2.all(size)) {
    // Add polygon hitbox matching the spike triangle
    add(PolygonHitbox(_getTriangleVertices()));
  }

  List<Vector2> _getTriangleVertices() {
    switch (direction) {
      case SpikeDirection.up:
        return [
          Vector2(width / 2, 2),
          Vector2(width - 2, height),
          Vector2(2, height),
        ];
      case SpikeDirection.down:
        return [
          Vector2(2, 0),
          Vector2(width - 2, 0),
          Vector2(width / 2, height - 2),
        ];
      case SpikeDirection.left:
        return [
          Vector2(2, height / 2),
          Vector2(width, 2),
          Vector2(width, height - 2),
        ];
      case SpikeDirection.right:
        return [
          Vector2(0, 2),
          Vector2(width - 2, height / 2),
          Vector2(0, height - 2),
        ];
    }
  }

  @override
  void trigger() {
    if (triggerVelocity != null && !_active) {
      _active = true;
      _velocity = triggerVelocity!.clone();
    }
  }

  @override
  void reset() {
    position.setFrom(_initialPosition);
    _velocity.setZero();
    _active = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_active && _velocity.length2 > 0) {
      position += _velocity * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final path = Path();
    switch (direction) {
      case SpikeDirection.up:
        path.moveTo(width / 2, 0);
        path.lineTo(width, height);
        path.lineTo(0, height);
        break;
      case SpikeDirection.down:
        path.moveTo(0, 0);
        path.lineTo(width, 0);
        path.lineTo(width / 2, height);
        break;
      case SpikeDirection.left:
        path.moveTo(0, height / 2);
        path.lineTo(width, 0);
        path.lineTo(width, height);
        break;
      case SpikeDirection.right:
        path.moveTo(0, 0);
        path.lineTo(width, height / 2);
        path.lineTo(0, height);
        break;
    }
    path.close();

    // Base spike metallic fill
    final fillPaint = Paint()..color = GameConstants.spikeColor;
    canvas.drawPath(path, fillPaint);

    // Inner shadow for 3D metallic feel
    final shadowPaint = Paint()..color = const Color(0xFF8892B0);
    final shadowPath = Path();
    if (direction == SpikeDirection.up) {
      shadowPath.moveTo(width / 2, 0);
      shadowPath.lineTo(width, height);
      shadowPath.lineTo(width / 2, height);
      shadowPath.close();
      canvas.drawPath(shadowPath, shadowPaint);
    }

    // Spike sharp outline
    final strokePaint = Paint()
      ..color = const Color(0xFF2E3440)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, strokePaint);
  }
}
