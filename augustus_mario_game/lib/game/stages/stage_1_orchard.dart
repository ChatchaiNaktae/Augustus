import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'stage_base.dart';
import '../game_constants.dart';
import '../components/platform_block.dart';
import '../components/hazards/spike_hazard.dart';
import '../components/hazards/apple_hazard.dart';
import '../components/hazards/trigger_zone.dart';

class Stage1Orchard extends StageBase {
  Stage1Orchard()
      : super(
          stageName: "STAGE 1: THE DECEPTIVE ORCHARD",
          stageIndex: 1,
          defaultSpawnPosition: Vector2(70, 540),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Surrounding Boundary Walls
    // Left Wall
    add(PlatformBlock(position: Vector2(0, 0), size: Vector2(32, GameConstants.gameHeight)));
    // Ceiling
    add(PlatformBlock(position: Vector2(0, 0), size: Vector2(GameConstants.gameWidth, 32)));

    // Bottom Floors (with dangerous pit in between)
    // Left Floor
    add(PlatformBlock(position: Vector2(0, 568), size: Vector2(260, 32)));
    // Right Floor
    add(PlatformBlock(position: Vector2(420, 568), size: Vector2(380, 32)));

    // Deadly Spikes inside the pit (Strictly grid-aligned across x: 260 to 420; exactly 5 spikes)
    add(SpikeHazard(position: Vector2(260, 568), direction: SpikeDirection.up));
    add(SpikeHazard(position: Vector2(292, 568), direction: SpikeDirection.up));

    // Trap 3: Disguised Pit Rocket Spike (Seamlessly placed at x: 324, y: 568)
    // Replaces the old floating mid-air apple; completely blends with floor spikes until triggered!
    final pitRocketSpike = SpikeHazard(
      position: Vector2(324, 568),
      direction: SpikeDirection.up,
      triggerVelocity: Vector2(0, -1100),
      hazardId: "spike_pit_rocket",
    );
    add(pitRocketSpike);

    add(TriggerZone(
      position: Vector2(325, 430),
      size: Vector2(20, 50),
      onTrigger: () => pitRocketSpike.trigger(),
    ));

    add(SpikeHazard(position: Vector2(356, 568), direction: SpikeDirection.up));
    // 5th spike ends exactly at x = 420, perfectly flush with the Right Floor block (Zero overlap)
    add(SpikeHazard(position: Vector2(388, 568), direction: SpikeDirection.up));

    // 2. Platforms & Structures
    // Low platform 1
    add(PlatformBlock(position: Vector2(130, 440), size: Vector2(100, 24)));

    // Mid-pit floating stepping stone
    add(PlatformBlock(position: Vector2(310, 460), size: Vector2(70, 20)));

    // Right side stairs/platforms
    add(PlatformBlock(position: Vector2(480, 420), size: Vector2(100, 24)));
    add(PlatformBlock(position: Vector2(620, 340), size: Vector2(100, 24)));

    // High resting platform
    add(PlatformBlock(position: Vector2(660, 200), size: Vector2(100, 24)));

    // 3. Handcrafted IWBTG Troll Traps (Point-Blank Proximity)!

    // Trap 1: The "Normal" Falling Apple (Drops only when player is directly underneath)
    final appleA = AppleHazard(
      position: Vector2(170, 120),
      behavior: AppleBehavior.fallDown,
      hazardId: "apple_drop_1",
    );
    add(appleA);

    // Point-blank trigger: directly aligned underneath Apple A (x: 162-180)
    add(TriggerZone(
      position: Vector2(162, 450),
      size: Vector2(18, 118),
      onTrigger: () => appleA.trigger(),
    ));

    // Trap 2: Dynamic Directional Ambush Apple under tree!
    // Senses player position: if player is to the left, shoots left; if to the right, shoots right!
    final appleA2 = AppleHazard(
      position: Vector2(205, 416),
      hazardId: "apple_tree_rusher",
    );
    add(appleA2);

    add(TriggerZone(
      position: Vector2(130, 380),
      size: Vector2(110, 60),
      onTrigger: () {
        final player = game.player;
        if (player != null) {
          appleA2.launchTowards(player.position.x, speed: 1050);
        } else {
          appleA2.trigger();
        }
      },
    ));

    // Trap 4: Sliding Platform Spike (Sits directly ON TOP of platform 620,340 at x=688, y=308)
    // When player approaches, slides left across the platform and stops at the leftmost edge (x=620)!
    final platformSpike = SpikeHazard(
      position: Vector2(688, 308),
      direction: SpikeDirection.up,
      triggerVelocity: Vector2(-850, 0),
      stopAtX: 620.0,
      hazardId: "spike_platform_slider",
    );
    add(platformSpike);

    // Point-blank trigger on jump approach to platform 620,340
    add(TriggerZone(
      position: Vector2(590, 260),
      size: Vector2(35, 90),
      onTrigger: () => platformSpike.trigger(),
    ));

    // Trap 5: Troll Ceiling Drop right before the exit on the high platform!
    final appleExit = AppleHazard(
      position: Vector2(710, 32),
      behavior: AppleBehavior.fallDown,
      hazardId: "apple_exit_troll",
    );
    add(appleExit);

    // Point-blank trigger on the high platform (x: 675-695)
    add(TriggerZone(
      position: Vector2(675, 160),
      size: Vector2(20, 40),
      onTrigger: () => appleExit.trigger(),
    ));

    // 4. Stage Exit Trigger (Right edge of high platform at top right)
    add(TriggerZone(
      position: Vector2(745, 120),
      size: Vector2(35, 80),
      onTrigger: () => completeStage(),
    ));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Render decorative retro tree trunk & foliage
    final treeTrunkPaint = Paint()..color = const Color(0xFF4A3728);
    canvas.drawRect(const Rect.fromLTWH(170, 140, 20, 300), treeTrunkPaint);

    final foliagePaint = Paint()..color = const Color(0xFF2E6F40);
    canvas.drawCircle(const Offset(180, 120), 45, foliagePaint);
    canvas.drawCircle(const Offset(150, 100), 35, foliagePaint);
    canvas.drawCircle(const Offset(210, 105), 35, foliagePaint);

    // Decorative sign at exit (moved to top right platform)
    final textPainter = TextPainter(
      text: const TextSpan(
        text: "STAGE 2 >>",
        style: TextStyle(
          color: Color(0xFFE5C07B),
          fontSize: 14,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(675, 160));
  }
}
