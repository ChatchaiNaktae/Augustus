import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../iwbtg_game.dart';
import '../utils/game_asset_loader.dart';
import 'player.dart';

class SavePointComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<IWBTGGame> {
  bool isActivated = false;
  Sprite? _sprite;

  SavePointComponent({required Vector2 position, Vector2? size})
      : super(
          position: position,
          size: size ?? Vector2(32, 32),
          anchor: Anchor.topLeft,
        ) {
    add(RectangleHitbox());
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = await GameAssetLoader.loadOptionalSprite('items/save_point.png');
  }

  void activate(Player player) {
    if (isActivated) return;
    isActivated = true;
    player.respawnPosition.setFrom(position + Vector2(4, 0));
  }

  void reset() {
    isActivated = false;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player) {
      activate(other);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_sprite != null) {
      _sprite!.render(canvas, size: size);
      if (isActivated) {
        final glowPaint = Paint()
          ..color = const Color(0xFFA3BE8C).withValues(alpha: 0.35)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width, height), const Radius.circular(4)),
          glowPaint,
        );
        final borderPaint = Paint()
          ..color = const Color(0xFFA3BE8C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width, height), const Radius.circular(4)),
          borderPaint,
        );
      }
      return;
    }

    final bgPaint = Paint()
      ..color = isActivated ? const Color(0xFFA3BE8C) : const Color(0xFFBF616A);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), borderPaint);

    // Retro Floppy Disk / Checkpoint Icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: isActivated ? "SAVED" : "SAVE",
        style: TextStyle(
          color: isActivated ? Colors.black : Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset((width - textPainter.width) / 2, (height - textPainter.height) / 2),
    );
  }
}
