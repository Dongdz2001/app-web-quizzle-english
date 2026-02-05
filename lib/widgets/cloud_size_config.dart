import 'dart:ui';

import '../models/vocabulary.dart';

/// Thông số width (độ rộng) của đám mây: dùng số ký tự tối đa cho tiếng Anh và tiếng Việt
/// để ước lượng "width của text". So sánh width đám mây (capacity) với width text (length)
/// để chọn đám mây có kích thước nhỏ nhất mà vẫn chứa vừa text.
class CloudSizeConfig {
  CloudSizeConfig._();

  /// Width đám mây (nhỏ): số ký tự tối đa cho từ tiếng Anh (word) fit trong width đó.
  static const int maxCharsEnglish = 12;

  /// Width đám mây (nhỏ): số ký tự tối đa cho nghĩa tiếng Việt (meaning) fit trong width đó.
  static const int maxCharsVietnamese = 16;
}

/// Một preset: (width, height) đám mây và ngưỡng width text (số ký tự EN/VI tương ứng).
class _CloudSizePreset {
  const _CloudSizePreset({
    required this.size,
    required this.maxCharsEnglish,
    required this.maxCharsVietnamese,
  });

  final Size size;
  /// Width capacity: max ký tự tiếng Anh fit trong đám mây này.
  final int maxCharsEnglish;
  /// Width capacity: max ký tự tiếng Việt fit trong đám mây này.
  final int maxCharsVietnamese;

  bool fits(int wordLen, int meaningLen) =>
      wordLen <= maxCharsEnglish && meaningLen <= maxCharsVietnamese;
}

/// Các preset kích thước đám mây: nhỏ → lớn.
/// Chiều cao đủ cho 2 dòng chữ + padding dọc (kCloudInternalPaddingV * 2).
final List<_CloudSizePreset> _cloudSizePresets = [
  _CloudSizePreset(
    size: Size(92, 82),
    maxCharsEnglish: 8,
    maxCharsVietnamese: 10,
  ),
  _CloudSizePreset(
    size: Size(112, 88),
    maxCharsEnglish: CloudSizeConfig.maxCharsEnglish,
    maxCharsVietnamese: CloudSizeConfig.maxCharsVietnamese,
  ),
  _CloudSizePreset(
    size: Size(138, 96),
    maxCharsEnglish: 18,
    maxCharsVietnamese: 24,
  ),
  _CloudSizePreset(
    size: Size(164, 108),
    maxCharsEnglish: 26,
    maxCharsVietnamese: 32,
  ),
];

/// Chọn kích thước đám mây phù hợp: so sánh width của text (số ký tự word/meaning)
/// với width capacity của từng preset, chọn đám mây có (width, height) nhỏ nhất mà vẫn chứa vừa.
Size pickCloudSize(Vocabulary word, {required Size layoutBounds}) {
  final wordLen = word.word.trim().length;
  final meaningLen = word.meaning.trim().length;

  for (final preset in _cloudSizePresets) {
    if (preset.fits(wordLen, meaningLen)) {
      final w = preset.size.width.clamp(80.0, layoutBounds.width);
      final h = preset.size.height.clamp(72.0, layoutBounds.height);
      return Size(w, h);
    }
  }
  final last = _cloudSizePresets.last;
  final w = last.size.width.clamp(80.0, layoutBounds.width);
  final h = last.size.height.clamp(72.0, layoutBounds.height);
  return Size(w, h);
}
