# Ninja School - Test offline Windows (không cần VPS)

## Có gì sau khi setup?

- Java game backend chạy trên máy của bạn tại 127.0.0.1:14444 (không cho phép kết nối từ Internet).
- MariaDB 10.11 chạy trong Docker Desktop, chỉ truy cập từ 127.0.0.1:3306.
- Game reference data: map, quái, item, skill, nhiệm vụ… được lọc từ dump data.
- Account DB: chỉ tạo **schema**, bỏ tất cả dữ liệu người chơi, nạp tiền, giao dịch từ nguồn cũ; tạo đúng **một tài khoản test mới** trên máy.
- Build Java hiện tại bằng Apache Ant thay vì dùng JAR gốc cũ; check TCP và Docker.
- Mật khẩu và SQL tạo ra được giữ trong .env, .offline/ (gitignore); không được công khai.

**Quan trọng:** Repo gốc chỉ chứa backend Java; chưa có client đã xác nhận tương thích. Cổng TCP mở thành công không có nghĩa đã vào game được. Không đưa bản này ra Internet: xử lý SQL injection, mật khẩu lưu dạng plaintext, bảo mật/giấy phép tài sản game trước.

## Bước 1. Cài công cụ (một lần)

Máy Windows 10/11 64-bit, RAM 8 GB trở lên nên có đủ cho test cơ bản.

1. [Docker Desktop](https://www.docker.com/products/docker-desktop/) với WSL 2. Chuyển sang **Linux containers**, bật Docker Desktop chờ Engine Running.
2. [Eclipse Temurin JDK 8](https://adoptium.net/temurin/releases/?version=8) (x64, đặt JAVA_HOME/PATH về JDK 8).
3. [Apache Ant](https://ant.apache.org/bindownload.cgi) (giải nén, thêm thư mục bin vào PATH, cần JAVA_HOME).
4. [Python 3](https://www.python.org/downloads/windows/) (tick Add Python to PATH) và Git nếu chưa có.

Mở CMD mới, xác nhận:

    docker compose version
    java -version
    ant -version
    py -3 --version

Nếu Windows không có py launcher, dùng python --version.

## Bước 2. Clone source hoặc cập nhật source

Clone lần đầu:

    git clone https://github.com/techzoneadapter-droid/ninjanoschool.git
    cd ninjanoschool

Nếu máy đã clone dự án, vào đúng thư mục và dùng git pull (chú ý không ghi đè thay đổi local chưa commit).

## Bước 3. Chạy bằng một file CMD

Nhấp đúp **TEST-NINJA-SCHOOL.cmd** (hoặc chạy nó từ CMD). Script sẽ:

1. Kiểm tra Docker, Java 8, Ant, Python và các file nguồn.
2. Sinh **hai mật khẩu database ngẫu nhiên** vào .env nếu chưa có. **Không in mật khẩu**.
3. Tạo schema account sạch và dữ liệu game, tạo mật khẩu riêng cho user testninja.
4. Bật database, chờ trạng thái healthy, nhập dữ liệu (chỉ lúc database chưa có bảng).
5. Build JAR từ code Java hiện tại.
6. Chạy game server và để cửa sổ mở, ghi log ra CMD.

Kiểm tra ở cửa sổ khác bằng **STATUS-NINJA-SCHOOL.cmd**. Trạng thái tốt khi database là healthy và cổng game là OPEN.

Tài khoản thử nằm trong **.offline/test-account.txt**:
- username: testninja
- password: mật khẩu riêng được sinh ngẫu nhiên lúc setup, xem trực tiếp trên máy.

Không đẩy .env hoặc .offline/test-account.txt lên Git, không dùng tài khoản này trên Internet. Client cần được cung cấp/xác minh riêng và phải trỏ về **127.0.0.1:14444** khi chạy trên cùng máy Windows.

## Dừng / Khởi động lại

- Dừng game: nhấn Ctrl+C trong cửa sổ CMD đang chạy (database tiếp tục chạy).
- Dừng database: chạy **STOP-LOCAL-DATABASE.cmd** sau khi đã dừng game; không xóa dữ liệu.
- Khởi động lại game không cần nạp SQL: chạy **run.bat** nếu Docker DB đã bật, hoặc TEST-NINJA-SCHOOL.cmd để tự kiểm tra/build.
- Xem trạng thái: **STATUS-NINJA-SCHOOL.cmd**.

Chưa cung cấp nút xóa database để tránh mất dữ liệu ngoài ý muốn. Lệnh xóa Docker volume không được dùng trừ khi có bản sao lưu rõ ràng và chấp nhận mất dữ liệu.

## Khắc phục lỗi

| Triệu chứng | Kiểm tra |
|---|---|
| Missing docker, WSL 2, Docker Engine | Cài/chạy Docker Desktop và chọn Linux containers |
| Missing Java 8, Ant, Python 3 | Cài các công cụ ở bước 1, đóng/mở CMD để PATH mới có hiệu lực |
| Port 3306 đã sử dụng | Kiểm tra MySQL/XAMPP đang dùng cổng đó; dừng dịch vụ gây xung đột hoặc đổi NSO_MYSQL_PORT trong .env (DB host port) |
| Port 14444 đã sử dụng | Đóng tiến trình Java cũ, kiểm tra bằng netstat -ano \| findstr :14444 |
| SQL import failed | Xem docker compose logs db; không xóa volume tự động hoặc nhập dump account gốc |
| Database partially initialized | Bản chạy bị dừng giữa khi import, cần kiểm tra schema/trạng thái trước khi tiếp tục; không tự reset |
| Game port không mở | Xem lỗi Java trong cửa sổ TEST-NINJA-SCHOOL; xem cấu hình .env, log DB và source |
| Game port mở nhưng không vào được game | Chưa có client kiểm chứng; cần kiểm tra giao thức/phiên bản/endpoint client và đăng nhập |
| Login failed | Đọc username/password trong .offline/test-account.txt; backend cũ dùng mật khẩu plaintext và chưa được sửa để đưa production |

## Kiểm thử tự động

- [Verify NSO Java server](../.github/workflows/verify-server.yml): build Java 8, các kiểm tra bảo mật và file SQL được lọc.
- [Windows Offline Environment Smoke Tests](../.github/workflows/offline-smoke.yml): chạy script Windows ở preflight, tạo MariaDB sạch trên runner và thử mở TCP Java local.

Đây là môi trường **dev offline**, không có đảm bảo an toàn hoặc quyền phát hành công khai. Việc tự quản GitHub/Windows/VPS không chuyển bản quyền source, nội dung/nhân vật, asset và tên game. Hãy dùng mã/asset có quyền hợp lệ nếu hướng tới game thương mại độc lập.
