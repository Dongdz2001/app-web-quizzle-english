# Firebase Database Schema - Decentralized Database

## Tổng quan

Database được thiết kế theo mô hình phi tập trung (decentralized), nơi tất cả người dùng đều có thể xem và đóng góp dữ liệu. Mỗi dữ liệu đều có metadata về người tạo và người chỉnh sửa.

## Collections

### 1. `topics` Collection

Lưu trữ tất cả các topic (chủ đề từ vựng).

**Document Structure:**
```json
{
  "id": "topic-id-123",
  "name": "Gia đình",
  "description": "Từ vựng về gia đình",
  "displayName": "Gia đình",
  "categoryId": "cat_topic",
  "gradeLevel": null,
  "words": [
    {
      "id": "word-id-1",
      "word": "family",
      "meaning": "gia đình",
      "wordForm": "noun",
      "englishDefinition": "a group of people related by blood",
      "synonym": "household",
      "antonym": null,
      "createdBy": {
        "userId": "user-123",
        "userName": "John Doe",
        "userEmail": "john@example.com",
        "userAvatarUrl": null
      },
      "createdAt": "2024-01-01T00:00:00Z",
      "updatedBy": {
        "userId": "user-123",
        "userName": "John Doe",
        "userEmail": "john@example.com"
      },
      "updatedAt": "2024-01-01T00:00:00Z"
    }
  ],
  "createdBy": {
    "userId": "user-123",
    "userName": "John Doe",
    "userEmail": "john@example.com",
    "userAvatarUrl": null
  },
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedBy": {
    "userId": "user-456",
    "userName": "Jane Smith",
    "userEmail": "jane@example.com"
  },
  "updatedAt": "2024-01-02T00:00:00Z"
}
```

**Fields:**
- `id`: Document ID (tự động tạo bởi Firestore)
- `name`: Tên topic
- `description`: Mô tả topic
- `displayName`: Tên hiển thị ở tâm cụm (có thể có `\n`)
- `categoryId`: ID category (`cat_topic`, `cat_grade`, `cat_grammar`, `cat_idiom`, `cat_ipa`)
- `gradeLevel`: Lớp học (1-12), chỉ dùng khi `categoryId = cat_grade`
- `words`: Array các từ vựng trong topic
- `createdBy`: Metadata người tạo topic
- `createdAt`: Thời gian tạo
- `updatedBy`: Metadata người cập nhật gần nhất
- `updatedAt`: Thời gian cập nhật gần nhất

### 2. `users` Collection

Lưu trữ thông tin người dùng (optional, để hiển thị thông tin người tạo).

**Document Structure:**
```json
{
  "userId": "user-123",
  "userName": "John Doe",
  "userEmail": "john@example.com",
  "userAvatarUrl": "https://example.com/avatar.jpg",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

## User Metadata Structure

Mỗi topic và word đều có metadata về người tạo/chỉnh sửa:

```json
{
  "userId": "unique-user-id",
  "userName": "Display Name",
  "userEmail": "email@example.com",
  "userAvatarUrl": "https://example.com/avatar.jpg"
}
```

## Quy tắc hoạt động

1. **Tất cả dữ liệu công khai**: Mọi người đều có thể xem tất cả topics và words
2. **Anonymous users**: Người dùng chưa đăng nhập sẽ tự động được tạo anonymous account
3. **Metadata tracking**: Mỗi thao tác tạo/sửa đều ghi lại thông tin người thực hiện
4. **Real-time sync**: Dữ liệu được đồng bộ real-time qua Firestore streams
5. **Timestamp**: Sử dụng server timestamp để đảm bảo tính nhất quán

## Security Rules (Firestore)

Để đảm bảo database phi tập trung hoạt động đúng, cần cấu hình Firestore Security Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Topics: Tất cả người dùng có thể đọc và ghi
    match /topics/{topicId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Users: Chỉ đọc công khai, chỉ user đó mới được cập nhật
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Sử dụng trong Code

```dart
// Khởi tạo service
final firebaseService = FirebaseService();

// Lấy tất cả topics
final topics = await firebaseService.getAllTopics();

// Lắng nghe thay đổi real-time
firebaseService.topicsStream().listen((topics) {
  // Cập nhật UI khi có thay đổi
});

// Tạo topic mới
final newTopic = Topic(
  id: 'new-topic-id',
  name: 'New Topic',
  words: [...],
);
await firebaseService.createTopic(newTopic);

// Cập nhật topic
await firebaseService.updateTopic(updatedTopic);

// Thêm word vào topic
await firebaseService.addWordToTopic(topicId, newWord);
```

## Lưu ý

- Tất cả timestamps sử dụng UTC
- User ID được lấy từ Firebase Auth (anonymous hoặc authenticated)
- Dữ liệu được lưu dạng nested (words trong topic) để tối ưu queries
- Có thể mở rộng sang subcollection nếu cần scale lớn hơn
