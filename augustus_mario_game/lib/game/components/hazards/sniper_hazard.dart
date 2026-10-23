import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'hazard_base.dart';
import 'sniper_bullet.dart';

class _RayHit {
  final double t;
  final Vector2 point;
  final Vector2 normal;

  _RayHit({required this.t, required this.point, required this.normal});
}

/// Sniper stationed at the top-right of Stage 3
/// Aims with a raycast laser, locks on with a 0.6s warning, and fires every 3 seconds.
class SniperHazard extends HazardBase {
  double _timer = 0.0;
  static const double shotInterval = 3.0;
  static const double lockOnTime = 2.4; // 0.6s warning lock

  Vector2 _targetPos = Vector2.zero();
  Vector2 _aimDir = Vector2(-1, 0.5).normalized();
  Vector2 _laserEndPos = Vector2.zero();
  bool _isLockedOn = false;
  double _muzzleFlashTimer = 0.0;
  final Random _rng = Random();

  SniperHazard({
    required super.position,
  }) : super(
          size: Vector2(40, 20),
          hazardId: 'sniper_hazard',
          priority: 8,
        ) {
    isDeadly = false; // Sniper rifle itself is the gun component; bullets kill the player
  }

  @override
  void reset() {
    _timer = 0.0;
    _isLockedOn = false;
    _muzzleFlashTimer = 0.0;
  }

  Vector2 get _muzzleWorldPos {
    // Offset along barrel from rifle pivot
    return position + _aimDir * 28.0;
  }

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

  void _calculateLaserLine() {
    final muzzle = _muzzleWorldPos;
    final rayEnd = muzzle + _aimDir * 1200.0;
    double minT = 1.0;
    Vector2 hitPoint = rayEnd;

    final stage = game.currentStage;
    if (stage != null) {
      // 1. Raycast against all solid obstacles
      for (final comp in stage.getSolidObstacleComponents()) {
        final hit = _raycastAABB(muzzle, rayEnd, comp.toRect());
        if (hit != null && hit.t < minT) {
          minT = hit.t;
          hitPoint = hit.point;
        }
      }

      // 2. Raycast against player
      final player = game.player;
      if (player != null && player.isAlive) {
        final hit = _raycastAABB(muzzle, rayEnd, player.toRect());
        if (hit != null && hit.t < minT) {
          minT = hit.t;
          hitPoint = hit.point;
        }
      }
    }

    _laserEndPos = hitPoint;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    if (_muzzleFlashTimer > 0) {
      _muzzleFlashTimer -= dt;
    }

    final player = game.player;

    if (_timer < lockOnTime) {
      _isLockedOn = false;
      // Active Tracking: Follow player's center
      if (player != null && player.isAlive) {
        _targetPos = player.position + player.size / 2;
        final toPlayer = _targetPos - position;
        if (toPlayer.length > 1.0) {
          _aimDir = toPlayer.normalized();
        }
      }
    } else {
      // Lock-On: Freeze aim direction for 0.6s warning
      _isLockedOn = true;
    }

    // Always compute laser raycast against world geometry
    _calculateLaserLine();

    // Fire bullet at 3.0s interval
    if (_timer >= shotInterval) {
      _timer = 0.0;
      _muzzleFlashTimer = 0.09;

      // Spawn high-speed sniper projectile along locked aim direction
      parent?.add(SniperBullet(
        startPos: _muzzleWorldPos,
        direction: _aimDir,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final angle = atan2(_aimDir.y, _aimDir.x);

    // 1. Draw Raycast Laser Line in world coordinates
    canvas.save();
    // Shift canvas back to world space for laser line drawing
    canvas.translate(-position.x, -position.y);

    final muzzle = _muzzleWorldPos;
    final laserPaint = Paint()..strokeCap = StrokeCap.round;

    if (_isLockedOn) {
      // Lock-on warning: intense pulsing laser beam
      final pulse = (sin(_timer * 30) * 0.5 + 0.5);
      laserPaint
        ..color = Color.lerp(const Color(0xFFFF0000), const Color(0xFFFFFFFF), pulse * 0.6)!
        ..strokeWidth = 2.5 + pulse * 1.5;
      canvas.drawLine(Offset(muzzle.x, muzzle.y), Offset(_laserEndPos.x, _laserEndPos.y), laserPaint);

      // Warning target dot / crosshair
      final dotPaint = Paint()..color = const Color(0xFFFF1744);
      canvas.drawCircle(Offset(_laserEndPos.x, _laserEndPos.y), 4.0 + pulse * 2.0, dotPaint);

      final ringPaint = Paint()
        ..color = const Color(0xFFFF1744)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(_laserEndPos.x, _laserEndPos.y), 8.0 - pulse * 3.0, ringPaint);
    } else {
      // Normal tracking: subtle translucent red beam
      laserPaint
        ..color = const Color(0x99FF2A2A)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(muzzle.x, muzzle.y), Offset(_laserEndPos.x, _laserEndPos.y), laserPaint);

      // Small laser dot at surface impact point
      final dotPaint = Paint()..color = const Color(0xFFFF2A2A);
      canvas.drawCircle(Offset(_laserEndPos.x, _laserEndPos.y), 2.5, dotPaint);
    }

    canvas.restore();

    // 2. Draw Sniper Rifle Visual
    canvas.save();
    canvas.rotate(angle);

    // If aiming leftwards, flip Y so the scope stays on TOP and magazine on BOTTOM
    if (_aimDir.x < 0) {
      canvas.scale(1.0, -1.0);
    }

    // Stock (wooden/dark rear)
    final stockPaint = Paint()..color = const Color(0xFF5D4037);
    final stockPath = Path()
      ..moveTo(-16, -2)
      ..lineTo(-6, -2)
      ..lineTo(-6, 3)
      ..lineTo(-14, 6)
      ..lineTo(-18, 5)
      ..close();
    canvas.drawPath(stockPath, stockPaint);

    // Receiver / Body (metal dark slate)
    final bodyPaint = Paint()..color = const Color(0xFF263238);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -3, 16, 6), const Radius.circular(1.0)),
      bodyPaint,
    );

    // Magazine
    final magPaint = Paint()..color = const Color(0xFF1B2428);
    canvas.drawRect(const Rect.fromLTWH(0, 3, 4, 6), magPaint);

    // Long Barrel (metallic gunmetal)
    final barrelPaint = Paint()..color = const Color(0xFF455A64);
    canvas.drawRect(const Rect.fromLTWH(10, -1.5, 18, 3), barrelPaint);

    // Muzzle Brake at tip
    final muzzleBrakePaint = Paint()..color = const Color(0xFF263238);
    canvas.drawRect(const Rect.fromLTWH(26, -2.5, 3, 5), muzzleBrakePaint);

    // Scope (mounted on top)
    final scopeMountPaint = Paint()..color = const Color(0xFF1B2428);
    canvas.drawRect(const Rect.fromLTWH(-2, -5, 2, 2), scopeMountPaint);
    canvas.drawRect(const Rect.fromLTWH(5, -5, 2, 2), scopeMountPaint);

    final scopeBodyPaint = Paint()..color = const Color(0xFF37474F);
    canvas.drawRect(const Rect.fromLTWH(-5, -8, 14, 4), scopeBodyPaint);
    // Scope Lens
    final lensPaint = Paint()..color = const Color(0xFF4FC3F7);
    canvas.drawRect(const Rect.fromLTWH(9, -8, 1.5, 4), lensPaint);

    // Muzzle Flash when shooting
    if (_muzzleFlashTimer > 0) {
      final flashPaint = Paint()..color = const Color(0xFFFFF176);
      canvas.drawCircle(const Offset(30, 0), 6.0 + _rng.nextDouble() * 3.0, flashPaint);

      final innerFlashPaint = Paint()..color = Colors.white;
      canvas.drawCircle(const Offset(30, 0), 3.5, innerFlashPaint);
    }

    canvas.restore();

    // 3. Mount bracket on the wall
    final mountPaint = Paint()..color = const Color(0xFF37474F);
    canvas.drawCircle(Offset.zero, 5.0, mountPaint);
    final pivotPinPaint = Paint()..color = const Color(0xFF78909C);
    canvas.drawCircle(Offset.zero, 2.0, pivotPinPaint);
  }
}
