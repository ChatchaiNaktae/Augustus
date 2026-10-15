import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_constants.dart';
import 'bullet.dart';

class SavePoint extends PositionComponent with CollisionCallbacks {
  bool isSaved = false;
  final VoidCallback? onSaved;
  final Vector2 respawnPosition;

  SavePoint({
    required Vector2 position,
    required this.respawnPosition,
    this.onSaved,
    double size = 32.0,
  }) : super(
          position: position,
          size: Vector2.all(size),
        ) {
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  void activateSave() {
    if (!isSaved) {
      isSaved = true;
      onSaved?.call();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Bullet) {
      activateSave();
      other.removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Rect.fromLTWH(0, 0, width, height);
    final statusColor = isSaved ? GameConstants.savePointSaved : GameConstants.savePointUnsaved;

    // Outer floppy disk / box
    final boxPaint = Paint()..color = const Color(0xFF1E222D);
    canvas.drawRect(rect, boxPaint);

    // Border
    final borderPaint = Paint()
      ..color = statusColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(rect, borderPaint);

    // Disk label / inner rectangle
    final labelRect = Rect.fromLTWH(4, 4, width - 8, height - 12);
    final labelPaint = Paint()..color = statusColor.withValues(alpha: 0.2);
    canvas.drawRect(labelRect, labelPaint);

    // Text: SAVE or SAVED
    final textPainter = TextPainter(
      text: TextSpan(
        text: isSaved ? "SAVED" : "SAVE",
        style: TextStyle(
          color: statusColor,
          fontSize: isSaved ? 7.5 : 8.5,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((width - textPainter.width) / 2, (height - textPainter.height) / 2),
    );
  }
}
