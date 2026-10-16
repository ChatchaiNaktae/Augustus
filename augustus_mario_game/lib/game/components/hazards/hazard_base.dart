import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../iwbtg_game.dart';

abstract class HazardBase extends PositionComponent
    with CollisionCallbacks, HasGameReference<IWBTGGame> {
  final String hazardId;
  bool isDeadly = true;

  HazardBase({
    required super.position,
    required super.size,
    this.hazardId = '',
  });

  void trigger() {}
  void reset() {}
}
