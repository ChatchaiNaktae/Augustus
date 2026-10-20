import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'platform_block.dart';
import '../game_constants.dart';
import '../iwbtg_game.dart';

class MovingPlatformBlock extends PlatformBlock with HasGameReference<IWBTGGame> {
  final Vector2 initialPosition;
  final Vector2 targetPosition;
  final double moveSpeed;

  bool _isMoving = false;
  bool _hasArrived = false;

  bool get isMoving => _isMoving;
  bool get hasArrived => _hasArrived;

  MovingPlatformBlock({
    required Vector2 position,
    required Vector2 targetPosition,
    required Vector2 size,
    this.moveSpeed = 180.0,
    Color fillColor = GameConstants.tileColor,
    Color borderColor = GameConstants.tileBorderColor,
    bool isOneWay = false,
  })  : initialPosition = position.clone(),
        targetPosition = targetPosition.clone(),
        super(
          position: position,
          size: size,
          fillColor: fillColor,
          borderColor: borderColor,
          isOneWay: isOneWay,
        );

  void startMoving() {
    if (!_hasArrived) {
      _isMoving = true;
    }
  }

  void reset() {
    position.setFrom(initialPosition);
    _isMoving = false;
    _hasArrived = false;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_isMoving || _hasArrived) return;

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

  void _carryPlayer(Vector2 deltaMove) {
    try {
      final player = game.player;
      if (player != null && player.isAlive && player.isOnGround) {
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
