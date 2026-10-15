import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'stage_base.dart';
import '../game_constants.dart';
import '../components/platform_block.dart';
import '../components/save_point.dart';
import '../components/hazards/spike_hazard.dart';
import '../components/hazards/apple_hazard.dart';
import '../components/hazards/trigger_zone.dart';

class Stage1Orchard extends StageBase {
  Stage1Orchard()
      : super(
          stageName: "STAGE 1: THE DECEPTIVE ORCHARD",
          stageIndex: 1,
          defaultSpawnPosition: Vector2(70, 520),
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

    // High platform holding the Save Point
    add(PlatformBlock(position: Vector2(660, 200), size: Vector2(100, 24)));

    // 3. Save Point (Shootable)
    final savePt = SavePoint(
      position: Vector2(700, 164),
      respawnPosition: Vector2(680, 160),
      onSaved: () {
        game.updateCheckpoint(Vector2(680, 160), stageIndex);
      },
    );
    add(savePt);

    // 4. Fixed Handcrafted IWBTG Traps!
    // Trap A: The "Normal" Falling Apple (Player walks under it, it falls down)
    final appleA = AppleHazard(
      position: Vector2(170, 120),
      behavior: AppleBehavior.fallDown,
      hazardId: "apple_drop_1",
    );
    add(appleA);

    add(TriggerZone(
      position: Vector2(140, 500),
      size: Vector2(80, 68),
      onTrigger: () => appleA.trigger(),
    ));

    // Trap B: The Infamous "Anti-Gravity Sky-Rocket Apple"
    // Sits peacefully near the pit, but when player jumps to cross the pit, it shoots UPWARD!
    final appleB = AppleHazard(
      position: Vector2(340, 530),
      behavior: AppleBehavior.flyUp,
      hazardId: "apple_rocket_1",
    );
    add(appleB);

    add(TriggerZone(
      position: Vector2(250, 400),
      size: Vector2(70, 120),
      onTrigger: () => appleB.trigger(),
    ));

    // Trap C: Horizontal Ambush Apple
    // Placed near the right ledge; when player steps on mid platform, it rushes left!
    final appleC = AppleHazard(
      position: Vector2(720, 335),
      behavior: AppleBehavior.flyLeft,
      hazardId: "apple_rusher_1",
    );
    add(appleC);

    add(TriggerZone(
      position: Vector2(490, 380),
      size: Vector2(80, 40),
      onTrigger: () => appleC.trigger(),
    ));

    // 5. Stage Exit Trigger (Right boundary at bottom right)
    add(TriggerZone(
      position: Vector2(770, 480),
      size: Vector2(30, 88),
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
