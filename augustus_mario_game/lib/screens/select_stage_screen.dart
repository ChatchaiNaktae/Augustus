import 'package:flutter/material.dart';
import '../theme/retro_theme.dart';
import 'game_play_screen.dart';

class SelectStageScreen extends StatelessWidget {
  const SelectStageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
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
                    "SELECT STAGE",
                    style: RetroTheme.titleStyle(fontSize: 24, color: RetroTheme.yellow),
                  ),
                  const Spacer(),
                  const SizedBox(width: 120), // Balance center
                ],
              ),
            ),

            // Stage Cards List
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    children: [
                      _stageCard(
                        context: context,
                        stageNumber: 1,
                        title: "STAGE 1: THE DECEPTIVE ORCHARD",
                        subtitle: "สวนผลไม้ลวงตา",
                        description:
                            "ระวังผลแอปเปิ้ลที่ดูไร้พิษภัย! บทเรียนแรกของ Masocore: อย่าไว้ใจแรงโน้มถ่วง เพราะแอปเปิ้ลอาจพุ่งย้อนศรขึ้นฟ้า!",
                        traps: "🍎 แอปเปิ้ลหล่น & พุ่งขึ้นฟ้า | ⚡ กับดักสองจังหวะ",
                        themeColor: RetroTheme.green,
                      ),
                      const SizedBox(height: 18),
                      _stageCard(
                        context: context,
                        stageNumber: 2,
                        title: "STAGE 2: THE SPIKE LABYRINTH",
                        subtitle: "เขาวงกตหนามบิน",
                        description:
                            "ทดสอบความแม่นยำในการกระโดดสองจังหวะลอดช่องแคบ ระวังหนามที่พุ่งออกมาจากผนัง และพื้นลวงตาที่เหยียบแล้วร่วงลงเหว!",
                        traps: "🗡️ หนามกิโยติน & หนามผนังพุ่งชน | ⚠️ พื้นลวงตายกตัว/ยุบตัว",
                        themeColor: RetroTheme.yellow,
                      ),
                      const SizedBox(height: 18),
                      _stageCard(
                        context: context,
                        stageNumber: 3,
                        title: "STAGE 3: THE LEAP OF FAITH",
                        subtitle: "กระโดดวัดใจ & เส้นชัยมรณะ",
                        description:
                            "ด่านท้าทายระดับขีดสุด! กระโดดข้ามเหวลึกไร้ก้น หลบการโจมตีประสานงาน และระวังกับดักหน้าแท่นถ้วยรางวัลเพื่อพิสูจน์ความเป็น THE GUY!",
                        traps: "🍎 แอปเปิ้ลยิงประสาน | 🗡️ กับดักหน้าเส้นชัย | 🏆 ถ้วยรางวัล",
                        themeColor: RetroTheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stageCard({
    required BuildContext context,
    required int stageNumber,
    required String title,
    required String subtitle,
    required String description,
    required String traps,
    required Color themeColor,
  }) {
    return Container(
      decoration: RetroTheme.pixelBoxDecoration(
        fillColor: RetroTheme.surface,
        borderColor: themeColor,
        borderWidth: 2.5,
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Stage Number Badge
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.15),
              border: Border.all(color: themeColor, width: 2),
            ),
            child: Center(
              child: Text(
                "$stageNumber",
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: themeColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Center Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: RetroTheme.pixelText(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: themeColor),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: RetroTheme.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  traps,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Play Button
          RetroButton(
            label: "PLAY",
            icon: Icons.play_arrow_rounded,
            width: 110,
            height: 48,
            fontSize: 14,
            baseColor: themeColor,
            textColor: Colors.black,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GamePlayScreen(initialStage: stageNumber),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
