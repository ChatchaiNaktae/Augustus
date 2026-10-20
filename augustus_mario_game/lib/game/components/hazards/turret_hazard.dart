import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'hazard_base.dart';
import '../../game_constants.dart';
import '../player.dart';
import '../../iwbtg_game.dart';

/// Rapid-fire machine gun projectile
class TurretBullet extends PositionComponent with CollisionCallbacks, HasGameReference<IWBTGGame> {
  final Vector2 velocity;
  final double angleRad;

  TurretBullet({
    required Vector2 startPos,
    required Vector2 direction,
    double speed = 650.0,
  })  : velocity = direction.normalized() * speed,
        angleRad = atan2(direction.y, direction.x),
        super(position: startPos.clone(), size: Vector2(10, 6), priority: 11) {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    // Remove if off screen
    if (position.y < -20 || position.y > GameConstants.gameHeight + 20 ||
        position.x < -20 || position.x > GameConstants.gameWidth + 20) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player && other.isAlive) {
      other.die();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.save();
    canvas.translate(width / 2, height / 2);
    canvas.rotate(angleRad);

    // Glowing tracer bullet
    final glowPaint = Paint()
      ..color = const Color(0xFFFF5722).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -3, 12, 6), const Radius.circular(2)), glowPaint);

    final corePaint = Paint()..color = const Color(0xFFFFEB3B);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -2, 10, 4), const Radius.circular(1.5)), corePaint);

    canvas.restore();
  }
}

/// Rapid-fire Machine Gun Turret on Platform 1 with dynamic sweeping arc
class TurretHazard extends HazardBase {
  bool isActive = false;
  double _fireTimer = 0.0;
  double _muzzleFlashTimer = 0.0;
  double _barrelSpinAngle = 0.0;
  static const double shotInterval = 0.16; // Rapid fire rate

  // Sweep angles: from ~ -5 deg (right) to ~ -115 deg (up-left) matching user arc
  static const double minAimAngle = -2.01; // ~ -115 deg (pointing up-left)
  static const double maxAimAngle = -0.09; // ~ -5 deg (pointing almost horizontal right)
  static const double sweepSpeed = 1.05;   // ~ 60 deg per second

  double _currentAimAngle = maxAimAngle;
  int _sweepDir = -1; // Sweeps towards left first

  Vector2 get currentShootDirection => Vector2(cos(_currentAimAngle), sin(_currentAimAngle));

  TurretHazard({
    required Vector2 position,
    String hazardId = "machine_gun_turret",
  }) : super(
          position: position,
          size: Vector2(26, 22),
          hazardId: hazardId,
          priority: 8,
        ) {
    isDeadly = false; // Bullets are deadly; base turret body is non-deadly obstacle
  }

  void activateTurret() {
    isActive = true;
    _fireTimer = 0.0;
    _currentAimAngle = maxAimAngle;
    _sweepDir = -1;
  }

  void deactivateTurret() {
    isActive = false;
    _fireTimer = 0.0;
    _muzzleFlashTimer = 0.0;
  }

  @override
  void reset() {
    super.reset();
    deactivateTurret();
    _currentAimAngle = maxAimAngle;
    _sweepDir = -1;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_muzzleFlashTimer > 0) {
      _muzzleFlashTimer = max(0.0, _muzzleFlashTimer - dt);
    }

    if (isActive) {
      _barrelSpinAngle += dt * 25.0;

      // Sweep turret aim angle back and forth across the arc
      _currentAimAngle += _sweepDir * sweepSpeed * dt;
      if (_currentAimAngle <= minAimAngle) {
        _currentAimAngle = minAimAngle;
        _sweepDir = 1;
      } else if (_currentAimAngle >= maxAimAngle) {
        _currentAimAngle = maxAimAngle;
        _sweepDir = -1;
      }

      _fireTimer += dt;
      if (_fireTimer >= shotInterval) {
        _fireTimer = 0.0;
        _muzzleFlashTimer = 0.06;

        // Spawn rapid bullet along current aim angle
        final dir = currentShootDirection;
        final muzzlePos = position + Vector2(width / 2, 4) + dir * 14.0;
        parent?.add(TurretBullet(
          startPos: muzzlePos,
          direction: dir,
          speed: 650.0,
        ));
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Turret Base Mount (dark metallic bunker pedestal)
    final basePaint = Paint()..color = const Color(0xFF37474F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(2, height - 8, width - 4, 8), const Radius.circular(2.0)),
      basePaint,
    );

    // Pivot mount dome
    final mountPaint = Paint()..color = const Color(0xFF455A64);
    canvas.drawCircle(Offset(width / 2, height - 6), 7.0, mountPaint);

    // 2. Angled Gatling Gun Barrels matching current aim angle
    canvas.save();
    canvas.translate(width / 2, height - 8);
    canvas.rotate(_currentAimAngle);

    // Barrel housing
    final housingPaint = Paint()..color = const Color(0xFF263238);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3, -5, 10, 10), const Radius.circular(1.0)), housingPaint);

    // Dual/Rotary Barrels
    final barrelPaint = Paint()..color = const Color(0xFFB0BEC5);
    final spinOffset = sin(_barrelSpinAngle) * 2.0;
    canvas.drawRect(Rect.fromLTWH(7, -3.5 + spinOffset, 12, 2.5), barrelPaint);
    canvas.drawRect(Rect.fromLTWH(7, 1.0 - spinOffset, 12, 2.5), barrelPaint);

    // Muzzle tip clamp
    final clampPaint = Paint()..color = const Color(0xFF263238);
    canvas.drawRect(const Rect.fromLTWH(18, -4, 2.5, 8), clampPaint);

    // Muzzle Flash
    if (_muzzleFlashTimer > 0) {
      final flashPaint = Paint()..color = const Color(0xFFFFD54F);
      canvas.drawCircle(const Offset(24, 0), 6.0, flashPaint);
    }

    canvas.restore();

    // Small active indicator LED light
    final ledPaint = Paint()..color = isActive ? const Color(0xFFFF1744) : const Color(0xFF4CAF50);
    canvas.drawCircle(Offset(width / 2, height - 3), 1.5, ledPaint);
  }
}
