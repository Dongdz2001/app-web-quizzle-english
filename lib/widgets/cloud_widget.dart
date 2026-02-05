import 'package:flutter/material.dart';

/// Đường dẫn ảnh đám mây không nền (các từ vựng).
const String kCloudImageAsset = 'assets/cloud.png';

/// Đường dẫn ảnh đám mây tâm/chủ đề (hồng/peach).
const String kCloudCenterImageAsset = 'assets/cloud_center.png';

/// Padding cho các từ vựng (nhiều hơn).
const double kCloudPaddingWords = 20;

/// Padding cho đám mây tâm/chủ đề (nhiều hơn).
const double kCloudPaddingCenter = 28;

/// Widget đám mây: dùng ảnh không nền, resize fit với text + padding.
/// [size]: null = fit nội dung + padding (dùng cho tâm cụm).
/// [imageAsset]: null = [kCloudImageAsset]; tâm dùng [kCloudCenterImageAsset].
class CloudWidget extends StatelessWidget {
  const CloudWidget({
    super.key,
    required this.child,
    this.size = const Size(120, 80),
    this.imageAsset,
    this.padding,
    this.tintColor,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  /// null = kích thước fit chữ + padding (cho tâm cụm).
  final Size? size;
  /// Ảnh nền; null = [kCloudImageAsset].
  final String? imageAsset;
  /// Padding bên trong đám mây; null = dùng [kCloudPaddingWords].
  final EdgeInsets? padding;
  /// Màu nhuộm đám mây; null = giữ ảnh gốc.
  final Color? tintColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final pad = padding ?? const EdgeInsets.all(kCloudPaddingWords);
    final asset = imageAsset ?? kCloudImageAsset;

    Widget imageWidget(String path) {
      Widget img = Image.asset(
        path,
        fit: size == null ? BoxFit.fill : BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.white,
          child: const Center(child: Icon(Icons.cloud)),
        ),
      );
      if (tintColor != null) {
        img = ColorFiltered(
          colorFilter: ColorFilter.mode(tintColor!, BlendMode.modulate),
          child: img,
        );
      }
      return img;
    }

    Widget cloud;
    if (size == null) {
      // Tâm cụm: fit chữ + padding
      cloud = IntrinsicWidth(
        child: IntrinsicHeight(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: imageWidget(asset),
              ),
              Padding(padding: pad, child: child),
            ],
          ),
        ),
      );
    } else {
      final padH = pad.horizontal;
      final padV = pad.vertical;
      cloud = SizedBox(
        width: size!.width,
        height: size!.height,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            imageWidget(asset),
            Padding(
              padding: pad,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: size!.width - padH,
                    maxHeight: size!.height - padV,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (onTap != null || onLongPress != null) {
      cloud = GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: cloud,
      );
    }

    return cloud;
  }
}
