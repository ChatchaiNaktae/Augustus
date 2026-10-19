import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'stage_base.dart';
import '../game_constants.dart';
import '../components/platform_block.dart';
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

    // Floor with spike pit
    add(PlatformBlock(position: Vector2(0, 568), size: Vector2(180, 32)));
    add(PlatformBlock(position: Vector2(600, 568), size: Vector2(200, 32)));

    // Floor Spikes in the middle pit
    for (double x = 180; x < 600; x += 32) {
      add(SpikeHazard(position: Vector2(x, 568), direction: SpikeDirection.up));
    }

    // 2. Platforms & Labyrinth Ledges
    add(PlatformBlock(position: Vector2(120, 430), size: Vector2(80, 24)));
    add(PlatformBlock(position: Vector2(240, 340), size: Vector2(80, 24)));

    // Mid-height resting platform
    add(PlatformBlock(position: Vector2(400, 240), size: Vector2(100, 24)));

    // Collapsing Fake Floor between platforms!
    final fakePlatform = CollapsingBlock(
      position: Vector2(280, 450),
      size: Vector2(80, 24),
    );
    add(fakePlatform);

    // High platforms leading to exit
    add(PlatformBlock(position: Vector2(560, 200), size: Vector2(90, 24)));
    add(PlatformBlock(position: Vector2(680, 140), size: Vector2(90, 24)));

    // 3. Handcrafted IWBTG Troll Traps (Point-Blank Proximity)!

    // Trap 1: The Guillotine Ceiling Spike (Drops only when player is directly underneath x: 252-270)
    final guillotineSpike = SpikeHazard(
      position: Vector2(260, 32),
      direction: SpikeDirection.down,
      triggerVelocity: Vector2(0, 1250),
      hazardId: "spike_guillotine",
    );
    add(guillotineSpike);

    add(TriggerZone(
      position: Vector2(252, 315),
      size: Vector2(18, 25),
      onTrigger: () => guillotineSpike.trigger(),
    ));

    // Trap 2: Double Guillotine Fakeout! Drops when player tries to rush right to dodge Trap 1 (x: 282-300)
    final guillotineSpike2 = SpikeHazard(
      position: Vector2(290, 32),
      direction: SpikeDirection.down,
      triggerVelocity: Vector2(0, 1250),
      hazardId: "spike_guillotine_2",
    );
    add(guillotineSpike2);

    add(TriggerZone(
      position: Vector2(282, 315),
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

    // Trap 4: Surprise Skyward Pit Spike jumping from below the crumbling platform
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

    // Trap 5: The Rocket Spike (Floor spike shooting straight up as player reaches the edge of platform 560)
    final rocketSpike = SpikeHazard(
      position: Vector2(600, 536),
      direction: SpikeDirection.up,
      triggerVelocity: Vector2(0, -1250),
      hazardId: "spike_rocket",
    );
    add(rocketSpike);

    add(TriggerZone(
      position: Vector2(590, 175),
      size: Vector2(20, 25),
      onTrigger: () => rocketSpike.trigger(),
    ));

    // Trap 6: Ceiling spike ambush dropping onto the final platform before exit
    final exitGuillotine = SpikeHazard(
      position: Vector2(700, 32),
      direction: SpikeDirection.down,
      triggerVelocity: Vector2(0, 1250),
      hazardId: "spike_exit_guillotine",
    );
    add(exitGuillotine);

    add(TriggerZone(
      position: Vector2(692, 115),
      size: Vector2(18, 25),
      onTrigger: () => exitGuillotine.trigger(),
    ));

    // Ceiling spikes hazard above exit passage to force tight low jumps
    for (double x = 680; x < 768; x += 32) {
      add(SpikeHazard(position: Vector2(x, 32), direction: SpikeDirection.down));
    }

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
