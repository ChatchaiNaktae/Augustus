import 'package:flutter/material.dart';
import '../theme/retro_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  RetroButton(
                    label: "BACK",
                    icon: Icons.arrow_back_rounded,
                    width: 120,
                    height: 42,
                    fontSize: 14,
                    baseColor: const Color(0xFF4C566A),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    "ABOUT / ผู้จัดทำ",
                    style: RetroTheme.titleStyle(fontSize: 22, color: RetroTheme.yellow),
                  ),
                  const Spacer(),
                  const SizedBox(width: 120),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Project Info Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: RetroTheme.pixelBoxDecoration(
                            fillColor: RetroTheme.surface,
                            borderColor: RetroTheme.accent,
                            borderWidth: 2.5,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "🎮 ข้อมูลโปรเจกต์ (PROJECT INFO)",
                                style: RetroTheme.pixelText(fontSize: 16, color: RetroTheme.yellow),
                              ),
                              const SizedBox(height: 12),
                              _infoRow("ชื่อเกม:", "Augustus Brutal (Flutter Edition)"),
                              _infoRow("ประเภทเกม:", "2D Masocore Action Platformer"),
                              _infoRow("เครื่องมือพัฒนา:", "Flutter 3.x, Flame Engine, Dart"),
                              _infoRow(
                                "แรงบันดาลใจ:",
                                "I Wanna Be The Guy: Remastered (Flook611 Gameplay)",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Authors Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: RetroTheme.pixelBoxDecoration(
                            fillColor: RetroTheme.surface,
                            borderColor: RetroTheme.green,
                            borderWidth: 2.5,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "👨‍💻 ข้อมูลผู้จัดทำ (DEVELOPER TEAM)",
                                style: RetroTheme.pixelText(fontSize: 16, color: RetroTheme.green),
                              ),
                              const SizedBox(height: 12),
                              _infoRow("วิชา:", "การพัฒนาโปรแกรมประยุกต์บนโทรศัพท์สมาร์ตโฟนด้วย Flutter"),
                              _infoRow("สาขา:", "วิทยาการคอมพิวเตอร์"),
                              _infoRow("สถาบัน:", "มหาวิทยาลัยเทคโนโลยีราชมงคลตะวันออก"),
                              _infoRow("อาจารย์ผู้สอน:", "อ.ยศภัทร เรืองไพศาล"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // System Features Summary
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: RetroTheme.pixelBoxDecoration(
                            fillColor: RetroTheme.surface,
                            borderColor: RetroTheme.primary,
                            borderWidth: 2.5,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "⭐ ฟีเจอร์หลักในระบบ (CORE FEATURES)",
                                style: RetroTheme.pixelText(fontSize: 16, color: RetroTheme.primary),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "• 3 Fixed Stages: สวนผลไม้ลวงตา, เขาวงกตหนามบิน, กระโดดวัดใจ\n"
                                "• The Kid Physics: Double Jump, Variable Jump, ปืนพก, กล่อง SAVE\n"
                                "• Zero-delay Instant Respawn เมื่อกดปุ่ม R\n"
                                "• Cross-Platform: รองรับทั้ง Keyboard (PC/Web) และ On-screen Touch Pad",
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: RetroTheme.white,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: RetroTheme.accent,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: RetroTheme.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
