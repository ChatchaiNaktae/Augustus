import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'stage_base.dart';
import '../game_constants.dart';
import '../components/platform_block.dart';
import '../components/moving_platform_block.dart';
import '../components/hazards/spike_hazard.dart';
import '../components/hazards/collapsing_block.dart';
import '../components/hazards/trigger_zone.dart';

class Stage2Spikes extends StageBase {
  Stage2Spikes()
      : super(
          stageName: "STAGE 2: THE SPIKE LABYRINTH",
          stageIndex: 2,
          defaultSpawnPosition: Vector2(70, 540),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Dungeon Boundaries
    // Left Wall
    add(PlatformBlock(position: Vector2(0, 0), size: Vector2(32, GameConstants.gameHeight)));
    // Ceiling
    add(PlatformBlock(position: Vector2(0, 0), size: Vector2(GameConstants.gameWidth, 32)));
    // Right Wall (with exit opening at top right)
    add(PlatformBlock(position: Vector2(768, 200), size: Vector2(32, 400)));

    // Floor with spike pit (416px pit = exactly 13 spikes of 32px, perfectly flush with floors)
    add(PlatformBlock(position: Vector2(0, 568), size: Vector2(192, 32)));
    add(PlatformBlock(position: Vector2(608, 568), size: Vector2(192, 32)));

    // Floor Spikes in the middle pit (192 to 608)
    // x = 320 is reserved for pitSpike2 so spikes never overlap!
    for (double x = 192; x < 608; x += 32) {
      if ((x - 320).abs() < 1.0) {
        continue;
      }
      add(SpikeHazard(position: Vector2(x, 568), direction: SpikeDirection.up));
    }

    // 2. Platforms & Labyrinth Ledges
    add(PlatformBlock(position: Vector2(120, 430), size: Vector2(80, 24)));
    add(PlatformBlock(position: Vector2(240, 340), size: Vector2(80, 24)));

    // Mid-height resting platform (Slides to x=460 when triggered mid-air)
    final midPlatform = MovingPlatformBlock(
      position: Vector2(400, 240),
      targetPosition: Vector2(460, 240),
      size: Vector2(100, 24),
      moveSpeed: 180,
    );
    add(midPlatform);

    // Collapsing Fake Floor between platforms!
    final fakePlatform = CollapsingBlock(
      position: Vector2(280, 450),
      size: Vector2(80, 24),
    );
    add(fakePlatform);

    // High platforms leading to exit
    add(PlatformBlock(position: Vector2(560, 200), size: Vector2(90, 24)));
    add(PlatformBlock(position: Vector2(680, 140), size: Vector2(90, 24)));

    // 3. Handcrafted IWBTG Troll Traps (Point-Blank Proximity, Zero Overlap)!

    // Trap 1: The Guillotine Ceiling Spike (Drops only when player is directly underneath x: 248-266)
    final guillotineSpike = SpikeHazard(
      position: Vector2(256, 32),
      direction: SpikeDirection.down,
      triggerVelocity: Vector2(0, 1250),
      hazardId: "spike_guillotine",
    );
    add(guillotineSpike);

    add(TriggerZone(
      position: Vector2(248, 315),
      size: Vector2(18, 25),
      onTrigger: () => guillotineSpike.trigger(),
    ));

    // Trap 2: Double Guillotine Fakeout! Drops when player tries to rush right to dodge Trap 1 (x: 280-298)
    final guillotineSpike2 = SpikeHazard(
      position: Vector2(288, 32),
      direction: SpikeDirection.down,
      triggerVelocity: Vector2(0, 1250),
      hazardId: "spike_guillotine_2",
    );
    add(guillotineSpike2);

    add(TriggerZone(
      position: Vector2(280, 315),
      size: Vector2(18, 25),
      onTrigger: () => guillotineSpike2.trigger(),
    ));

    // Trap 3: Wall Impaler Spike (Shoots horizontally right when player drops down near wall)
    final wallSpike = SpikeHazard(
      position: Vector2(32, 400),
      direction: SpikeDirection.right,
      triggerVelocity: Vector2(1150, 0),
      hazardId: "spike_wall_rusher",
    );
    add(wallSpike);

    add(TriggerZone(
      position: Vector2(75, 410),
      size: Vector2(20, 35),
      onTrigger: () => wallSpike.trigger(),
    ));

    // Trap 3B (Image 1): Catches player jumping onto/across Platform 1 to the right
    add(TriggerZone(
      position: Vector2(110, 340),
      size: Vector2(100, 90),
      onTrigger: () => wallSpike.trigger(),
    ));

    // Trap 4: Surprise Skyward Pit Spike (Occupies x=320 in the pit seamlessly, zero overlap)
    final pitSpike2 = SpikeHazard(
      position: Vector2(320, 568),
      direction: SpikeDirection.up,
      triggerVelocity: Vector2(0, -1150),
      hazardId: "spike_pit_jumper",
    );
    add(pitSpike2);

    add(TriggerZone(
      position: Vector2(305, 425),
      size: Vector2(20, 30),
      onTrigger: () => pitSpike2.trigger(),
    ));

    // Trap 5: The Rocket Spike (Floor spike on right ledge x=608, zero overlap with pit)
    final rocketSpike = SpikeHazard(
      position: Vector2(608, 536),
      direction: SpikeDirection.up,
      triggerVelocity: Vector2(0, -850),
      hazardId: "spike_rocket",
    );
    add(rocketSpike);

    add(TriggerZone(
      position: Vector2(595, 175),
      size: Vector2(20, 25),
      onTrigger: () => rocketSpike.trigger(),
    ));

    // Trap 6: Ceiling spike ambush dropping onto the final platform before exit (x=704)
    final exitGuillotine = SpikeHazard(
      position: Vector2(704, 32),
      direction: SpikeDirection.down,
      triggerVelocity: Vector2(0, 1250),
      hazardId: "spike_exit_guillotine",
    );
    add(exitGuillotine);

    add(TriggerZone(
      position: Vector2(696, 115),
      size: Vector2(18, 25),
      onTrigger: () => exitGuillotine.trigger(),
    ));

    // Ceiling spikes hazard flanking exitGuillotine (x=672, 704[trap], 736 - zero overlap!)
    add(SpikeHazard(position: Vector2(672, 32), direction: SpikeDirection.down));
    add(SpikeHazard(position: Vector2(736, 32), direction: SpikeDirection.down));

    // Trap 7 (Image 2): Mid-air vertical trigger zone that shifts midPlatform to the right
    add(TriggerZone(
      position: Vector2(335, 40),
      size: Vector2(30, 280),
      onTrigger: () => midPlatform.startMoving(),
    ));

    // 4. Stage Exit Trigger (Upper right corner)
    add(TriggerZone(
      position: Vector2(745, 80),
      size: Vector2(25, 60),
      onTrigger: () => completeStage(),
    ));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Decorative dungeon bricks outline
    final textPainter = TextPainter(
      text: const TextSpan(
        text: "STAGE 3 >>",
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
    textPainter.paint(canvas, const Offset(680, 80));
  }
}
