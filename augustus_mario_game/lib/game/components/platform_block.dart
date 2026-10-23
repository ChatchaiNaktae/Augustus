import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_constants.dart';
import '../utils/game_asset_loader.dart';

class PlatformBlock extends PositionComponent with CollisionCallbacks {
  final Color fillColor;
  final Color borderColor;
  final bool isOneWay;
  bool isSolid;
  Sprite? _sprite;

  PlatformBlock({
    required Vector2 super.position,
    required Vector2 super.size,
    this.fillColor = GameConstants.tileColor,
    this.borderColor = GameConstants.tileBorderColor,
    this.isOneWay = false,
    this.isSolid = true,
    super.priority,
  }) {
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = await GameAssetLoader.loadOptionalSprite('tiles/tile_block.png');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_sprite != null) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, width, height));
      for (double x = 0; x < width; x += 32) {
        for (double y = 0; y < height; y += 32) {
          _sprite!.render(
            canvas,
            position: Vector2(x, y),
            size: Vector2(32, 32),
          );
        }
      }
      canvas.restore();
      return;
    }

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
