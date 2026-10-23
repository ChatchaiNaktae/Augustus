import 'package:flutter/material.dart';
import '../models/player_career_stats.dart';
import '../models/player_customization.dart';
import '../services/storage_manager.dart';
import '../theme/retro_theme.dart';

class CareerStatsScreen extends StatelessWidget {
  const CareerStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = StorageManager.instance.getCareerStats();
    final custom = StorageManager.instance.getCustomization();

    return Scaffold(
      backgroundColor: RetroTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  RetroButton(
                    label: "BACK",
                    prefixIcon: Icons.arrow_back,
                    width: 100,
                    height: 38,
                    baseColor: RetroTheme.surface,
                    textColor: RetroTheme.white,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "CAREER STATS & TROPHIES",
                    style: RetroTheme.titleStyle(fontSize: 22, color: RetroTheme.yellow),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Content: Profile Stats Left, Trophy Cabinet Right
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left: Stats Summary
                    Expanded(
                      flex: 4,
                      child: _buildProfileStatsCard(stats, custom),
                    ),
                    const SizedBox(width: 16),
                    // Right: Trophy Cabinet
                    Expanded(
                      flex: 6,
                      child: _buildTrophyCabinet(stats),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStatsCard(PlayerCareerStats stats, PlayerCustomization custom) {
    final totalAttempts = stats.totalDeaths + stats.totalClears;
    final winRate = totalAttempts > 0
        ? ((stats.totalClears / totalAttempts) * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RetroTheme.surface,
        border: Border.all(color: RetroTheme.surfaceHighlight, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: RetroTheme.primary.withValues(alpha: 0.2),
            child: const Text(
              "PLAYER PROFILE",
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: RetroTheme.accent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Mini avatar preview
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: RetroTheme.background,
              border: Border.all(color: RetroTheme.accent, width: 2),
            ),
            child: CustomPaint(
              painter: _MiniAvatarPainter(customization: custom),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildStatRow("TOTAL DEATHS", "${stats.totalDeaths} 💀", RetroTheme.primary),
                _buildStatRow("TOTAL CLEARS", "${stats.totalClears} 🏆", RetroTheme.yellow),
                _buildStatRow("WIN RATE", "$winRate%", RetroTheme.accent),
                _buildStatRow("STAGES CREATED", "${stats.stagesCreatedCount} 📐", RetroTheme.green),
                _buildStatRow("TROPHIES UNLOCKED",
                    "${stats.unlockedAchievements.length} / ${PlayerCareerStats.allAchievements.length}",
                    Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: RetroTheme.background,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey)),
            Text(value, style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold, color: valColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrophyCabinet(PlayerCareerStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RetroTheme.surface,
        border: Border.all(color: RetroTheme.surfaceHighlight, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: RetroTheme.yellow.withValues(alpha: 0.2),
            child: const Text(
              "MASOCORE TROPHY CABINET",
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: RetroTheme.yellow,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: PlayerCareerStats.allAchievements.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ach = PlayerCareerStats.allAchievements[index];
                final isUnlocked = stats.unlockedAchievements.contains(ach.key);

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUnlocked ? RetroTheme.background : RetroTheme.background.withValues(alpha: 0.5),
                    border: Border.all(
                      color: isUnlocked ? RetroTheme.yellow : Colors.grey[800]!,
                      width: isUnlocked ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        ach.icon,
                        style: TextStyle(fontSize: 24, color: isUnlocked ? null : Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ach.title,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked ? RetroTheme.yellow : Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ach.description,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: isUnlocked ? Colors.grey[300] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isUnlocked ? RetroTheme.green : Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isUnlocked ? "UNLOCKED" : "LOCKED",
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? Colors.black : Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAvatarPainter extends CustomPainter {
  final PlayerCustomization customization;

  _MiniAvatarPainter({required this.customization});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    const double baseSize = 24.0;
    final scale = size.width / baseSize;
    canvas.scale(scale, scale);

    // Cape
    if (customization.capeEnabled) {
      canvas.drawPath(
        Path()
          ..moveTo(2, 10)
          ..lineTo(-5, 14)
          ..lineTo(-3, 22)
          ..lineTo(4, 18)
          ..close(),
        Paint()..color = customization.capeColorValue,
      );
    }

    // Body
    canvas.drawRect(const Rect.fromLTWH(4, 12, 14, 14), Paint()..color = customization.pantsColorValue);
    // Shirt
    canvas.drawRect(const Rect.fromLTWH(5, 12, 12, 6), Paint()..color = customization.shirtColorValue);
    // Face
    canvas.drawRect(const Rect.fromLTWH(5, 4, 12, 9), Paint()..color = customization.skinColorValue);
    // Eye
    canvas.drawRect(const Rect.fromLTWH(12, 6, 2, 4), Paint()..color = Colors.black);

    // Hat
    if (customization.hatType == HatType.cap) {
      canvas.drawRect(const Rect.fromLTWH(3, 1, 15, 4), Paint()..color = customization.hatColorValue);
      canvas.drawRect(const Rect.fromLTWH(11, 4, 6, 2), Paint()..color = customization.hatColorValue);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniAvatarPainter oldDelegate) =>
      oldDelegate.customization != customization;
}
