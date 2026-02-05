import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/vocabulary.dart';
import 'cloud_size_config.dart';
import 'cloud_widget.dart';

/// Quản lý animation và vị trí từ vựng theo quỹ đạo bầu dục đồng tâm.
class TopicCloudView extends StatefulWidget {
  final String topicName;
  final List<Vocabulary> words;
  final Function(Vocabulary) onWordTap;
  final Function(Vocabulary) onWordLongPress;

  const TopicCloudView({
    super.key,
    required this.topicName,
    required this.words,
    required this.onWordTap,
    required this.onWordLongPress,
  });

  @override
  State<TopicCloudView> createState() => _TopicCloudViewState();
}

class _TopicCloudViewState extends State<TopicCloudView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Size _layoutSize = Size.zero;
  List<_WordPlacement> _placements = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(TopicCloudView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu số lượng từ hoặc tên topic thay đổi, reset animation
    if (oldWidget.words.length != widget.words.length ||
        oldWidget.topicName != widget.topicName) {
      _animController.reset();
      _animController.forward();
    }
  }

  List<_WordPlacement> _computePlacementsForSize(Size size) {
    final count = widget.words.length;
    final words = widget.words;
    if (count == 0) return [];

    final w = size.width;
    final h = size.height;
    final centerX = w / 2;
    final centerY = h / 2;

    // Tính kích thước đám mây cho từng từ
    final cloudSizes = words.map((word) {
      return pickCloudSize(word, layoutBounds: size);
    }).toList();

    final wordW = cloudSizes.map((s) => s.width).reduce(math.max);
    final wordH = cloudSizes.map((s) => s.height).reduce(math.max);

    // Xếp từ theo hình bầu dục (ellipse) đồng tâm: rx theo chiều ngang, ry theo chiều dọc
    final placements = <_WordPlacement>[];
    var wordIndex = 0;
    var radius = math.min(w, h) * 0.18; // Bán kính cơ sở vòng đầu tiên
    final radiusStep = wordH + 14; // Bước tăng bán kính
    final spacing = 12.0;
    // Hệ số bầu dục: mở rộng ngang mạnh (1.65), giảm chiều cao (0.75)
    const ovalScaleX = 1.65;
    const ovalScaleY = 0.75;

    while (wordIndex < count) {
      final radiusX = radius * ovalScaleX; // Bán trục ngang
      final radiusY = radius * ovalScaleY; // Bán trục dọc
      // Chu vi ellipse gần đúng: π * (rx + ry)
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
          finalLeft: fx,
          finalTop: fy,
          staggerDelay: staggerDelay,
          cloudSize: cloudSizes[wordIndex],
        ));
        wordIndex++;
      }

      radius += radiusStep;
      // Không giới hạn radius: đặt hết từ, user kéo (InteractiveViewer) để xem
    }

    return placements;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        // Recompute nếu size thay đổi hoặc số lượng từ thay đổi
        if (_layoutSize != size || _placements.length != widget.words.length) {
          _layoutSize = size;
          _placements = _computePlacementsForSize(size);
        }

        return AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Vẽ các từ vựng
                for (final p in _placements) _buildWordCloud(p),
                // Tâm cụm (topic name)
                _buildCenterTopic(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCenterTopic() {
    return Positioned(
      left: _layoutSize.width / 2,
      top: _layoutSize.height / 2,
      child: Transform.translate(
        offset: const Offset(-0.5, -0.5),
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: CloudWidget(
            size: null, // Dynamic sizing
            imageAsset: kCloudCenterImageAsset,
            padding: const EdgeInsets.all(kCloudPaddingCenter),
            child: Text(
              widget.topicName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordCloud(_WordPlacement p) {
    final elapsed = _animController.value;
    final start = p.staggerDelay;
    final end = start + 0.6;
    final t = ((elapsed - start) / (end - start)).clamp(0.0, 1.0);
    final curve = Curves.easeOutCubic.transform(t);

    return Positioned(
      left: p.finalLeft,
      top: p.finalTop,
      child: Opacity(
        opacity: curve,
        child: Transform.scale(
          scale: 0.5 + 0.5 * curve,
          child: CloudWidget(
            size: p.cloudSize,
            onTap: () => widget.onWordTap(p.word),
            onLongPress: () => widget.onWordLongPress(p.word),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.word.word,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.word.meaning,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WordPlacement {
  final Vocabulary word;
  final double finalLeft;
  final double finalTop;
  final double staggerDelay;
  final Size cloudSize;

  _WordPlacement({
    required this.word,
    required this.finalLeft,
    required this.finalTop,
    required this.staggerDelay,
    required this.cloudSize,
  });
}
