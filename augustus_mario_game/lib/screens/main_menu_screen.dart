import 'stage_editor_screen.dart';
import 'select_custom_stage_screen.dart';
import 'character_editor_screen.dart';
import 'career_stats_screen.dart';
import 'package:flutter/material.dart';
import '../theme/retro_theme.dart';
import 'select_stage_screen.dart';
import 'game_play_screen.dart';
import 'about_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RetroTheme.surface,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: RetroTheme.yellow, width: 3),
        ),
        title: Center(
          child: Text(
            "HOW TO PLAY",
            style: RetroTheme.titleStyle(fontSize: 22, color: RetroTheme.yellow),
          ),
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _instructionSection("⌨️ KEYBOARD (DESKTOP & WEB)", [
                  "Move: Left / Right Arrow or A / D",
                  "Jump / Double Jump: Shift or Space or W",
                  "Instant Restart: R (Zero Delay!)",
                  "Release jump early for lower jump (Variable Jump)",
                ]),
                const SizedBox(height: 16),
                _instructionSection("📱 TOUCH CONTROLS (MOBILE)", [
                  "Virtual D-Pad on bottom-left to move",
                  "JUMP button on bottom-right (Double Jump)",
                  "R button above JUMP for instant retry after death",
                ]),
                const SizedBox(height: 16),
                _instructionSection("💡 SURVIVAL TIPS", [
                  "Traps trigger at point-blank proximity — stay alert!",
                  "Apples and spikes do NOT follow the laws of physics!",
                  "Death is part of the learning process - press R quickly!",
                ]),
              ],
            ),
          ),
        ),
        actions: [
          Center(
            child: RetroButton(
              label: "GOT IT!",
              width: 160,
              height: 44,
              baseColor: RetroTheme.green,
              textColor: Colors.black,
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionSection(String title, List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: RetroTheme.pixelText(fontSize: 14, color: RetroTheme.accent),
        ),
        const SizedBox(height: 6),
        ...lines.map(
          (line) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(color: RetroTheme.primary, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    line,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: RetroTheme.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroTheme.background,
      body: Stack(
        children: [
          // Background Retro Grid pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _RetroGridPainter(),
            ),
          ),

          // Main Center Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Decorative Cherries & Spikes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _miniSpike(),
                      const SizedBox(width: 8),
                      _miniApple(),
                      const SizedBox(width: 12),
                      Text(
                        "FLUTTER EDITION",
                        style: RetroTheme.pixelText(
                          fontSize: 14,
                          color: RetroTheme.yellow,
                          hasShadow: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _miniApple(),
                      const SizedBox(width: 8),
                      _miniSpike(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Giant Title
                  Text(
                    "AUGUSTUS\nBRUTAL",
                    textAlign: TextAlign.center,
                    style: RetroTheme.titleStyle(
                      fontSize: 42,
                      color: Colors.white,
                      hasShadow: false,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "MASOCORE TRAP PLATFORMER",
                    style: RetroTheme.pixelText(
                      fontSize: 13,
                      color: RetroTheme.accent,
                      hasShadow: false,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Menu Buttons in 2-Column Responsive Layout
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Column 1: Story & Gameplay
                        Expanded(
                          child: Column(
                            children: [
                              RetroButton(
                                label: "START GAME",
                                icon: Icons.play_arrow_rounded,
                                baseColor: RetroTheme.green,
                                textColor: Colors.black,
                                width: double.infinity,
                                height: 48,
                                fontSize: 14,
                                hasShadow: false,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const GamePlayScreen(initialStage: 1),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              RetroButton(
                                label: "SELECT STAGE",
                                icon: Icons.grid_view_rounded,
                                baseColor: RetroTheme.accent,
                                textColor: Colors.black,
                                width: double.infinity,
                                height: 48,
                                fontSize: 14,
                                hasShadow: false,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SelectStageScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              RetroButton(
                                label: "CUSTOM STAGES",
                                icon: Icons.videogame_asset,
                                baseColor: RetroTheme.yellow,
                                textColor: Colors.black,
                                width: double.infinity,
                                height: 48,
                                fontSize: 14,
                                hasShadow: false,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SelectCustomStageScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              RetroButton(
                                label: "HOW TO PLAY",
                                icon: Icons.help_outline_rounded,
                                baseColor: RetroTheme.surfaceHighlight,
                                textColor: RetroTheme.white,
                                width: double.infinity,
                                height: 48,
                                fontSize: 14,
                                hasShadow: false,
                                onPressed: () => _showHowToPlay(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Column 2: Studio & Customization & Career
                        Expanded(
                          child: Column(
                            children: [
                              RetroButton(
                                label: "STAGE EDITOR",
                                icon: Icons.construction,
                                baseColor: const Color(0xFF5E81AC),
                                textColor: Colors.white,
                                width: double.infinity,
                                height: 48,
                                fontSize: 14,
                                hasShadow: false,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const StageEditorScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              RetroButton(
                                label: "CHARACTER",
                                icon: Icons.checkroom,
                                baseColor: const Color(0xFFD08770),
                                textColor: Colors.black,
                                width: double.infinity,
                                height: 48,
                                fontSize: 14,
                                hasShadow: false,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CharacterEditorScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              RetroButton(
                                label: "CAREER STATS",
                                icon: Icons.emoji_events,
                                baseColor: const Color(0xFFB48EAD),
                                textColor: Colors.white,
                                width: double.infinity,
                                height: 48,
                                fontSize: 14,
                                hasShadow: false,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CareerStatsScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              RetroButton(
                                label: "ABOUT / ผู้จัดทำ",
                                icon: Icons.info_outline_rounded,
                                baseColor: RetroTheme.purple,
                                textColor: Colors.white,
                                width: double.infinity,
                                height: 48,
                                fontSize: 14,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AboutScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Footer credits
                  Text(
                    "Inspired by I Wanna Be The Guy & Flook611 Gameplay\nBuilt with Flutter & Flame Engine",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniApple() {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: RetroTheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _miniSpike() {
    return CustomPaint(
      size: const Size(16, 16),
      painter: _MiniSpikePainter(),
    );
  }
}

class _RetroGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniSpikePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFD8DEE9));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
