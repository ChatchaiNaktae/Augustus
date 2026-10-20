import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game_constants.dart';

/// Single stuck blood mark painted on a solid obstacle (floor, wall, ceiling)
class StuckBloodSplat {
  final Rect rect;
  final Color color;

  const StuckBloodSplat({
    required this.rect,
    required this.color,
  });
}

/// Permanent decal layer that renders accumulated blood stains across deaths
class BloodDecalComponent extends Component {
  BloodDecalComponent() : super(priority: 5);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..style = PaintingStyle.fill;
    for (final splat in BloodParticleSystem.persistentSplats) {
      paint.color = splat.color;
      canvas.drawRect(splat.rect, paint);
    }
  }
}

/// Active flying blood drop particle
class _BloodDrop {
  Vector2 position;
  Vector2 velocity;
  double size;
  Color color;
  double alpha;

  _BloodDrop({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
  }) : alpha = 1.0;
}

class _RayHit {
  final double t;
  final Vector2 point;
  final Vector2 normal;

  _RayHit({required this.t, required this.point, required this.normal});
}

/// System for simulating death blood fountain with continuous raycast collision
/// against static platforms, walls, and floors.
class BloodParticleSystem extends PositionComponent {
  /// Persistent blood marks across deaths (retained until stage reload)
  static final List<StuckBloodSplat> persistentSplats = [];
  static const int maxPersistentSplats = 1500;

  static void clearPersistentSplats() {
    persistentSplats.clear();
  }

  static void addStuckSplat(StuckBloodSplat splat) {
    persistentSplats.add(splat);
    if (persistentSplats.length > maxPersistentSplats) {
      persistentSplats.removeRange(0, persistentSplats.length - maxPersistentSplats);
    }
  }

  final List<_BloodDrop> _particles = [];
  final List<Rect> _obstacles;
  final Random _rng = Random();
  double _lifeTimer = 0.0;
  static const double maxLifetime = GameConstants.bloodLifetime;

  BloodParticleSystem({
    required Vector2 origin,
    List<Rect> obstacles = const [],
    int count = GameConstants.deathBloodParticleCount,
  })  : _obstacles = obstacles,
        super(position: Vector2.zero(), priority: 10) {
    // Pure, authentic IWBTG retro blood color palette (various shades of crimson/red)
    final colors = [
      const Color(0xFFE02222), // Bright arterial red
      const Color(0xFFBE1E2D), // Classic IWBTG crimson
      const Color(0xFFCC1111), // Vivid blood red
      const Color(0xFF990000), // Dark blood
      const Color(0xFF7A0000), // Dried blood
      const Color(0xFF550000), // Deep coagulated red
    ];

    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = GameConstants.bloodMinSpeed +
          _rng.nextDouble() * (GameConstants.bloodMaxSpeed - GameConstants.bloodMinSpeed);
      final velocity = Vector2(cos(angle) * speed, sin(angle) * speed);

      // Natural burst spread around player center
      final startPos = Vector2(
        origin.x + (_rng.nextDouble() - 0.5) * 12,
        origin.y + (_rng.nextDouble() - 0.5) * 14,
      );

      _particles.add(
        _BloodDrop(
          position: startPos,
          velocity: velocity,
          size: 2.0 + _rng.nextDouble() * 2.5,
          color: colors[_rng.nextInt(colors.length)],
        ),
      );
    }
  }

  /// Raycast continuous line segment against an axis-aligned bounding box (AABB)
  _RayHit? _raycastAABB(Vector2 p0, Vector2 p1, Rect box) {
    if (box.contains(Offset(p0.x, p0.y))) {
      return _RayHit(t: 0.0, point: p0, normal: Vector2(0, -1));
    }

    final double dx = p1.x - p0.x;
    final double dy = p1.y - p0.y;

    double tNearX;
    double tFarX;
    double normalNearX;

    if (dx.abs() < 1e-6) {
      if (p0.x < box.left || p0.x > box.right) return null;
      tNearX = -double.infinity;
      tFarX = double.infinity;
      normalNearX = 0;
    } else {
      final double invDx = 1.0 / dx;
      final double t1 = (box.left - p0.x) * invDx;
      final double t2 = (box.right - p0.x) * invDx;
      if (t1 < t2) {
        tNearX = t1;
        tFarX = t2;
        normalNearX = -1.0; // Left face
      } else {
        tNearX = t2;
        tFarX = t1;
        normalNearX = 1.0; // Right face
      }
    }

    double tNearY;
    double tFarY;
    double normalNearY;

    if (dy.abs() < 1e-6) {
      if (p0.y < box.top || p0.y > box.bottom) return null;
      tNearY = -double.infinity;
      tFarY = double.infinity;
      normalNearY = 0;
    } else {
      final double invDy = 1.0 / dy;
      final double t1 = (box.top - p0.y) * invDy;
      final double t2 = (box.bottom - p0.y) * invDy;
      if (t1 < t2) {
        tNearY = t1;
        tFarY = t2;
        normalNearY = -1.0; // Top face (Floor)
      } else {
        tNearY = t2;
        tFarY = t1;
        normalNearY = 1.0; // Bottom face (Ceiling)
      }
    }

    final double tNear = max(tNearX, tNearY);
    final double tFar = min(tFarX, tFarY);

    if (tNear > tFar || tFar < 0.0 || tNear > 1.0) {
      return null;
    }

    final double t = tNear.clamp(0.0, 1.0);
    final Vector2 hitPoint = p0 + (p1 - p0) * t;

    Vector2 hitNormal;
    if (tNearX > tNearY) {
      hitNormal = Vector2(normalNearX, 0);
    } else {
      hitNormal = Vector2(0, normalNearY);
    }

    return _RayHit(t: t, point: hitPoint, normal: hitNormal);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTimer += dt;

    final gravity = Vector2(0, 850 * dt);

    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      final from = Vector2.copy(p.position);
      p.velocity += gravity;
      final to = from + p.velocity * dt;

      // Check raycast against static obstacles
      _RayHit? closestHit;
      Rect? closestBox;

      for (final box in _obstacles) {
        final hit = _raycastAABB(from, to, box);
        if (hit != null) {
          if (closestHit == null || hit.t < closestHit.t) {
            closestHit = hit;
            closestBox = box;
          }
        }
      }

      if (closestHit != null && closestBox != null) {
        // 80% stick as blood decals, 20% bounce off / disintegrate
        if (_rng.nextDouble() < 0.80) {
          final normal = closestHit.normal;

          // Natural chunky retro pixel splat size (2x2 to 4x4)
          final double baseSize = (2 + _rng.nextInt(3)).toDouble(); // 2, 3, or 4 px
          double splatW = baseSize;
          double splatH = baseSize;

          if (_rng.nextBool()) {
            if (normal.y != 0) {
              splatW += 1.0; // slight horizontal spread on floor/ceiling
            } else {
              splatH += 1.0; // slight vertical drip on walls
            }
          }

          double splatX = closestHit.point.x - splatW / 2;
          double splatY = closestHit.point.y - splatH / 2;

          // Align nicely onto the surface edge with subtle random jitter (+- 1.5px)
          if (normal.y < 0) {
            // Floor / Platform Top
            splatY = closestBox.top - splatH + 1.0;
            splatX += (_rng.nextDouble() - 0.5) * 3.0;
          } else if (normal.y > 0) {
            // Ceiling
            splatY = closestBox.bottom - 1.0;
            splatX += (_rng.nextDouble() - 0.5) * 3.0;
          } else if (normal.x < 0) {
            // Left face of wall
            splatX = closestBox.left - splatW + 1.0;
            splatY += (_rng.nextDouble() - 0.5) * 3.0;
          } else if (normal.x > 0) {
            // Right face of wall
            splatX = closestBox.right - 1.0;
            splatY += (_rng.nextDouble() - 0.5) * 3.0;
          }

          final splatRect = Rect.fromLTWH(
            splatX.roundToDouble(),
            splatY.roundToDouble(),
            splatW,
            splatH,
          );

          addStuckSplat(StuckBloodSplat(rect: splatRect, color: p.color));
        }

        // Particle done flying
        _particles.removeAt(i);
        continue;
      }

      // No collision: continue flying
      p.position = to;

      // Fade out non-stuck flying particles in the last 30% of lifetime
      if (_lifeTimer > maxLifetime * 0.7) {
        final progress = (_lifeTimer - maxLifetime * 0.7) / (maxLifetime * 0.3);
        p.alpha = (1.0 - progress).clamp(0.0, 1.0);
      }

      // Expire particle if off-screen or faded
      if (_lifeTimer >= maxLifetime || p.position.y > 650 || p.alpha <= 0) {
        _particles.removeAt(i);
      }
    }

    // Once all flying particles have either stuck or expired, remove this active system
    if (_particles.isEmpty) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in _particles) {
      if (p.alpha <= 0) continue;
      paint.color = p.color.withValues(alpha: p.alpha);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(p.position.x, p.position.y), width: p.size, height: p.size),
        paint,
      );
    }
  }
}
