# I Wanna Be That Guy (Flutter & Flame Edition) 🎮

เกมแอ็กชันแพลตฟอร์มแนว **Masocore / Trap Platformer** ที่ถอดแบบและเลียนแบบเอกลักษณ์ของเกมในตำนานอย่าง *I Wanna Be The Guy: Remastered* (อ้างอิงจากการวิเคราะห์คลิป [Flook611 Gameplay 100%](https://www.youtube.com/watch?v=LatC4e_Rk4A)) พัฒนาด้วย **Flutter** และ **Flame Engine**

---

## 🌟 ฟีเจอร์เด่นของเกม (Core Features)

1. **ลำดับหน้าจอตามข้อกำหนด (5+ Screens):**
   - **Main Menu Screen:** หน้าแรกสุดคลาสสิก พร้อมปุ่ม `Start Game`, `Select Stage`, `How to Play`, และ `About / ผู้จัดทำ`
   - **Select Stage Screen:** หน้าจอเลือกด่าน Stage 1, 2, และ 3 พร้อมการ์ดแสดงรายละเอียดความยากและกับดัก
   - **Game Play Screen:** รันตัวเกม 800x600 สไตล์เรโทร พร้อม HUD ตัวนับการตาย (Deaths Counter) และปุ่มเมนู Pause
   - **How To Play:** หน้าจออธิบายการควบคุมและกลยุทธ์การเล่น
   - **About Screen:** หน้าจอข้อมูลผู้จัดทำและข้อมูลวิชา
2. **ระบบฟิสิกส์ถอดแบบ The Kid (Pixel-Precision Physics):**
   - **Instant Movement:** ตัวละครไม่มีแรงเฉื่อย กดหยุดคือหยุดทันที ไม่ลื่นไหล
   - **Variable Jump & Double Jump:** กระโดดสองจังหวะกลางอากาศ และตัดความสูงเมื่อปล่อยปุ่มกระโดดเร็ว
   - **Pistol Shooting:** ยิงกระสุนทำลายสิ่งกีดขวางและยิงป้าย SAVE เพื่อบันทึกจุดเกิด
   - **Instant Respawn (ปุ่ม R):** ตายแล้วเกิดใหม่ที่จุดเซฟทันทีใน 0 วินาที ไม่มีหน้าจอโหลดค้าง
   - **Blood Particle Explosion:** ระเบิดเลือดกระจุยเต็มจอเมื่อสัมผัสกับดัก
3. **ด่านแบบ Handcrafted & Fixed Traps (3 ด่าน):**
   - **Stage 1 (The Deceptive Orchard):** กับดักแอปเปิ้ลหล่นปกติ vs แอปเปิ้ลพุ่งย้อนศรขึ้นฟ้า
   - **Stage 2 (The Spike Labyrinth):** หนามกิโยตินหล่นจากเพดาน หนามพุ่งจากกำแพง และพื้นลวงตายกตัว/ยุบตัว
   - **Stage 3 (The Leap of Faith):** กระโดดข้ามเหวลึก กับดักแอปเปิ้ลยิงประสาน และแท่นถ้วยรางวัลแห่งชัยชนะ "YOU ARE THE GUY!"
4. **รองรับ Cross-Platform:**
   - **Desktop / Web:** ควบคุมด้วยคีย์บอร์ดแม่นยำสูงสุด
   - **Mobile (Touch):** มี Virtual D-Pad, ปุ่ม Jump, Shoot, และปุ่ม Retry (R) พร้อมปุ่มเปิด/ปิดจอยบนหน้าจอ

---

## 🕹️ ปุ่มควบคุม (Controls)

| การกระทำ | คีย์บอร์ด (Desktop/Web) | ทัชสกรีน (Mobile) |
| :--- | :--- | :--- |
| **เดินซ้าย / ขวา** | `←` / `→` หรือ `A` / `D` | Virtual D-Pad (ซ้าย-ขวา) |
| **กระโดด / กระโดด 2 จังหวะ** | `Shift` หรือ `Space` หรือ `W` | ปุ่ม `JUMP` (กดซ้ำกลางอากาศ) |
| **ยิงปืนพก** | `Z` หรือ `J` | ปุ่ม `SHOOT` |
| **ฟื้นคืนชีพทันที (Quick Respawn)** | `R` | ปุ่ม `R` (ตรงกลางจอ) |
| **หยุดเกม / เมนู** | `MENU` (มุมขวาบน) | `MENU` (มุมขวาบน) |

---

## 🚀 วิธีการรันใน GitHub Codespaces

1. ใน Terminal ของ Codespaces เข้าไปยังโฟลเดอร์โปรเจกต์:
   ```bash
   cd augustus_mario_game
   ```
2. ติดตั้งแพ็กเกจ:
   ```bash
   flutter pub get
   ```
3. รันเกมบน Web Server:
   ```bash
   flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
   ```
4. เปิดดูเกมผ่านแท็บ **PORTS (พอร์ต 8080)**

---

## 📦 การ Build APK ผ่าน GitHub Actions

1. ไปที่แท็บ **Actions** บน GitHub Repository
2. เลือก Workflow **Build APK**
3. กดปุ่ม **Run workflow**
4. เมื่อกระบวนการเสร็จสิ้น (ประมาณ 5-10 นาที) สามารถดาวน์โหลดไฟล์ `app-apk.zip` ในส่วน Artifacts ได้ทันที