import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemMouseCursors;
import '../models/vocabulary.dart';
import 'cloud_size_config.dart';
import 'cloud_widget.dart';

/// Quản lý animation và vị trí từ vựng theo quỹ đạo vòng tròn đồng tâm (cách đều, đối xứng tâm).
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
  int? _hoveredPlacementIndex;

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

    final cloudSizes = words.map((word) {
      return pickCloudSize(word, layoutBounds: size);
    }).toList();

    final wordW = cloudSizes.map((s) => s.width).reduce(math.max);
    final wordH = cloudSizes.map((s) => s.height).reduce(math.max);

    final placements = <_WordPlacement>[];
    var wordIndex = 0;
    final minDim = math.min(w, h);
    final radiusFactor = kIsWeb ? 0.18 : 0.32;
    var radius = kIsWeb ? minDim * radiusFactor : math.max(minDim * radiusFactor, 100.0);
    final radiusStep = wordH + 14;
    final spacing = 12.0;
    // Quỹ đạo ellipse: chiều ngang dài hơn (1.5), chiều dọc hẹp hơn (0.85)
    const ovalScaleX = 1.5;
    const ovalScaleY = 0.85;

    while (wordIndex < count) {
      final radiusX = radius * ovalScaleX;
      final radiusY = radius * ovalScaleY;
      // Chu vi ellipse gần đúng: π * (rx + ry)
      final perimeter = math.pi * (radiusX + radiusY);
      final cloudArc = wordW + spacing;
      final maxWordsOnCircle = math.max(1, (perimeter / cloudArc).floor());
      final wordsOnThisCircle = math.min(maxWordsOnCircle, count - wordIndex);

      for (var i = 0; i < wordsOnThisCircle; i++) {
        final angle = i * 2 * math.pi / wordsOnThisCircle;
        final cw = cloudSizes[wordIndex].width;
        final ch = cloudSizes[wordIndex].height;
        final fx = centerX + radiusX * math.cos(angle) - cw / 2;
        final fy = centerY + radiusY * math.sin(angle) - ch / 2;

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

        if (_layoutSize != size || _placements.length != widget.words.length) {
          _layoutSize = size;
          _placements = _computePlacementsForSize(size);
        }

        return AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < _placements.length; i++)
                    _buildWordCloud(_placements[i], index: i),
                  _buildCenterTopic(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCenterTopic() {
    // Tâm cụm đặt chính xác tại (width/2, height/2) - đối xứng hoàn toàn
    return Positioned(
      left: _layoutSize.width / 2,
      top: _layoutSize.height / 2,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: CloudWidget(
          size: null,
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
    );
  }

  String _fullInfoText(Vocabulary w) {
    final parts = <String>[
      w.word,
      w.meaning,
      if (w.wordForm.isNotEmpty) 'Loại từ: ${w.wordForm}',
      if (w.englishDefinition != null && w.englishDefinition!.isNotEmpty)
        'Definition: ${w.englishDefinition}',
      if (w.synonym != null && w.synonym!.isNotEmpty)
        'Từ đồng nghĩa: ${w.synonym}',
      if (w.antonym != null && w.antonym!.isNotEmpty)
        'Từ trái nghĩa: ${w.antonym}',
    ];
    return parts.join('\n');
  }

  Widget _buildWordCloud(_WordPlacement p, {required int index}) {
    final elapsed = _animController.value;
    final start = p.staggerDelay;
    final end = start + 0.6;
    final t = ((elapsed - start) / (end - start)).clamp(0.0, 1.0);
    final curve = Curves.easeOutCubic.transform(t);
    final isHovered = kIsWeb && _hoveredPlacementIndex == index;
    final baseScale = 0.5 + 0.5 * curve;

    const hoverScaleUp = 1.45;
    const hoverAnimDuration = Duration(milliseconds: 280);
    const hoverCurve = Curves.easeInOut;

    Widget content = Opacity(
      opacity: curve,
      child: kIsWeb
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: isHovered ? 1.0 : 0),
              duration: hoverAnimDuration,
              curve: hoverCurve,
              builder: (context, value, child) {
                final scale = baseScale * (1.0 + value * (hoverScaleUp - 1.0));
                return Transform.scale(scale: scale, child: child);
              },
              child: _cloudContent(p),
            )
          : Transform.scale(
              scale: baseScale,
              child: _cloudContent(p),
            ),
    );

    if (kIsWeb) {
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hoveredPlacementIndex = index),
        onExit: (_) => setState(() => _hoveredPlacementIndex = null),
        child: Tooltip(
          message: _fullInfoText(p.word),
          preferBelow: false,
          waitDuration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            color: const Color(0xFF2D3748),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.all(8),
          child: content,
        ),
      );
    }

    return Positioned(
      left: p.finalLeft,
      top: p.finalTop,
      child: content,
    );
  }

  Widget _cloudContent(_WordPlacement p) {
    return CloudWidget(
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
