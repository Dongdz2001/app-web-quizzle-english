import 'package:flutter/material.dart';

/// Kiểu hàm tạo path đám mây theo size.
typedef CloudPathBuilder = Path Function(Size size);

/// Path 1: Đám mây cân đối, bo tròn mềm (original).
Path cloudPath1(Size size) {
  final w = size.width;
  final h = size.height;
  final path = Path();
  path.moveTo(w * 0.2, h * 0.6);
  path.quadraticBezierTo(w * 0.1, h * 0.3, w * 0.3, h * 0.3);
  path.quadraticBezierTo(w * 0.35, h * 0.1, w * 0.5, h * 0.25);
  path.quadraticBezierTo(w * 0.65, h * 0.05, w * 0.75, h * 0.3);
  path.quadraticBezierTo(w * 0.95, h * 0.35, w * 0.85, h * 0.6);
  path.quadraticBezierTo(w * 0.85, h * 0.85, w * 0.6, h * 0.85);
  path.lineTo(w * 0.3, h * 0.85);
  path.quadraticBezierTo(w * 0.1, h * 0.85, w * 0.2, h * 0.6);
  path.close();
  return path;
}

/// Path 2: Cao, hẹp – đám mây dọc, nhiều bướu trên.
Path cloudPath2(Size size) {
  final w = size.width;
  final h = size.height;
  final path = Path();
  path.moveTo(w * 0.35, h * 0.7);
  path.quadraticBezierTo(w * 0.2, h * 0.7, w * 0.25, h * 0.5);
  path.quadraticBezierTo(w * 0.15, h * 0.35, w * 0.35, h * 0.25);
  path.quadraticBezierTo(w * 0.4, h * 0.05, w * 0.5, h * 0.15);
  path.quadraticBezierTo(w * 0.6, h * 0.02, w * 0.65, h * 0.25);
  path.quadraticBezierTo(w * 0.85, h * 0.2, w * 0.75, h * 0.5);
  path.quadraticBezierTo(w * 0.9, h * 0.55, w * 0.8, h * 0.75);
  path.quadraticBezierTo(w * 0.75, h * 0.92, w * 0.5, h * 0.9);
  path.quadraticBezierTo(w * 0.25, h * 0.9, w * 0.35, h * 0.7);
  path.close();
  return path;
}

/// Path 3: Rộng, dẹt – đám mây ngang, trải dài.
Path cloudPath3(Size size) {
  final w = size.width;
  final h = size.height;
  final path = Path();
  path.moveTo(w * 0.08, h * 0.5);
  path.quadraticBezierTo(w * 0.02, h * 0.35, w * 0.15, h * 0.3);
  path.quadraticBezierTo(w * 0.12, h * 0.1, w * 0.3, h * 0.2);
  path.quadraticBezierTo(w * 0.35, h * 0.05, w * 0.5, h * 0.15);
  path.quadraticBezierTo(w * 0.65, h * 0.02, w * 0.7, h * 0.2);
  path.quadraticBezierTo(w * 0.88, h * 0.08, w * 0.85, h * 0.3);
  path.quadraticBezierTo(w * 0.98, h * 0.35, w * 0.92, h * 0.5);
  path.quadraticBezierTo(w * 0.95, h * 0.75, w * 0.7, h * 0.8);
  path.lineTo(w * 0.3, h * 0.8);
  path.quadraticBezierTo(w * 0.05, h * 0.78, w * 0.08, h * 0.5);
  path.close();
  return path;
}

/// Path 4: Lệch phải – đám mây không đối xứng.
Path cloudPath4(Size size) {
  final w = size.width;
  final h = size.height;
  final path = Path();
  path.moveTo(w * 0.15, h * 0.65);
  path.quadraticBezierTo(w * 0.05, h * 0.5, w * 0.2, h * 0.35);
  path.quadraticBezierTo(w * 0.25, h * 0.1, w * 0.45, h * 0.2);
  path.quadraticBezierTo(w * 0.55, h * 0.05, w * 0.75, h * 0.25);
  path.quadraticBezierTo(w * 0.95, h * 0.2, w * 0.9, h * 0.45);
  path.quadraticBezierTo(w * 0.98, h * 0.6, w * 0.85, h * 0.75);
  path.quadraticBezierTo(w * 0.8, h * 0.95, w * 0.5, h * 0.88);
  path.quadraticBezierTo(w * 0.2, h * 0.85, w * 0.15, h * 0.65);
  path.close();
  return path;
}

/// Path 5: Nhỏ gọn – đám mây tròn, ít bướu.
Path cloudPath5(Size size) {
  final w = size.width;
  final h = size.height;
  final path = Path();
  path.moveTo(w * 0.25, h * 0.55);
  path.quadraticBezierTo(w * 0.1, h * 0.4, w * 0.25, h * 0.3);
  path.quadraticBezierTo(w * 0.3, h * 0.12, w * 0.5, h * 0.2);
  path.quadraticBezierTo(w * 0.7, h * 0.1, w * 0.75, h * 0.3);
  path.quadraticBezierTo(w * 0.92, h * 0.35, w * 0.85, h * 0.55);
  path.quadraticBezierTo(w * 0.88, h * 0.82, w * 0.55, h * 0.82);
  path.quadraticBezierTo(w * 0.2, h * 0.8, w * 0.25, h * 0.55);
  path.close();
  return path;
}

/// Danh sách các path đám mây để random.
final List<CloudPathBuilder> cloudPathBuilders = [
  cloudPath1,
  cloudPath2,
  cloudPath3,
  cloudPath4,
  cloudPath5,
];

/// Lấy path đám mây theo [index] (0..4). Dùng 0 nếu index null.
Path cloudPath(Size size, [int? index]) {
  final i = (index ?? 0).clamp(0, cloudPathBuilders.length - 1);
  return cloudPathBuilders[i](size);
}

/// Vẽ hình đám mây bằng Path + Bezier curve, bo tròn mềm như mây thật.
class CloudPainter extends CustomPainter {
  CloudPainter({
    required this.strokeColor,
    this.strokeWidth = 2,
    this.fillColor = Colors.white,
    int? pathIndex,
  }) : pathIndex = pathIndex ?? 0;

  final Color strokeColor;
  final double strokeWidth;
  final Color fillColor;
  final int pathIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final path = cloudPath(size, pathIndex);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CloudPainter oldDelegate) =>
      strokeColor != oldDelegate.strokeColor ||
      fillColor != oldDelegate.fillColor ||
      strokeWidth != oldDelegate.strokeWidth ||
      pathIndex != oldDelegate.pathIndex;
}

/// Hằng số padding bên trong đám mây (đủ để text không bị cắt bởi viền cong).
const double kCloudInternalPadding = 12;

/// Widget đám mây: vẽ bằng Path + Bezier curve, viền xanh, nền trắng,
/// fit content với padding bên trong 5.
/// [pathIndex]: 0..4 để chọn hình dạng đám mây khác nhau.
class CloudWidget extends StatelessWidget {
  const CloudWidget({
    super.key,
    required this.child,
    this.size = const Size(120, 80),
    this.strokeColor,
    int? pathIndex,
    this.onTap,
    this.onLongPress,
  }) : pathIndex = pathIndex ?? 0;

  final Widget child;
  final Size size;
  final Color? strokeColor;
  final int pathIndex;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = strokeColor ?? Theme.of(context).colorScheme.primary;

    Widget cloud = SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: size,
            painter: CloudPainter(
              strokeColor: color,
              fillColor: Colors.white,
              pathIndex: pathIndex,
            ),
          ),
          ClipPath(
            clipper: _CloudPathClipper(size, pathIndex),
            child: Padding(
              padding: const EdgeInsets.all(kCloudInternalPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: size.width - kCloudInternalPadding * 2,
                    maxHeight: size.height - kCloudInternalPadding * 2,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

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

class _CloudPathClipper extends CustomClipper<Path> {
  _CloudPathClipper(this.size, [int? pathIndex]) : pathIndex = pathIndex ?? 0;

  final Size size;
  final int pathIndex;

  @override
  Path getClip(Size size) => cloudPath(size, pathIndex);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldDelegate) =>
      oldDelegate is _CloudPathClipper &&
      (oldDelegate.size != size || oldDelegate.pathIndex != pathIndex);
}
