lib/
├── core/                       # 1. CÁC THÀNH PHẦN DÙNG CHUNG
│   ├── constants/              # Biến toàn cục, API endpoints, màu sắc, strings
│   ├── errors/                 # Xử lý lỗi ngoại lệ (Exceptions, Failures)
│   ├── network/                # Cấu hình gọi API (Dio, Interceptors, HTTP client)
│   ├── services/               # Các dịch vụ bên thứ 3 (Hardware, SDKs, printer, barcode, notification)
│   ├── storage/                # Xử lý lưu trữ local (SharedPreferences, Hive, SQLite)
│   ├── theme/                  # Quản lý giao diện chung (Light/Dark theme, Typography)
│   ├── utils/                  # Các hàm tiện ích (Format tiền tệ, ngày tháng, validators)
│   └── widgets/                # Component UI dùng chung toàn hệ thống (CustomButton, Dialogs)
│ 
├── shared/
│   ├── extensions/
│   ├── enums/            # Shared enums (UserRole, PackageStatus, etc.)              
│
├── features/                   # 2. CÁC TÍNH NĂNG NGHIỆP VỤ (Áp dụng Clean Architecture)
│   ├── auth/                   # Xử lý Đăng nhập, Quên mật khẩu chung
│   │    ├── domain/
│   │    ├── data/
│   │    ├──  presentation/
│   │    │    ├── common/        
│   │    │    ├── pos_ui/        # PIN login / thẻ nhân viên
│   │    │    ├── admin_ui/      # Email + 2FA
│   │    │          ├── state/              # Quản lý trạng thái (Ví dụ dùng BLoC)
│   │    │          ├── pages/              # Các màn hình chính
│   │    │          └── widgets/            # Các component UI chỉ dùng riêng cho Feature này
│   │    │    ├── client_ui/     # Email / Social login
│   │
│   ├── packages/               # Nghiệp vụ Gói cước (Dùng chung cho cả Admin & Client)
│   │   ├── domain/             # TẦNG CỐT LÕI 
│   │   │   ├── entities/       
│   │   │   ├── repositories/   
│   │   │   └── usecases/      
│   │   ├── data/               # TẦNG DỮ LIỆU 
│   │   │   ├── models/         
│   │   │   ├── datasources/    
│   │   │   └── repositories/   
│   │   └── presentation/       # TẦNG GIAO DIỆN                   
│
├── app/
│   ├── bootstrap.dart          # # init app
│   └── di/
│       ├── global_di.dart      # Inject những gì THỰC SỰ dùng chung 3 app (logger, http client, base services)
├── app_entries/                # 3. CÁC ĐIỂM NEO KHỞI CHẠY ỨNG DỤNG TÁCH BIỆT
│   ├── pos/
│   │   ├── pos_app.dart        # Chứa MaterialApp
│   │   ├── pos_routes.dart     # CHỈ chứa các route của POS
│   │   └── pos_di.dart         # Dependency Injection (GetIt) CHỈ bơm các repo của POS
│   │
│   ├── admin/
│   │   ├── admin_app.dart      
│   │   ├── admin_routes.dart   # Định tuyến Admin 
│   │   └── admin_di.dart       
│   │
│   └── client/
│       ├── client_app.dart     
│       ├── client_routes.dart  
│       └── client_di.dart      
│
├── env/                        # 5. CẤU HÌNH MÔI TRƯỜNG
│   ├── env.dart            
│   ├── env_dev.dart            # Trỏ API về server Test
│   └── env_prod.dart           # Trỏ API về server Production
│
├── main_pos.dart               # Lệnh build: flutter build apk -t lib/main_pos.dart (Cho máy POS Android)
├── main_admin.dart             # Lệnh build: flutter build web -t lib/main_admin.dart (Cho Web Super Admin)
└── main_client.dart            # Lệnh build: flutter build apk/ios/web -t lib/main_client.dart (Cho Web/Mobile Chủ quán)