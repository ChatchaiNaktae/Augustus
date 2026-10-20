import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../iwbtg_game.dart';

abstract class HazardBase extends PositionComponent
    with CollisionCallbacks, HasGameReference<IWBTGGame> {
  final String hazardId;
  bool isDeadly = true;

  HazardBase({
    required Vector2 position,
    required Vector2 size,
    this.hazardId = '',
    int? priority,
  }) : super(position: position, size: size, priority: priority);

  void trigger() {}
  void reset() {}
}
