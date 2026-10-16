import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:augustus_mario_game/game/components/platform_block.dart';
import 'package:augustus_mario_game/game/components/hazards/apple_hazard.dart';
import 'package:augustus_mario_game/game/components/hazards/spike_hazard.dart';
import 'package:augustus_mario_game/game/components/hazards/trigger_zone.dart';
import 'package:augustus_mario_game/game/components/hazards/collapsing_block.dart';
import 'package:augustus_mario_game/game/iwbtg_game.dart';
import 'package:augustus_mario_game/game/game_constants.dart';

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
}
