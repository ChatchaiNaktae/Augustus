import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_constants.dart';

class PlatformBlock extends PositionComponent with CollisionCallbacks {
  final Color fillColor;
  final Color borderColor;
  final bool isOneWay;

  PlatformBlock({
    required Vector2 position,
    required Vector2 size,
    this.fillColor = GameConstants.tileColor,
    this.borderColor = GameConstants.tileBorderColor,
    this.isOneWay = false,
    int? priority,
  }) : super(position: position, size: size, priority: priority) {
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw solid base
    final paint = Paint()..color = fillColor;
    final rect = Rect.fromLTWH(0, 0, width, height);
    canvas.drawRect(rect, paint);

    // Draw retro grid border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(rect, borderPaint);

    // Subtle 8-bit highlight on top edge
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(1, 1), Offset(width - 1, 1), highlightPaint);

    // Draw inner brick pattern if block is large enough
    if (width >= 32 && height >= 32) {
      final brickPaint = Paint()
        ..color = borderColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      for (double y = 16; y < height; y += 16) {
        canvas.drawLine(Offset(0, y), Offset(width, y), brickPaint);
      }
      for (double x = 16; x < width; x += 32) {
        canvas.drawLine(Offset(x, 0), Offset(x, height), brickPaint);
      }
    }
  }
}
