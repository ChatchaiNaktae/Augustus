import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/iwbtg_game.dart';
import '../game/ui/hud_overlay.dart';
import '../game/ui/virtual_controls.dart';
import '../theme/retro_theme.dart';
import 'select_stage_screen.dart';

class GamePlayScreen extends StatefulWidget {
  final int initialStage;

  const GamePlayScreen({super.key, this.initialStage = 1});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  late IWBTGGame _game;
  int _deathCount = 0;
  String _currentStageName = "STAGE 1";
  bool _showVirtualControls = true;
  bool _isPlayerDead = false;

  @override
  void initState() {
    super.initState();
    _game = IWBTGGame(
      initialStage: widget.initialStage,
      onDeathsUpdated: (deaths) {
        if (mounted) setState(() => _deathCount = deaths);
      },
      onStageUpdated: (stageNum, name) {
        if (mounted) setState(() => _currentStageName = name);
      },
      onVictoryTriggered: () {
        if (mounted) _showVictoryDialog();
      },
      onPlayerStateChanged: (isDead) {
        if (mounted) setState(() => _isPlayerDead = isDead);
      },
      onPauseRequested: () {
        if (mounted) _showPauseMenu();
      },
    );
  }

  void _showPauseMenu() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: RetroTheme.surface,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: RetroTheme.yellow, width: 3),
        ),
        title: Center(
          child: Text(
            "PAUSED",
            style: RetroTheme.titleStyle(fontSize: 24, color: RetroTheme.yellow),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "CURRENT DEATHS: $_deathCount",
              style: RetroTheme.pixelText(fontSize: 14, color: RetroTheme.primary),
            ),
            const SizedBox(height: 24),
            RetroButton(
              label: "RESUME",
              icon: Icons.play_arrow_rounded,
              baseColor: RetroTheme.green,
              textColor: Colors.black,
              width: 200,
              height: 46,
              onPressed: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 12),
            RetroButton(
              label: "RESTART STAGE",
              icon: Icons.refresh_rounded,
              baseColor: RetroTheme.primary,
              textColor: Colors.white,
              width: 200,
              height: 46,
              onPressed: () {
                Navigator.pop(ctx);
                _game.restartCurrentStage();
              },
            ),
            const SizedBox(height: 12),
            RetroButton(
              label: "SELECT STAGE",
              icon: Icons.grid_view_rounded,
              baseColor: RetroTheme.accent,
              textColor: Colors.black,
              width: 200,
              height: 46,
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SelectStageScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            RetroButton(
              label: "MAIN MENU",
              icon: Icons.home_rounded,
              baseColor: const Color(0xFF4C566A),
              textColor: Colors.white,
              width: 200,
              height: 46,
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Back to MainMenuScreen
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: RetroTheme.surface,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFFFFD700), width: 4),
        ),
        title: Column(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 54),
            const SizedBox(height: 8),
            Text(
              "CONGRATULATIONS!",
              style: RetroTheme.titleStyle(fontSize: 22, color: const Color(0xFFFFD700)),
            ),
            Text(
              "YOU ARE THE GUY!",
              style: RetroTheme.pixelText(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "TOTAL DEATHS: $_deathCount",
              style: RetroTheme.pixelText(fontSize: 16, color: RetroTheme.primary),
            ),
            const SizedBox(height: 10),
            const Text(
              "คุณได้พิชิตทั้ง 3 ด่านของเกม Masocore ในตำนานสำเร็จแล้ว!",
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            RetroButton(
              label: "PLAY AGAIN",
              icon: Icons.replay_rounded,
              baseColor: RetroTheme.green,
              textColor: Colors.black,
              width: 200,
              height: 46,
              onPressed: () {
                Navigator.pop(ctx);
                _game.loadStage(1);
              },
            ),
            const SizedBox(height: 12),
            RetroButton(
              label: "MAIN MENU",
              icon: Icons.home_rounded,
              baseColor: RetroTheme.accent,
              textColor: Colors.black,
              width: 200,
              height: 46,
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // The Flame Game Canvas
          Positioned.fill(
            child: GameWidget<IWBTGGame>(
              game: _game,
              autofocus: true,
            ),
          ),

          // Mobile / Virtual Controls Overlay (if enabled)
          if (_showVirtualControls)
            VirtualControlsOverlay(game: _game),

          // Game Over / Tap to Retry Overlay (shown only when dead)
          if (_isPlayerDead)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _game.respawnPlayer(),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "GAME OVER",
                          style: RetroTheme.titleStyle(fontSize: 34, color: RetroTheme.primary),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: RetroTheme.pixelBoxDecoration(
                            fillColor: const Color(0xEE1E222D),
                            borderColor: RetroTheme.yellow,
                            borderWidth: 2,
                          ),
                          child: Text(
                            "PRESS [R] OR TAP ANYWHERE TO RETRY",
                            style: RetroTheme.pixelText(fontSize: 13, color: RetroTheme.yellow),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Top HUD Overlay (Placed on top so Menu is always clickable!)
          ValueListenableBuilder<bool>(
            valueListenable: _game.showHazardHitboxesNotifier,
            builder: (context, showHitbox, _) {
              return HudOverlay(
                stageName: _currentStageName,
                deathCount: _deathCount,
                showControls: _showVirtualControls,
                showHitbox: showHitbox,
                onToggleControls: () {
                  setState(() => _showVirtualControls = !_showVirtualControls);
                },
                onToggleHitbox: _game.toggleHazardHitboxes,
                onMenuPressed: _showPauseMenu,
              );
            },
          ),
        ],
      ),
    );
  }
}
