import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'platform_block.dart';
import '../game_constants.dart';
import '../iwbtg_game.dart';

/// Platform that rotates 90 degrees clockwise into a vertical wall/pillar
/// when the player stands on it.
class RotatingPlatformBlock extends PlatformBlock with HasGameReference<IWBTGGame> {
  final Vector2 initialPos;
  final Vector2 horizontalSize;
  final Vector2 verticalSize;
  final Vector2 pivotCenter;

  bool _isTriggered = false;
  bool _isRotated = false;
  double _rotateProgress = 0.0; // 0.0 (horizontal) to 1.0 (vertical)
  static const double rotateDuration = 0.22; // 0.22s snappy flip

  bool get isRotated => _isRotated;

  RotatingPlatformBlock({
    required Vector2 position,
    required Vector2 size,
    Color fillColor = GameConstants.tileColor,
    Color borderColor = GameConstants.tileBorderColor,
    int? priority,
  })  : initialPos = position.clone(),
        horizontalSize = size.clone(),
        verticalSize = Vector2(size.y, size.x),
        pivotCenter = Vector2(position.x + size.x / 2, position.y + size.y / 2),
        super(
          position: position,
          size: size,
          fillColor: fillColor,
          borderColor: borderColor,
          priority: priority,
        );

  void trigger() {
    if (!_isTriggered) {
      _isTriggered = true;
    }
  }

  void reset() {
    _isTriggered = false;
    _isRotated = false;
    _rotateProgress = 0.0;
    position.setFrom(initialPos);
    size.setFrom(horizontalSize);
    isSolid = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Check if player lands/stands on top while still horizontal
    if (!_isTriggered) {
      try {
        final player = game.player;
        if (player != null && player.isAlive && player.isOnGround) {
          final pRect = player.toRect();
          final bRect = toRect();
          // Feet touching top surface
          if ((pRect.bottom - bRect.top).abs() <= 6.0 &&
              pRect.right > bRect.left + 2.0 &&
              pRect.left < bRect.right - 2.0) {
            trigger();
          }
        }
      } catch (_) {}
    }

    if (_isTriggered && !_isRotated) {
      _rotateProgress += dt / rotateDuration;
      if (_rotateProgress >= 1.0) {
        _rotateProgress = 1.0;
        _isRotated = true;
      }

      // Morph physical AABB smoothly around the fixed pivotCenter (440, 330)
      final currentW = lerpDouble(horizontalSize.x, verticalSize.x, _rotateProgress)!;
      final currentH = lerpDouble(horizontalSize.y, verticalSize.y, _rotateProgress)!;
      size.setValues(currentW, currentH);
      position.setValues(pivotCenter.x - currentW / 2, pivotCenter.y - currentH / 2);

      // Prevent player from getting trapped inside the morphing/rotating pillar
      try {
        final player = game.player;
        if (player != null && player.isAlive) {
          final pRect = player.toRect();
          final bRect = toRect();
          if (pRect.overlaps(bRect)) {
            if (player.position.x + player.width / 2 < pivotCenter.x) {
              player.position.x = bRect.left - player.width;
            } else {
              player.position.x = bRect.right;
            }
          }
        }
      } catch (_) {}
    }
  }

  @override
  void render(Canvas canvas) {
    final currentAngle = _rotateProgress * (pi / 2);

    canvas.save();
    canvas.translate(width / 2, height / 2);
    canvas.rotate(currentAngle);

    // Draw using original horizontal dimensions centered on local origin
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: horizontalSize.x,
      height: horizontalSize.y,
    );

    final bgPaint = Paint()..color = fillColor;
    canvas.drawRect(rect, bgPaint);

    final borderPaint = Paint()
      ..color = _isTriggered ? const Color(0xFFE06C75) : borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(rect, borderPaint);

    // Inner detail rivet/lines to show mechanical rotation
    final detailPaint = Paint()
      ..color = const Color(0xFF4C566A)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(-horizontalSize.x / 2 + 6, 0), Offset(horizontalSize.x / 2 - 6, 0), detailPaint);
    canvas.drawCircle(Offset.zero, 3.0, Paint()..color = const Color(0xFF88C0D0));

    canvas.restore();
  }
}
