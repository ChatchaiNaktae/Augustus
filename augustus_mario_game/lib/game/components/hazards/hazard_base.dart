import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

abstract class HazardBase extends PositionComponent with CollisionCallbacks {
  final String hazardId;
  bool isDeadly = true;

  HazardBase({
    required Vector2 position,
    required Vector2 size,
    this.hazardId = '',
  }) : super(position: position, size: size);

  void trigger() {}
  void reset() {}
}
