import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// طبقة تحميل تغطي الشاشة أثناء العمليات التي تتطلب انتظارًا قصيرًا.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  /// بناء طبقة ضبابية مع مؤشر تحميل مخصص ورسالة انتظار.
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
        child: Container(
          color: Colors.black.withOpacity(0.65),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AnimatedHomeLoader(),
              const SizedBox(height: 32),
              const Text(
                'جاري تحضير الصفحة الرئيسية...',
                style: TextStyle(
                  fontFamily: 'ElMessiri',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// مؤشر تحميل متحرك مرسوم يدويًا ليتماشى مع هوية التطبيق.
class AnimatedHomeLoader extends StatefulWidget {
  const AnimatedHomeLoader({super.key});

  @override
  State<AnimatedHomeLoader> createState() => _AnimatedHomeLoaderState();
}

class _AnimatedHomeLoaderState extends State<AnimatedHomeLoader>
    with SingleTickerProviderStateMixin {
  /// متحكم الحركة الذي يعيد تشغيل الرسم بشكل دوري.
  late AnimationController _controller;

  @override
  /// بدء الحركة المتكررة عند إنشاء مؤشر التحميل.
  void initState() {
    super.initState();
    // 2.5 seconds loop for a slow, elegant sweep back and forth.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  /// التخلص من متحكم الحركة عند إزالة المؤشر من الشجرة.
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  /// إعادة رسم المؤشر مع كل تحديث لقيمة الحركة.
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: HomeRepairPainter(animationValue: _controller.value),
        );
      },
    );
  }
}

/// رسام مخصص يرسم منزلًا وأداة طلاء متحركة كمؤشر تحميل بصري.
class HomeRepairPainter extends CustomPainter {
  final double animationValue;

  /// تهيئة الرسام بقيمة الحركة الحالية للتحكم في موضع الأداة.
  HomeRepairPainter({required this.animationValue});

  @override
  /// رسم الشكل المتحرك بناءً على قيمة الحركة الحالية.
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cycle = animationValue * 2 * math.pi;

    // Smooth sine wave for roller X position
    // Sweeps from left (0.05 w) to right (0.95 w) and back.
    final rollerX = w * 0.5 - math.cos(cycle) * (w * 0.45);

    /// رسم المنزل بنسخته الشفافة أو الملونة بحسب جزء الحركة الحالي.
    void drawHouse(Canvas c, bool isColored) {
      final paint = Paint()
        ..style = isColored ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = isColored ? 0 : w * 0.015
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Chimney
      paint.color = isColored ? const Color(0xFFE64A19) : Colors.white24;
      final chimneyRect = Rect.fromLTRB(w * 0.65, h * 0.28, w * 0.72, h * 0.45);
      c.drawRRect(RRect.fromRectAndRadius(chimneyRect, Radius.circular(w * 0.01)), paint);

      // Base of the house
      paint.color = isColored ? const Color(0xFF1E88E5) : Colors.white24;
      final baseRect = Rect.fromLTRB(w * 0.25, h * 0.5, w * 0.75, h * 0.85);
      c.drawRRect(RRect.fromRectAndRadius(baseRect, Radius.circular(w * 0.04)), paint);

      // Door
      paint.color = isColored ? Colors.white : Colors.white24;
      final doorRect = Rect.fromLTRB(w * 0.42, h * 0.65, w * 0.58, h * 0.85);
      c.drawRRect(
        RRect.fromRectAndCorners(doorRect,
            topLeft: Radius.circular(w * 0.04),
            topRight: Radius.circular(w * 0.04)),
        paint,
      );

      // Window
      paint.color = isColored ? const Color(0xFF99F6E4) : Colors.white24;
      final windowRect = Rect.fromLTRB(w * 0.3, h * 0.55, w * 0.38, h * 0.63);
      c.drawRRect(RRect.fromRectAndRadius(windowRect, Radius.circular(w * 0.015)), paint);
      
      // Roof
      paint.color = isColored ? const Color(0xFF0F766E) : Colors.white24;
      final roofPath = Path();
      if (isColored) {
        roofPath.moveTo(w * 0.15, h * 0.55);
        roofPath.lineTo(w * 0.5, h * 0.25);
        roofPath.lineTo(w * 0.85, h * 0.55);
        roofPath.lineTo(w * 0.75, h * 0.55);
        roofPath.lineTo(w * 0.5, h * 0.35); // inner roof thickness
        roofPath.lineTo(w * 0.25, h * 0.55);
      } else {
        // Just the outline for uncolored form
        roofPath.moveTo(w * 0.15, h * 0.55);
        roofPath.lineTo(w * 0.5, h * 0.25);
        roofPath.lineTo(w * 0.85, h * 0.55);
      }
      roofPath.close();
      c.drawPath(roofPath, paint);
    }

    // 1. Draw Faint "Blueprint" House
    drawHouse(canvas, false);

    // 2. Draw Living Colored House (Clipped to the left of the roller)
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, rollerX, h));
    drawHouse(canvas, true);
    canvas.restore();

    // 3. Draw the Magic Paint Roller
    final rollerPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Roller Sponge (cyan/blue paint color)
    rollerPaint.color = const Color(0xFF14B8A6);
    final rollerRect = Rect.fromCenter(
        center: Offset(rollerX, h * 0.5), width: w * 0.08, height: h * 0.68);
    canvas.drawRRect(RRect.fromRectAndRadius(rollerRect, Radius.circular(w * 0.04)), rollerPaint);

    // Roller Bracket (Metal Frame)
    rollerPaint.color = const Color(0xFFB0BEC5);
    rollerPaint.style = PaintingStyle.stroke;
    rollerPaint.strokeWidth = w * 0.015;
    
    final bracketPath = Path();
    bracketPath.moveTo(rollerX, h * 0.16); // top pin
    bracketPath.lineTo(rollerX + w * 0.08, h * 0.16); // right arm
    bracketPath.lineTo(rollerX + w * 0.08, h * 0.88); // down external arm
    bracketPath.lineTo(rollerX + w * 0.03, h * 0.88); // back in towards handle
    canvas.drawPath(bracketPath, rollerPaint);

    // Handle
    rollerPaint.style = PaintingStyle.fill;
    rollerPaint.color = const Color(0xFF424242);
    final handleRect = Rect.fromCenter(
        center: Offset(rollerX + w * 0.03, h * 0.94),
        width: w * 0.035,
        height: h * 0.12);
    canvas.drawRRect(RRect.fromRectAndRadius(handleRect, Radius.circular(w * 0.02)), rollerPaint);
  }

  @override
  /// إعادة الرسم فقط عند تغير قيمة الحركة.
  bool shouldRepaint(HomeRepairPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
