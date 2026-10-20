import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'hazard_base.dart';
import '../../game_constants.dart';
import '../blood_particle.dart';

class CollapsingBlock extends HazardBase {
  final Vector2 _initialPosition;
  final double collapseDelay;
  final double warningDuration;
  double _timer = 0.0;
  bool _isTriggered = false;
  bool _isFalling = false;
  double _fallSpeed = 0.0;
  final Random _rng = Random();

  bool get isFalling => _isFalling;
  bool get isWarning => _isTriggered && !_isFalling && _timer >= (collapseDelay - warningDuration);

  CollapsingBlock({
    required Vector2 position,
    required Vector2 size,
    this.collapseDelay = 0.20,
    this.warningDuration = 0.20,
    String hazardId = '',
    int? priority,
  })  : _initialPosition = position.clone(),
        super(
          position: position,
          size: size,
          hazardId: hazardId,
          priority: priority,
        ) {
    isDeadly = false; // Collapsing blocks crumble and fall; they do not kill the player directly
    add(RectangleHitbox());
  }

  @override
  void trigger() {
    if (!_isTriggered) {
      _isTriggered = true;
      _timer = 0.0;
    }
  }

  @override
  void reset() {
    if (_isFalling) {
      BloodParticleSystem.onBlockReset(this);
    }
    position.setFrom(_initialPosition);
    _isTriggered = false;
    _isFalling = false;
    _timer = 0.0;
    _fallSpeed = 0.0;
    isDeadly = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isTriggered && !_isFalling) {
      _timer += dt;
      if (isWarning) {
        // Slight shake
        position.x = _initialPosition.x + (_rng.nextDouble() * 4 - 2);
      }
      if (_timer >= collapseDelay) {
        _isFalling = true;
        position.x = _initialPosition.x;
        isDeadly = false; // Player falls down with gravity, not killed by the block
      }
    } else if (_isFalling) {
      _fallSpeed += 1200 * dt;
      position.y += _fallSpeed * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Rect.fromLTWH(0, 0, width, height);
    final basePaint = Paint()..color = GameConstants.tileColor;
    canvas.drawRect(rect, basePaint);

    final borderPaint = Paint()
      ..color = isWarning ? const Color(0xFFE06C75) : GameConstants.tileBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(rect, borderPaint);

    if (isWarning) {
      // Crack lines
      final crackPaint = Paint()
        ..color = const Color(0xFFE06C75)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(width * 0.2, 0), Offset(width * 0.4, height), crackPaint);
      canvas.drawLine(Offset(width * 0.4, height * 0.5), Offset(width * 0.8, height * 0.2), crackPaint);
      canvas.drawLine(Offset(width * 0.6, 0), Offset(width * 0.7, height), crackPaint);
    }
  }
}
