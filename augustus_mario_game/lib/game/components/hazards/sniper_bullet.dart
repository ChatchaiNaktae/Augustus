import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../iwbtg_game.dart';
import '../bullet_spark_fx.dart';

class _RayHit {
  final double t;
  final Vector2 point;
  final Vector2 normal;

  _RayHit({required this.t, required this.point, required this.normal});
}

/// High-velocity sniper projectile that ricochets/sparks on obstacles and kills the player on hit
class SniperBullet extends PositionComponent with HasGameReference<IWBTGGame> {
  final Vector2 velocity;
  final double angleRad;
  static const double bulletSpeed = 1500.0;
  static const double bulletLength = 16.0;

  SniperBullet({
    required Vector2 startPos,
    required Vector2 direction,
  })  : velocity = direction.normalized() * bulletSpeed,
        angleRad = atan2(direction.y, direction.x),
        super(position: startPos.clone(), size: Vector2(bulletLength, 4), priority: 12);

  _RayHit? _raycastAABB(Vector2 p0, Vector2 p1, Rect box) {
    if (box.contains(Offset(p0.x, p0.y))) {
      return _RayHit(t: 0.0, point: p0, normal: Vector2(0, -1));
    }

    final double dx = p1.x - p0.x;
    final double dy = p1.y - p0.y;

    double tNearX;
    double tFarX;
    double normalNearX;

    if (dx.abs() < 1e-6) {
      if (p0.x < box.left || p0.x > box.right) return null;
      tNearX = -double.infinity;
      tFarX = double.infinity;
      normalNearX = 0;
    } else {
      final double invDx = 1.0 / dx;
      final double t1 = (box.left - p0.x) * invDx;
      final double t2 = (box.right - p0.x) * invDx;
      if (t1 < t2) {
        tNearX = t1;
        tFarX = t2;
        normalNearX = -1.0;
      } else {
        tNearX = t2;
        tFarX = t1;
        normalNearX = 1.0;
      }
    }

    double tNearY;
    double tFarY;
    double normalNearY;

    if (dy.abs() < 1e-6) {
      if (p0.y < box.top || p0.y > box.bottom) return null;
      tNearY = -double.infinity;
      tFarY = double.infinity;
      normalNearY = 0;
    } else {
      final double invDy = 1.0 / dy;
      final double t1 = (box.top - p0.y) * invDy;
      final double t2 = (box.bottom - p0.y) * invDy;
      if (t1 < t2) {
        tNearY = t1;
        tFarY = t2;
        normalNearY = -1.0;
      } else {
        tNearY = t2;
        tFarY = t1;
        normalNearY = 1.0;
      }
    }

    final double tNear = max(tNearX, tNearY);
    final double tFar = min(tFarX, tFarY);

    if (tNear > tFar || tFar < 0.0 || tNear > 1.0) {
      return null;
    }

    final double t = tNear.clamp(0.0, 1.0);
    final Vector2 hitPoint = p0 + (p1 - p0) * t;

    Vector2 hitNormal;
    if (tNearX > tNearY) {
      hitNormal = Vector2(normalNearX, 0);
    } else {
      hitNormal = Vector2(0, normalNearY);
    }

    return _RayHit(t: t, point: hitPoint, normal: hitNormal);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final from = position.clone();
    final to = from + velocity * dt;

    // 1. Check collision with Player
    final player = game.player;
    if (player != null && player.isAlive) {
      final playerRect = player.toRect();
      final pHit = _raycastAABB(from, to, playerRect);
      if (pHit != null) {
        player.die();
        removeFromParent();
        return;
      }
    }

    // 2. Check collision with obstacles (Bunkers, Platforms, Walls, Ceiling)
    final stage = game.currentStage;
    if (stage != null) {
      final obstacles = stage.getSolidObstacleComponents();
      _RayHit? closestHit;

      for (final comp in obstacles) {
        final hit = _raycastAABB(from, to, comp.toRect());
        if (hit != null) {
          if (closestHit == null || hit.t < closestHit.t) {
            closestHit = hit;
          }
        }
      }

      if (closestHit != null) {
        // Impact obstacle: trigger spark particles and remove bullet
        parent?.add(BulletSparkFX(
          position: closestHit.point,
          normal: closestHit.normal,
        ));
        removeFromParent();
        return;
      }
    }

    // Move forward
    position.setFrom(to);

    // Destroy if out of bounds
    if (position.x < -60 || position.x > 860 || position.y < -60 || position.y > 660) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.save();
    canvas.rotate(angleRad);

    // Outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF9800)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-bulletLength / 2, 0), Offset(bulletLength / 2, 0), glowPaint);

    // Inner hot core
    final corePaint = Paint()
      ..color = const Color(0xFFFFF9C4)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-bulletLength / 2 + 2, 0), Offset(bulletLength / 2, 0), corePaint);

    canvas.restore();
  }
}
