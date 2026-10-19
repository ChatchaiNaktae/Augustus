import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'hazard_base.dart';
import '../../game_constants.dart';
import '../../utils/game_asset_loader.dart';

enum SpikeDirection { up, down, left, right }

class SpikeHazard extends HazardBase {
  Sprite? _sprite;
  final SpikeDirection direction;
  final Vector2? triggerVelocity;
  final bool isTriggered;
  final Vector2 _initialPosition;
  Vector2 _velocity = Vector2.zero();
  bool _active = false;

  SpikeHazard({
    required super.position,
    this.direction = SpikeDirection.up,
    this.triggerVelocity,
    this.isTriggered = false,
    super.hazardId,
    double size = 32.0,
  })  : _initialPosition = position!.clone(),
        super(size: Vector2.all(size)) {
    // Add polygon hitbox matching the spike triangle
    add(PolygonHitbox(_getTriangleVertices()));
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final spriteName = switch (direction) {
      SpikeDirection.up => 'hazards/spike_up.png',
      SpikeDirection.down => 'hazards/spike_down.png',
      SpikeDirection.left => 'hazards/spike_left.png',
      SpikeDirection.right => 'hazards/spike_right.png',
    };
    _sprite = await GameAssetLoader.loadOptionalSprite(spriteName);
  }

  List<Vector2> _getTriangleVertices() {
    switch (direction) {
      case SpikeDirection.up:
        return [
          Vector2(width / 2, 2),
          Vector2(width - 2, height),
          Vector2(2, height),
        ];
      case SpikeDirection.down:
        return [
          Vector2(2, 0),
          Vector2(width - 2, 0),
          Vector2(width / 2, height - 2),
        ];
      case SpikeDirection.left:
        return [
          Vector2(2, height / 2),
          Vector2(width, 2),
          Vector2(width, height - 2),
        ];
      case SpikeDirection.right:
        return [
          Vector2(0, 2),
          Vector2(width - 2, height / 2),
          Vector2(0, height - 2),
        ];
    }
  }

  @override
  void trigger() {
    if (triggerVelocity != null && !_active) {
      _active = true;
      _velocity = triggerVelocity!.clone();
    }
  }

  @override
  void reset() {
    position.setFrom(_initialPosition);
    _velocity.setZero();
    _active = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active || _velocity.length2 == 0) return;

    // Sub-step movement to prevent tunneling against player at high speed (> 1,200 px/s)
    final moveDist = _velocity.length * dt;
    const double maxStep = 6.0;
    final int steps = (moveDist / maxStep).ceil().clamp(1, 24);
    final double stepDt = dt / steps;

    for (int i = 0; i < steps; i++) {
      position += _velocity * stepDt;

      if (isDeadly) {
        _checkPlayerCollision();
        if (!isDeadly || !_active) break;
      }
    }
  }

  void _checkPlayerCollision() {
    try {
      final player = game.player;
      if (player == null || !player.isAlive) return;

      final pRect = player.hitboxRect;
      if (_intersectsPlayer(pRect)) {
        player.die();
      }
    } catch (_) {
      // In case component is detached from game tree during update
    }
  }

  bool _intersectsPlayer(Rect pRect) {
    final sRect = toRect();
    if (!sRect.overlaps(pRect)) return false;

    final xMin = sRect.left > pRect.left ? sRect.left : pRect.left;
    final xMax = sRect.right < pRect.right ? sRect.right : pRect.right;
    final yMin = sRect.top > pRect.top ? sRect.top : pRect.top;
    final yMax = sRect.bottom < pRect.bottom ? sRect.bottom : pRect.bottom;

    final centerX = sRect.left + sRect.width / 2;
    final centerY = sRect.top + sRect.height / 2;

    switch (direction) {
      case SpikeDirection.up:
        // Tip at top (centerX, sRect.top), base at bottom sRect.bottom.
        // Triangle width increases with y; max width in [yMin, yMax] is at yMax.
        final maxW = ((yMax - sRect.top) / sRect.height) * (sRect.width / 2);
        return pRect.right >= centerX - maxW && pRect.left <= centerX + maxW;

      case SpikeDirection.down:
        // Tip at bottom (centerX, sRect.bottom), base at top sRect.top.
        // Triangle width increases as y decreases; max width in [yMin, yMax] is at yMin.
        final maxW = ((sRect.bottom - yMin) / sRect.height) * (sRect.width / 2);
        return pRect.right >= centerX - maxW && pRect.left <= centerX + maxW;

      case SpikeDirection.left:
        // Tip at left (sRect.left, centerY), base at right sRect.right.
        // Triangle height increases as x increases; max height in [xMin, xMax] is at xMax.
        final maxH = ((xMax - sRect.left) / sRect.width) * (sRect.height / 2);
        return pRect.bottom >= centerY - maxH && pRect.top <= centerY + maxH;

      case SpikeDirection.right:
        // Tip at right (sRect.right, centerY), base at left sRect.left.
        // Triangle height increases as x decreases; max height in [xMin, xMax] is at xMin.
        final maxH = ((sRect.right - xMin) / sRect.width) * (sRect.height / 2);
        return pRect.bottom >= centerY - maxH && pRect.top <= centerY + maxH;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_sprite != null) {
      _sprite!.render(canvas, size: size);
      return;
    }

    final path = Path();
    switch (direction) {
      case SpikeDirection.up:
        path.moveTo(width / 2, 0);
        path.lineTo(width, height);
        path.lineTo(0, height);
        break;
      case SpikeDirection.down:
        path.moveTo(0, 0);
        path.lineTo(width, 0);
        path.lineTo(width / 2, height);
        break;
      case SpikeDirection.left:
        path.moveTo(0, height / 2);
        path.lineTo(width, 0);
        path.lineTo(width, height);
        break;
      case SpikeDirection.right:
        path.moveTo(0, 0);
        path.lineTo(width, height / 2);
        path.lineTo(0, height);
        break;
    }
    path.close();

    // Base spike metallic fill
    final fillPaint = Paint()..color = GameConstants.spikeColor;
    canvas.drawPath(path, fillPaint);

    // Inner shadow for 3D metallic feel
    final shadowPaint = Paint()..color = const Color(0xFF8892B0);
    final shadowPath = Path();
    if (direction == SpikeDirection.up) {
      shadowPath.moveTo(width / 2, 0);
      shadowPath.lineTo(width, height);
      shadowPath.lineTo(width / 2, height);
      shadowPath.close();
      canvas.drawPath(shadowPath, shadowPaint);
    }

    // Spike sharp outline
    final strokePaint = Paint()
      ..color = const Color(0xFF2E3440)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, strokePaint);
  }
}
