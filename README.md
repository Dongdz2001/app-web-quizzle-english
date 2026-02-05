# Vocab Web App - Ghi Nhớ Từ Vựng

Ứng dụng học và ghi nhớ từ vựng tiếng Anh, chạy được trên **Web** và **Mobile** (iOS/Android). Hiện tại dùng dữ liệu local để test.

## Tính năng

### 1. Quản lý Topic (Chủ đề)
- ➕ Thêm topic mới
- ✏️ Sửa topic  
- ❌ Xóa topic
- Mỗi topic chứa danh sách từ vựng riêng

### 2. Quản lý Từ vựng
- **Word** (từ tiếng Anh)
- **Meaning** (nghĩa tiếng Việt)
- **Word form** (noun, verb, adj, adv...)
- **English definition** (tùy chọn)
- **Synonym** - từ đồng nghĩa (tùy chọn)
- **Antonym** - từ trái nghĩa (tùy chọn)

### 3. Học từ vựng
- Xem danh sách từ theo topic
- Chế độ ẩn nghĩa → đoán → hiện đáp án

### 4. Luyện tập & Puzzle
- **Chọn nghĩa đúng**: 4 đáp án A, B, C, D
- **Điền từ**: nhập từ tiếng Anh khi biết nghĩa
- **Ghép từ - nghĩa**: chọn nghĩa phù hợp với từ
- **Đồng nghĩa/Trái nghĩa**: chọn từ đồng nghĩa hoặc trái nghĩa

### 5. Quiz thi thử
- Câu hỏi trắc nghiệm A, B, C, D
- Kết quả sau khi hoàn thành
- Có thể làm lại

### 6. Theo dõi tiến trình
- Số từ đã học
- Số câu đúng/sai
- Thống kê theo topic

## Chạy ứng dụng

### Web
```bash
cd vocab_app
flutter run -d chrome
```

### Mobile (Android)
```bash
flutter run
```

### Mobile (iOS) - cần Mac
```bash
flutter run
```

## Dữ liệu Demo

Ứng dụng tự động seed dữ liệu demo khi chạy lần đầu:
- **Topic Gia đình**: family, parents, sibling
- **Topic Công việc**: career, colleague

## Cấu trúc dự án

```
lib/
├── main.dart                 # Entry point
├── models/
│   ├── topic.dart           # Model Topic
│   ├── vocabulary.dart     # Model từ vựng
│   └── learning_progress.dart
├── providers/
│   └── vocab_provider.dart  # State management
├── services/
│   └── storage_service.dart # Local storage (SharedPreferences)
├── screens/
│   ├── home_screen.dart     # Danh sách topics
│   ├── topic_detail_screen.dart
│   ├── add_edit_topic_dialog.dart
│   ├── add_edit_word_dialog.dart
│   ├── learn_screen.dart    # Học từ
│   ├── practice_screen.dart # Luyện tập
│   ├── quiz_screen.dart     # Thi thử
│   └── progress_screen.dart # Tiến trình
└── theme/
    └── app_theme.dart
```

## Công nghệ

- **Flutter** - Cross-platform (Web, iOS, Android)
- **Provider** - State management
- **SharedPreferences** - Local storage

## Chuẩn bị cho Firebase (sau này)

Dự án đã thiết kế sẵn cấu trúc để dễ dàng tích hợp Firebase:
- Firebase Authentication
- Firestore Database
- Cấu trúc: users/{userId}, topics/{topicId}, words/{wordId}, progress/{userId}/{topicId}
# app-web-quizzle-english
