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

    // Deadly Spikes inside the pit
    for (double x = 260; x < 420; x += 32) {
      add(SpikeHazard(position: Vector2(x, 568), direction: SpikeDirection.up));
    }

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

    // Trap 2 (Fakeout): As player jumps up to platform 1 to dodge the apple, a 2nd apple rushes left!
    final appleA2 = AppleHazard(
      position: Vector2(210, 410),
      behavior: AppleBehavior.flyLeft,
      hazardId: "apple_drop_fakeout",
    );
    add(appleA2);

    add(TriggerZone(
      position: Vector2(140, 415),
      size: Vector2(20, 30),
      onTrigger: () => appleA2.trigger(),
    ));

    // Trap 3: The Infamous "Anti-Gravity Sky-Rocket Apple"
    // Launches straight UP only when player is genuinely leaping over the pit (x: 330-348)
    final appleB = AppleHazard(
      position: Vector2(340, 530),
      behavior: AppleBehavior.flyUp,
      hazardId: "apple_rocket_1",
    );
    add(appleB);

    // Point-blank trigger: strictly on the mid-stone leap trajectory (x: 330-348)
    add(TriggerZone(
      position: Vector2(330, 430),
      size: Vector2(18, 50),
      onTrigger: () => appleB.trigger(),
    ));

    // Trap 4: Surprise Skyward Spike leaping from pit edge when jumping to the right floor
    final pitSpike = SpikeHazard(
      position: Vector2(410, 568),
      direction: SpikeDirection.up,
      triggerVelocity: Vector2(0, -950),
      hazardId: "spike_pit_launch",
    );
    add(pitSpike);

    add(TriggerZone(
      position: Vector2(370, 440),
      size: Vector2(18, 40),
      onTrigger: () => pitSpike.trigger(),
    ));

    // Trap 5: Horizontal Ambush Apple rushing left when player lands point-blank on platform 620,340
    final appleC = AppleHazard(
      position: Vector2(720, 335),
      behavior: AppleBehavior.flyLeft,
      hazardId: "apple_rusher_1",
    );
    add(appleC);

    // Point-blank trigger on platform edge (x: 630-648)
    add(TriggerZone(
      position: Vector2(630, 315),
      size: Vector2(18, 25),
      onTrigger: () => appleC.trigger(),
    ));

    // Trap 6: Troll Ceiling Drop right before the exit sign!
    final appleExit = AppleHazard(
      position: Vector2(710, 32),
      behavior: AppleBehavior.fallDown,
      hazardId: "apple_exit_troll",
    );
    add(appleExit);

    // Point-blank trigger right before exit sign (x: 695-715)
    add(TriggerZone(
      position: Vector2(695, 520),
      size: Vector2(20, 48),
      onTrigger: () => appleExit.trigger(),
    ));

    // 4. Stage Exit Trigger (Right boundary at bottom right)
    add(TriggerZone(
      position: Vector2(775, 480),
      size: Vector2(25, 88),
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

    // Decorative sign at exit
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
    textPainter.paint(canvas, const Offset(690, 530));
  }
}
