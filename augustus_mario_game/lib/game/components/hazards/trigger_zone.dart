import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../player.dart';

class TriggerZone extends PositionComponent with CollisionCallbacks {
  final List<String> targetHazardIds;
  final VoidCallback? onTrigger;
  final bool triggerOnce;
  final bool defaultEnabled;
  bool isEnabled;
  bool _hasTriggered = false;

  bool get hasTriggered => _hasTriggered;

  TriggerZone({
    required super.position,
    required super.size,
    this.targetHazardIds = const [],
    this.onTrigger,
    this.triggerOnce = true,
    this.isEnabled = true,
  }) : defaultEnabled = isEnabled {
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  void activate() {
    if (!isEnabled) return;
    if (triggerOnce && _hasTriggered) return;
    _hasTriggered = true;
    onTrigger?.call();
  }

  void reset() {
    _hasTriggered = false;
    isEnabled = defaultEnabled;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Player && other.isAlive) {
      activate();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player && other.isAlive) {
      activate();
    }
  }
}
