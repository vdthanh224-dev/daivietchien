# 🚀 Hướng Dẫn Triển Khai Deno Realtime Game Server (Đại Việt Chiến 2v2)

Máy chủ chuyên dụng xử lý trận đấu thời gian thực 100% trên RAM (In-Memory GameState) với độ trễ siêu tốc (<15ms).

---

## 🛠️ CÁCH 1: Chạy Thử Trên Máy Tính (Localhost)

1. Cài đặt Deno (nếu chưa cài):
   Mở PowerShell và dán lệnh sau:
   `powershell
   irm https://deno.land/install.ps1 | iex
   `
2. Khởi động Game Server:
   `ash
   cd deno-server
   deno task start
   `
   Máy chủ sẽ chạy tại địa chỉ: ws://localhost:8080 (hoặc http://localhost:8080 để xem trạng thái).

---

## 🌐 CÁCH 2: Deploy Miễn Phí Lên Deno Deploy (Khuyên Dùng)

Deno Deploy cung cấp cụm máy chủ Edge toàn cầu (bao gồm Singapore) với **100.000 requests/ngày hoàn toàn miễn phí**.

### Các Bước Triển Khai:

1. **Đăng nhập Deno Deploy**:
   - Truy cập: [https://dash.deno.com](https://dash.deno.com)
   - Đăng nhập bằng tài khoản GitHub.

2. **Tạo Dự Án Mới (New Project)**:
   - Bấm nút **"New Project"**.
   - Chọn kho lưu trữ GitHub của bạn (Dai_Viet_Chien).
   - Cấu hình file chạy:
     - **Production Branch**: main (hoặc branch của bạn).
     - **Root Directory**: deno-server
     - **Entrypoint**: server.js
   - Bấm **"Deploy Project"**.

3. **Lấy Đường Dẫn WebSocket**:
   - Sau khi deploy xong (chỉ mất ~5 giây), Deno sẽ cấp cho bạn một domain HTTPS/WSS, ví dụ:
     wss://dai-viet-chien.deno.dev

4. **Dán Đường Dẫn Vào Unity**:
   - Mở Assets/Scripts/AppwriteMatchmaking.cs (hoặc cấu hình GameServer URL).
   - Điền URL máy chủ Deno vừa nhận được.
