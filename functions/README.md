# Cloud Functions cho Quizzle English App

Thư mục này chứa Firebase Cloud Functions để xử lý các tác vụ server-side.

## Functions

### `deleteUser`
Xóa user khỏi Firebase Authentication. Chỉ admin (adminchi@gmail.com) mới có quyền gọi function này.

**Input:**
```json
{
  "userId": "string"
}
```

**Output:**
```json
{
  "success": true,
  "message": "User deleted successfully from Firebase Auth"
}
```

## Cài đặt và Deploy

### 1. Cài đặt dependencies

```bash
cd functions
npm install
```

### 2. Deploy functions

```bash
# Deploy tất cả functions
npm run deploy

# Hoặc sử dụng Firebase CLI trực tiếp
firebase deploy --only functions
```

### 3. Test local (tùy chọn)

```bash
# Chạy emulator
npm run serve

# Hoặc
firebase emulators:start --only functions
```

## Yêu cầu

- Node.js 18 hoặc cao hơn
- Firebase CLI đã được cài đặt và đăng nhập
- Firebase project đã được khởi tạo với `firebase init`

## Lưu ý

- Function `deleteUser` yêu cầu authentication và chỉ admin mới có quyền gọi
- Đảm bảo Firebase Admin SDK đã được cấu hình đúng trong project
- Function sẽ tự động được deploy với region mặc định (us-central1) nếu không chỉ định

## Troubleshooting

### Lỗi "Permission denied"
- Đảm bảo bạn đang đăng nhập với tài khoản admin (adminchi@gmail.com)
- Kiểm tra Firebase Authentication rules

### Lỗi "Function not found"
- Đảm bảo function đã được deploy thành công
- Kiểm tra tên function trong code Flutter khớp với tên trong `index.js`

### Lỗi khi deploy
- Kiểm tra Firebase CLI version: `firebase --version`
- Đảm bảo đã đăng nhập: `firebase login`
- Kiểm tra project ID trong `.firebaserc` hoặc `firebase.json`
