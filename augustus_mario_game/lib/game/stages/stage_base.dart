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
    _registerComponent(component);
    return super.add(component);
  }

  @override
  Future<void> addAll(Iterable<Component> components) {
    for (final component in components) {
      _registerComponent(component);
    }
    return super.addAll(components);
  }

  void _registerComponent(Component component) {
    if (component is PlatformBlock) {
      if (!platforms.contains(component)) platforms.add(component);
    } else if (component is CollapsingBlock) {
      if (!collapsingPlatforms.contains(component)) collapsingPlatforms.add(component);
    } else if (component is HazardBase) {
      if (!hazards.contains(component)) hazards.add(component);
    } else if (component is TriggerZone) {
      if (!triggerZones.contains(component)) triggerZones.add(component);
    }
  }

  @override
  void remove(Component component) {
    if (component is PlatformBlock) {
      platforms.remove(component);
    } else if (component is CollapsingBlock) {
      collapsingPlatforms.remove(component);
    } else if (component is HazardBase) {
      hazards.remove(component);
    } else if (component is TriggerZone) {
      triggerZones.remove(component);
    }
    super.remove(component);
  }

  void resetHazards() {
    final Set<HazardBase> allHazards = {...hazards, ...children.whereType<HazardBase>()};
    for (final hazard in allHazards) {
      hazard.reset();
    }
    final Set<TriggerZone> allTriggers = {...triggerZones, ...children.whereType<TriggerZone>()};
    for (final trigger in allTriggers) {
      trigger.reset();
    }
    final Set<CollapsingBlock> allCollapsing = {...collapsingPlatforms, ...children.whereType<CollapsingBlock>()};
    for (final block in allCollapsing) {
      block.reset();
    }
  }

  void completeStage() {
    game.onStageCleared(stageIndex);
  }
}
