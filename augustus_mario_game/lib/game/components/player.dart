import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_constants.dart';
import '../iwbtg_game.dart';
import 'blood_particle.dart';
import 'platform_block.dart';
import 'hazards/hazard_base.dart';
import 'hazards/trigger_zone.dart';
import 'hazards/collapsing_block.dart';
import '../utils/game_asset_loader.dart';

class Player extends PositionComponent with CollisionCallbacks, HasGameReference<IWBTGGame> {
  Sprite? _idleSprite;
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

  Rect get hitboxRect => Rect.fromLTWH(
        position.x + (GameConstants.playerWidth - GameConstants.playerHitboxWidth) / 2,
        position.y + (GameConstants.playerHeight - GameConstants.playerHitboxHeight) / 2,
        GameConstants.playerHitboxWidth,
        GameConstants.playerHitboxHeight,
      );

  Player({required Vector2 initialPosition})
      : respawnPosition = initialPosition.clone(),
        super(
          position: initialPosition,
          size: Vector2(GameConstants.playerWidth, GameConstants.playerHeight),
          anchor: Anchor.topLeft,
        ) {
    isOnGround = true;
    canDoubleJump = true;
    _coyoteTimer = 0.10;

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

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _idleSprite = await GameAssetLoader.loadOptionalSprite('player/player_idle.png');
  }

  void setMoveInput(double input) {
    moveInput = input.clamp(-1.0, 1.0);
    if (!isAlive) return;
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

  void die() {
    if (!isAlive) return;
    isAlive = false;
    velocity.setZero();

    // Spawn massive blood explosion with surface raycast sticking
    final obstacles = game.currentStage?.getSolidObstacleComponents() ?? [];
    parent?.add(BloodParticleSystem(
      origin: position + size / 2,
      obstacles: obstacles,
    ));

    // Notify game
    game.onPlayerDied();
  }

  void respawnAt(Vector2 targetPos) {
    position.setFrom(targetPos);
    velocity.setZero();
    isAlive = true;
    isOnGround = true; // Grounded on spawn platform
    canDoubleJump = true; // Can air jump
    moveInput = 0.0;
    isJumpHeld = false;
    _coyoteTimer = 0.10; // Immediate coyote leniency
    _jumpBufferTimer = 0.0;
  }

  List<PlatformBlock> _getBlocks() {
    final stage = game.currentStage;
    if (stage != null && stage.platforms.isNotEmpty) {
      return stage.platforms;
    }
    final List<PlatformBlock> list = [];
    if (stage != null) {
      list.addAll(stage.children.whereType<PlatformBlock>());
    }
    if (parent != null && parent != stage) {
      list.addAll(parent!.children.whereType<PlatformBlock>());
    }
    return list;
  }

  List<CollapsingBlock> _getCollapsingBlocks() {
    final stage = game.currentStage;
    if (stage != null && stage.collapsingPlatforms.isNotEmpty) {
      return stage.collapsingPlatforms;
    }
    final List<CollapsingBlock> list = [];
    if (stage != null) {
      list.addAll(stage.children.whereType<CollapsingBlock>());
    }
    if (parent != null && parent != stage) {
      list.addAll(parent!.children.whereType<CollapsingBlock>());
    }
    return list;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;

    // Clamp dt to avoid tunneling during lag spikes or initial frame
    final clampedDt = dt.clamp(0.0, 0.033);

    // Sub-step physics if dt is large enough to ensure collision precision
    if (clampedDt > 0.016) {
      final halfDt = clampedDt / 2;
      _updatePhysics(halfDt);
      if (isAlive) _updatePhysics(halfDt);
    } else {
      _updatePhysics(clampedDt);
    }

    // Fall out of screen = death
    if (position.y > GameConstants.gameHeight + 40) {
      die();
    }
  }

  void _updatePhysics(double dt) {
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

    // Active TriggerZone sweep check
    final stage = game.currentStage;
    if (stage != null) {
      final pRect = toRect();
      final zones = stage.triggerZones.isNotEmpty
          ? stage.triggerZones
          : stage.children.whereType<TriggerZone>();
      for (final zone in zones) {
        if (zone.toRect().overlaps(pRect)) {
          zone.activate();
        }
      }
    }

    // Move & resolve collisions with solid blocks
    _moveWithCollisions(dt);
  }

  bool _hasBlockAbove(PlatformBlock block, List<PlatformBlock> blocks) {
    final bRect = block.toRect();
    return blocks.any((other) {
      if (other == block) return false;
      final oRect = other.toRect();
      return (oRect.bottom - bRect.top).abs() < 1.0 &&
          oRect.left < bRect.right - 2.0 &&
          oRect.right > bRect.left + 2.0;
    });
  }

  bool _hasBlockBelow(PlatformBlock block, List<PlatformBlock> blocks) {
    final bRect = block.toRect();
    return blocks.any((other) {
      if (other == block) return false;
      final oRect = other.toRect();
      return (bRect.bottom - oRect.top).abs() < 1.0 &&
          oRect.left < bRect.right - 2.0 &&
          oRect.right > bRect.left + 2.0;
    });
  }

  bool _hasBlockLeft(PlatformBlock block, List<PlatformBlock> blocks) {
    final bRect = block.toRect();
    return blocks.any((other) {
      if (other == block) return false;
      final oRect = other.toRect();
      return (oRect.right - bRect.left).abs() < 1.0 &&
          oRect.top < bRect.bottom - 2.0 &&
          oRect.bottom > bRect.top + 2.0;
    });
  }

  bool _hasBlockRight(PlatformBlock block, List<PlatformBlock> blocks) {
    final bRect = block.toRect();
    return blocks.any((other) {
      if (other == block) return false;
      final oRect = other.toRect();
      return (bRect.right - oRect.left).abs() < 1.0 &&
          oRect.top < bRect.bottom - 2.0 &&
          oRect.bottom > bRect.top + 2.0;
    });
  }

  void _moveWithCollisions(double dt) {
    final blocks = _getBlocks();
    final collapsingBlocks = _getCollapsingBlocks();

    final prevY = position.y;

    // 1. Horizontal movement and collision pass
    position.x += velocity.x * dt;

    for (final block in blocks) {
      if (!block.isSolid) continue;
      final blockRect = block.toRect();
      final playerRectX = toRect();
      if (!playerRectX.overlaps(blockRect)) continue;

      // Ignore internal vertical seams between adjacent floor/ceiling blocks
      if (velocity.x > 0 && _hasBlockLeft(block, blocks)) continue;
      if (velocity.x < 0 && _hasBlockRight(block, blocks)) continue;

      final bool hasAbove = _hasBlockAbove(block, blocks);
      final bool hasBelow = _hasBlockBelow(block, blocks);

      // Check if player is above the block ledge
      final bool wasAboveTop = !hasAbove && (prevY + height <= blockRect.top + 1.0);
      // Ledge hop assistance: if jumping upwards and feet will reach/clear the ledge
      final bool willClearLedge = !hasAbove &&
          velocity.y < 0 &&
          (prevY + velocity.y * dt + height <= blockRect.top + 6.0);
      // If player was below the block underside
      final bool wasBelowBottom = !hasBelow && (prevY >= blockRect.bottom - 1.0);

      if (!wasAboveTop && !willClearLedge && !wasBelowBottom) {
        if (playerRectX.bottom > blockRect.top + 3.0 && playerRectX.top < blockRect.bottom - 3.0) {
          if (velocity.x > 0) {
            position.x = blockRect.left - width;
          } else if (velocity.x < 0) {
            position.x = blockRect.right;
          }
          velocity.x = 0;
        }
      }
    }

    // Also block horizontally against intact collapsing blocks
    for (final cBlock in collapsingBlocks) {
      if (cBlock.isFalling) continue;
      final blockRect = cBlock.toRect();
      final playerRectX = toRect();
      if (!playerRectX.overlaps(blockRect)) continue;

      final bool wasAboveTop = prevY + height <= blockRect.top + 1.0;
      final bool willClearLedge = velocity.y < 0 && (prevY + velocity.y * dt + height <= blockRect.top + 6.0);
      final bool wasBelowBottom = prevY >= blockRect.bottom - 1.0;

      if (!wasAboveTop && !willClearLedge && !wasBelowBottom) {
        if (playerRectX.bottom > blockRect.top + 3.0 && playerRectX.top < blockRect.bottom - 3.0) {
          if (velocity.x > 0) {
            position.x = blockRect.left - width;
          } else if (velocity.x < 0) {
            position.x = blockRect.right;
          }
          velocity.x = 0;
        }
      }
    }

    // 2. Vertical movement and collision pass
    position.y += velocity.y * dt;
    isOnGround = false;

    // Check solid blocks
    for (final block in blocks) {
      if (!block.isSolid) continue;
      final blockRect = block.toRect();
      final playerRectY = toRect();
      if (!playerRectY.overlaps(blockRect)) continue;

      final bool hasAbove = _hasBlockAbove(block, blocks);
      final bool hasBelow = _hasBlockBelow(block, blocks);

      // Only land or bonk ceiling if horizontally overlapping the block
      if (playerRectY.right > blockRect.left + 2.0 && playerRectY.left < blockRect.right - 2.0) {
        if (velocity.y > 0 && !hasAbove) {
          // Landing on exposed block top
          if (prevY + height <= blockRect.top + (velocity.y * dt).abs() + 6.0) {
            position.y = blockRect.top - height;
            velocity.y = 0;
            isOnGround = true;
          }
        } else if (velocity.y < 0) {
          // Check if hitting exposed ceiling from underneath
          if (!hasBelow && prevY >= blockRect.bottom - (velocity.y * dt).abs() - 4.0) {
            position.y = blockRect.bottom;
            velocity.y = 0;
          } else if (!hasAbove && playerRectY.bottom <= blockRect.top + 6.0) {
            // Ledge hop landing: jumped up and feet caught the top edge
            position.y = blockRect.top - height;
            velocity.y = 0;
            isOnGround = true;
          }
        }
      } else if (velocity.y < 0 && !hasBelow && prevY >= blockRect.bottom - 6.0) {
        // Corner correction on ceiling bonk:
        // If clipping a ceiling corner by <= 4 pixels, nudge horizontally to glide past
        if (playerRectY.right <= blockRect.left + 4.0 && velocity.x <= 0) {
          position.x = blockRect.left - width;
        } else if (playerRectY.left >= blockRect.right - 4.0 && velocity.x >= 0) {
          position.x = blockRect.right;
        }
      }
    }

    // Check collapsing blocks (only when intact and not falling)
    for (final cBlock in collapsingBlocks) {
      if (cBlock.isFalling) continue;
      final cRect = cBlock.toRect();
      final playerRectY = toRect();
      if (!playerRectY.overlaps(cRect)) continue;

      if (playerRectY.right > cRect.left + 2.0 &&
          playerRectY.left < cRect.right - 2.0) {
        if (velocity.y > 0 && prevY + height <= cRect.top + (velocity.y * dt).abs() + 6.0) {
          position.y = cRect.top - height;
          velocity.y = 0;
          isOnGround = true;
          cBlock.trigger(); // Trigger collapse
        } else if (velocity.y < 0) {
          // Check if hitting exposed ceiling from underneath (solid head bonk)
          if (prevY >= cRect.bottom - (velocity.y * dt).abs() - 4.0) {
            position.y = cRect.bottom;
            velocity.y = 0;
          } else if (playerRectY.bottom <= cRect.top + 6.0) {
            // Ledge hop landing: jumped up and feet caught the top edge
            position.y = cRect.top - height;
            velocity.y = 0;
            isOnGround = true;
            cBlock.trigger();
          }
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
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
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

    // If custom sprite asset is provided, render it!
    if (_idleSprite != null) {
      _idleSprite!.render(canvas, size: size);
      canvas.restore();
      return;
    }

    // Procedural Vector Fallback:
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

    canvas.restore();
  }
}
