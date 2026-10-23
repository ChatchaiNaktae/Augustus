import 'package:flutter/material.dart';
import '../models/custom_stage_data.dart';
import '../services/storage_manager.dart';
import '../theme/retro_theme.dart';
import 'game_play_screen.dart';
import 'stage_editor_screen.dart';
import 'stage_sharing_dialog.dart';

class SelectCustomStageScreen extends StatefulWidget {
  const SelectCustomStageScreen({super.key});

  @override
  State<SelectCustomStageScreen> createState() => _SelectCustomStageScreenState();
}

class _SelectCustomStageScreenState extends State<SelectCustomStageScreen> {
  late List<CustomStageData> _stages;

  @override
  void initState() {
    super.initState();
    _refreshStages();
  }

  void _refreshStages() {
    setState(() {
      _stages = StorageManager.instance.getAllStages();
    });
  }

  void _deleteStage(CustomStageData stage) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RetroTheme.surface,
        title: Text("DELETE STAGE?", style: RetroTheme.titleStyle(fontSize: 18, color: RetroTheme.primary)),
        content: Text("Are you sure you want to delete '${stage.title}'?",
            style: const TextStyle(fontFamily: 'monospace', color: Colors.white)),
        actions: [
          TextButton(
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          RetroButton(
            label: "DELETE",
            width: 100,
            height: 34,
            baseColor: RetroTheme.primary,
            textColor: Colors.white,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageManager.instance.deleteStage(stage.id);
      _refreshStages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Top Bar
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
                    "CUSTOM STAGES",
                    style: RetroTheme.titleStyle(fontSize: 22, color: RetroTheme.yellow),
                  ),
                  const Spacer(),
                  RetroButton(
                    label: "IMPORT",
                    prefixIcon: Icons.download,
                    width: 110,
                    height: 38,
                    baseColor: RetroTheme.accent,
                    textColor: Colors.black,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => StageSharingDialog(
                          stage: CustomStageData.blankTemplate(),
                          onStageImported: (imported) async {
                            await StorageManager.instance.saveStage(imported);
                            _refreshStages();
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  RetroButton(
                    label: "CREATE NEW",
                    prefixIcon: Icons.add,
                    width: 140,
                    height: 38,
                    baseColor: RetroTheme.green,
                    textColor: Colors.black,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StageEditorScreen()),
                      );
                      _refreshStages();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stages List
              Expanded(
                child: _stages.isEmpty
                    ? Center(
                        child: Text(
                          "No custom stages found!\nClick 'CREATE NEW' or 'IMPORT' to get started.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'monospace', fontSize: 14, color: Colors.grey[500]),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.2,
                        ),
                        itemCount: _stages.length,
                        itemBuilder: (context, index) {
                          final stage = _stages[index];
                          return _buildStageCard(stage);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageCard(CustomStageData stage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RetroTheme.surface,
        border: Border.all(color: RetroTheme.surfaceHighlight, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                color: RetroTheme.background,
                child: const Icon(Icons.videogame_asset, size: 24, color: RetroTheme.yellow),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RetroTheme.pixelText(fontSize: 14, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "By ${stage.author} • ${stage.elements.length} Objects",
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                onPressed: () => _deleteStage(stage),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              RetroButton(
                label: "EDIT",
                prefixIcon: Icons.edit,
                width: 90,
                height: 32,
                baseColor: RetroTheme.surfaceHighlight,
                textColor: RetroTheme.white,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StageEditorScreen(initialStage: stage)),
                  );
                  _refreshStages();
                },
              ),
              const SizedBox(width: 8),
              RetroButton(
                label: "PLAY",
                prefixIcon: Icons.play_arrow,
                width: 100,
                height: 32,
                baseColor: RetroTheme.green,
                textColor: Colors.black,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GamePlayScreen(customStageData: stage),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
