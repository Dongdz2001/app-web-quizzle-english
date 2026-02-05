import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import 'cloud_size_config.dart';
import 'cloud_widget.dart';

/// Vị trí cuối cùng của mỗi từ (gần tâm → xa dần theo thứ tự xuất hiện).
class _WordPlacement {
  _WordPlacement({
    required this.word,
    required this.finalLeft,
    required this.finalTop,
    required this.staggerDelay,
    required this.cloudSize,
  });

  final Vocabulary word;
  final double finalLeft;
  final double finalTop;
  final double staggerDelay;
  /// Kích thước đám mây cho từ này (chọn theo length word + meaning).
  final Size cloudSize;
}

/// Hiển thị chủ đề dạng đám mây: topic ở giữa, các từ xuất hiện ngẫu nhiên
/// từ gần tâm rồi dần ra xa (animation).
class TopicCloudView extends StatefulWidget {
  const TopicCloudView({
    super.key,
    required this.topicName,
    required this.words,
    required this.onWordTap,
    required this.onWordLongPress,
  });

  final String topicName;
  final List<Vocabulary> words;
  final void Function(Vocabulary word) onWordTap;
  final void Function(Vocabulary word) onWordLongPress;

  @override
  State<TopicCloudView> createState() => _TopicCloudViewState();
}

class _TopicCloudViewState extends State<TopicCloudView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_WordPlacement> _placements = [];
  Size? _layoutSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didUpdateWidget(covariant TopicCloudView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.words != widget.words || oldWidget.topicName != widget.topicName) {
      _layoutSize = null;
      _placements = [];
      _controller
        ..reset()
        ..forward();
    }
  }

  List<_WordPlacement> _computePlacementsForSize(Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;
    final centerY = h / 2;
    // Kích thước tối đa cho 1 đám mây (để pickCloudSize clamp)
    final layoutBounds = Size(w * 0.28, h * 0.18);

    final words = List<Vocabulary>.from(widget.words);
    final count = words.length;
    if (count == 0) return [];

    // Tính cloudSize cho từng từ theo maxCharsEnglish / maxCharsVietnamese
    final cloudSizes = words.map((v) => pickCloudSize(v, layoutBounds: layoutBounds)).toList();
    final wordW = cloudSizes.map((s) => s.width).reduce(math.max);
    final wordH = cloudSizes.map((s) => s.height).reduce(math.max);

    // Xếp từ theo hình bầu dục (ellipse) đồng tâm: rx theo chiều ngang, ry theo chiều dọc
    final placements = <_WordPlacement>[];
    var wordIndex = 0;
    var radius = math.min(w, h) * 0.18; // Bán kính cơ sở vòng đầu tiên
    final radiusStep = wordH + 14; // Bước tăng bán kính
    final spacing = 12.0;
    // Hệ số bầu dục: ngang rộng hơn (1.2), dọc hẹp hơn (0.88)
    const ovalScaleX = 1.2;
    const ovalScaleY = 0.88;

    while (wordIndex < count) {
      final radiusX = radius * ovalScaleX; // Bán trục ngang
      final radiusY = radius * ovalScaleY; // Bán trục dọc
      // Chu vi ellipse gần đúng: π * (3*(rx+ry) - sqrt((3*rx+ry)*(rx+3*ry))) hoặc đơn giản π*(rx+ry)
      final perimeter = math.pi * (radiusX + radiusY);
      final cloudArc = wordW + spacing;
      final maxWordsOnCircle = math.max(1, (perimeter / cloudArc).floor());
      final wordsOnThisCircle = math.min(maxWordsOnCircle, count - wordIndex);

      for (var i = 0; i < wordsOnThisCircle; i++) {
        final angle = i * 2 * math.pi / wordsOnThisCircle;
        // Ellipse: x = centerX + rx*cos(θ), y = centerY + ry*sin(θ)
        final fx = centerX + radiusX * math.cos(angle) - wordW / 2;
        final fy = centerY + radiusY * math.sin(angle) - wordH / 2;

        final t = count <= 1 ? 1.0 : wordIndex / (count - 1);
        final staggerDelay = 0.15 + 0.25 * t;

        placements.add(_WordPlacement(
          word: words[wordIndex],
          finalLeft: fx.clamp(10.0, w - wordW - 10),
          finalTop: fy.clamp(10.0, h - wordH - 10),
          staggerDelay: staggerDelay,
          cloudSize: cloudSizes[wordIndex],
        ));
        wordIndex++;
      }

      radius += radiusStep;
      if (radius > math.min(w, h) * 0.5) break;
    }

    return placements;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Cập nhật layout khi kích thước thay đổi; tính ngay trong build để đám mây hiện ngay
        if (_layoutSize != size) {
          _layoutSize = size;
          _placements = _computePlacementsForSize(size);
          _controller
            ..reset()
            ..forward();
        }

        final w = size.width;
        final h = size.height;
        final centerX = w / 2;
        final centerY = h / 2;
        // Kích thước ô layout = max của tất cả cloudSize
        final layoutW = _placements.isEmpty
            ? 120.0
            : _placements.map((p) => p.cloudSize.width).reduce(math.max);
        final layoutH = _placements.isEmpty
            ? 80.0
            : _placements.map((p) => p.cloudSize.height).reduce(math.max);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Topic ở giữa: size fit chữ + padding 10, ảnh cloud_center.png
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: CloudWidget(
                      size: null,
                      imageAsset: kCloudCenterImageAsset,
                      padding: const EdgeInsets.all(kCloudPaddingCenter),
                      child: Text(
                        widget.topicName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ),
                ),
                // Các từ xuất hiện từ tâm → ra xa
                ...List.generate(_placements.length, (i) {
                  final p = _placements[i];
                  final t = ((_controller.value - p.staggerDelay) / (1 - p.staggerDelay))
                      .clamp(0.0, 1.0);
                  final curveT = Curves.easeOutCubic.transform(t);

                  final cellLeft = centerX - layoutW / 2 +
                      (p.finalLeft - centerX + layoutW / 2) * curveT;
                  final cellTop = centerY - layoutH / 2 +
                      (p.finalTop - centerY + layoutH / 2) * curveT;
                  // Center cloud trong ô (cloud có thể nhỏ hơn ô)
                  final left = cellLeft + (layoutW - p.cloudSize.width) / 2;
                  final top = cellTop + (layoutH - p.cloudSize.height) / 2;
                  final scale = 0.3 + 0.7 * curveT;
                  final opacity = curveT;

                  return Positioned(
                    left: left.clamp(0.0, w - p.cloudSize.width),
                    top: top.clamp(0.0, h - p.cloudSize.height),
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.center,
                        child: CloudWidget(
                          size: p.cloudSize,
                          onTap: () => widget.onWordTap(p.word),
                          onLongPress: () => widget.onWordLongPress(p.word),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p.word.word,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.word.meaning,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[700],
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}
