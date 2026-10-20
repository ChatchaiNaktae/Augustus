import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../iwbtg_game.dart';
import '../components/platform_block.dart';
import '../components/moving_platform_block.dart';
import '../components/hazards/hazard_base.dart';
import '../components/hazards/collapsing_block.dart';
import '../components/hazards/trigger_zone.dart';
import '../components/hazards/spike_hazard.dart';
import '../components/hazards/apple_hazard.dart';

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
    final Set<MovingPlatformBlock> allMoving = {
      ...platforms.whereType<MovingPlatformBlock>(),
      ...children.whereType<MovingPlatformBlock>(),
    };
    for (final block in allMoving) {
      block.reset();
    }
  }

  void completeStage() {
    game.onStageCleared(stageIndex);
  }

  @override
  void renderTree(Canvas canvas) {
    super.renderTree(canvas);

    if (game.showHazardHitboxes) {
      _renderHazardHitboxes(canvas);
    }
  }

  void _renderHazardHitboxes(Canvas canvas) {
    final Set<HazardBase> allHazards = {...hazards, ...children.whereType<HazardBase>()};
    for (final hazard in allHazards) {
      if (hazard is SpikeHazard) {
        final vertices = hazard.getTriangleVertices();
        if (vertices.isEmpty) continue;
        final path = Path();
        final start = hazard.position + vertices.first;
        path.moveTo(start.x, start.y);
        for (int i = 1; i < vertices.length; i++) {
          final pt = hazard.position + vertices[i];
          path.lineTo(pt.x, pt.y);
        }
        path.close();

        final color = hazard.isHidden ? const Color(0xFFBD93F9) : const Color(0xFF50FA7B);
        final fillPaint = Paint()
          ..color = color.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        final strokePaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
      } else if (hazard is AppleHazard) {
        final center = Offset(hazard.position.x + hazard.radius, hazard.position.y + hazard.radius);
        final color = const Color(0xFF50FA7B);
        final fillPaint = Paint()
          ..color = color.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        final strokePaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(center, hazard.radius - 1, fillPaint);
        canvas.drawCircle(center, hazard.radius - 1, strokePaint);
      }
    }

    // Render Trigger Zone bounds (Cyan for active/armed, Slate Blue for disarmed)
    final Set<TriggerZone> allTriggers = {...triggerZones, ...children.whereType<TriggerZone>()};
    for (final trigger in allTriggers) {
      final rect = Rect.fromLTWH(
        trigger.position.x,
        trigger.position.y,
        trigger.width,
        trigger.height,
      );
      final bool isDisarmed = trigger.triggerOnce && trigger.hasTriggered;
      final color = isDisarmed ? const Color(0xFF6272A4) : const Color(0xFF00E5FF);

      final fillPaint = Paint()
        ..color = color.withValues(alpha: isDisarmed ? 0.08 : 0.20)
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = color.withValues(alpha: isDisarmed ? 0.40 : 0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);
    }
  }
}
