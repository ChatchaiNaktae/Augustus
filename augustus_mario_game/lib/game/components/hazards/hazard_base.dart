import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../iwbtg_game.dart';

abstract class HazardBase extends PositionComponent
    with CollisionCallbacks, HasGameReference<IWBTGGame> {
  final String hazardId;
  bool isDeadly = true;

  HazardBase({
    required Vector2 super.position,
    required Vector2 super.size,
    this.hazardId = '',
    super.priority,
  });

  void trigger() {}
  void reset() {}
}
