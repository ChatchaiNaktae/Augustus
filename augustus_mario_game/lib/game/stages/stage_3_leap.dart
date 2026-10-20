import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'stage_base.dart';
import '../game_constants.dart';
import '../components/platform_block.dart';
import '../components/hazards/spike_hazard.dart';
import '../components/hazards/collapsing_block.dart';
import '../components/hazards/trigger_zone.dart';
import '../components/hazards/sniper_hazard.dart';

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
    add(PlatformBlock(position: Vector2(0, 568), size: Vector2(160, 32)));

    // Bunker Cover above spawn (White Box in player sketch)
    add(PlatformBlock(position: Vector2(0, 490), size: Vector2(160, 24)));

    // Victory Altar (Far Right)
    add(PlatformBlock(position: Vector2(640, 500), size: Vector2(128, 100)));

    // Bottomless Spike Pit across the entire bottom (x: 160 to 640 = 480px = 15 spikes)
    for (double x = 160; x < 640; x += 32) {
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

    // 3. Top-Right Sniper Hazard (Aiming Raycast Laser + Bullet every 3s)
    add(SniperHazard(position: Vector2(740, 65)));

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
