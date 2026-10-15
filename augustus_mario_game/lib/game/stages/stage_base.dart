import 'package:flame/components.dart';
import '../iwbtg_game.dart';
import '../components/hazards/hazard_base.dart';
import '../components/hazards/trigger_zone.dart';

abstract class StageBase extends Component with HasGameReference<IWBTGGame> {
  final String stageName;
  final int stageIndex;
  final Vector2 defaultSpawnPosition;

  StageBase({
    required this.stageName,
    required this.stageIndex,
    required this.defaultSpawnPosition,
  });

  void resetHazards() {
    for (final child in children) {
      if (child is HazardBase) {
        child.reset();
      } else if (child is TriggerZone) {
        child.reset();
      }
    }
  }

  void completeStage() {
    game.onStageCleared(stageIndex);
  }
}
