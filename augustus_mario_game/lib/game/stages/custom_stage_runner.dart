import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/custom_stage_data.dart';
import 'stage_base.dart';
import '../components/platform_block.dart';
import '../components/moving_platform_block.dart';
import '../components/rotating_platform_block.dart';
import '../components/hazards/collapsing_block.dart';
import '../components/hazards/spike_hazard.dart';
import '../components/hazards/apple_hazard.dart';
import '../components/hazards/turret_hazard.dart';
import '../components/hazards/sniper_hazard.dart';
import '../components/hazards/trigger_zone.dart';
import '../components/save_point_component.dart';
import '../components/goal_portal_component.dart';

class CustomStageRunner extends StageBase {
  final CustomStageData stageData;

  CustomStageRunner({required this.stageData})
      : super(
          stageName: stageData.title,
          stageIndex: 999, // Custom stage index
          defaultSpawnPosition: Vector2(stageData.spawnX, stageData.spawnY),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Map to keep track of hazards for trigger binding
    final Map<String, dynamic> hazardsById = {};

    for (final elem in stageData.elements) {
      switch (elem.type) {
        case StageElementType.platform:
          final colorVal = elem.color != null ? Color(elem.color!) : null;
          final plat = PlatformBlock(
            position: Vector2(elem.x, elem.y),
            size: Vector2(elem.width, elem.height),
            fillColor: colorVal ?? const Color(0xFF434C5E),
          );
          await add(plat);
          break;

        case StageElementType.movingPlatform:
          final moveRange = (elem.properties['moveRange'] as num?)?.toDouble() ?? 100.0;
          final speed = (elem.properties['speed'] as num?)?.toDouble() ?? 80.0;
          final isHorizontal = elem.properties['horizontal'] as bool? ?? true;
          final targetPos = isHorizontal
              ? Vector2(elem.x + moveRange, elem.y)
              : Vector2(elem.x, elem.y + moveRange);

          final movingPlat = MovingPlatformBlock(
            position: Vector2(elem.x, elem.y),
            targetPosition: targetPos,
            size: Vector2(elem.width, elem.height),
            moveSpeed: speed,
          );
          await add(movingPlat);
          break;

        case StageElementType.rotatingPlatform:
          final rotPlat = RotatingPlatformBlock(
            position: Vector2(elem.x, elem.y),
            size: Vector2(elem.width, elem.height),
          );
          await add(rotPlat);
          break;

        case StageElementType.collapsingBlock:
          final cBlock = CollapsingBlock(
            position: Vector2(elem.x, elem.y),
            size: Vector2(elem.width, elem.height),
          );
          await add(cBlock);
          break;

        case StageElementType.spike:
        case StageElementType.slidingSpike:
          SpikeDirection dir = SpikeDirection.up;
          final rot = elem.rotation.round() % 360;
          if (rot >= 45 && rot < 135) {
            dir = SpikeDirection.right;
          } else if (rot >= 135 && rot < 225) {
            dir = SpikeDirection.down;
          } else if (rot >= 225 && rot < 315) {
            dir = SpikeDirection.left;
          }

          final isTriggered = elem.properties['isTriggered'] as bool? ?? false;
          Vector2? triggerVel;
          if (elem.properties['triggerSpeedX'] != null || elem.properties['triggerSpeedY'] != null) {
            triggerVel = Vector2(
              (elem.properties['triggerSpeedX'] as num?)?.toDouble() ?? 0.0,
              (elem.properties['triggerSpeedY'] as num?)?.toDouble() ?? 0.0,
            );
          }

          final spike = SpikeHazard(
            position: Vector2(elem.x, elem.y),
            direction: dir,
            customSize: Vector2(elem.width, elem.height),
            hazardId: elem.id,
            isTriggered: isTriggered,
            triggerVelocity: triggerVel,
          );
          await add(spike);
          hazardsById[elem.id] = spike;
          break;

        case StageElementType.apple:
          AppleBehavior behavior = AppleBehavior.staticItem;
          final bStr = elem.properties['behavior'] as String?;
          if (bStr == 'flyUp') {
            behavior = AppleBehavior.flyUp;
          } else if (bStr == 'fallDown') {
            behavior = AppleBehavior.fallDown;
          } else if (bStr == 'flyLeft') {
            behavior = AppleBehavior.flyLeft;
          } else if (bStr == 'flyRight') {
            behavior = AppleBehavior.flyRight;
          }

          final apple = AppleHazard(
            position: Vector2(elem.x, elem.y),
            radius: elem.width / 2,
            hazardId: elem.id,
            behavior: behavior,
          );
          await add(apple);
          hazardsById[elem.id] = apple;
          break;

        case StageElementType.turret:
          final turret = TurretHazard(
            position: Vector2(elem.x, elem.y),
            hazardId: elem.id,
          );
          await add(turret);
          hazardsById[elem.id] = turret;
          break;

        case StageElementType.sniper:
          final sniper = SniperHazard(
            position: Vector2(elem.x, elem.y),
          );
          await add(sniper);
          break;

        case StageElementType.savePoint:
          final savePoint = SavePointComponent(
            position: Vector2(elem.x, elem.y),
            size: Vector2(elem.width, elem.height),
          );
          await add(savePoint);
          break;

        case StageElementType.goal:
          final goal = GoalPortalComponent(
            position: Vector2(elem.x, elem.y),
            size: Vector2(elem.width, elem.height),
            onCleared: () => completeStage(),
          );
          await add(goal);
          break;

        case StageElementType.triggerZone:
          final targetId = elem.properties['targetId'] as String?;
          final trigger = TriggerZone(
            position: Vector2(elem.x, elem.y),
            size: Vector2(elem.width, elem.height),
            onTrigger: () {
              if (targetId != null && hazardsById.containsKey(targetId)) {
                final target = hazardsById[targetId];
                if (target is SpikeHazard) {
                  target.trigger();
                } else if (target is AppleHazard) {
                  target.trigger();
                } else if (target is TurretHazard) {
                  target.isActive = true;
                }
              }
            },
          );
          await add(trigger);
          break;
      }
    }
  }

  @override
  void renderTree(Canvas canvas) {
    // Fill stage custom background
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 800, 600),
      Paint()..color = Color(stageData.backgroundColor),
    );
    super.renderTree(canvas);
  }
}
