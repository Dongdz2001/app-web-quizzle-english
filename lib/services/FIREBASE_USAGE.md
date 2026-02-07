# Hướng dẫn sử dụng Firebase Database - Decentralized System

## Tổng quan

Hệ thống database phi tập trung cho phép tất cả người dùng xem và đóng góp dữ liệu. Mỗi dữ liệu đều có metadata về người tạo và người chỉnh sửa.

## Khởi tạo

Firebase đã được khởi tạo tự động trong `main.dart`. Không cần làm gì thêm.

## Sử dụng FirebaseService

### 1. Lấy tất cả topics

```dart
import 'package:vocab_app/services/firebase_service.dart';

final firebaseService = FirebaseService();
final topics = await firebaseService.getAllTopics();
```

### 2. Lắng nghe thay đổi real-time

```dart
firebaseService.topicsStream().listen((topics) {
  // Cập nhật UI khi có thay đổi từ bất kỳ người dùng nào
  setState(() {
    _topics = topics;
  });
});
```

### 3. Tạo topic mới

```dart
final newTopic = Topic(
  id: 'unique-topic-id',
  name: 'New Topic',
  description: 'Description',
  categoryId: CategoryIds.topic,
  words: [
    Vocabulary(
      id: 'word-1',
      word: 'hello',
      meaning: 'xin chào',
      wordForm: 'noun',
    ),
  ],
);

final topicId = await firebaseService.createTopic(newTopic);
// Metadata (createdBy, createdAt) sẽ được tự động thêm
```

### 4. Cập nhật topic

```dart
final updatedTopic = topic.copyWith(
  name: 'Updated Name',
  description: 'Updated Description',
);

await firebaseService.updateTopic(updatedTopic);
// Metadata (updatedBy, updatedAt) sẽ được tự động cập nhật
```

### 5. Thêm word vào topic

```dart
final newWord = Vocabulary(
  id: 'new-word-id',
  word: 'world',
  meaning: 'thế giới',
  wordForm: 'noun',
);

await firebaseService.addWordToTopic(topicId, newWord);
```

### 6. Cập nhật word

```dart
final updatedWord = word.copyWith(
  meaning: 'nghĩa mới',
);

await firebaseService.updateWordInTopic(topicId, updatedWord);
```

### 7. Xóa word

```dart
await firebaseService.deleteWordFromTopic(topicId, wordId);
```

### 8. Lọc topics theo category

```dart
final grammarTopics = await firebaseService.getTopicsByCategory(CategoryIds.grammar);
```

### 9. Lọc topics theo grade level

```dart
final grade1Topics = await firebaseService.getTopicsByGradeLevel(1);
```

## User Management

### Anonymous Users

- Người dùng chưa đăng nhập sẽ tự động được tạo anonymous account
- Anonymous user có thể đọc và ghi dữ liệu
- User ID được tự động tạo và lưu

### Cập nhật thông tin user

```dart
await firebaseService.updateUserInfo(
  userName: 'New Name',
  userEmail: 'newemail@example.com',
  userAvatarUrl: 'https://example.com/avatar.jpg',
);
```

## Metadata

Mỗi topic và word đều có metadata:

- `createdBy`: Thông tin người tạo (userId, userName, userEmail, userAvatarUrl)
- `createdAt`: Thời gian tạo
- `updatedBy`: Thông tin người cập nhật gần nhất
- `updatedAt`: Thời gian cập nhật gần nhất

Metadata được tự động thêm vào khi tạo/cập nhật dữ liệu.

## Lưu ý quan trọng

1. **Tất cả dữ liệu công khai**: Mọi người đều có thể xem và chỉnh sửa
2. **Real-time sync**: Dữ liệu được đồng bộ real-time qua Firestore
3. **Automatic metadata**: Metadata được tự động thêm, không cần set thủ công
4. **Error handling**: Các lỗi được log ra console, app vẫn tiếp tục chạy
5. **Offline support**: Firestore hỗ trợ offline, dữ liệu sẽ sync khi online

## Tích hợp với Provider

Để tích hợp với VocabProvider hiện tại:

```dart
class VocabProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  List<Topic> _topics = [];
  
  VocabProvider() {
    // Lắng nghe thay đổi real-time
    _firebaseService.topicsStream().listen((topics) {
      _topics = topics;
      notifyListeners();
    });
  }
  
  Future<void> addTopic(Topic topic) async {
    await _firebaseService.createTopic(topic);
    // UI sẽ tự động cập nhật qua stream
  }
}
```

## Security Rules

Đảm bảo Firestore Security Rules được cấu hình đúng (xem FIREBASE_DATABASE_SCHEMA.md)
