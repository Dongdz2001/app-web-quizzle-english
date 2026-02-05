import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import 'cloud_widget.dart';

/// Vị trí cuối cùng của mỗi từ (gần tâm → xa dần theo thứ tự xuất hiện).
class _WordPlacement {
  _WordPlacement({
    required this.word,
    required this.finalLeft,
    required this.finalTop,
    required this.staggerDelay,
    required this.pathIndex,
  });

  final Vocabulary word;
  final double finalLeft;
  final double finalTop;
  final double staggerDelay;
  final int pathIndex;
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
  final _random = math.Random();

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
    final wordW = math.min(120, w * 0.25);
    final wordH = math.min(80, h * 0.15);

    final words = List<Vocabulary>.from(widget.words)..shuffle(_random);
    final count = words.length;
    var maxRadius = math.min(w, h) * 0.38;
    if (count > 6) {
      maxRadius *= (1 + (count - 6) * 0.04);
    }

    // Shuffle danh sách pathIndex để mỗi từ có hình đám mây ngẫu nhiên, phân bố đều
    final pathIndices = List.generate(cloudPathBuilders.length, (i) => i)..shuffle(_random);
    final placements = <_WordPlacement>[];
    for (var i = 0; i < count; i++) {
      // Từ gần tâm (i=0) → xa dần (i=count-1)
      final t = count <= 1 ? 1.0 : i / (count - 1);
      final radius = maxRadius * (0.15 + 0.85 * t);

      // Góc ngẫu nhiên để trông organic
      final angle = _random.nextDouble() * 2 * math.pi;

      final fx = centerX + radius * math.cos(angle) - wordW / 2;
      final fy = centerY + radius * math.sin(angle) - wordH / 2;

      // Stagger: từ xuất hiện trước gần tâm, delay nhỏ; từ xa hơn delay lớn hơn
      final staggerDelay = 0.15 + 0.25 * t;
      // Hình đám mây ngẫu nhiên cho mỗi từ (0..4), lặp nếu nhiều từ
      final pathIndex = pathIndices[i % pathIndices.length];

      placements.add(_WordPlacement(
        word: words[i],
        finalLeft: fx,
        finalTop: fy,
        staggerDelay: staggerDelay,
        pathIndex: pathIndex,
      ));
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

        if (_layoutSize != size) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _layoutSize != size) {
              setState(() {
                _layoutSize = size;
                _placements = _computePlacementsForSize(size);
                _controller
                  ..reset()
                  ..forward();
              });
            }
          });
        }

        final w = size.width;
        final h = size.height;
        final centerX = w / 2;
        final centerY = h / 2;
        final topicSize =
            Size(math.max(140, math.min(200, w * 0.4)), math.max(80, math.min(120, h * 0.22)));
        final wordSize =
            Size(math.max(100, math.min(140, w * 0.28)), math.max(70, math.min(90, h * 0.18)));

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Topic ở giữa
                Positioned(
                  left: centerX - topicSize.width / 2,
                  top: centerY - topicSize.height / 2,
                  child: CloudWidget(
                    size: topicSize,
                    child: Text(
                      widget.topicName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
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

                  final left = centerX - wordSize.width / 2 +
                      (p.finalLeft - centerX + wordSize.width / 2) * curveT;
                  final top = centerY - wordSize.height / 2 +
                      (p.finalTop - centerY + wordSize.height / 2) * curveT;
                  final scale = 0.3 + 0.7 * curveT;
                  final opacity = curveT;

                  return Positioned(
                    left: left.clamp(0.0, w - wordSize.width),
                    top: top.clamp(0.0, h - wordSize.height),
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.center,
                        child: CloudWidget(
                          size: wordSize,
                          pathIndex: p.pathIndex,
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.word.meaning,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey[700],
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
