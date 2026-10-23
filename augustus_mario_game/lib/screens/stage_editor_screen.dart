import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/custom_stage_data.dart';
import '../services/storage_manager.dart';
import '../theme/retro_theme.dart';
import '../game/iwbtg_game.dart';
import 'stage_sharing_dialog.dart';

enum StudioTool { select, move, scale, rotate }

class StageEditorScreen extends StatefulWidget {
  final CustomStageData? initialStage;

  const StageEditorScreen({super.key, this.initialStage});

  @override
  State<StageEditorScreen> createState() => _StageEditorScreenState();
}

class _StageEditorScreenState extends State<StageEditorScreen> {
  late CustomStageData _stage;
  StageElementData? _selectedElement;
  StudioTool _activeTool = StudioTool.select;
  int _snapGridSize = 16; // 0: off, 16: 16px, 32: 32px

  bool _isPlaytesting = false;
  IWBTGGame? _playtestGame;

  int _leftTab = 0; // 0: Explorer, 1: Toolbox

  // Color options for properties panel
  final List<int> _colorOptions = [
    0xFF434C5E, // Dark Slate
    0xFF5E81AC, // Blue
    0xFF81A1C1, // Light Blue
    0xFF88C0D0, // Cyan
    0xFFA3BE8C, // Green
    0xFFEBCB8B, // Yellow
    0xFFD08770, // Orange
    0xFFBF616A, // Red
    0xFFB48EAD, // Purple
    0xFFECEFF4, // White
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialStage != null) {
      // Clone so edits don't overwrite until saved
      _stage = CustomStageData.fromJson(widget.initialStage!.toJson());
    } else {
      _stage = CustomStageData.blankTemplate(title: 'New Brutal Stage');
    }
  }

  double _snap(double val) {
    if (_snapGridSize <= 0) return val;
    return (val / _snapGridSize).roundToDouble() * _snapGridSize;
  }

  void _saveStage() async {
    await StorageManager.instance.saveStage(_stage);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Stage "${_stage.title}" saved successfully!',
            style: const TextStyle(fontFamily: 'monospace')),
        backgroundColor: RetroTheme.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _startPlaytest() {
    setState(() {
      _isPlaytesting = true;
      _playtestGame = IWBTGGame(
        customStageData: _stage,
        onVictoryTriggered: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 STAGE CLEARED!', style: TextStyle(fontFamily: 'monospace')),
              backgroundColor: RetroTheme.yellow,
            ),
          );
        },
      );
    });
  }

  void _stopPlaytest() {
    setState(() {
      _isPlaytesting = false;
      _playtestGame = null;
    });
  }

  void _addElement(StageElementType type) {
    final newId = 'elem_${DateTime.now().millisecondsSinceEpoch}';
    final count = _stage.elements.where((e) => e.type == type).length + 1;

    double defaultW = 32.0;
    double defaultH = 32.0;
    if (type == StageElementType.platform) {
      defaultW = 64.0;
      defaultH = 24.0;
    } else if (type == StageElementType.movingPlatform) {
      defaultW = 64.0;
      defaultH = 16.0;
    } else if (type == StageElementType.goal) {
      defaultW = 48.0;
      defaultH = 64.0;
    }

    final newElement = StageElementData(
      id: newId,
      type: type,
      name: '${type.displayName} $count',
      x: 360.0,
      y: 260.0,
      width: defaultW,
      height: defaultH,
    );

    setState(() {
      _stage.elements.add(newElement);
      _selectedElement = newElement;
    });
  }

  void _deleteElement(StageElementData elem) {
    setState(() {
      _stage.elements.removeWhere((e) => e.id == elem.id);
      if (_selectedElement?.id == elem.id) {
        _selectedElement = null;
      }
    });
  }

  void _duplicateElement(StageElementData elem) {
    final cloned = elem.copyWith(
      id: 'elem_${DateTime.now().millisecondsSinceEpoch}',
      name: '${elem.name} (Copy)',
      x: elem.x + 16,
      y: elem.y + 16,
    );
    setState(() {
      _stage.elements.add(cloned);
      _selectedElement = cloned;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Studio Top Toolbar
            _buildToolbar(),
            // Main Editor Workspace
            Expanded(
              child: _isPlaytesting ? _buildPlaytestView() : _buildEditorLayout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: RetroTheme.surface,
        border: Border(bottom: BorderSide(color: RetroTheme.surfaceHighlight, width: 2)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
          // Exit button
          RetroButton(
            label: "EXIT",
            prefixIcon: Icons.arrow_back,
            width: 90,
            height: 32,
            baseColor: RetroTheme.background,
            textColor: RetroTheme.white,
            onPressed: () {
              if (_isPlaytesting) {
                _stopPlaytest();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 12),
          // Stage Title
          Text(
            _stage.title.toUpperCase(),
            style: RetroTheme.titleStyle(fontSize: 16, color: RetroTheme.yellow),
          ),
          const SizedBox(width: 24),
          if (!_isPlaytesting) ...[
            // Tool selector
            _buildToolButton(StudioTool.select, Icons.near_me, "Select"),
            _buildToolButton(StudioTool.move, Icons.open_with, "Move"),
            _buildToolButton(StudioTool.scale, Icons.aspect_ratio, "Scale"),
            _buildToolButton(StudioTool.rotate, Icons.rotate_right, "Rotate"),
            const SizedBox(width: 16),
            // Snap Grid
            _buildGridSnapToggle(),
            const SizedBox(width: 20),
            // Templates
            RetroButton(
              label: "TEMPLATE",
              prefixIcon: Icons.dashboard_customize,
              width: 110,
              height: 32,
              baseColor: RetroTheme.surfaceHighlight,
              textColor: RetroTheme.white,
              onPressed: _showTemplateDialog,
            ),
            const SizedBox(width: 8),
            // Share / Export-Import
            RetroButton(
              label: "SHARE",
              prefixIcon: Icons.share,
              width: 90,
              height: 32,
              baseColor: RetroTheme.accent,
              textColor: Colors.black,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => StageSharingDialog(
                    stage: _stage,
                    onStageImported: (imported) {
                      setState(() {
                        _stage = imported;
                        _selectedElement = null;
                      });
                    },
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            // Save
            RetroButton(
              label: "SAVE",
              prefixIcon: Icons.save,
              width: 90,
              height: 32,
              baseColor: RetroTheme.green,
              textColor: Colors.black,
              onPressed: _saveStage,
            ),
            const SizedBox(width: 12),
            // Playtest
            RetroButton(
              label: "PLAYTEST",
              prefixIcon: Icons.play_arrow,
              width: 120,
              height: 34,
              baseColor: const Color(0xFF4CAF50),
              textColor: Colors.white,
              onPressed: _startPlaytest,
            ),
          ] else ...[
            const SizedBox(width: 20),
            RetroButton(
              label: "STOP PLAYTEST",
              prefixIcon: Icons.stop,
              width: 160,
              height: 34,
              baseColor: RetroTheme.primary,
              textColor: Colors.white,
              onPressed: _stopPlaytest,
            ),
          ],
        ],
      ),
    ),
  );
}

  Widget _buildToolButton(StudioTool tool, IconData icon, String tooltip) {
    final isSelected = _activeTool == tool;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: () => setState(() => _activeTool = tool),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? RetroTheme.primary : RetroTheme.background,
            border: Border.all(color: isSelected ? Colors.white : Colors.grey[700]!, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[300]),
              const SizedBox(width: 4),
              Text(
                tooltip,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey[300],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridSnapToggle() {
    return Container(
      decoration: BoxDecoration(
        color: RetroTheme.background,
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [16, 32, 0].map((size) {
          final isSelected = _snapGridSize == size;
          final label = size == 0 ? "OFF" : "${size}px";
          return GestureDetector(
            onTap: () => setState(() => _snapGridSize = size),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              color: isSelected ? RetroTheme.yellow : Colors.transparent,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : Colors.grey[400],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEditorLayout() {
    return Row(
      children: [
        // Left Panel: Explorer & Toolbox
        SizedBox(
          width: 210,
          child: _buildLeftPanel(),
        ),
        // Center: Interactive 2D Canvas Viewport
        Expanded(
          child: _buildCanvasViewport(),
        ),
        // Right Panel: Properties Inspector
        SizedBox(
          width: 240,
          child: _buildPropertiesPanel(),
        ),
      ],
    );
  }

  Widget _buildPlaytestView() {
    if (_playtestGame == null) return const SizedBox.shrink();
    return GameWidget(game: _playtestGame!);
  }

  // --- Left Panel ---
  Widget _buildLeftPanel() {
    return Container(
      decoration: BoxDecoration(
        color: RetroTheme.surface,
        border: Border(right: BorderSide(color: RetroTheme.surfaceHighlight, width: 2)),
      ),
      child: Column(
        children: [
          // Left Tabs
          Row(
            children: [
              Expanded(
                child: _buildLeftTabHeader(0, "EXPLORER", Icons.account_tree),
              ),
              Expanded(
                child: _buildLeftTabHeader(1, "TOOLBOX", Icons.category),
              ),
            ],
          ),
          const Divider(height: 1, color: RetroTheme.surfaceHighlight),
          Expanded(
            child: _leftTab == 0 ? _buildExplorerView() : _buildToolboxView(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftTabHeader(int tabIndex, String title, IconData icon) {
    final isSelected = _leftTab == tabIndex;
    return GestureDetector(
      onTap: () => setState(() => _leftTab = tabIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        color: isSelected ? RetroTheme.surface : RetroTheme.background,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? RetroTheme.yellow : Colors.grey),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? RetroTheme.yellow : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplorerView() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        // Spawn Point
        ListTile(
          dense: true,
          leading: const Icon(Icons.person_pin_circle, size: 18, color: RetroTheme.green),
          title: const Text("Player Spawn", style: TextStyle(fontFamily: 'monospace', fontSize: 11)),
          subtitle: Text("(${_stage.spawnX.toInt()}, ${_stage.spawnY.toInt()})",
              style: const TextStyle(fontSize: 9, color: Colors.grey)),
          onTap: () {
            setState(() {
              _selectedElement = null; // deselect elements
            });
          },
        ),
        const Divider(height: 1, color: RetroTheme.surfaceHighlight),
        ..._stage.elements.map((elem) {
          final isSelected = _selectedElement?.id == elem.id;
          return Container(
            color: isSelected ? RetroTheme.primary.withValues(alpha: 0.3) : Colors.transparent,
            child: ListTile(
              dense: true,
              leading: Icon(elem.type.icon, size: 16, color: elem.type.categoryColor),
              title: Text(
                elem.name,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? RetroTheme.yellow : Colors.white,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 14, color: Colors.grey),
                onPressed: () => _deleteElement(elem),
              ),
              onTap: () {
                setState(() => _selectedElement = elem);
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildToolboxView() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _buildToolboxSection("PLATFORMS & BLOCKS", [
          _buildToolboxItem(StageElementType.platform),
          _buildToolboxItem(StageElementType.movingPlatform),
          _buildToolboxItem(StageElementType.rotatingPlatform),
          _buildToolboxItem(StageElementType.collapsingBlock),
        ]),
        const SizedBox(height: 12),
        _buildToolboxSection("HAZARDS & TRAPS", [
          _buildToolboxItem(StageElementType.spike),
          _buildToolboxItem(StageElementType.slidingSpike),
          _buildToolboxItem(StageElementType.apple),
          _buildToolboxItem(StageElementType.turret),
          _buildToolboxItem(StageElementType.sniper),
        ]),
        const SizedBox(height: 12),
        _buildToolboxSection("INTERACTIONS", [
          _buildToolboxItem(StageElementType.triggerZone),
          _buildToolboxItem(StageElementType.savePoint),
          _buildToolboxItem(StageElementType.goal),
        ]),
      ],
    );
  }

  Widget _buildToolboxSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 10,
            color: RetroTheme.accent,
          ),
        ),
        const SizedBox(height: 6),
        ...items,
      ],
    );
  }

  Widget _buildToolboxItem(StageElementType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: InkWell(
        onTap: () => _addElement(type),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: RetroTheme.background,
            border: Border.all(color: Colors.grey[800]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(type.icon, size: 16, color: type.categoryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  type.displayName,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white),
                ),
              ),
              const Icon(Icons.add, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // --- Center Viewport (Canvas) ---
  Widget _buildCanvasViewport() {
    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: 800 / 600,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final canvasW = constraints.maxWidth;
              final canvasH = constraints.maxHeight;
              final scaleFactor = canvasW / 800.0;

              return GestureDetector(
                onTapDown: (details) {
                  final localX = details.localPosition.dx / scaleFactor;
                  final localY = details.localPosition.dy / scaleFactor;

                  // Find tapped element (from top to bottom)
                  StageElementData? hit;
                  for (final elem in _stage.elements.reversed) {
                    final rect = Rect.fromLTWH(elem.x, elem.y, elem.width, elem.height);
                    if (rect.contains(Offset(localX, localY))) {
                      hit = elem;
                      break;
                    }
                  }

                  setState(() {
                    _selectedElement = hit;
                  });
                },
                onPanUpdate: (details) {
                  if (_selectedElement == null) return;
                  final deltaX = details.delta.dx / scaleFactor;
                  final deltaY = details.delta.dy / scaleFactor;

                  setState(() {
                    if (_activeTool == StudioTool.move || _activeTool == StudioTool.select) {
                      _selectedElement!.x = _snap(_selectedElement!.x + deltaX);
                      _selectedElement!.y = _snap(_selectedElement!.y + deltaY);
                    } else if (_activeTool == StudioTool.scale) {
                      _selectedElement!.width = max(16.0, _snap(_selectedElement!.width + deltaX));
                      _selectedElement!.height = max(16.0, _snap(_selectedElement!.height + deltaY));
                    }
                  });
                },
                child: CustomPaint(
                  size: Size(canvasW, canvasH),
                  painter: _StudioCanvasPainter(
                    stage: _stage,
                    selectedElement: _selectedElement,
                    activeTool: _activeTool,
                    snapGridSize: _snapGridSize,
                    scaleFactor: scaleFactor,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- Right Panel: Properties Inspector ---
  Widget _buildPropertiesPanel() {
    return Container(
      decoration: BoxDecoration(
        color: RetroTheme.surface,
        border: Border(left: BorderSide(color: RetroTheme.surfaceHighlight, width: 2)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: RetroTheme.background,
            child: const Text(
              "PROPERTIES INSPECTOR",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: RetroTheme.yellow,
              ),
            ),
          ),
          const Divider(height: 1, color: RetroTheme.surfaceHighlight),
          Expanded(
            child: _selectedElement == null
                ? _buildStagePropertiesView()
                : _buildElementPropertiesView(_selectedElement!),
          ),
        ],
      ),
    );
  }

  Widget _buildStagePropertiesView() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildPropertyHeader("STAGE SETTINGS"),
        _buildTextField("Title", _stage.title, (val) => setState(() => _stage.title = val)),
        _buildTextField("Author", _stage.author, (val) => setState(() => _stage.author = val)),
        const SizedBox(height: 12),
        _buildPropertyHeader("PLAYER SPAWN POINT"),
        Row(
          children: [
            Expanded(
              child: _buildNumberField("Spawn X", _stage.spawnX, (v) => setState(() => _stage.spawnX = v)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNumberField("Spawn Y", _stage.spawnY, (v) => setState(() => _stage.spawnY = v)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPropertyHeader("BACKGROUND COLOR"),
        _buildColorPicker(
          _stage.backgroundColor,
          (col) => setState(() => _stage.backgroundColor = col),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: RetroTheme.background,
            border: Border.all(color: RetroTheme.surfaceHighlight),
          ),
          child: Text(
            "Total Objects: ${_stage.elements.length}\nClick any object on Canvas or Explorer to inspect its properties.",
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildElementPropertiesView(StageElementData elem) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildPropertyHeader("SELECTED OBJECT"),
        _buildTextField("Name", elem.name, (val) => setState(() => elem.name = val)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(elem.type.icon, size: 16, color: elem.type.categoryColor),
            const SizedBox(width: 6),
            Text(elem.type.displayName,
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: elem.type.categoryColor)),
          ],
        ),
        const SizedBox(height: 12),
        _buildPropertyHeader("TRANSFORM"),
        Row(
          children: [
            Expanded(child: _buildNumberField("X", elem.x, (v) => setState(() => elem.x = _snap(v)))),
            const SizedBox(width: 8),
            Expanded(child: _buildNumberField("Y", elem.y, (v) => setState(() => elem.y = _snap(v)))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildNumberField("Width", elem.width, (v) => setState(() => elem.width = max(8, _snap(v))))),
            const SizedBox(width: 8),
            Expanded(child: _buildNumberField("Height", elem.height, (v) => setState(() => elem.height = max(8, _snap(v))))),
          ],
        ),
        const SizedBox(height: 8),
        _buildPropertyHeader("ROTATION"),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [0.0, 90.0, 180.0, 270.0].map((deg) {
            final isSelected = (elem.rotation.round() % 360) == deg.round();
            return ChoiceChip(
              label: Text("${deg.toInt()}°", style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
              selected: isSelected,
              selectedColor: RetroTheme.primary,
              backgroundColor: RetroTheme.background,
              onSelected: (_) => setState(() => elem.rotation = deg),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildPropertyHeader("COLOR"),
        _buildColorPicker(
          elem.color ?? 0xFF434C5E,
          (col) => setState(() => elem.color = col),
        ),
        const SizedBox(height: 16),
        // Type specific behaviors
        if (elem.type == StageElementType.movingPlatform) ...[
          _buildPropertyHeader("MOVING PLATFORM SETTINGS"),
          _buildSlider("Move Range", (elem.properties['moveRange'] as num?)?.toDouble() ?? 100.0, 20.0, 300.0,
              (v) => setState(() => elem.properties['moveRange'] = v)),
          _buildSlider("Speed (px/s)", (elem.properties['speed'] as num?)?.toDouble() ?? 80.0, 20.0, 250.0,
              (v) => setState(() => elem.properties['speed'] = v)),
          SwitchListTile(
            dense: true,
            title: const Text("Horizontal Move", style: TextStyle(fontFamily: 'monospace', fontSize: 11)),
            value: elem.properties['horizontal'] as bool? ?? true,
            onChanged: (v) => setState(() => elem.properties['horizontal'] = v),
          ),
        ] else if (elem.type == StageElementType.apple) ...[
          _buildPropertyHeader("APPLE BEHAVIOR"),
          DropdownButtonFormField<String>(
            initialValue: elem.properties['behavior'] as String? ?? 'staticItem',
            dropdownColor: RetroTheme.surface,
            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'staticItem', child: Text("Static Item", style: TextStyle(fontFamily: 'monospace', fontSize: 11))),
              DropdownMenuItem(value: 'flyUp', child: Text("Anti-Gravity (Fly Up)", style: TextStyle(fontFamily: 'monospace', fontSize: 11))),
              DropdownMenuItem(value: 'fallDown', child: Text("Fall Down", style: TextStyle(fontFamily: 'monospace', fontSize: 11))),
              DropdownMenuItem(value: 'flyLeft', child: Text("Fly Left", style: TextStyle(fontFamily: 'monospace', fontSize: 11))),
              DropdownMenuItem(value: 'flyRight', child: Text("Fly Right", style: TextStyle(fontFamily: 'monospace', fontSize: 11))),
            ],
            onChanged: (val) {
              if (val != null) setState(() => elem.properties['behavior'] = val);
            },
          ),
        ],
        const SizedBox(height: 20),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: RetroButton(
                label: "CLONE",
                prefixIcon: Icons.copy,
                height: 34,
                baseColor: RetroTheme.surfaceHighlight,
                textColor: RetroTheme.white,
                onPressed: () => _duplicateElement(elem),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RetroButton(
                label: "DELETE",
                prefixIcon: Icons.delete,
                height: 34,
                baseColor: RetroTheme.primary,
                textColor: Colors.white,
                onPressed: () => _deleteElement(elem),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 10,
          color: RetroTheme.accent,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String value, ValueChanged<String> onChanged) {
    return TextFormField(
      initialValue: value,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField(String label, double value, ValueChanged<double> onChanged) {
    return TextFormField(
      key: ValueKey('$label-$value'),
      initialValue: value.toInt().toString(),
      keyboardType: TextInputType.number,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: (val) {
        final d = double.tryParse(val);
        if (d != null) onChanged(d);
      },
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ${value.toInt()}", style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          activeColor: RetroTheme.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildColorPicker(int currentColor, ValueChanged<int> onSelected) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _colorOptions.map((col) {
        final isSelected = currentColor == col;
        return GestureDetector(
          onTap: () => onSelected(col),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Color(col),
              border: Border.all(color: isSelected ? Colors.white : Colors.black, width: isSelected ? 2.5 : 1),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showTemplateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RetroTheme.surface,
        title: Text("CHOOSE TEMPLATE", style: RetroTheme.titleStyle(fontSize: 18, color: RetroTheme.yellow)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.crop_square, color: Colors.blue),
              title: const Text("Blank Stage (Empty Room)", style: TextStyle(fontFamily: 'monospace')),
              onTap: () {
                setState(() {
                  _stage = CustomStageData.blankTemplate(title: "New Stage");
                  _selectedElement = null;
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: const Text("Parkour Challenge Template", style: TextStyle(fontFamily: 'monospace')),
              onTap: () {
                setState(() {
                  _stage = CustomStageData.parkourTemplate();
                  _selectedElement = null;
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for 2D Viewport Canvas
class _StudioCanvasPainter extends CustomPainter {
  final CustomStageData stage;
  final StageElementData? selectedElement;
  final StudioTool activeTool;
  final int snapGridSize;
  final double scaleFactor;

  _StudioCanvasPainter({
    required this.stage,
    required this.selectedElement,
    required this.activeTool,
    required this.snapGridSize,
    required this.scaleFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scaleFactor, scaleFactor);

    // 1. Draw Background
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 800, 600),
      Paint()..color = Color(stage.backgroundColor),
    );

    // 2. Draw Grid
    if (snapGridSize > 0) {
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 1.0;

      for (double x = 0; x <= 800; x += snapGridSize) {
        canvas.drawLine(Offset(x, 0), Offset(x, 600), gridPaint);
      }
      for (double y = 0; y <= 600; y += snapGridSize) {
        canvas.drawLine(Offset(0, y), Offset(800, y), gridPaint);
      }
    }

    // 3. Draw Stage Elements
    for (final elem in stage.elements) {
      final rect = Rect.fromLTWH(elem.x, elem.y, elem.width, elem.height);
      final isSelected = selectedElement?.id == elem.id;

      canvas.save();
      if (elem.rotation != 0) {
        final center = rect.center;
        canvas.translate(center.dx, center.dy);
        canvas.rotate(elem.rotation * pi / 180.0);
        canvas.translate(-center.dx, -center.dy);
      }

      // Render based on type
      switch (elem.type) {
        case StageElementType.platform:
        case StageElementType.movingPlatform:
        case StageElementType.rotatingPlatform:
        case StageElementType.collapsingBlock:
          final color = elem.color != null ? Color(elem.color!) : const Color(0xFF434C5E);
          canvas.drawRect(rect, Paint()..color = color);
          canvas.drawRect(rect, Paint()..color = Colors.white24..style = PaintingStyle.stroke);
          if (elem.type == StageElementType.movingPlatform) {
            // Draw movement arrow indicator
            final arrowPaint = Paint()..color = Colors.yellow..style = PaintingStyle.stroke..strokeWidth = 2;
            canvas.drawLine(rect.centerLeft + const Offset(4, 0), rect.centerRight - const Offset(4, 0), arrowPaint);
          }
          break;

        case StageElementType.spike:
        case StageElementType.slidingSpike:
          final spikeColor = elem.color != null ? Color(elem.color!) : const Color(0xFFBF616A);
          final path = Path()
            ..moveTo(rect.left, rect.bottom)
            ..lineTo(rect.center.dx, rect.top)
            ..lineTo(rect.right, rect.bottom)
            ..close();
          canvas.drawPath(path, Paint()..color = spikeColor);
          canvas.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1);
          break;

        case StageElementType.apple:
          final appleColor = elem.color != null ? Color(elem.color!) : const Color(0xFFD08770);
          canvas.drawCircle(rect.center, rect.width / 2, Paint()..color = appleColor);
          canvas.drawCircle(rect.center, rect.width / 2, Paint()..color = Colors.white..style = PaintingStyle.stroke);
          break;

        case StageElementType.turret:
          canvas.drawRect(rect, Paint()..color = const Color(0xFFB48EAD));
          canvas.drawCircle(rect.center, 8, Paint()..color = Colors.redAccent);
          break;

        case StageElementType.sniper:
          canvas.drawRect(rect, Paint()..color = const Color(0xFF2E3440));
          canvas.drawLine(rect.centerLeft, rect.centerRight + const Offset(12, 0), Paint()..color = Colors.red..strokeWidth = 2);
          break;

        case StageElementType.savePoint:
          canvas.drawRect(rect, Paint()..color = const Color(0xFFA3BE8C));
          canvas.drawRect(rect, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
          break;

        case StageElementType.goal:
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), Paint()..color = const Color(0xFFEBCB8B));
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
          break;

        case StageElementType.triggerZone:
          final zonePaint = Paint()
            ..color = Colors.cyan.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill;
          canvas.drawRect(rect, zonePaint);
          final borderPaint = Paint()
            ..color = Colors.cyan
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawRect(rect, borderPaint);
          break;
      }

      canvas.restore();

      // 4. Selection Gizmo & Bounding Box
      if (isSelected) {
        final selectBorder = Paint()
          ..color = Colors.cyanAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawRect(rect.inflate(2), selectBorder);

        // Gizmo Handles
        final handlePaint = Paint()..color = Colors.white;
        final handleStroke = Paint()..color = Colors.black..style = PaintingStyle.stroke;
        const hSize = 6.0;

        for (final corner in [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight]) {
          final hRect = Rect.fromCenter(center: corner, width: hSize, height: hSize);
          canvas.drawRect(hRect, handlePaint);
          canvas.drawRect(hRect, handleStroke);
        }
      }
    }

    // 5. Draw Player Spawn Point Indicator
    final spawnPos = Offset(stage.spawnX, stage.spawnY);
    final spawnPaint = Paint()..color = const Color(0xFF81A1C1);
    canvas.drawCircle(spawnPos + const Offset(12, 12), 12, spawnPaint);
    canvas.drawCircle(spawnPos + const Offset(12, 12), 12, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: "P1",
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, spawnPos + const Offset(6, 6));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StudioCanvasPainter oldDelegate) {
    return true;
  }
}
