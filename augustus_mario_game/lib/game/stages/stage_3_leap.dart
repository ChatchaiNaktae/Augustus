import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'stage_base.dart';
import '../game_constants.dart';
import '../components/platform_block.dart';
import '../components/hazards/spike_hazard.dart';
import '../components/hazards/apple_hazard.dart';
import '../components/hazards/collapsing_block.dart';
import '../components/hazards/trigger_zone.dart';

class Stage3Leap extends StageBase {
  Stage3Leap()
      : super(
          stageName: "STAGE 3: THE LEAP OF FAITH",
          stageIndex: 3,
          defaultSpawnPosition: Vector2(70, 540),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Boundaries
    // Left Wall
    add(PlatformBlock(position: Vector2(0, 0), size: Vector2(32, GameConstants.gameHeight)));
    // Right Wall
    add(PlatformBlock(position: Vector2(768, 0), size: Vector2(32, GameConstants.gameHeight)));
    // Ceiling
    add(PlatformBlock(position: Vector2(0, 0), size: Vector2(GameConstants.gameWidth, 32)));

    // Starting Ledge
    add(PlatformBlock(position: Vector2(0, 568), size: Vector2(150, 32)));

    // Victory Altar (Far Right)
    add(PlatformBlock(position: Vector2(650, 500), size: Vector2(120, 100)));

    // Bottomless Spike Pit across the entire bottom
    for (double x = 150; x < 650; x += 32) {
      add(SpikeHazard(position: Vector2(x, 568), direction: SpikeDirection.up));
    }

    // 2. High Altitude Stepping Stones
    add(PlatformBlock(position: Vector2(180, 460), size: Vector2(70, 20)));

    // Platform 2 is a treacherous Collapsing Block!
    final collapse2 = CollapsingBlock(
      position: Vector2(290, 390),
      size: Vector2(65, 20),
    );
    add(collapse2);

    // Mid-air resting platform
    add(PlatformBlock(position: Vector2(400, 320), size: Vector2(80, 20)));

    // Platform 4 before the leap
    add(PlatformBlock(position: Vector2(530, 380), size: Vector2(70, 20)));

    // 3. Handcrafted IWBTG Troll Traps (Point-Blank Proximity)!

    // Trap 1: Surprise Leaping Pit Spike during the first leap
    final leapSpike1 = SpikeHazard(
      position: Vector2(230, 568),
      direction: SpikeDirection.up,
      triggerVelocity: Vector2(0, -1150),
      hazardId: "spike_leap_1",
    );
    add(leapSpike1);

    add(TriggerZone(
      position: Vector2(225, 420),
      size: Vector2(18, 40),
      onTrigger: () => leapSpike1.trigger(),
    ));

    // Trap 2: Ceiling Apple Drop timed with the collapsing platform!
    final collapseApple = AppleHazard(
      position: Vector2(320, 32),
      behavior: AppleBehavior.fallDown,
      hazardId: "apple_collapse_sniper",
    );
    add(collapseApple);

    add(TriggerZone(
      position: Vector2(305, 365),
      size: Vector2(20, 25),
      onTrigger: () => collapseApple.trigger(),
    ));

    // Trap 3: Crossfire Apples! Ambush as player lands on mid platform (x: 425-445)
    final appleLeft = AppleHazard(
      position: Vector2(200, 250),
      behavior: AppleBehavior.flyRight,
      hazardId: "apple_cross_1",
    );
    final appleRight = AppleHazard(
      position: Vector2(480, 250),
      behavior: AppleBehavior.flyLeft,
      hazardId: "apple_cross_2",
    );
    add(appleLeft);
    add(appleRight);

    add(TriggerZone(
      position: Vector2(425, 295),
      size: Vector2(20, 25),
      onTrigger: () {
        appleLeft.trigger();
        appleRight.trigger();
      },
    ));

    // Trap 4: Ceiling Ambush Spike directly above Platform 4 (x: 545-565)
    final dropSpike = SpikeHazard(
      position: Vector2(550, 32),
      direction: SpikeDirection.down,
      triggerVelocity: Vector2(0, 1250),
      hazardId: "spike_altar_drop",
    );
    add(dropSpike);

    add(TriggerZone(
      position: Vector2(545, 355),
      size: Vector2(18, 25),
      onTrigger: () => dropSpike.trigger(),
    ));

    // Trap 5: The Ultimate Trophy Deception Spike!
    // Sits right before the trophy; launches UP when player is within 15px of the trophy
    final trollSpike = SpikeHazard(
      position: Vector2(670, 468),
      direction: SpikeDirection.up,
      triggerVelocity: Vector2(0, -1150),
      hazardId: "spike_trophy_troll",
    );
    add(trollSpike);

    // Point-blank proximity trigger right in front of the trophy (x: 665-680)
    add(TriggerZone(
      position: Vector2(665, 450),
      size: Vector2(15, 50),
      onTrigger: () => trollSpike.trigger(),
    ));

    // 4. The Golden Trophy (Touching triggers victory!)
    add(TriggerZone(
      position: Vector2(710, 450),
      size: Vector2(40, 50),
      onTrigger: () => game.onVictory(),
    ));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw Golden Trophy on Altar
    final trophyCenter = const Offset(730, 475);
    final goldPaint = Paint()..color = const Color(0xFFFFD700);

    // Cup
    final cupPath = Path()
      ..moveTo(trophyCenter.dx - 12, trophyCenter.dy - 16)
      ..lineTo(trophyCenter.dx + 12, trophyCenter.dy - 16)
      ..lineTo(trophyCenter.dx + 8, trophyCenter.dy)
      ..lineTo(trophyCenter.dx - 8, trophyCenter.dy)
      ..close();
    canvas.drawPath(cupPath, goldPaint);

    // Stem and Base
    canvas.drawRect(Rect.fromLTWH(trophyCenter.dx - 3, trophyCenter.dy, 6, 10), goldPaint);
    canvas.drawRect(Rect.fromLTWH(trophyCenter.dx - 10, trophyCenter.dy + 10, 20, 5), goldPaint);

    // Handles
    final handlePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(trophyCenter.dx - 12, trophyCenter.dy - 8), width: 10, height: 12),
      1.5,
      3.14,
      false,
      handlePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(trophyCenter.dx + 12, trophyCenter.dy - 8), width: 10, height: 12),
      -1.5,
      3.14,
      false,
      handlePaint,
    );

    // "THE GUY" text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: "🏆 BE THE GUY 🏆",
        style: TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(665, 435));
  }
}
