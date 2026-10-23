import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/custom_stage_data.dart';
import '../theme/retro_theme.dart';

class StageSharingDialog extends StatefulWidget {
  final CustomStageData stage;
  final ValueChanged<CustomStageData>? onStageImported;

  const StageSharingDialog({
    super.key,
    required this.stage,
    this.onStageImported,
  });

  @override
  State<StageSharingDialog> createState() => _StageSharingDialogState();
}

class _StageSharingDialogState extends State<StageSharingDialog> {
  int _activeTab = 0; // 0: Export, 1: Import
  late TextEditingController _exportController;
  late TextEditingController _importController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final code = widget.stage.exportCode();
    _exportController = TextEditingController(text: code);
    _importController = TextEditingController();
  }

  @override
  void dispose() {
    _exportController.dispose();
    _importController.dispose();
    super.dispose();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _exportController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stage code copied to clipboard!', style: TextStyle(fontFamily: 'monospace')),
        backgroundColor: RetroTheme.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _importStage() {
    setState(() => _errorMessage = null);
    final text = _importController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please paste a valid stage code.');
      return;
    }

    final imported = CustomStageData.importCode(text);
    if (imported == null) {
      setState(() => _errorMessage = 'Invalid stage code format! Please check and retry.');
      return;
    }

    if (widget.onStageImported != null) {
      widget.onStageImported!(imported);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Imported "${imported.title}" successfully!',
            style: const TextStyle(fontFamily: 'monospace')),
        backgroundColor: RetroTheme.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: RetroTheme.surface,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: RetroTheme.yellow, width: 2),
      ),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Tabs
            Row(
              children: [
                Text(
                  "SHARE / IMPORT STAGE",
                  style: RetroTheme.titleStyle(fontSize: 18, color: RetroTheme.yellow),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildTabButton(0, "EXPORT CODE", Icons.upload)),
                const SizedBox(width: 8),
                Expanded(child: _buildTabButton(1, "IMPORT CODE", Icons.download)),
              ],
            ),
            const SizedBox(height: 16),
            // Content
            _activeTab == 0 ? _buildExportView() : _buildImportView(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int tabIdx, String label, IconData icon) {
    final isSelected = _activeTab == tabIdx;
    return InkWell(
      onTap: () => setState(() => _activeTab = tabIdx),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? RetroTheme.primary : RetroTheme.background,
          border: Border.all(color: isSelected ? Colors.white : Colors.grey[700]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[400]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Copy this shareable stage code and send it to your friends:",
          style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey[300]),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _exportController,
          readOnly: true,
          maxLines: 4,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: RetroTheme.accent),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: RetroTheme.background,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            RetroButton(
              label: "COPY CODE",
              prefixIcon: Icons.copy,
              width: 140,
              height: 38,
              baseColor: RetroTheme.green,
              textColor: Colors.black,
              onPressed: _copyToClipboard,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImportView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Paste an AGY stage code string below to load the custom stage:",
          style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey[300]),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _importController,
          maxLines: 4,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Paste AGY:... or raw JSON code here",
            border: OutlineInputBorder(),
            filled: true,
            fillColor: RetroTheme.background,
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: RetroTheme.primary),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            RetroButton(
              label: "LOAD STAGE",
              prefixIcon: Icons.check,
              width: 140,
              height: 38,
              baseColor: RetroTheme.yellow,
              textColor: Colors.black,
              onPressed: _importStage,
            ),
          ],
        ),
      ],
    );
  }
}
