import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../data/categories.dart';
import '../data/init_data_names.dart';
import '../data/init_data_color_label.dart';
import '../models/vocabulary.dart';
import 'cloud_size_config.dart';
import 'cloud_widget.dart';

/// Các thông số vị trí/size cho label người tạo.
/// Bạn chỉ cần chỉnh các hằng số này để đổi vị trí & kích thước
/// mà không phải sửa sâu trong widget.
const double kCreatorLabelWidth = 100;          // độ rộng label (px)
const double kCreatorLabelHeight = 18;         // chiều cao label (px)
const double kCreatorLabelTopOffset = 4;       // label lệch theo trục Y so với đám mây
const double kCreatorLabelRightOffset = 10;     // label lệch theo trục X so với đám mây
const double kCreatorLabelTextRightPadding = 5; // chữ lùi vào trong label từ mép phải
const double kCreatorLabelTextTopPadding = 4;    // chữ dịch xuống/dịch lên trong label
/// Kích thước đám mây tham chiếu để label zoom theo tỉ lệ.
const double kCreatorLabelRefCloudWidth = 100;
const double kCreatorLabelRefCloudHeight = 80;

/// Quản lý animation và vị trí từ vựng theo quỹ đạo vòng tròn đồng tâm (cách đều, đối xứng tâm).
class TopicCloudView extends StatefulWidget {
  final String topicName;
  final List<Vocabulary> words;
  final Function(Vocabulary) onWordTap;
  final Function(Vocabulary)? onWordDoubleTap;
  final Function(Vocabulary) onWordLongPress;
  /// Category ID để xác định cách hiển thị tên (ví dụ: grammar sẽ viết tắt)
  final String? categoryId;
  /// Khi set: tooltip không vẽ trong view (dùng để vẽ bên ngoài). [position] = toạ độ global chuột (để đặt tooltip dưới con trỏ).
  final void Function(String? text, Offset? position)? onGuideTextChanged;

  const TopicCloudView({
    super.key,
    required this.topicName,
    required this.words,
    required this.onWordTap,
    this.onWordDoubleTap,
    required this.onWordLongPress,
    this.categoryId,
    this.onGuideTextChanged,
  });

  @override
  State<TopicCloudView> createState() => _TopicCloudViewState();
}

class _TopicCloudViewState extends State<TopicCloudView>
    with SingleTickerProviderStateMixin {
  static const double _mobileHitSlop = 20;

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

    // Tính độ dài trung bình của các từ để xác định có phải grammar không
    final avgWordLength = words.map((w) => w.word.length).reduce((a, b) => a + b) / words.length;
    // Nếu độ dài trung bình > 15 ký tự (thường là câu grammar), tăng khoảng cách
    final isLongText = avgWordLength > 15;
    final radiusStepMultiplier = isLongText ? 2.0 : 1.0; // Tăng từ 1.5 lên 2.0 cho grammar
    final spacingMultiplier = isLongText ? 1.8 : 1.0; // Tăng khoảng cách giữa các đám mây trên cùng vòng tròn

    final placements = <_WordPlacement>[];
    var wordIndex = 0;
    final minDim = math.min(w, h);
    final radiusFactor = kIsWeb ? 0.18 : 0.32;
    var radius = kIsWeb ? minDim * radiusFactor : math.max(minDim * radiusFactor, 100.0);
    final radiusStep = (wordH + 14) * radiusStepMultiplier;
    final spacing = 12.0 * spacingMultiplier;
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

  /// So sánh nội dung words với _placements — nếu khác thì cần tính lại placement (sau khi sửa từ).
  bool _wordsContentChanged(List<Vocabulary> words) {
    if (_placements.length != words.length) return true;
    for (var i = 0; i < words.length; i++) {
      final a = _placements[i].word;
      final b = words[i];
      if (a.id != b.id ||
          a.word != b.word ||
          a.meaning != b.meaning ||
          a.englishDefinition != b.englishDefinition) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        final wordsContentChanged = _placements.length != widget.words.length ||
            _wordsContentChanged(widget.words);
        if (_layoutSize != size || wordsContentChanged) {
          _layoutSize = size;
          _placements = _computePlacementsForSize(size);
        }

        return AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return SizedBox(
              width: size.width,
              height: size.height,
              child: OverflowBox(
                minWidth: size.width,
                minHeight: size.height,
                maxWidth: size.width * 4,
                maxHeight: size.height * 4,
                alignment: Alignment.center,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                  // Render tất cả các đám mây không hover trước
                  for (var i = 0; i < _placements.length; i++)
                    if (_hoveredPlacementIndex != i)
                      _buildWordCloud(_placements[i], index: i),
                  // Render tâm cụm
                  _buildCenterTopic(),
                  // Render đám mây đang hover sau cùng (ở trên cùng) - đảm bảo z-index cao nhất
                  if (_hoveredPlacementIndex != null)
                    _buildWordCloud(_placements[_hoveredPlacementIndex!], index: _hoveredPlacementIndex!),
                  if (kIsWeb && widget.onGuideTextChanged == null)
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: true,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(top: 24, right: 24),
                            child: TopicCloudGuideHint(
                              text: _hoveredPlacementIndex != null
                                  ? _fullInfoText(
                                      _placements[_hoveredPlacementIndex!]
                                          .word,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
                ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Viết tắt tên tiếng Việt cho grammar: lấy chữ cái đầu của mỗi từ và in hoa, giữ lại phần tiếng Anh trong ngoặc đơn
  String _abbreviateVietnameseName(String name) {
    // Tách phần tiếng Việt và phần tiếng Anh trong ngoặc đơn
    String vietnamesePart = name;
    String? englishPart;
    
    if (name.contains('(')) {
      final openParenIndex = name.indexOf('(');
      vietnamesePart = name.substring(0, openParenIndex).trim();
      final closeParenIndex = name.indexOf(')', openParenIndex);
      if (closeParenIndex != -1) {
        englishPart = name.substring(openParenIndex, closeParenIndex + 1);
      } else {
        englishPart = name.substring(openParenIndex);
      }
    }
    
    // Loại bỏ \n nếu có
    vietnamesePart = vietnamesePart.replaceAll('\n', ' ').trim();
    
    // Tách thành các từ và lấy chữ cái đầu
    final words = vietnamesePart.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return name.toUpperCase();
    
    // Lấy chữ cái đầu của mỗi từ và in hoa
    final abbreviation = words.map((w) {
      // Lấy chữ cái đầu, bỏ qua dấu
      final firstChar = w[0];
      return firstChar.toUpperCase();
    }).join('');
    
    // Kết hợp viết tắt tiếng Việt với phần tiếng Anh trong ngoặc đơn, xuống dòng
    if (englishPart != null) {
      return '$abbreviation\n$englishPart';
    }
    
    return abbreviation;
  }

  Widget _buildCenterTopic() {
    // Tâm cụm đặt chính xác tại (width/2, height/2) - đối xứng hoàn toàn
    // Tự động xuống dòng cho tên dài (đặc biệt topic IPA có dấu ngoặc đơn)
    // Nếu tên đã có \n thì giữ nguyên để hiển thị xuống dòng
    String displayName = widget.topicName;
    
    // Nếu là grammar, viết tắt và in hoa tên tiếng Việt
    if (widget.categoryId == CategoryIds.grammar) {
      displayName = _abbreviateVietnameseName(displayName);
    } else {
      if (displayName.contains('(') && !displayName.contains('\n')) {
        // Thêm \n trước dấu ngoặc đơn để xuống dòng
        displayName = displayName.replaceFirst(' (', '\n(');
      }
    }
    // Nếu tên đã có \n (như "Thành ngữ\nthông dụng"), Text widget sẽ tự động hiển thị xuống dòng
    
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
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
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
        'Phiên âm: ${w.englishDefinition}',
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
              child: _cloudContent(p, showLabel: isHovered),
            )
          : Transform.scale(
              scale: baseScale,
              child: _cloudContent(p, showLabel: false),
            ),
    );

    if (kIsWeb) {
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() => _hoveredPlacementIndex = index);
          widget.onGuideTextChanged?.call(
            _fullInfoText(_placements[index].word),
            null,
          );
        },
        onHover: (event) {
          widget.onGuideTextChanged?.call(
            _fullInfoText(_placements[index].word),
            event.position,
          );
        },
        onExit: (_) {
          setState(() => _hoveredPlacementIndex = null);
          widget.onGuideTextChanged?.call(null, null);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (isHovered)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: AnimatedOpacity(
                    opacity: isHovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orangeAccent.withValues(alpha: 0.55),
                            blurRadius: 36,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            content,
          ],
        ),
      );
    }

    // Mobile: vùng chạm lớn hơn và không bị scale theo hiệu ứng.
    if (!kIsWeb) {
      final hitW = p.cloudSize.width + _mobileHitSlop * 2;
      final hitH = p.cloudSize.height + _mobileHitSlop * 2;
      content = SizedBox(
        width: hitW,
        height: hitH,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            content,
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onWordTap(p.word),
                onDoubleTap: widget.onWordDoubleTap != null
                    ? () => widget.onWordDoubleTap!(p.word)
                    : null,
                onLongPress: () => widget.onWordLongPress(p.word),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      );
    }

    return Positioned(
      left: kIsWeb ? p.finalLeft : p.finalLeft - _mobileHitSlop,
      top: kIsWeb ? p.finalTop : p.finalTop - _mobileHitSlop,
      child: content,
    );
  }

  Widget _cloudContent(_WordPlacement p, {bool showLabel = false}) {
    // Demo: mỗi đám mây 1 tên, 1 màu label, 1 màu đám mây (ngẫu nhiên).
    final seed = widget.topicName.hashCode ^ p.word.id.hashCode;
    final rnd = math.Random(seed);
    final demoName = initDataNames[rnd.nextInt(initDataNames.length)];
    final demoColor = initDataColors[rnd.nextInt(initDataColors.length)];
    final cloudColor = initDataColors[rnd.nextInt(initDataColors.length)];

    final cloud = CloudWidget(
      size: p.cloudSize,
      tintColor: cloudColor,
      onTap: kIsWeb ? () => widget.onWordTap(p.word) : null,
      onDoubleTap: kIsWeb && widget.onWordDoubleTap != null ? () => widget.onWordDoubleTap!(p.word) : null,
      onLongPress: kIsWeb ? () => widget.onWordLongPress(p.word) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            p.word.word,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (p.word.englishDefinition != null &&
              p.word.englishDefinition!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              p.word.englishDefinition!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[200],
              ),
            ),
          ],
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

    // Gắn label nhỏ ở góc trên bên phải đám mây; chỉ hiện khi hover (web).
    return Stack(
      clipBehavior: Clip.none,
      children: [
        cloud,
        if (showLabel)
          Positioned(
            top: kCreatorLabelTopOffset,
            right: kCreatorLabelRightOffset,
            child: _CreatorLabel(
              name: demoName,
              labelColor: demoColor,
              cloudSize: p.cloudSize,
            ),
          ),
      ],
    );
  }
}

/// Tooltip kiểu "tour guide" hoành tráng cho từng đám mây từ vựng trên web.
class _FancyWordGuideBubble extends StatelessWidget {
  final String text;

  const _FancyWordGuideBubble({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 480),
      builder: (context, value, child) {
        // Chỉ fade-in đơn giản
        final t = Curves.easeOut.transform(value).clamp(0.0, 1.0);

        return Opacity(
          opacity: t,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
              width: 1.4,
            ),
          ),
          child: DefaultTextStyle(
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ghi chú nhanh',
                      style: theme.textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Góc hướng dẫn: chỉ hiện tooltip khi có text (khi hover vào đám mây).
/// Public để màn hình có thể đặt cố định ngoài InteractiveViewer (không bị zoom).
class TopicCloudGuideHint extends StatelessWidget {
  final String? text;

  const TopicCloudGuideHint({this.text, super.key});

  @override
  Widget build(BuildContext context) {
    final hasText = text != null && text!.isNotEmpty;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: hasText
          ? _FancyWordGuideBubble(
              key: const ValueKey('guide-bubble'),
              text: text!,
            )
          : const SizedBox.shrink(key: ValueKey('guide-empty')),
    );
  }
}

/// Label ruy băng nhỏ để hiển thị tên người tạo.
/// Width tự động thu vào / dài ra theo nội dung chữ.
class _CreatorLabel extends StatelessWidget {
  final String name;
  final Color? labelColor;
  final Size? cloudSize;

  const _CreatorLabel({
    required this.name,
    this.labelColor,
    this.cloudSize,
  });

  @override
  Widget build(BuildContext context) {
    final scaleW = cloudSize != null
        ? (cloudSize!.width / kCreatorLabelRefCloudWidth).clamp(0.5, 2.0)
        : 1.0;
    final scaleH = cloudSize != null
        ? (cloudSize!.height / kCreatorLabelRefCloudHeight).clamp(0.5, 2.0)
        : 1.0;
    final h = kCreatorLabelHeight * scaleH;
    final textColor = labelColor != null
        ? (labelColor!.computeLuminance() > 0.5 ? Colors.black87 : Colors.white)
        : const Color.fromARGB(255, 98, 97, 97);
    final baseFontSize = (9 * (scaleW + scaleH) / 2).clamp(7.0, 12.0);
    final wordCount = name.trim().split(RegExp(r'\s+')).length;
    final fontSize = wordCount >= 5 ? (baseFontSize - 4).clamp(5.0, 12.0) : baseFontSize;
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: textColor,
    );

    Widget imageChild = Image.asset(
      'assets/label.png',
      fit: BoxFit.fill,
    );
    if (labelColor != null) {
      imageChild = ColorFiltered(
        colorFilter: ColorFilter.mode(
          labelColor!,
          BlendMode.modulate,
        ),
        child: imageChild,
      );
    }

    return SizedBox(
      height: h,
      child: IntrinsicWidth(
        child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Positioned.fill(
                child: imageChild,
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 6 * scaleW + 10,
                  right: kCreatorLabelTextRightPadding * scaleW + 2,
                  top: kCreatorLabelTextTopPadding * scaleH,
                ),
                child: Text(
                  name,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: textStyle,
                ),
              ),
            ],
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
