import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../iwbtg_game.dart';
import '../utils/game_asset_loader.dart';
import 'player.dart';

class GoalPortalComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<IWBTGGame> {
  final VoidCallback? onCleared;
  Sprite? _sprite;

  GoalPortalComponent({
    required Vector2 position,
    Vector2? size,
    this.onCleared,
  }) : super(
          position: position,
          size: size ?? Vector2(48, 64),
          anchor: Anchor.topLeft,
        ) {
    add(RectangleHitbox());
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _sprite = await GameAssetLoader.loadOptionalSprite('items/goal_portal.png');
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player && other.isAlive) {
      if (onCleared != null) {
        onCleared!();
      } else {
        game.onVictoryTriggered?.call();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_sprite != null) {
      _sprite!.render(canvas, size: size);
      return;
    }

    // Glowing retro portal
    final portalPaint = Paint()
      ..color = const Color(0xFFEBCB8B)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(4, 4, width - 8, height - 8), const Radius.circular(8)),
      portalPaint,
    );

    final innerPaint = Paint()..color = const Color(0xFFD08770);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(8, 8, width - 16, height - 16), const Radius.circular(6)),
      innerPaint,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(4, 4, width - 8, height - 8), const Radius.circular(8)),
      borderPaint,
    );

    // Portal icon / flag text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: "GOAL",
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
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
