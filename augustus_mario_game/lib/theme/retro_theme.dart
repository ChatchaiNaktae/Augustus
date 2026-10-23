import 'package:flutter/material.dart';

class RetroTheme {
  static const Color background = Color(0xFF0F111A);
  static const Color surface = Color(0xFF1E222D);
  static const Color surfaceHighlight = Color(0xFF2C313C);
  static const Color primary = Color(0xFFE06C75);    // Retro Red
  static const Color accent = Color(0xFF61AFEF);     // Retro Blue
  static const Color yellow = Color(0xFFE5C07B);     // Retro Gold/Yellow
  static const Color green = Color(0xFF98C379);      // Retro Emerald
  static const Color purple = Color(0xFFC678DD);     // Retro Purple
  static const Color white = Color(0xFFABB2BF);
  static const Color pureWhite = Color(0xFFFFFFFF);

  static TextStyle titleStyle({double fontSize = 28, Color color = pureWhite, bool hasShadow = true}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      fontFamily: 'monospace',
      letterSpacing: 2.0,
      color: color,
      shadows: hasShadow
          ? const [
              Shadow(offset: Offset(3, 3), color: Colors.black, blurRadius: 0),
              Shadow(offset: Offset(-1, -1), color: Color(0x33FFFFFF), blurRadius: 0),
            ]
          : null,
    );
  }

  static TextStyle pixelText({double fontSize = 16, Color color = pureWhite, bool bold = true, bool hasShadow = true}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      fontFamily: 'monospace',
      letterSpacing: 1.2,
      color: color,
      shadows: hasShadow
          ? const [
              Shadow(offset: Offset(2, 2), color: Colors.black, blurRadius: 0),
            ]
          : null,
    );
  }

  static BoxDecoration pixelBoxDecoration({
    Color fillColor = surface,
    Color borderColor = yellow,
    double borderWidth = 3.0,
  }) {
    return BoxDecoration(
      color: fillColor,
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: const [
        BoxShadow(offset: Offset(4, 4), color: Colors.black),
      ],
    );
  }
}

class RetroButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color baseColor;
  final Color textColor;
  final IconData? icon;
  final double width;
  final double height;
  final double fontSize;
  final bool hasShadow;
  final bool hasTextShadow;

  const RetroButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.baseColor = RetroTheme.primary,
    this.textColor = Colors.white,
    IconData? icon,
    IconData? prefixIcon,
    this.width = 240,
    this.height = 54,
    this.fontSize = 16,
    this.hasShadow = true,
    this.hasTextShadow = false,
  }) : icon = icon ?? prefixIcon;

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double offset = _isPressed ? 1.0 : (_isHovered ? 3.0 : 4.0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.baseColor.withValues(alpha: 0.9)
                : widget.baseColor,
            border: Border.all(
              color: _isHovered ? Colors.white : Colors.black,
              width: 3.0,
            ),
            boxShadow: widget.hasShadow
                ? [
                    BoxShadow(
                      offset: Offset(offset, offset),
                      color: Colors.black,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: widget.textColor, size: widget.fontSize + 2),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: RetroTheme.pixelText(
                        fontSize: widget.fontSize,
                        color: widget.textColor,
                        hasShadow: widget.hasTextShadow,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
