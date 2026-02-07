# Hướng dẫn Deploy Cloud Functions

## Bước 1: Cài đặt Firebase CLI

Nếu chưa có Firebase CLI, cài đặt bằng npm:

```bash
npm install -g firebase-tools
```

## Bước 2: Đăng nhập Firebase

```bash
firebase login
```

## Bước 3: Khởi tạo Firebase Functions (nếu chưa có)

Nếu project chưa được khởi tạo với Firebase:

```bash
firebase init functions
```

Chọn:
- Language: JavaScript
- ESLint: Yes
- Install dependencies: Yes

## Bước 4: Cài đặt dependencies cho Functions

```bash
cd functions
npm install
cd ..
```

## Bước 5: Deploy Functions

```bash
# Deploy tất cả functions
firebase deploy --only functions

# Hoặc deploy function cụ thể
firebase deploy --only functions:deleteUser
```

## Bước 6: Cài đặt package Flutter

Sau khi deploy Cloud Functions, cài đặt package `cloud_functions` trong Flutter:

```bash
flutter pub get
```

## Bước 7: Test

1. Đăng nhập vào app với admin account (adminchi@gmail.com)
2. Vào trang admin dashboard
3. Thử xóa một user
4. Kiểm tra trong Firebase Console > Authentication > Users để xác nhận user đã bị xóa

## Troubleshooting

### Lỗi "Permission denied" khi gọi function

- Đảm bảo bạn đang đăng nhập với tài khoản admin (adminchi@gmail.com)
- Kiểm tra Firebase Authentication rules

### Lỗi "Function not found"

- Kiểm tra function đã được deploy: `firebase functions:list`
- Đảm bảo tên function trong code Flutter (`deleteUser`) khớp với tên trong `functions/index.js`

### Lỗi khi deploy

- Kiểm tra Firebase CLI version: `firebase --version` (nên >= 12.0.0)
- Kiểm tra Node.js version: `node --version` (nên >= 18)
- Kiểm tra project ID trong `.firebaserc` khớp với project thực tế

### Function không hoạt động sau khi deploy

- Kiểm tra logs: `firebase functions:log`
- Kiểm tra function có được enable trong Firebase Console > Functions
- Đảm bảo billing đã được bật cho project (Cloud Functions yêu cầu Blaze plan)

## Lưu ý quan trọng

⚠️ **Cloud Functions yêu cầu Firebase Blaze plan (pay-as-you-go)**. Plan Spark (free) không hỗ trợ Cloud Functions.

Để bật billing:
1. Vào Firebase Console
2. Project Settings > Usage and billing
3. Upgrade to Blaze plan

Blaze plan có free tier hào phóng cho development và testing.

## Kiểm tra Function đã deploy

```bash
# List tất cả functions
firebase functions:list

# Xem logs của function
firebase functions:log --only deleteUser
```

## Cấu trúc Files

```
.
├── functions/
│   ├── index.js          # Cloud Function code
│   ├── package.json      # Dependencies
│   ├── .eslintrc.js      # ESLint config
│   └── README.md         # Documentation
├── firebase.json         # Firebase config
└── .firebaserc           # Firebase project config
```
