# Source code VIP NEW backend server game ninja school online Dev Mob by GVN
# Source code VIP NEW backend server game ninja school online version Hồi Ức version VIP NEW
<img width="450" height="250" src="https://ninjaschool.org/images/slide-01.png">
# 📬 Dev Mob by GVN

## Tự vận hành / Self-hosting (NVB fork)

Xem [hướng dẫn triển khai và sao lưu](docs/SELF_HOSTING.md).

- `ninja.conf` giờ chỉ chứa thông số local, không còn mật khẩu/database của máy chủ gốc.
- Sao chép `.env.example` sang `.env` và tự đặt mật khẩu trước khi khởi chạy.
- MariaDB riêng: `docker compose up -d db`; build từ source: `ant clean jar`.
- Windows: `run.bat`; Linux: `bash scripts/start-server.sh`.
- Server mặc định chạy trên `127.0.0.1:14444`. Chỉ mở public khi đã kiểm thử.
- CI kiểm tra build ở tab **Actions**.

**Chú ý:** Chưa kiểm thử đầy đủ game/client hoặc quyền phát hành. Source upstream không kèm giấy phép mở; quyền quản trị GitHub và server không tự động cấp quyền thương mại với nội dung của người khác.
