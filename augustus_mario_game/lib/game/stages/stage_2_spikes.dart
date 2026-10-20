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
  bool isEvent2Armed = false;
  bool isGateClosed = false;
  late TriggerZone topExitTrigger;
  late TriggerZone bottomExitTrigger;
  late TriggerZone floorSpawnTrigger;
  late SpikeHazard giantRightWallSpike;

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

    // Event 1 Gate Wall: starts at y=200 (open), slides up to y=32 (closed) when Event 1 triggered
    final gateWall = MovingPlatformBlock(
      position: Vector2(768, 200),
      targetPosition: Vector2(768, 32),
      size: Vector2(32, 168),
      moveSpeed: 800,
    );
    add(gateWall);

    // Floor with spike pit (416px pit = exactly 13 spikes of 32px, perfectly flush with floors)
    add(PlatformBlock(position: Vector2(0, 568), size: Vector2(192, 32), priority: 2));
    add(PlatformBlock(position: Vector2(608, 568), size: Vector2(192, 32), priority: 2));

    // Giant Right Spike (Point 2): Hidden behind left wall, shoots right across floor if player falls back down
    giantRightWallSpike = SpikeHazard(
      position: Vector2(-128, 440),
      customSize: Vector2(160, 128),
      direction: SpikeDirection.right,
      isInitiallyDeadly: false,
      isHidden: true,
      priority: 1,
      hazardId: "spike_giant_wall_right",
    );
    add(giantRightWallSpike);

    // Floor Trigger Zone 2 (Point 2): Armed once player reaches Platform 2. Expanded vertically (y: 440..568) under Platform 1 to floor!
    floorSpawnTrigger = TriggerZone(
      position: Vector2(32, 440),
      size: Vector2(160, 128),
      isEnabled: false,
      onTrigger: () => giantRightWallSpike.slideTo(32, speed: 1400),
    );
    add(floorSpawnTrigger);

    // Floor Spikes in the middle pit (192 to 608)
    // x = 320 is reserved for pitSpike2 so spikes never overlap!
    for (double x = 192; x < 608; x += 32) {
      if ((x - 320).abs() < 1.0) {
        continue;
      }
      add(SpikeHazard(position: Vector2(x, 568), direction: SpikeDirection.up));
    }

    // 2. Platforms & Labyrinth Ledges
    // Platform 1 (Image 1 Req 2): Crumbles and collapses after standing for 3 seconds!
    final platform1 = CollapsingBlock(
      position: Vector2(120, 430),
      size: Vector2(80, 24),
      collapseDelay: 3.0,
      warningDuration: 1.0,
      hazardId: "platform_1_crumbling",
    );
    add(platform1);

    // Platform 2: Rendered with priority 2 to cover the hidden left spike behind its left edge
    final platform2 = PlatformBlock(
      position: Vector2(240, 340),
      size: Vector2(80, 24),
      priority: 2,
    );
    add(platform2);

    // Trigger Zone (Point 1): Arms bottom floor trap when player reaches Platform 2
    add(TriggerZone(
      position: Vector2(240, 290),
      size: Vector2(80, 50),
      triggerOnce: false,
      onTrigger: () {
        floorSpawnTrigger.isEnabled = true;
      },
    ));

    // Trap (Image 1 Req 1): Hidden Left Spike concealed behind Platform 2 (priority 1)
    // When player approaches Platform 1's right edge, it slowly emerges 32px out to x=208
    final hiddenLeftSpike = SpikeHazard(
      position: Vector2(240, 340),
      customSize: Vector2(32, 24),
      direction: SpikeDirection.left,
      isInitiallyDeadly: false,
      priority: 1,
      hazardId: "spike_hidden_left",
    );
    add(hiddenLeftSpike);

    // Trigger Zone: Catches player approaching right edge of Platform 1
    add(TriggerZone(
      position: Vector2(175, 390),
      size: Vector2(30, 45),
      onTrigger: () => hiddenLeftSpike.slideTo(208, speed: 100),
    ));

    // Mid-height resting platform (Slides to x=460 when triggered mid-air, crumbles after 3s standing)
    final midPlatform = MovingPlatformBlock(
      position: Vector2(400, 240),
      targetPosition: Vector2(460, 240),
      size: Vector2(100, 24),
      moveSpeed: 180,
      collapseDelay: 3.0,
      warningDuration: 1.0,
    );
    add(midPlatform);

    // Collapsing Fake Floor between platforms!
    final fakePlatform = CollapsingBlock(
      position: Vector2(280, 450),
      size: Vector2(80, 24),
    );
    add(fakePlatform);

    // High platforms leading to exit
    // Platform 3 (priority 2 to conceal hidden left spike behind its left edge)
    final platform3 = PlatformBlock(
      position: Vector2(560, 200),
      size: Vector2(90, 24),
      priority: 2,
    );
    add(platform3);

    // Trap 9 (Image 1 Req 1): Hidden Left Spike concealed behind Platform 3 (priority 1)
    // When player approaches right edge of midPlatform, it slowly emerges 32px out to x=528
    final hiddenLeftSpike2 = SpikeHazard(
      position: Vector2(560, 200),
      customSize: Vector2(32, 24),
      direction: SpikeDirection.left,
      isInitiallyDeadly: false,
      priority: 1,
      hazardId: "spike_hidden_left_2",
    );
    add(hiddenLeftSpike2);

    // Trigger Zone: Catches player approaching right edge of midPlatform (purple/white box in Image)
    add(TriggerZone(
      position: Vector2(520, 190),
      size: Vector2(35, 50),
      onTrigger: () => hiddenLeftSpike2.slideTo(528, speed: 100),
    ));
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

    // Event 2 (Image 1 Req 2): Giant Spike on Platform 3 (hidden until triggered if player backtracks after Event 1)
    final platform3GiantSpike = SpikeHazard(
      position: Vector2(565, 200),
      customSize: Vector2(80, 100),
      direction: SpikeDirection.up,
      isInitiallyDeadly: false,
      isHidden: true,
      priority: 1,
      hazardId: "spike_p3_giant",
    );
    add(platform3GiantSpike);

    add(TriggerZone(
      position: Vector2(560, 140),
      size: Vector2(90, 60),
      triggerOnce: false,
      onTrigger: () {
        if (isEvent2Armed) {
          platform3GiantSpike.slideToY(100, speed: 1400);
        }
      },
    ));

    // Event 3 (Image 1 Req 3): Giant Floor Spike in Chasm (hidden until triggered, shoots up when player falls into gap)
    final chasmGiantSpike = SpikeHazard(
      position: Vector2(635, 568),
      customSize: Vector2(80, 240),
      direction: SpikeDirection.up,
      isInitiallyDeadly: false,
      isHidden: true,
      priority: 1,
      hazardId: "spike_chasm_giant",
    );
    add(chasmGiantSpike);

    // Trigger Zone 3: Expanded vertically to floor (y: 260..568) to catch players jumping across
    add(TriggerZone(
      position: Vector2(640, 260),
      size: Vector2(75, 308),
      onTrigger: () {
        chasmGiantSpike.slideToY(328, speed: 1500);
      },
    ));

    // 4. Stage Exit & Event 1 (Troll Gate & Exit Relocation)
    topExitTrigger = TriggerZone(
      position: Vector2(745, 80),
      size: Vector2(25, 60),
      onTrigger: () => completeStage(),
    );
    add(topExitTrigger);

    bottomExitTrigger = TriggerZone(
      position: Vector2(725, 520),
      size: Vector2(40, 48),
      isEnabled: false,
      onTrigger: () => completeStage(),
    );
    add(bottomExitTrigger);

    // Trigger Zone 1 (Event 1): Slams gate shut and moves exit to bottom right
    add(TriggerZone(
      position: Vector2(690, 90),
      size: Vector2(35, 50),
      onTrigger: () {
        gateWall.startMoving();
        topExitTrigger.isEnabled = false;
        bottomExitTrigger.isEnabled = true;
        isGateClosed = true;
        isEvent2Armed = true;
      },
    ));
  }

  @override
  void resetHazards() {
    super.resetHazards();
    isEvent2Armed = false;
    isGateClosed = false;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final textPainter = TextPainter(
      text: TextSpan(
        text: isGateClosed ? "STAGE 3 ↓↓" : "STAGE 3 >>",
        style: const TextStyle(
          color: Color(0xFFE5C07B),
          fontSize: 14,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    if (isGateClosed) {
      textPainter.paint(canvas, const Offset(690, 490));
    } else {
      textPainter.paint(canvas, const Offset(680, 80));
    }
  }
}
