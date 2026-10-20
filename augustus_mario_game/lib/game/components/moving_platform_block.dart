import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'platform_block.dart';
import 'blood_particle.dart';
import '../game_constants.dart';
import '../iwbtg_game.dart';

class MovingPlatformBlock extends PlatformBlock with HasGameReference<IWBTGGame> {
  final Vector2 initialPosition;
  final Vector2 targetPosition;
  final double moveSpeed;
  final double? collapseDelay;
  final double warningDuration;

  bool _isMoving = false;
  bool _hasArrived = false;
  bool _hasStartedStanding = false;
  double _standingTimer = 0.0;
  bool _isFalling = false;
  double _fallSpeed = 0.0;
  double _shakeOffsetX = 0.0;
  final Random _rng = Random();

  bool get isMoving => _isMoving;
  bool get hasArrived => _hasArrived;
  bool get isFalling => _isFalling;
  bool get isWarning =>
      collapseDelay != null &&
      _hasStartedStanding &&
      !_isFalling &&
      _standingTimer >= (collapseDelay! - warningDuration);

  MovingPlatformBlock({
    required Vector2 position,
    required Vector2 targetPosition,
    required Vector2 size,
    this.moveSpeed = 180.0,
    this.collapseDelay,
    this.warningDuration = 1.0,
    Color fillColor = GameConstants.tileColor,
    Color borderColor = GameConstants.tileBorderColor,
    bool isOneWay = false,
    int? priority,
  })  : initialPosition = position.clone(),
        targetPosition = targetPosition.clone(),
        super(
          position: position,
          size: size,
          fillColor: fillColor,
          borderColor: borderColor,
          isOneWay: isOneWay,
          priority: priority,
        );

  void startMoving() {
    if (!_hasArrived) {
      _isMoving = true;
    }
  }

  void reset() {
    if (_isFalling) {
      BloodParticleSystem.onBlockReset(this);
    }
    position.setFrom(initialPosition);
    _isMoving = false;
    _hasArrived = false;
    _hasStartedStanding = false;
    _standingTimer = 0.0;
    _isFalling = false;
    _fallSpeed = 0.0;
    _shakeOffsetX = 0.0;
    isSolid = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 1. Sliding movement logic
    if (_isMoving && !_hasArrived) {
      final toTarget = targetPosition - position;
      final dist = toTarget.length;
      final step = moveSpeed * dt;

      Vector2 deltaMove;
      if (dist <= step || dist < 0.001) {
        deltaMove = targetPosition - position;
        position.setFrom(targetPosition);
        _hasArrived = true;
        _isMoving = false;
      } else {
        final dir = toTarget.normalized();
        deltaMove = dir * step;
        position += deltaMove;
      }

      _carryPlayer(deltaMove);
    }

    // 2. Standing & Collapse logic
    if (collapseDelay != null) {
      try {
        final player = game.player;
        if (player != null && player.isAlive && player.isOnGround) {
          final pRect = player.toRect();
          final bRect = toRect();
          if ((pRect.bottom - bRect.top).abs() <= 4.0 &&
              pRect.right > bRect.left + 2.0 &&
              pRect.left < bRect.right - 2.0) {
            _hasStartedStanding = true;
          }
        }
      } catch (_) {}

      if (_hasStartedStanding && !_isFalling) {
        _standingTimer += dt;
        if (isWarning) {
          _shakeOffsetX = _rng.nextDouble() * 4 - 2;
        }
        if (_standingTimer >= collapseDelay!) {
          _isFalling = true;
          isSolid = false;
          _shakeOffsetX = 0.0;
        }
      } else if (_isFalling) {
        _fallSpeed += 1200 * dt;
        position.y += _fallSpeed * dt;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (isWarning) {
      canvas.save();
      canvas.translate(_shakeOffsetX, 0);

      final rect = Rect.fromLTWH(0, 0, width, height);
      final paint = Paint()..color = fillColor;
      canvas.drawRect(rect, paint);

      // Warning red border
      final borderPaint = Paint()
        ..color = const Color(0xFFE06C75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(rect, borderPaint);

      // Warning crack lines
      final crackPaint = Paint()
        ..color = const Color(0xFFE06C75)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(width * 0.2, 0), Offset(width * 0.4, height), crackPaint);
      canvas.drawLine(Offset(width * 0.4, height * 0.5), Offset(width * 0.8, height * 0.2), crackPaint);
      canvas.drawLine(Offset(width * 0.6, 0), Offset(width * 0.7, height), crackPaint);

      canvas.restore();
    } else {
      super.render(canvas);
    }
  }

  void _carryPlayer(Vector2 deltaMove) {
    try {
      final player = game.player;
      if (player != null && player.isAlive && player.isOnGround && !_isFalling) {
        final pRect = player.toRect();
        final bRect = toRect();
        // Check if player is resting on top of this block
        if ((pRect.bottom - bRect.top).abs() <= 3.0 &&
            pRect.right > bRect.left &&
            pRect.left < bRect.right) {
          player.position.x += deltaMove.x;
          player.position.y += deltaMove.y;
        }
      }
    } catch (_) {}
  }
}
