import 'dart:async';
import 'package:flame/components.dart';
import '../iwbtg_game.dart';
import '../components/platform_block.dart';
import '../components/hazards/hazard_base.dart';
import '../components/hazards/collapsing_block.dart';
import '../components/hazards/trigger_zone.dart';

abstract class StageBase extends Component with HasGameReference<IWBTGGame> {
  final String stageName;
  final int stageIndex;
  final Vector2 defaultSpawnPosition;

  final List<PlatformBlock> platforms = [];
  final List<CollapsingBlock> collapsingPlatforms = [];
  final List<HazardBase> hazards = [];
  final List<TriggerZone> triggerZones = [];

  StageBase({
    required this.stageName,
    required this.stageIndex,
    required this.defaultSpawnPosition,
  });

  @override
  FutureOr<void> add(Component component) {
    if (component is PlatformBlock) {
      platforms.add(component);
    } else if (component is CollapsingBlock) {
      collapsingPlatforms.add(component);
    } else if (component is HazardBase) {
      hazards.add(component);
    } else if (component is TriggerZone) {
      triggerZones.add(component);
    }
    return super.add(component);
  }

  void resetHazards() {
    for (final hazard in hazards) {
      hazard.reset();
    }
    for (final trigger in triggerZones) {
      trigger.reset();
    }
    for (final block in collapsingPlatforms) {
      block.reset();
    }
  }

  void completeStage() {
    game.onStageCleared(stageIndex);
  }
}
