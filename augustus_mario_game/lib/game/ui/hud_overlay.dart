import 'package:flutter/material.dart';
import '../../theme/retro_theme.dart';

class HudOverlay extends StatelessWidget {
  final String stageName;
  final int deathCount;
  final VoidCallback onMenuPressed;
  final VoidCallback onToggleControls;
  final bool showControls;
  final VoidCallback? onToggleHitbox;
  final bool showHitbox;

  const HudOverlay({
    super.key,
    required this.stageName,
    required this.deathCount,
    required this.onMenuPressed,
    required this.onToggleControls,
    required this.showControls,
    this.onToggleHitbox,
    this.showHitbox = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Stage Title Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: RetroTheme.pixelBoxDecoration(
              fillColor: const Color(0xDD1E222D),
              borderColor: RetroTheme.accent,
              borderWidth: 2,
            ),
            child: Text(
              stageName,
              style: RetroTheme.pixelText(fontSize: 13, color: RetroTheme.yellow),
            ),
          ),

          // Death Counter Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: RetroTheme.pixelBoxDecoration(
              fillColor: const Color(0xDD1E222D),
              borderColor: RetroTheme.primary,
              borderWidth: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.dangerous_rounded, color: RetroTheme.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  "DEATHS: $deathCount",
                  style: RetroTheme.pixelText(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),

          // Actions: Hitbox Debug, Controls Toggle & Menu Button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onToggleHitbox != null)
                IconButton(
                  tooltip: showHitbox ? "Hide Hazard Hitboxes (H)" : "Show Hazard Hitboxes (H)",
                  icon: Icon(
                    showHitbox ? Icons.visibility_rounded : Icons.visibility_off_outlined,
                    color: showHitbox ? RetroTheme.green : Colors.grey,
                    size: 24,
                  ),
                  onPressed: onToggleHitbox,
                ),
              IconButton(
                tooltip: showControls ? "Hide Virtual Controls" : "Show Virtual Controls",
                icon: Icon(
                  showControls ? Icons.gamepad_rounded : Icons.gamepad_outlined,
                  color: showControls ? RetroTheme.green : Colors.grey,
                  size: 24,
                ),
                onPressed: onToggleControls,
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onMenuPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: RetroTheme.pixelBoxDecoration(
                    fillColor: RetroTheme.primary,
                    borderColor: Colors.white,
                    borderWidth: 2,
                  ),
                  child: Text(
                    "MENU",
                    style: RetroTheme.pixelText(fontSize: 13, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
