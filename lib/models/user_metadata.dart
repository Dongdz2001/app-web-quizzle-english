/// Metadata về người tạo/chỉnh sửa dữ liệu
class CreatorMetadata {
  final String userId;
  final String? userName;
  final String? userEmail;
  final String? userAvatarUrl;

  CreatorMetadata({
    required this.userId,
    this.userName,
    this.userEmail,
    this.userAvatarUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userAvatarUrl': userAvatarUrl,
    };
  }

  factory CreatorMetadata.fromJson(Map<String, dynamic> json) {
    return CreatorMetadata(
      userId: json['userId'] as String,
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      userAvatarUrl: json['userAvatarUrl'] as String?,
    );
  }

  CreatorMetadata copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    String? userAvatarUrl,
  }) {
    return CreatorMetadata(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    );
  }
}
