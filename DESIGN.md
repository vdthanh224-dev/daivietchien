# 📜 DESIGN SYSTEM & CREATIVE DIRECTION: ĐẠI VIỆT CHIẾN
> *Chuẩn hóa theo phương pháp luận Impeccable Design Language của Paul Bakaus*
> *Kim chỉ nam mỹ thuật, nhận diện thương hiệu và quy tắc UI/UX cho toàn bộ dự án Game Đại Việt Chiến.*

---

## 🏛️ 1. Triết Lý Mỹ Thuật & Tinh Thần Dự Án (Brand Identity & Aesthetic)

* **Tên Dự Án:** Đại Việt Chiến (Đấu Trường Thẻ Bài Lịch Sử 2v2).
* **Phong Cách Cốt Lõi (Core Aesthetic):** **Hào Khí Đông A - Sử Thi Lịch Sử & Huyền Tích Cổ Điển Việt Nam**.
* **Cảm Hứng Thị Giác:** Hoa văn Trống đồng Đông Sơn, chạm khắc rồng phượng thời Lý - Trần - Lê, tranh khắc gỗ dân gian, sơn mài cẩn xà cừ và vàng kim hoàng gia.
* **Nguyên Tắc Tránh "AI Slop" (Anti-Generic Rules):**
  * ❌ **Tuyệt đối không:** Dùng các dải gradient tím-xanh hiện đại (modern SaaS tech vibes), card lồng card vô nghĩa, font chữ mờ nhạt thiếu tương phản.
  * ✅ **Bắt buộc:** Tương phản sắc nét trên nền tối (Dark Wood / Obsidian Battlefield), viền kim loại vàng kim hoặc ngọc bích sắc sảo, icon và ký hiệu văn hóa rõ ràng.

---

## 🎨 2. Hệ Thống Mã Màu Chuẩn (Design Color Tokens)

| Token Name | Mã Hex / RGBA | Ý Nghĩa / Vị Trí Áp Dụng |
|---|---|---|
| **Imperial Gold (Vàng Kim Hoàng Triều)** | `#FFD166` / `#F4A261` | Khung viền Thẻ bài, Viền Modal chính, Nút hành động nổi bật |
| **Blood Crimson (Đỏ Son Huyết Chiến)** | `#E63946` / `#B82323` | Phe Phượng, Nút [KHÔNG NÉ], Cảnh báo Cận Tử, Sát thương |
| **Azure Dragon (Lam Long Đại Việt)** | `#3B82F6` / `#2563EB` | Phe Rồng, Thanh chọn mục tiêu, Hiệu ứng Nước/Băng |
| **Lotus Jade (Ngọc Bích Sen Ngọc)** | `#2A9D8F` / `#55FF55` | Nút [DÙNG BÀI], Hồi phục Máu, Khóa Diệu Kế thành công |
| **Thunder Violet (Lôi Điện Hồ Triều)** | `#9D4EDD` / `#7B2CBF` | Sát thương Lôi, Thần Sấm Báo Ứng, Kỹ năng đặc biệt |
| **Obsidian Dark (Màn Đêm Chiến Trận)** | `#060912` / `rgba(6,9,18,0.95)` | Nền Modal, Nền Khung chứa bài, Thanh Thông tin trận đấu |
| **Text Primary (Bạch Kim Soi Sáng)** | `#F8FAFC` / `#FFFFFF` | Tiêu đề, Tên tướng, Số lượng máu, Số giây đếm ngược |
| **Text Muted (Vàng Trầm Cổ Kính)** | `#E2D9B8` / `#CBD5E1` | Mô tả kỹ năng, Lời thoại lịch sử, Chi tiết cẩm nang |

---

## ✍️ 3. Hệ Thống Kiểu Chữ & Phân Cấp Thị Giác (Typography Hierarchy)

* **Font Tiêu Đề / Tên Tướng (Header Font):** Serif Cổ Điển / Kiếm Hiệp Sử Thi, In đậm (Bold), Có viền chữ đen (Outline/Shadow) để luôn nổi bật trên mọi hiệu ứng ánh sáng.
* **Font Nội Dung / Thông Số (Body Font):** Sans-serif cô đọng, dễ đọc, khoảng cách dòng (line-height) 1.25x - 1.35x.

### Bảng Phân Cấp Kích Thước (Font Scale):
1. **Title Modal / Victory Banner:** `18pt - 22pt` (Bold, Imperial Gold `#FFD166`).
2. **Card Name / General Name:** `13pt - 15pt` (Bold, White / Gold).
3. **Button Action Text:** `12pt - 13pt` (Bold, Uppercase, Center).
4. **Card Description / Combat Log:** `10pt - 11pt` (Regular / Italic, Clean spacing).
5. **Badge / Small Counter / Timer Subtext:** `9pt - 10pt` (Bold, High Contrast).

---

## 🎴 4. Quy Chuẩn Thành Phần Giao Diện (Component System)

### A. Thẻ Bài (CardUI)
* **Tỉ Lệ Chuẩn:** `94px x 130px` (Hand UI), `184px x 245px` (General Card).
* **Viền (Frame):** Viền kim loại họa tiết cổ, tự động phát quang (Lotus Halo Glow) khi được chọn hoặc đến lượt tương tác.
* **Biểu Tượng Chất & Số (Suit & Rank):** Đặt tại góc trên bên trái, cỡ chữ to rõ nét.

### B. Modal & Bảng Phản Hồi Chiến Thuật (Combat Modals)
* **Khung Nền (Panel Backdrop):** Nền tối sâu `#060912` với độ mờ 95%, bo viền họa tiết vàng kim `UI/card_frame`.
* **Kích Thước Chuẩn:**
  * Modal Hỏi Diệu Kế / Phản Hồi: `620px x 160px`.
  * Modal Mở Kho Cứu Tế: `680px x 280px`.
  * Panel Phản Ứng Đỡ / Trảm: `680px x 48px` (Đặt phía trên tay bài tại Y: +238px).
* **Đồng Hồ Đếm Ngược (Turn Timer):**
  * Luôn hiển thị biểu tượng `⏳` cùng số giây `40s...` nổi bật bằng màu Cyan / Vàng kim rực rỡ.
  * Tự động đồng bộ với thanh đếm trên đầu avatar tướng.

### C. Nút Bấm Tương Tác (Action Buttons)
* **Nút Đồng Ý / Kích Hoạt:** Màu Xanh Ngọc (`#2A9D8F`) hoặc Vàng Kim, có icon minh họa phía trước (🛡️, ⚔️, 🌾).
* **Nút Bỏ Qua / Chịu Sát Thương:** Màu Xám Trầm (`#4B5563`) hoặc Đỏ Tối (`#991B1B`), icon ❌.

---

## ✨ 5. Chuyển Động & Hiệu Ứng Thị Giác (Motion & Micro-Interactions)

1. **Tia Sáng Tấn Công (Attack Beam):** Tia năng lượng vàng/đỏ lượn sóng đi từ thẻ bài đến avatar mục tiêu với Particle Trail.
2. **Rút Bài & Đánh Bài (Card Physics):** Chuyển động mượt mà với đường cong Bezier và Cubic Easing (0.25s - 0.35s).
3. **Hiệu Ứng Sát Thương (Damage Numbers & Shake):** Số sát thương nảy lên (`Floating Text`) kèm hiệu ứng rung màn hình nhẹ (Screen Shake) 0.15s khi dính đòn chí mạng hoặc Thần Sấm Báo Ứng.
4. **Phản Hồi Âm Thanh (Sound Design Sync):** Mỗi thao tác ra bài, đỡ đòn, tiếng xúc xắc gieo, tiếng binh khí va chạm (Clang/Parry) đều đồng bộ chính xác với khung hình xuất hiện hiệu ứng.

---

## 📐 6. Quy Chuẩn Canvas & Tương Thích Thiết Bị (Responsive Canvas Rules)

* **Độ Phân Giải Tham Chiếu (Reference Resolution):** `1920 x 1080` (Tỉ lệ chuẩn 16:9).
* **Canvas Scaler Mode:** `Scale With Screen Size`, `Match Width Or Height: 0.5`.
* **Vùng An Toàn (Safe Area):** Tất cả các nút thao tác chính (Hand cards, End Turn, Chat, History) cách mép màn hình tối thiểu 16px để đảm bảo không bị che khuất trên điện thoại màn hình tai thỏ / đục lỗ.

---
*Tài liệu này là chuẩn mực bắt buộc cho mọi đợt phát triển, mở rộng tướng mới, thẻ bài mới và nâng cấp đồ họa trong Đại Việt Chiến.*
