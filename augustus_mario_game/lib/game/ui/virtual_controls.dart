import 'package:flutter/material.dart';
import '../iwbtg_game.dart';
import '../../theme/retro_theme.dart';

class VirtualControlsOverlay extends StatefulWidget {
  final IWBTGGame game;

  const VirtualControlsOverlay({super.key, required this.game});

  @override
  State<VirtualControlsOverlay> createState() => _VirtualControlsOverlayState();
}

class _VirtualControlsOverlayState extends State<VirtualControlsOverlay> {
  bool _leftPressed = false;
  bool _rightPressed = false;

  @override
  void initState() {
    super.initState();
    widget.game.onPlayerRespawned = _resetControls;
  }

  @override
  void dispose() {
    if (widget.game.onPlayerRespawned == _resetControls) {
      widget.game.onPlayerRespawned = null;
    }
    super.dispose();
  }

  void _resetControls() {
    if (!mounted) return;
    setState(() {
      _leftPressed = false;
      _rightPressed = false;
    });
    widget.game.player?.setMoveInput(0.0);
  }

  void _updateMovement() {
    double move = 0.0;
    if (_leftPressed) move -= 1.0;
    if (_rightPressed) move += 1.0;
    widget.game.player?.setMoveInput(move);
  }

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
                onDown: () {
                  _leftPressed = true;
                  _updateMovement();
                },
                onUp: () {
                  _leftPressed = false;
                  _updateMovement();
                },
              ),
              const SizedBox(width: 12),
              _TouchButton(
                icon: Icons.arrow_forward_ios_rounded,
                onDown: () {
                  _rightPressed = true;
                  _updateMovement();
                },
                onUp: () {
                  _rightPressed = false;
                  _updateMovement();
                },
              ),
            ],
          ),

          // Action Buttons: Shoot & (R stacked over Jump)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _TouchButton(
                label: "SHOOT",
                bgColor: RetroTheme.yellow.withValues(alpha: 0.85),
                textColor: Colors.black,
                size: 58,
                fontSize: 10,
                onDown: () {
                  if (widget.game.player?.isAlive == false) {
                    widget.game.respawnPlayer();
                  } else {
                    widget.game.player?.shoot();
                  }
                },
              ),
              const SizedBox(width: 14),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _TouchButton(
                    label: "R",
                    bgColor: RetroTheme.primary.withValues(alpha: 0.85),
                    borderColor: Colors.white,
                    size: 46,
                    fontSize: 12,
                    onDown: () => widget.game.respawnPlayer(),
                  ),
                  const SizedBox(height: 10),
                  _TouchButton(
                    label: "JUMP",
                    bgColor: RetroTheme.green.withValues(alpha: 0.85),
                    textColor: Colors.black,
                    size: 68,
                    fontSize: 12,
                    onDown: () {
                      if (widget.game.player?.isAlive == false) {
                        widget.game.respawnPlayer();
                      } else {
                        widget.game.player?.pressJump();
                      }
                    },
                    onUp: () => widget.game.player?.releaseJump(),
                  ),
                ],
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
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        setState(() => _isPressed = true);
        widget.onDown();
      },
      onPointerUp: (_) {
        setState(() => _isPressed = false);
        widget.onUp?.call();
      },
      onPointerCancel: (_) {
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
