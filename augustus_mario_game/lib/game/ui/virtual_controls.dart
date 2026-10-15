import 'package:flutter/material.dart';
import '../iwbtg_game.dart';
import '../../theme/retro_theme.dart';

class VirtualControlsOverlay extends StatelessWidget {
  final IWBTGGame game;

  const VirtualControlsOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // D-Pad: Left & Right
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TouchButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onDown: () => game.player?.setMoveInput(-1.0),
                onUp: () => game.player?.setMoveInput(0.0),
              ),
              const SizedBox(width: 12),
              _TouchButton(
                icon: Icons.arrow_forward_ios_rounded,
                onDown: () => game.player?.setMoveInput(1.0),
                onUp: () => game.player?.setMoveInput(0.0),
              ),
            ],
          ),

          // Center Quick Retry 'R' button
          _TouchButton(
            label: "R",
            bgColor: RetroTheme.primary.withValues(alpha: 0.85),
            borderColor: Colors.white,
            size: 52,
            onDown: () => game.respawnPlayer(),
          ),

          // Action Buttons: Shoot & Jump
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TouchButton(
                label: "SHOOT",
                bgColor: RetroTheme.yellow.withValues(alpha: 0.85),
                textColor: Colors.black,
                size: 58,
                fontSize: 10,
                onDown: () => game.player?.shoot(),
              ),
              const SizedBox(width: 14),
              _TouchButton(
                label: "JUMP",
                bgColor: RetroTheme.green.withValues(alpha: 0.85),
                textColor: Colors.black,
                size: 68,
                fontSize: 12,
                onDown: () => game.player?.pressJump(),
                onUp: () => game.player?.releaseJump(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TouchButton extends StatefulWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback onDown;
  final VoidCallback? onUp;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final double size;
  final double fontSize;

  const _TouchButton({
    this.icon,
    this.label,
    required this.onDown,
    this.onUp,
    this.bgColor = const Color(0x992E3440),
    this.borderColor = const Color(0xFFD8DEE9),
    this.textColor = Colors.white,
    this.size = 60.0,
    this.fontSize = 12.0,
  });

  @override
  State<_TouchButton> createState() => _TouchButtonState();
}

class _TouchButtonState extends State<_TouchButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _isPressed = true);
        widget.onDown();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onUp?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        widget.onUp?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 40),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _isPressed ? widget.bgColor.withValues(alpha: 1.0) : widget.bgColor,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: _isPressed ? Colors.white : widget.borderColor,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              offset: Offset(_isPressed ? 1 : 3, _isPressed ? 1 : 3),
              color: Colors.black.withValues(alpha: 0.8),
            ),
          ],
        ),
        child: Center(
          child: widget.icon != null
              ? Icon(widget.icon, color: widget.textColor, size: widget.size * 0.45)
              : Text(
                  widget.label ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w900,
                    color: widget.textColor,
                  ),
                ),
        ),
      ),
    );
  }
}
