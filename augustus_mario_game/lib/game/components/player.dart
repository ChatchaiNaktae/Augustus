import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_constants.dart';
import '../iwbtg_game.dart';
import 'bullet.dart';
import 'blood_particle.dart';
import 'platform_block.dart';
import 'hazards/hazard_base.dart';
import 'hazards/trigger_zone.dart';
import 'hazards/collapsing_block.dart';

class Player extends PositionComponent with CollisionCallbacks, HasGameReference<IWBTGGame> {
  final Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  bool canDoubleJump = false;
  bool isAlive = true;
  bool facingRight = true;

  double moveInput = 0.0;
  bool isJumpHeld = false;

  // Coyote time & Jump buffer
  double _coyoteTimer = 0.0;
  double _jumpBufferTimer = 0.0;

  final Vector2 respawnPosition;

  Player({required Vector2 initialPosition})
      : respawnPosition = initialPosition.clone(),
        super(
          position: initialPosition,
          size: Vector2(GameConstants.playerWidth, GameConstants.playerHeight),
          anchor: Anchor.topLeft,
        ) {
    // Smaller precise hitbox for masocore dodging
    add(
      RectangleHitbox(
        position: Vector2(
          (GameConstants.playerWidth - GameConstants.playerHitboxWidth) / 2,
          (GameConstants.playerHeight - GameConstants.playerHitboxHeight) / 2,
        ),
        size: Vector2(GameConstants.playerHitboxWidth, GameConstants.playerHitboxHeight),
      ),
    );
  }

  void setMoveInput(double input) {
    if (!isAlive) return;
    moveInput = input.clamp(-1.0, 1.0);
    if (moveInput > 0.1) facingRight = true;
    if (moveInput < -0.1) facingRight = false;
  }

  void pressJump() {
    if (!isAlive) return;
    isJumpHeld = true;
    _jumpBufferTimer = 0.12; // Buffer jump for 120ms
  }

  void releaseJump() {
    isJumpHeld = false;
    // Variable jump: if releasing jump while going up, cut velocity
    if (velocity.y < 0) {
      velocity.y *= GameConstants.jumpCutMultiplier;
    }
  }

  void shoot() {
    if (!isAlive) return;
    final bulletDir = facingRight ? 1.0 : -1.0;
    final spawnPos = Vector2(
      facingRight ? position.x + width + 2 : position.x - 6,
      position.y + height * 0.45,
    );
    parent?.add(Bullet(position: spawnPos, direction: bulletDir));
  }

  void die() {
    if (!isAlive) return;
    isAlive = false;
    velocity.setZero();

    // Spawn massive blood explosion
    parent?.add(BloodParticleSystem(origin: position + size / 2));

    // Notify game
    game.onPlayerDied();
  }

  void respawnAt(Vector2 targetPos) {
    position.setFrom(targetPos);
    velocity.setZero();
    isAlive = true;
    isOnGround = false;
    canDoubleJump = false;
    _coyoteTimer = 0.0;
    _jumpBufferTimer = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;

    // Horizontal Movement (Zero latency)
    velocity.x = moveInput * GameConstants.playerMoveSpeed;

    // Timers
    if (isOnGround) {
      _coyoteTimer = 0.10; // Coyote time
      canDoubleJump = true;
    } else {
      _coyoteTimer -= dt;
    }

    if (_jumpBufferTimer > 0) {
      _jumpBufferTimer -= dt;
    }

    // Process Jump & Double Jump
    if (_jumpBufferTimer > 0) {
      if (_coyoteTimer > 0) {
        // Normal jump from ground / coyote
        velocity.y = GameConstants.jumpVelocity;
        _coyoteTimer = 0;
        _jumpBufferTimer = 0;
        isOnGround = false;
      } else if (canDoubleJump) {
        // Masocore Air Double Jump
        velocity.y = GameConstants.doubleJumpVelocity;
        canDoubleJump = false;
        _jumpBufferTimer = 0;
      }
    }

    // Gravity
    velocity.y += GameConstants.gravity * dt;
    if (velocity.y > GameConstants.maxFallSpeed) {
      velocity.y = GameConstants.maxFallSpeed;
    }

    // Move & resolve collisions with solid blocks
    _moveWithCollisions(dt);

    // Fall out of screen = death
    if (position.y > GameConstants.gameHeight + 40) {
      die();
    }
  }

  void _moveWithCollisions(double dt) {
    final blocks = parent?.children.whereType<PlatformBlock>().toList() ?? [];
    final collapsingBlocks = parent?.children.whereType<CollapsingBlock>().toList() ?? [];

    // Horizontal pass
    position.x += velocity.x * dt;
    final playerRectX = toRect();

    for (final block in blocks) {
      final blockRect = block.toRect();
      if (playerRectX.overlaps(blockRect)) {
        if (velocity.x > 0) {
          position.x = blockRect.left - width;
        } else if (velocity.x < 0) {
          position.x = blockRect.right;
        }
        velocity.x = 0;
      }
    }

    // Vertical pass
    position.y += velocity.y * dt;
    final playerRectY = toRect();
    isOnGround = false;

    // Check solid blocks
    for (final block in blocks) {
      final blockRect = block.toRect();
      if (playerRectY.overlaps(blockRect)) {
        if (velocity.y > 0) {
          // Landing on block
          position.y = blockRect.top - height;
          velocity.y = 0;
          isOnGround = true;
        } else if (velocity.y < 0) {
          // Ceiling hit
          position.y = blockRect.bottom;
          velocity.y = 0;
        }
      }
    }

    // Check collapsing blocks
    for (final cBlock in collapsingBlocks) {
      final cRect = cBlock.toRect();
      if (playerRectY.overlaps(cRect)) {
        if (velocity.y > 0 && position.y + height - velocity.y * dt <= cRect.top + 8) {
          position.y = cRect.top - height;
          velocity.y = 0;
          isOnGround = true;
          cBlock.trigger(); // Trigger collapse
        }
      }
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (!isAlive) return;

    if (other is HazardBase && other.isDeadly) {
      die();
    } else if (other is TriggerZone) {
      other.activate();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!isAlive) return;

    canvas.save();
    if (!facingRight) {
      canvas.translate(width, 0);
      canvas.scale(-1, 1);
    }

    // Cape / Bow at the back
    final capePaint = Paint()..color = const Color(0xFFE5E9F0);
    final capePath = Path()
      ..moveTo(2, 10)
      ..lineTo(-5, 14)
      ..lineTo(-3, 22)
      ..lineTo(4, 18)
      ..close();
    canvas.drawPath(capePath, capePaint);

    // Blue Overalls / Body
    final bodyPaint = Paint()..color = const Color(0xFF3B4252);
    canvas.drawRect(const Rect.fromLTWH(4, 12, 14, 14), bodyPaint);

    // Cute retro shirt
    final shirtPaint = Paint()..color = const Color(0xFF81A1C1);
    canvas.drawRect(const Rect.fromLTWH(5, 12, 12, 6), shirtPaint);

    // Peach Skin Face
    final facePaint = Paint()..color = const Color(0xFFF0C09E);
    canvas.drawRect(const Rect.fromLTWH(5, 4, 12, 9), facePaint);

    // Cute Pixel Eye
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawRect(const Rect.fromLTWH(12, 6, 2, 4), eyePaint);

    // Red Cap
    final hatPaint = Paint()..color = const Color(0xFFBF616A);
    canvas.drawRect(const Rect.fromLTWH(3, 1, 15, 4), hatPaint);
    canvas.drawRect(const Rect.fromLTWH(11, 4, 6, 2), hatPaint); // visor

    // Hand holding Pistol
    final gunPaint = Paint()..color = const Color(0xFFD8DEE9);
    canvas.drawRect(const Rect.fromLTWH(16, 14, 6, 3), gunPaint);
    canvas.drawRect(const Rect.fromLTWH(15, 15, 3, 4), const Paint()..color = const Color(0xFF4C566A));

    canvas.restore();
  }
}
