import 'package:flutter/material.dart';

class GameConstants {
  // Virtual Game Resolution (Classic Retro 4:3)
  static const double gameWidth = 800.0;
  static const double gameHeight = 600.0;

  // Grid / Tile Size
  static const double tileSize = 32.0;

  // Player Physics
  static const double playerWidth = 24.0;
  static const double playerHeight = 28.0;
  static const double playerHitboxWidth = 14.0;
  static const double playerHitboxHeight = 22.0;

  static const double playerMoveSpeed = 220.0;
  static const double gravity = 1400.0;
  static const double maxFallSpeed = 700.0;
  static const double jumpVelocity = -485.0; // เดิม -430.0 (สูงขึ้นจาก 66px เป็น 84px)
  static const double doubleJumpVelocity = -445.0; // เดิม -390.0 (สูงขึ้นจาก 54px เป็น 71px)
  static const double jumpCutMultiplier = 0.45; // Variable jump height reduction

  // Blood Particle FX
  static const int deathBloodParticleCount = 75;
  static const double bloodMinSpeed = 80.0;
  static const double bloodMaxSpeed = 450.0;
  static const double bloodLifetime = 2.5;

  // Retro Colors
  static const Color bgColor = Color(0xFF0F111A);
  static const Color tileColor = Color(0xFF2E3440);
  static const Color tileBorderColor = Color(0xFF4C566A);
  static const Color spikeColor = Color(0xFFE5E9F0);
  static const Color appleRed = Color(0xFFE06C75);
  static const Color appleGreen = Color(0xFF98C379);
  static const Color retroYellow = Color(0xFFE5C07B);
  static const Color retroCyan = Color(0xFF56B6C2);
}
