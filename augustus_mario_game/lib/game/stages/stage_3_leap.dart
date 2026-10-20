import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'stage_base.dart';
import '../game_constants.dart';
import '../components/platform_block.dart';
import '../components/rotating_platform_block.dart';
import '../components/spawnable_platform_block.dart';
import '../components/hazards/spike_hazard.dart';
import '../components/hazards/collapsing_block.dart';
import '../components/hazards/trigger_zone.dart';
import '../components/hazards/sniper_hazard.dart';

class Stage3Leap extends StageBase {
  bool _trophyTrolled = false;
  final Vector2 _initialTrophyPos = Vector2(730, 475);
  final Vector2 _trollTrophyPos = Vector2(95, 100);
  late Vector2 _currentTrophyPos;

  late final TriggerZone _victoryTrigger;
  late final TriggerZone _trophyTrollTrigger;

  final List<SpawnablePlatformBlock> _spawnedPlatforms = [];

  Stage3Leap()
      : super(
          stageName: "STAGE 3: THE LEAP OF FAITH",
          stageIndex: 3,
          defaultSpawnPosition: Vector2(70, 540),
        ) {
    _currentTrophyPos = _initialTrophyPos.clone();
  }

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

    // Bunker Cover above spawn (Shortened according to user sketch in Image 2)
    add(PlatformBlock(position: Vector2(0, 490), size: Vector2(110, 24), priority: 2));

    // Giant Spike on Bunker Roof (Surprise Spike that shoots UP when player steps on bunker roof)
    final bunkerGiantSpike = SpikeHazard(
      position: Vector2(32, 490),
      customSize: Vector2(78, 190),
      direction: SpikeDirection.up,
      isInitiallyDeadly: false,
      isHidden: true,
      priority: 1,
      hazardId: "spike_bunker_giant",
    );
    add(bunkerGiantSpike);

    // Trigger Zone on Bunker Roof
    add(TriggerZone(
      position: Vector2(32, 440),
      size: Vector2(78, 50),
      onTrigger: () => bunkerGiantSpike.slideToY(300, speed: 1500),
    ));

    // Victory Altar (Far Right)
    add(PlatformBlock(position: Vector2(640, 500), size: Vector2(128, 100), priority: 2));

    // Bottomless Spike Pit across the entire bottom (x: 160 to 640 = 480px = 15 spikes)
    // leapSpike1 replaces the spike at x = 224 (index 2) so they don't overlap!
    for (double x = 160; x < 640; x += 32) {
      if ((x - 224).abs() > 1) {
        add(SpikeHazard(position: Vector2(x, 568), direction: SpikeDirection.up));
      }
    }

    // 2. High Altitude Stepping Stones
    add(PlatformBlock(position: Vector2(180, 460), size: Vector2(70, 20)));

    // Platform 2 is a treacherous Collapsing Block!
    final collapse2 = CollapsingBlock(
      position: Vector2(290, 390),
      size: Vector2(65, 20),
    );
    add(collapse2);

    // Rotating Platform Block (90-degree clockwise vertical barrier triggered when stepped on)
    add(RotatingPlatformBlock(position: Vector2(400, 320), size: Vector2(80, 20)));

    // Platform 4 before the leap
    add(PlatformBlock(position: Vector2(530, 380), size: Vector2(70, 20)));

    // 3. Handcrafted IWBTG Troll Traps!

    // Trap 1: Surprise Leaping Pit Spike during the first leap (snapped to 32px grid slot x: 224)
    final leapSpike1 = SpikeHazard(
      position: Vector2(224, 568),
      direction: SpikeDirection.up,
      triggerVelocity: Vector2(0, -1150),
      hazardId: "spike_leap_1",
    );
    add(leapSpike1);

    add(TriggerZone(
      position: Vector2(220, 420),
      size: Vector2(18, 40),
      onTrigger: () => leapSpike1.trigger(),
    ));

    // Trap 2: Ceiling Ambush Spike directly above Platform 4 (x: 545-565)
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

    // Trap 3: The Ultimate Trophy Deception Spike!
    // Hidden underneath the altar floor (y=500); launches UP when player approaches in proximity
    final trollSpike = SpikeHazard(
      position: Vector2(670, 500),
      direction: SpikeDirection.up,
      triggerVelocity: Vector2(0, -1150),
      isInitiallyDeadly: false,
      isHidden: true,
      priority: 1,
      hazardId: "spike_trophy_troll",
    );
    add(trollSpike);

    // Point-blank proximity trigger right in front of the trophy (x: 660-685)
    add(TriggerZone(
      position: Vector2(660, 440),
      size: Vector2(25, 60),
      onTrigger: () => trollSpike.trigger(),
    ));

    // 4. Top-Right Sniper Hazard (Aiming Raycast Laser + Bullet every 3s)
    add(SniperHazard(position: Vector2(740, 65)));

    // 5. Spawnable Platforms
    // 5.1 Blocking Platform (Spawns at bottom to block descent into the altar)
    final blockingPlatform = SpawnablePlatformBlock(
      position: Vector2(640, 440),
      size: Vector2(100, 20),
    );
    add(blockingPlatform);
    _spawnedPlatforms.add(blockingPlatform);

    // 5.2 Sky Return Platforms (Connecting back from x=640, y=440 to top-left x=95, y=100)
    final returnPlat1 = SpawnablePlatformBlock(
      position: Vector2(490, 340),
      size: Vector2(60, 16),
    );
    add(returnPlat1);
    _spawnedPlatforms.add(returnPlat1);

    final returnPlat2 = SpawnablePlatformBlock(
      position: Vector2(340, 250),
      size: Vector2(60, 16),
    );
    add(returnPlat2);
    _spawnedPlatforms.add(returnPlat2);

    final returnPlat3 = SpawnablePlatformBlock(
      position: Vector2(200, 180),
      size: Vector2(60, 16),
    );
    add(returnPlat3);
    _spawnedPlatforms.add(returnPlat3);

    final trophyLedge = SpawnablePlatformBlock(
      position: Vector2(60, 120),
      size: Vector2(70, 16),
    );
    add(trophyLedge);
    _spawnedPlatforms.add(trophyLedge);

    // 6. Trophy Troll Trigger Zone (Placed mid-air right above the trophy altar)
    // When player enters this zone in mid-air, spawns blocking platform and teleports trophy to top-left!
    _trophyTrollTrigger = TriggerZone(
      position: Vector2(640, 380),
      size: Vector2(90, 50),
      triggerOnce: true,
      onTrigger: () => _onTrophyTrolled(),
    );
    add(_trophyTrollTrigger);

    // 7. The Golden Trophy Trigger (Touching triggers victory!)
    _victoryTrigger = TriggerZone(
      position: Vector2(710, 450),
      size: Vector2(40, 50),
      onTrigger: () => game.onVictory(),
    );
    add(_victoryTrigger);
  }

  void _onTrophyTrolled() {
    if (_trophyTrolled) return;
    _trophyTrolled = true;

    // Relocate trophy and victory trigger to top-left
    _currentTrophyPos.setFrom(_trollTrophyPos);
    _victoryTrigger.position.setValues(75, 75);

    // Activate all spawned platforms immediately
    for (final plat in _spawnedPlatforms) {
      plat.activate();
    }
  }

  @override
  void resetHazards() {
    super.resetHazards();
    _trophyTrolled = false;
    _currentTrophyPos.setFrom(_initialTrophyPos);
    _victoryTrigger.position.setValues(710, 450);
    _victoryTrigger.reset();
    _trophyTrollTrigger.reset();
    for (final plat in _spawnedPlatforms) {
      plat.deactivate();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw Golden Trophy
    final trophyCenter = Offset(_currentTrophyPos.x, _currentTrophyPos.y);
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

    final textOffset = _trophyTrolled
        ? Offset(trophyCenter.dx - 60, trophyCenter.dy - 38)
        : const Offset(665, 435);
    textPainter.paint(canvas, textOffset);
  }
}
