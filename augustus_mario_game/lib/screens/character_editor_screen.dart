import 'package:flutter/material.dart';
import '../models/player_customization.dart';
import '../services/storage_manager.dart';
import '../theme/retro_theme.dart';

class CharacterEditorScreen extends StatefulWidget {
  const CharacterEditorScreen({super.key});

  @override
  State<CharacterEditorScreen> createState() => _CharacterEditorScreenState();
}

class _CharacterEditorScreenState extends State<CharacterEditorScreen>
    with SingleTickerProviderStateMixin {
  late PlayerCustomization _customization;
  late AnimationController _animController;

  String _currentAnim = 'IDLE'; // IDLE, WALK, JUMP
  int _selectedTab = 0; // 0: Hair, 1: Headwear, 2: Skin, 3: Outfit, 4: Cape

  final List<int> _colorPalette = [
    0xFFBF616A, // Crimson Red
    0xFFD08770, // Orange
    0xFFEBCB8B, // Gold Yellow
    0xFFA3BE8C, // Forest Green
    0xFF88C0D0, // Cyan
    0xFF81A1C1, // Sky Blue
    0xFF5E81AC, // Deep Blue
    0xFFB48EAD, // Purple
    0xFF4C566A, // Charcoal Brown
    0xFF2E3440, // Night Black
    0xFFD8DEE9, // Silver Grey
    0xFFECEFF4, // Snow White
    0xFFFF69B4, // Hot Pink
    0xFF8D5524, // Deep Brown
  ];

  final List<int> _skinPalette = [
    0xFFF0C09E, // Classic Peach
    0xFFFFDFC4, // Pale
    0xFFE0AC69, // Warm Honey
    0xFFC68642, // Tan
    0xFF8D5524, // Deep Umber
    0xFFA3BE8C, // Alien Green
    0xFF88C0D0, // Zombie Blue
    0xFFD8DEE9, // Ghost White
  ];

  @override
  void initState() {
    super.initState();
    _customization = StorageManager.instance.getCustomization();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _saveAndApply() async {
    await StorageManager.instance.saveCustomization(_customization);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Character saved successfully!', style: TextStyle(fontFamily: 'monospace')),
        backgroundColor: RetroTheme.green,
        duration: Duration(seconds: 1),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              // Top Bar
              _buildTopBar(),
              const SizedBox(height: 12),
              // Main Content (Preview Left, Customizer Right)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left: Live Preview Box & Quick Actions
                    Expanded(
                      flex: 4,
                      child: _buildPreviewPanel(),
                    ),
                    const SizedBox(width: 16),
                    // Right: Category Tabs & Option Selectors
                    Expanded(
                      flex: 6,
                      child: _buildCustomizerPanel(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Bottom Action Bar
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        RetroButton(
          label: "BACK",
          prefixIcon: Icons.arrow_back,
          width: 110,
          height: 38,
          baseColor: RetroTheme.surface,
          textColor: RetroTheme.white,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 16),
        Text(
          "CHARACTER CUSTOMIZER",
          style: RetroTheme.titleStyle(fontSize: 20, color: RetroTheme.yellow),
        ),
        const Spacer(),
        RetroButton(
          label: "RANDOM",
          prefixIcon: Icons.shuffle,
          width: 120,
          height: 38,
          baseColor: RetroTheme.accent,
          textColor: Colors.black,
          onPressed: () {
            setState(() {
              _customization = PlayerCustomization.randomize();
            });
          },
        ),
        const SizedBox(width: 8),
        RetroButton(
          label: "RESET",
          prefixIcon: Icons.refresh,
          width: 110,
          height: 38,
          baseColor: RetroTheme.primary,
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _customization = PlayerCustomization.defaultTheKid();
            });
          },
        ),
      ],
    );
  }

  Widget _buildPreviewPanel() {
    return Container(
      decoration: BoxDecoration(
        color: RetroTheme.surface,
        border: Border.all(color: RetroTheme.accent, width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: RetroTheme.primary.withValues(alpha: 0.2),
            child: const Text(
              "LIVE PREVIEW",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: RetroTheme.accent,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(180, 180),
                    painter: _CharacterPreviewPainter(
                      customization: _customization,
                      animProgress: _animController.value,
                      mode: _currentAnim,
                    ),
                  );
                },
              ),
            ),
          ),
          // Animation mode selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimModeButton('IDLE', Icons.accessibility_new),
                const SizedBox(width: 8),
                _buildAnimModeButton('WALK', Icons.directions_walk),
                const SizedBox(width: 8),
                _buildAnimModeButton('JUMP', Icons.upgrade),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimModeButton(String mode, IconData icon) {
    final isSelected = _currentAnim == mode;
    return GestureDetector(
      onTap: () => setState(() => _currentAnim = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? RetroTheme.yellow : RetroTheme.background,
          border: Border.all(
            color: isSelected ? RetroTheme.white : RetroTheme.accent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.black : RetroTheme.white),
            const SizedBox(width: 4),
            Text(
              mode,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : RetroTheme.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomizerPanel() {
    return Container(
      decoration: BoxDecoration(
        color: RetroTheme.surface,
        border: Border.all(color: RetroTheme.surfaceHighlight, width: 2),
      ),
      child: Column(
        children: [
          // Category Tabs
          _buildTabs(),
          const Divider(height: 1, color: RetroTheme.surfaceHighlight),
          // Category Options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: _buildActiveTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      {'title': 'HAIR', 'icon': Icons.face},
      {'title': 'HEADWEAR', 'icon': Icons.military_tech},
      {'title': 'SKIN', 'icon': Icons.palette},
      {'title': 'OUTFIT', 'icon': Icons.checkroom},
      {'title': 'CAPE', 'icon': Icons.air},
    ];

    return Container(
      color: RetroTheme.background,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? RetroTheme.surface : RetroTheme.background,
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? RetroTheme.yellow : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      tabs[i]['icon'] as IconData,
                      size: 16,
                      color: isSelected ? RetroTheme.yellow : Colors.grey,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tabs[i]['title'] as String,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? RetroTheme.yellow : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildHairTab();
      case 1:
        return _buildHeadwearTab();
      case 2:
        return _buildSkinTab();
      case 3:
        return _buildOutfitTab();
      case 4:
        return _buildCapeTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHairTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("HAIR STYLE"),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: HairStyle.values.map((style) {
            final isSelected = _customization.hairStyle == style;
            return ChoiceChip(
              label: Text(style.displayName, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              selected: isSelected,
              selectedColor: RetroTheme.primary,
              backgroundColor: RetroTheme.background,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey[300]),
              onSelected: (_) {
                setState(() {
                  _customization = _customization.copyWith(hairStyle: style);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildSectionHeader("HAIR COLOR"),
        _buildColorGrid(
          currentColor: _customization.hairColor,
          palette: _colorPalette,
          onColorSelected: (col) {
            setState(() {
              _customization = _customization.copyWith(hairColor: col);
            });
          },
        ),
      ],
    );
  }

  Widget _buildHeadwearTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("HEADWEAR TYPE"),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: HatType.values.map((type) {
            final isSelected = _customization.hatType == type;
            return ChoiceChip(
              label: Text(type.displayName, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              selected: isSelected,
              selectedColor: RetroTheme.primary,
              backgroundColor: RetroTheme.background,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey[300]),
              onSelected: (_) {
                setState(() {
                  _customization = _customization.copyWith(hatType: type);
                });
              },
            );
          }).toList(),
        ),
        if (_customization.hatType != HatType.none) ...[
          const SizedBox(height: 16),
          _buildSectionHeader("HEADWEAR COLOR"),
          _buildColorGrid(
            currentColor: _customization.hatColor,
            palette: _colorPalette,
            onColorSelected: (col) {
              setState(() {
                _customization = _customization.copyWith(hatColor: col);
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSkinTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("SKIN TONE PALETTE"),
        _buildColorGrid(
          currentColor: _customization.skinColor,
          palette: _skinPalette,
          onColorSelected: (col) {
            setState(() {
              _customization = _customization.copyWith(skinColor: col);
            });
          },
        ),
      ],
    );
  }

  Widget _buildOutfitTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("SHIRT COLOR"),
        _buildColorGrid(
          currentColor: _customization.shirtColor,
          palette: _colorPalette,
          onColorSelected: (col) {
            setState(() {
              _customization = _customization.copyWith(shirtColor: col);
            });
          },
        ),
        const SizedBox(height: 16),
        _buildSectionHeader("OVERALLS / PANTS COLOR"),
        _buildColorGrid(
          currentColor: _customization.pantsColor,
          palette: _colorPalette,
          onColorSelected: (col) {
            setState(() {
              _customization = _customization.copyWith(pantsColor: col);
            });
          },
        ),
        const SizedBox(height: 16),
        _buildSectionHeader("SHOES COLOR"),
        _buildColorGrid(
          currentColor: _customization.shoesColor,
          palette: _colorPalette,
          onColorSelected: (col) {
            setState(() {
              _customization = _customization.copyWith(shoesColor: col);
            });
          },
        ),
      ],
    );
  }

  Widget _buildCapeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("HERO CAPE / BOW"),
        SwitchListTile(
          title: const Text(
            "ENABLE CAPE",
            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13),
          ),
          value: _customization.capeEnabled,
          activeThumbColor: RetroTheme.green,
          onChanged: (val) {
            setState(() {
              _customization = _customization.copyWith(capeEnabled: val);
            });
          },
        ),
        if (_customization.capeEnabled) ...[
          const SizedBox(height: 12),
          _buildSectionHeader("CAPE COLOR"),
          _buildColorGrid(
            currentColor: _customization.capeColor,
            palette: _colorPalette,
            onColorSelected: (col) {
              setState(() {
                _customization = _customization.copyWith(capeColor: col);
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: RetroTheme.accent,
        ),
      ),
    );
  }

  Widget _buildColorGrid({
    required int currentColor,
    required List<int> palette,
    required ValueChanged<int> onColorSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: palette.map((colorInt) {
        final isSelected = currentColor == colorInt;
        return GestureDetector(
          onTap: () => onColorSelected(colorInt),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(colorInt),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.black45,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [const BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        RetroButton(
          label: "SAVE & APPLY",
          prefixIcon: Icons.check,
          width: 170,
          height: 42,
          baseColor: RetroTheme.green,
          textColor: Colors.black,
          onPressed: _saveAndApply,
        ),
      ],
    );
  }
}

class _CharacterPreviewPainter extends CustomPainter {
  final PlayerCustomization customization;
  final double animProgress;
  final String mode;

  _CharacterPreviewPainter({
    required this.customization,
    required this.animProgress,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Scale up from 24x24 pixel sprite to center preview
    const double baseSize = 24.0;
    final scale = (size.width / baseSize) * 0.7;
    canvas.translate(size.width * 0.18, size.height * 0.12);
    canvas.scale(scale, scale);

    // Apply animation offset
    double yOffset = 0.0;
    if (mode == 'IDLE') {
      yOffset = (animProgress * 1.5).roundToDouble(); // Subtle pixel breathing bounce
    } else if (mode == 'WALK') {
      yOffset = (animProgress * 2.0).roundToDouble();
    } else if (mode == 'JUMP') {
      yOffset = -3.0;
    }
    canvas.translate(0, yOffset);

    // 1. Cape
    if (customization.capeEnabled) {
      final capePaint = Paint()..color = customization.capeColorValue;
      final capeFlap = (mode == 'WALK' || mode == 'JUMP') ? (animProgress * 3.0) : 0.0;
      final capePath = Path()
        ..moveTo(2, 10)
        ..lineTo(-5 - capeFlap, 14)
        ..lineTo(-3 - capeFlap, 22)
        ..lineTo(4, 18)
        ..close();
      canvas.drawPath(capePath, capePaint);
    }

    // 2. Overalls / Body
    final bodyPaint = Paint()..color = customization.pantsColorValue;
    canvas.drawRect(const Rect.fromLTWH(4, 12, 14, 14), bodyPaint);

    // 3. Shirt
    final shirtPaint = Paint()..color = customization.shirtColorValue;
    canvas.drawRect(const Rect.fromLTWH(5, 12, 12, 6), shirtPaint);

    // 4. Shoes
    final shoesPaint = Paint()..color = customization.shoesColorValue;
    if (mode == 'WALK') {
      final legOffset = (animProgress * 2.0).roundToDouble();
      canvas.drawRect(Rect.fromLTWH(4, 24 - legOffset, 6, 2), shoesPaint);
      canvas.drawRect(Rect.fromLTWH(12, 24 + legOffset, 6, 2), shoesPaint);
    } else {
      canvas.drawRect(const Rect.fromLTWH(4, 24, 6, 2), shoesPaint);
      canvas.drawRect(const Rect.fromLTWH(12, 24, 6, 2), shoesPaint);
    }

    // 5. Skin Face
    final facePaint = Paint()..color = customization.skinColorValue;
    canvas.drawRect(const Rect.fromLTWH(5, 4, 12, 9), facePaint);

    // 6. Hair
    final hairPaint = Paint()..color = customization.hairColorValue;
    switch (customization.hairStyle) {
      case HairStyle.classic:
        canvas.drawRect(const Rect.fromLTWH(3, 3, 5, 5), hairPaint);
        break;
      case HairStyle.spiky:
        final spikePath = Path()
          ..moveTo(3, 4)
          ..lineTo(1, 1)
          ..lineTo(5, 2)
          ..lineTo(7, -1)
          ..lineTo(9, 2)
          ..close();
        canvas.drawPath(spikePath, hairPaint);
        canvas.drawRect(const Rect.fromLTWH(3, 3, 4, 6), hairPaint);
        break;
      case HairStyle.ponytail:
        canvas.drawRect(const Rect.fromLTWH(3, 3, 5, 5), hairPaint);
        canvas.drawRect(const Rect.fromLTWH(-1, 5, 4, 7), hairPaint);
        break;
      case HairStyle.bob:
        canvas.drawRect(const Rect.fromLTWH(3, 3, 5, 8), hairPaint);
        canvas.drawRect(const Rect.fromLTWH(14, 3, 4, 8), hairPaint);
        break;
      case HairStyle.bald:
        break;
    }

    // 7. Eye
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawRect(const Rect.fromLTWH(12, 6, 2, 4), eyePaint);

    // 8. Hat
    final hatPaint = Paint()..color = customization.hatColorValue;
    switch (customization.hatType) {
      case HatType.cap:
        canvas.drawRect(const Rect.fromLTWH(3, 1, 15, 4), hatPaint);
        canvas.drawRect(const Rect.fromLTWH(11, 4, 6, 2), hatPaint); // visor
        break;
      case HatType.bandana:
        canvas.drawRect(const Rect.fromLTWH(4, 2, 14, 3), hatPaint);
        canvas.drawRect(const Rect.fromLTWH(1, 3, 3, 2), hatPaint); // knot
        break;
      case HatType.crown:
        final crownPaint = Paint()..color = const Color(0xFFEBCB8B);
        final crownPath = Path()
          ..moveTo(3, 4)
          ..lineTo(3, 0)
          ..lineTo(6, 2)
          ..lineTo(10, -1)
          ..lineTo(14, 2)
          ..lineTo(17, 0)
          ..lineTo(17, 4)
          ..close();
        canvas.drawPath(crownPath, crownPaint);
        break;
      case HatType.none:
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CharacterPreviewPainter oldDelegate) {
    return oldDelegate.customization != customization ||
        oldDelegate.animProgress != animProgress ||
        oldDelegate.mode != mode;
  }
}
