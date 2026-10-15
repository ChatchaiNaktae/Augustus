import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TriggerZone extends PositionComponent with CollisionCallbacks {
  final List<String> targetHazardIds;
  final VoidCallback? onTrigger;
  final bool triggerOnce;
  bool _hasTriggered = false;

  TriggerZone({
    required Vector2 position,
    required Vector2 size,
    this.targetHazardIds = const [],
    this.onTrigger,
    this.triggerOnce = true,
  }) : super(position: position, size: size) {
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  void activate() {
    if (triggerOnce && _hasTriggered) return;
    _hasTriggered = true;
    onTrigger?.call();
  }

  void reset() {
    _hasTriggered = false;
  }
}
