import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:augustus_mario_game/game/components/platform_block.dart';
import 'package:augustus_mario_game/game/components/hazards/apple_hazard.dart';
import 'package:augustus_mario_game/game/components/hazards/spike_hazard.dart';
import 'package:augustus_mario_game/game/components/hazards/trigger_zone.dart';
import 'package:augustus_mario_game/game/components/hazards/collapsing_block.dart';
import 'package:augustus_mario_game/game/iwbtg_game.dart';
import 'package:augustus_mario_game/game/game_constants.dart';
import 'package:augustus_mario_game/game/stages/stage_1_orchard.dart';

Future<IWBTGGame> createTestGame() async {
  final game = IWBTGGame(initialStage: 1);
  await game.onLoad();
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Player Physics & Collision Tests', () {
    test('Player starts grounded with coyote time and double jump ready', () async {
      final game = await createTestGame();
      final player = game.player!;

      expect(player.isAlive, isTrue);
      expect(player.isOnGround, isTrue);
      expect(player.canDoubleJump, isTrue);

      // Instant jump on first frame should work
      player.pressJump();
      player.update(0.016);
      expect(player.velocity.y, closeTo(GameConstants.jumpVelocity + GameConstants.gravity * 0.016, 1.0));
    });

    test('Player respawn immediately resets coyote time and double jump', () async {
      final game = await createTestGame();
      final player = game.player!;

      // Kill player
      player.die();
      expect(player.isAlive, isFalse);

      // Respawn
      game.respawnPlayer();
      expect(player.isAlive, isTrue);
      expect(player.isOnGround, isTrue);
      expect(player.canDoubleJump, isTrue);

      // Can jump immediately out of respawn
      player.pressJump();
      player.update(0.016);
      expect(player.velocity.y, closeTo(GameConstants.jumpVelocity + GameConstants.gravity * 0.016, 1.0));
    });

    test('Diagonal jump onto platform does not warp or halt horizontal speed and lands or clears ledge', () async {
      final game = await createTestGame();
      final player = game.player!;

      // Place platform at (100, 300, 80, 24)
      final platform = PlatformBlock(position: Vector2(100, 300), size: Vector2(80, 24));
      game.currentStage!.add(platform);

      // Position player jumping diagonally up-right towards the platform ledge
      player.position = Vector2(80, 280);
      player.setMoveInput(1.0);
      player.velocity.y = -300;

      final prevX = player.position.x;
      player.update(0.016);

      // Horizontal velocity should NOT be killed to 0
      expect(player.position.x, greaterThan(prevX));
      expect(player.velocity.x, equals(GameConstants.playerMoveSpeed));

      // Player MUST NOT warp downward to platform bottom (y=324)
      expect(player.position.y, lessThan(300.0));
    });

    test('Falling vertically or diagonally along stacked wall blocks does not snag on seams', () async {
      final game = await createTestGame();
      final player = game.player!;

      // Stack two 32x32 wall blocks at x=100: Block 1 at y=200, Block 2 at y=232
      final wall1 = PlatformBlock(position: Vector2(100, 200), size: Vector2(32, 32));
      final wall2 = PlatformBlock(position: Vector2(100, 232), size: Vector2(32, 32));
      game.currentStage!.add(wall1);
      game.currentStage!.add(wall2);

      // Player to the left of wall, falling down and pressing into the wall
      player.position = Vector2(100 - player.width, 210);
      player.setMoveInput(1.0);
      player.velocity.y = 400.0;

      // Update across the seam at y=232
      for (int i = 0; i < 5; i++) {
        player.update(0.016);
      }

      // Player must be below y=232, falling continuously, NOT falsely landed (isOnGround = false)
      expect(player.position.y, greaterThan(232.0));
      expect(player.isOnGround, isFalse);
      expect(player.velocity.y, greaterThan(0));
    });

    test('Running horizontally across adjacent blocks does not snag on seams', () async {
      final game = await createTestGame();
      final player = game.player!;

      // Add two adjacent floor blocks at y=400
      final block1 = PlatformBlock(position: Vector2(50, 400), size: Vector2(50, 32));
      final block2 = PlatformBlock(position: Vector2(100, 400), size: Vector2(50, 32));
      game.currentStage!.add(block1);
      game.currentStage!.add(block2);

      // Stand on block 1 near seam: feet at y=400, x right edge near 100
      player.position = Vector2(90, 400 - player.height);
      player.velocity.setValues(GameConstants.playerMoveSpeed, 0);
      player.setMoveInput(1.0);

      // Step forward across the seam at x=100
      player.update(0.016);
      player.update(0.016);

      expect(player.position.x, greaterThan(90));
      expect(player.velocity.x, equals(GameConstants.playerMoveSpeed));
    });
  });

  group('Anti-Tunneling Hazard Tests', () {
    test('High speed falling apple (1,100+ px/s) hits player and does not tunnel', () async {
      final game = await createTestGame();
      final player = game.player!;
      player.position = Vector2(200, 400);

      // Spawn falling apple 25 pixels directly above player
      final apple = AppleHazard(
        position: Vector2(200, 375),
        behavior: AppleBehavior.fallDown,
      );
      game.currentStage!.add(apple);
      apple.trigger();

      // Update frame with dt=0.033 (simulating large dt frame / 30fps drop)
      apple.update(0.033);

      // Player must be dead (anti-tunneling caught the collision)
      expect(player.isAlive, isFalse);
    });

    test('High speed guillotine spike (1,250 px/s) hits player and does not tunnel', () async {
      final game = await createTestGame();
      final player = game.player!;
      player.position = Vector2(300, 350);

      // Spawn guillotine spike directly above player
      final spike = SpikeHazard(
        position: Vector2(300, 320),
        direction: SpikeDirection.down,
        triggerVelocity: Vector2(0, 1250),
      );
      game.currentStage!.add(spike);
      spike.trigger();

      // Large frame update (30fps)
      spike.update(0.033);

      expect(player.isAlive, isFalse);
    });

    test('Anti-tunneling holds under severe lag spike (dt=0.08s at 1,250 px/s)', () async {
      final game = await createTestGame();
      final player = game.player!;
      player.position = Vector2(300, 400);

      // Spike 50 pixels away moving at 1,250 px/s (would travel 100 px in 0.08s)
      final spike = SpikeHazard(
        position: Vector2(300, 350),
        direction: SpikeDirection.down,
        triggerVelocity: Vector2(0, 1250),
      );
      game.currentStage!.add(spike);
      spike.trigger();

      spike.update(0.08);

      expect(player.isAlive, isFalse);
    });

    test('High speed horizontal apple (1,050 px/s) hits player and does not tunnel', () async {
      final game = await createTestGame();
      final player = game.player!;
      player.position = Vector2(300, 300);

      // Spawn horizontal rusher apple 20 pixels to the left
      final apple = AppleHazard(
        position: Vector2(280, 300),
        behavior: AppleBehavior.flyRight,
      );
      game.currentStage!.add(apple);
      apple.trigger();

      apple.update(0.033);

      expect(player.isAlive, isFalse);
    });
  });

  group('Spike Triangle Hitbox Precision Tests', () {
    test('Player beside tip of right-pointing spike survives and is not falsely killed', () async {
      final game = await createTestGame();
      final player = game.player!;

      // Spike pointing right at (100, 100), tip is at (132, 116)
      final spike = SpikeHazard(
        position: Vector2(100, 100),
        direction: SpikeDirection.right,
      );
      game.currentStage!.add(spike);

      // Player positioned near x=128 (near tip x) but vertically at y=95 (above the tip)
      // Player hitbox (14x22): center at y=95+3=98, bottom=117...
      // Place player top at y=80, so hitboxRect is y=83..105, x=120..134
      player.position = Vector2(120, 80);

      // Player is in bounding box horizontally and near tip, but completely above the triangle!
      // In the prior attempt, this falsely killed the player because of inverted triangle formula.
      spike.update(0.016);
      expect(player.isAlive, isTrue);
    });

    test('Player touching tip of right-pointing spike dies', () async {
      final game = await createTestGame();
      final player = game.player!;

      // Spike pointing right at (100, 100), tip is at (132, 116)
      final spike = SpikeHazard(
        position: Vector2(100, 100),
        direction: SpikeDirection.right,
        triggerVelocity: Vector2(100, 0),
      );
      game.currentStage!.add(spike);
      spike.trigger();

      // Place player directly aligned with tip: y=105 (hitbox center around 116)
      player.position = Vector2(125, 105);

      spike.update(0.016);
      expect(player.isAlive, isFalse);
    });
  });

  group('TriggerZone Tests', () {
    test('TriggerZone triggers via sweep even at high speed', () async {
      final game = await createTestGame();
      final player = game.player!;

      bool triggered = false;
      final zone = TriggerZone(
        position: Vector2(player.position.x, player.position.y + 10),
        size: Vector2(50, 50),
        onTrigger: () => triggered = true,
      );
      game.currentStage!.add(zone);

      player.velocity.y = 600;
      player.update(0.016);

      expect(triggered, isTrue);
    });
  });

  group('CollapsingBlock Tests', () {
    test('CollapsingBlock crumbling makes player fall naturally without dying', () async {
      final game = await createTestGame();
      final player = game.player!;

      final cBlock = CollapsingBlock(
        position: Vector2(200, 300),
        size: Vector2(60, 20),
      );
      game.currentStage!.add(cBlock);

      // Place player standing on the collapsing block
      player.position = Vector2(210, 300 - player.height);
      player.velocity.setZero();
      player.update(0.016);

      expect(player.isOnGround, isTrue);
      expect(player.isAlive, isTrue);

      // Trigger the block (simulate stepping on it)
      cBlock.trigger();

      // Update past the 0.20s shake warning into the falling state
      for (int i = 0; i < 20; i++) {
        cBlock.update(0.016);
        player.update(0.016);
      }

      expect(cBlock.isFalling, isTrue);
      // Player must NOT die from the crumbling block
      expect(player.isAlive, isTrue);
      // Player must no longer be grounded and should be falling
      expect(player.isOnGround, isFalse);
      expect(player.velocity.y, greaterThan(0));
      expect(player.position.y, greaterThan(300 - player.height));
    });
  });

  group('Proximity Trigger Tests', () {
    test('TriggerZone does not fire when player is far, but fires at point-blank proximity', () async {
      final game = await createTestGame();
      final player = game.player!;

      bool triggered = false;
      // Trigger zone placed 50px away from player
      final zone = TriggerZone(
        position: Vector2(player.position.x + 50, player.position.y),
        size: Vector2(18, 40),
        onTrigger: () => triggered = true,
      );
      game.currentStage!.add(zone);

      // Player idle or moving slightly (does not reach zone)
      player.update(0.016);
      expect(triggered, isFalse);

      // Move player into point-blank proximity
      player.position.x = player.position.x + 45;
      player.update(0.016);
      expect(triggered, isTrue);
    });
  });

  group('Stage 1 Mechanics & Polish Tests', () {
    test('Stage 1 has exactly 5 pit spikes aligned across 260-420 with 0 overlap on right floor', () async {
      final stage = Stage1Orchard();
      await stage.onLoad();

      final spikes = stage.hazards.whereType<SpikeHazard>().where((s) => s.position.y == 568).toList();

      // Exactly 5 spikes across the 160px pit (x=260 to x=420)
      expect(spikes.length, equals(5));

      // Sorted by x position
      spikes.sort((a, b) => a.position.x.compareTo(b.position.x));

      final expectedXs = [260.0, 292.0, 324.0, 356.0, 388.0];
      for (int i = 0; i < spikes.length; i++) {
        expect(spikes[i].position.x, equals(expectedXs[i]));
        expect(spikes[i].position.y, equals(568.0));
      }

      // The 5th spike ends at 388 + 32 = 420.0, which perfectly touches the right platform without overlap
      final rightmostSpike = spikes.last;
      expect(rightmostSpike.position.x + rightmostSpike.width, equals(420.0));
    });

    test('Stage 1 tree apple is removed', () async {
      final stage = Stage1Orchard();
      await stage.onLoad();

      final hasTreeApple = stage.hazards
          .whereType<AppleHazard>()
          .any((a) => a.hazardId == 'apple_tree_rusher');

      expect(hasTreeApple, isFalse);
    });

    test('Stage 1 has two-way sliding spike on platform 3 (slides left to 620, then returns to 688)', () async {
      final stage = Stage1Orchard();
      await stage.onLoad();

      final sliderSpike = stage.hazards
          .whereType<SpikeHazard>()
          .firstWhere((s) => s.hazardId == 'spike_platform_slider');

      // Resting on platform (620, 340) surface: y = 308, x = 688
      expect(sliderSpike.position.x, equals(688.0));
      expect(sliderSpike.position.y, equals(308.0));
      expect(sliderSpike.direction, equals(SpikeDirection.up));

      // Phase 1: Slides across platform to the left (target 620.0 at tuned speed 450)
      sliderSpike.slideTo(620.0, speed: 450);
      for (int i = 0; i < 60; i++) {
        sliderSpike.update(0.016);
      }
      expect(sliderSpike.position.x, equals(620.0));
      expect(sliderSpike.position.y, equals(308.0));

      // Phase 2: Player steps on right side -> slides back to the right (target 688.0 at speed 480)
      sliderSpike.slideTo(688.0, speed: 480);
      for (int i = 0; i < 60; i++) {
        sliderSpike.update(0.016);
      }
      expect(sliderSpike.position.x, equals(688.0));
      expect(sliderSpike.position.y, equals(308.0));
    });

    test('Stage 1 has hidden pop-up spike inside Platform 2 (480, 420)', () async {
      final stage = Stage1Orchard();
      await stage.onLoad();

      final hiddenSpike = stage.hazards
          .whereType<SpikeHazard>()
          .firstWhere((s) => s.hazardId == 'spike_platform_hidden');

      expect(hiddenSpike.isHidden, isTrue);
      expect(hiddenSpike.isDeadly, isFalse);
      expect(hiddenSpike.position.x, equals(514.0));
      expect(hiddenSpike.position.y, equals(420.0));

      // Trigger pop-up
      hiddenSpike.trigger();
      expect(hiddenSpike.isHidden, isFalse);
      expect(hiddenSpike.isDeadly, isTrue);

      hiddenSpike.update(0.016);
      expect(hiddenSpike.position.y, lessThan(420.0));
    });

    test('Stage 1 has off-screen horizon rusher spike shooting left across map', () async {
      final stage = Stage1Orchard();
      await stage.onLoad();

      final rusher = stage.hazards
          .whereType<SpikeHazard>()
          .firstWhere((s) => s.hazardId == 'spike_offscreen_rusher');

      // Placed off-screen to the right at player body height
      expect(rusher.position.x, equals(832.0));
      expect(rusher.position.y, equals(536.0));
      expect(rusher.direction, equals(SpikeDirection.left));
      expect(rusher.triggerVelocity!.x, lessThan(-1000.0));

      // Trigger and verify it moves left
      rusher.trigger();
      rusher.update(0.016);
      expect(rusher.position.x, lessThan(832.0));
    });

    test('Stage 1 pit rocket spike is disguised at y=568 and launches upward', () async {
      final stage = Stage1Orchard();
      await stage.onLoad();

      final pitRocket = stage.hazards
          .whereType<SpikeHazard>()
          .firstWhere((s) => s.hazardId == 'spike_pit_rocket');

      // Rest position matches the pit floor spikes exactly
      expect(pitRocket.position.x, equals(324.0));
      expect(pitRocket.position.y, equals(568.0));
      expect(pitRocket.triggerVelocity!.y, lessThan(-1000.0));

      // Trigger it and update
      pitRocket.trigger();
      pitRocket.update(0.016);
      expect(pitRocket.position.y, lessThan(568.0));
    });

    test('Stage 1 exit is located at the top right platform', () async {
      final stage = Stage1Orchard();
      await stage.onLoad();

      final exitZones = stage.triggerZones
          .where((z) => z.position.x >= 740 && z.position.y < 200)
          .toList();

      expect(exitZones.isNotEmpty, isTrue);
    });

    test('Stage 1 has off-screen stepping stone rusher spike shooting right across map', () async {
      final stage = Stage1Orchard();
      await stage.onLoad();

      final stoneRusher = stage.hazards
          .whereType<SpikeHazard>()
          .firstWhere((s) => s.hazardId == 'spike_offscreen_stepping_stone');

      // Placed off-screen to the left aligned with stepping stone surface (y=428, 428+32=460)
      expect(stoneRusher.position.x, equals(-40.0));
      expect(stoneRusher.position.y, equals(428.0));
      expect(stoneRusher.direction, equals(SpikeDirection.right));
      expect(stoneRusher.triggerVelocity!.x, greaterThan(1000.0));

      // Trigger and verify it moves right
      stoneRusher.trigger();
      stoneRusher.update(0.016);
      expect(stoneRusher.position.x, greaterThan(-40.0));
    });
  });

  group('Hazard Debug Hitbox Tests', () {
    test('game.toggleHazardHitboxes() flips showHazardHitboxes and notifies listeners', () async {
      final game = await createTestGame();

      expect(game.showHazardHitboxes, isFalse);

      bool notified = false;
      game.showHazardHitboxesNotifier.addListener(() {
        notified = true;
      });

      game.toggleHazardHitboxes();
      expect(game.showHazardHitboxes, isTrue);
      expect(notified, isTrue);

      game.toggleHazardHitboxes();
      expect(game.showHazardHitboxes, isFalse);
    });

    test('SpikeHazard and AppleHazard provide valid debug hitbox geometries', () async {
      final spike = SpikeHazard(
        position: Vector2(100, 200),
        direction: SpikeDirection.up,
      );
      final vertices = spike.getTriangleVertices();
      expect(vertices.length, equals(3));
      // Local tip of up-pointing spike (32x32) is (16, 2)
      expect(vertices[0], equals(Vector2(16.0, 2.0)));
      // World position of tip: spike.position + vertices[0] = (116, 202)
      expect(spike.position + vertices[0], equals(Vector2(116.0, 202.0)));

      final apple = AppleHazard(
        position: Vector2(50, 60),
      );
      expect(apple.radius, equals(12.0));
    });

    test('TriggerZone hasTriggered reflects active vs disarmed state for debug hitboxes', () {
      final trigger = TriggerZone(
        position: Vector2(100, 100),
        size: Vector2(40, 40),
        triggerOnce: true,
      );

      expect(trigger.hasTriggered, isFalse);
      trigger.activate();
      expect(trigger.hasTriggered, isTrue);
      trigger.reset();
      expect(trigger.hasTriggered, isFalse);
    });
  });
}

