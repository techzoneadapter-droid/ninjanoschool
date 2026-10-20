# Ninja School – self-hosting / tự vận hành

## Trạng thái và giới hạn

Repo này là một bản sao nguồn công khai, gồm Java backend, cấu trúc SQL và tài nguyên. Chưa xác minh client tương thích, nội dung/mã nguồn có quyền cấp phép phát hành thương mại, hay mức độ an toàn bảo mật của gameplay. Việc sở hữu repo GitHub **không** chuyển quyền tác giả hoặc quyền khai thác game gốc.

Thay đổi tự vận hành: máy chủ chỉ nghe **127.0.0.1** theo mặc định; tên miền/database cũ không còn trong cấu hình hoạt động; thông tin database đặt trong `.env` hoặc file riêng qua `NSO_CONFIG_FILE`. Không mở public cho tới khi kiểm thử, cập nhật thư viện và kiểm toán bảo mật.

## Chuẩn bị (Windows 10/11 hoặc Linux VPS)

1. Cài Git, Java JDK 8 (để build source Java 8 cũ), Apache Ant, và Docker Desktop / Docker Engine + Docker Compose.
2. Clone: `git clone https://github.com/techzoneadapter-droid/ninjanoschool.git`. Thực hiện từ **thư mục gốc repo** để tìm được `ninja.conf` và `res/`.
3. Copy `.env.example` thành `.env`, thay `NSO_DB_ROOT_PASSWORD` và `NSO_MYSQL_PASSWORD` bằng **hai mật khẩu mạnh khác nhau**. Không đẩy file này lên Git.
4. Chạy `docker compose config` để kiểm tra và `docker compose up -d db` để khởi động MariaDB. Chỉ cổng **127.0.0.1:3306** được mở trên máy chủ, không công khai database.
5. Đợi `docker compose ps` báo database khỏe. Container tạo mới hai database `nsohuyda_data` và `nsohuyda_account` qua `deploy/initdb` **chỉ khi volume còn trống**.

## Dữ liệu SQL an toàn cho môi trường test

**Không nạp trực tiếp dump tài khoản gốc** vì có dữ liệu người chơi và giao dịch của máy chủ khác. Đối với Windows offline, làm theo [WINDOWS_OFFLINE.md](WINDOWS_OFFLINE.md) và chạy `TEST-NINJA-SCHOOL.cmd` để tự động tách SQL: chỉ nạp game reference data, lấy schema tài khoản trống, tạo một user thử hoàn toàn mới.

Lệnh tạo SQL sạch khi làm thủ công: `python scripts/prepare_offline_sql.py` (output ở `.offline/generated/`, bị Git bỏ qua). Chỉ dùng SQL có quyền sử dụng hợp lệ. Tự kiểm tra quyền đối với nội dung tài nguyên trước khi triển khai công khai.

## Build và chạy

Chạy `ant clean jar` để dựng lại JAR từ source thay vì mặc định tin JAR cũ có sẵn. Kiểm tra `dist/NSO-HUYDAT.jar` và `dist/lib/`.

Windows: `run.bat` hoặc `powershell -File scripts/start-server.ps1`.

Linux: `bash scripts/start-server.sh`.

Chương trình chạy mặc định tại `127.0.0.1:14444`. Để client ở máy khác kết nối trong mạng riêng, đổi `NSO_BIND_HOST=0.0.0.0` và chỉ mở firewall cho IP test. Khi chuẩn bị production, cần IP/domain cố định, port forwarding và endpoint client tương thích. `NSO_PUBLIC_HOST` không tự thay host đã ghi cứng trong client bên ngoài repo.

Sau khi thay `.env`, restart tiến trình Java. `NSO_CONFIG_FILE` là đường dẫn tuyệt đối tới file cấu hình riêng cùng định dạng `ninja.conf` (ưu tiên env cao hơn file). Đừng ghi mật khẩu vào `ninja.conf` được Git theo dõi.

## Sao lưu và khôi phục

Trên Linux chạy `bash scripts/backup-db.sh`. Bản dump ở `backups/` (đã gitignore), bảo vệ bằng quyền truy cập máy chủ và mã hóa ngoài máy. Thử khôi phục vào database test ít nhất một lần; lịch sử backup chưa tự động lập lịch. Không xóa Docker volume nếu chưa backup.

## Kiểm tra trước khi đưa online

- Đảm bảo database mới không dùng mật khẩu xuất hiện trong lịch sử Git. **Mật khẩu cũ trong lịch sử upstream phải được xem là đã lộ và thay/thu hồi tại nguồn**.
- Trước khi phát hành, đánh giá bản quyền/giấy phép của source, nhãn hiệu, đồ họa, âm thanh, nội dung và client.
- Kiểm tra việc đăng ký/đăng nhập, kết nối/disconnect, lưu dữ liệu, đa người chơi, lưu item/currency, tính toàn vẹn sau restart và sao lưu.
- Review SQL injection, xác thực và phân quyền GM/admin, chống nhân bản vật phẩm, rate limiting, packet-size limits, crash resilience và log chứa thông tin cá nhân.
- Nâng cấp JDBC driver/MySQL dependencies Java cũ, tách user DB chỉ có quyền cần thiết, TLS khi DB không cùng host, giám sát tài nguyên và chính sách sao lưu/khôi phục.
- Đưa web / thanh toán / nạp tiền lên production **chỉ sau khi** bảo mật, tài chính và quyền thương mại được xem xét.

## Lệnh vận hành

```bash
docker compose ps
docker compose logs --tail=100 db
bash scripts/backup-db.sh
```

**Chưa có VPS/IP/SSH của chủ dự án nên các bước mới dừng ở bộ cấu hình triển khai; chưa có bằng chứng game vào chơi được trên máy chủ public.**
