import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

enum AuthIllustrationType {
  login,
  register,
  forgotPassword,
}

/// A lightweight, pure Flutter vector illustration widget for MeMe authentication screens.
/// Features a finance-themed visual (wallet, card, coins, sprout, and ambient scenery)
/// that displays in a clean, airy light aesthetic by default as requested.
class AuthIllustration extends StatelessWidget {
  final AuthIllustrationType type;
  final double height;
  final Widget? topLeading;
  final bool forceLight;

  const AuthIllustration({
    super.key,
    required this.type,
    this.height = 220,
    this.topLeading,
    this.forceLight = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = forceLight ? false : AppColors.isDark(context);
    final topPadding = MediaQuery.of(context).padding.top;
    final totalHeight = height + topPadding;

    final CustomPainter painter;
    switch (type) {
      case AuthIllustrationType.login:
        painter = _LoginFinancePainter(isDark: isDark, topPadding: topPadding);
        break;
      case AuthIllustrationType.register:
        painter = _RegisterFinancePainter(isDark: isDark, topPadding: topPadding);
        break;
      case AuthIllustrationType.forgotPassword:
        painter = _ForgotPasswordFinancePainter(isDark: isDark, topPadding: topPadding);
        break;
    }

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Vector Painting
          CustomPaint(
            painter: painter,
          ),

          // Optional top-leading action (e.g. back button)
          if (topLeading != null)
            Positioned(
              top: topPadding + 8,
              left: 18,
              child: topLeading!,
            ),
        ],
      ),
    );
  }
}

/// Custom painter for Login screen illustration:
/// Soft layered hills in the backdrop, a stylish 3D MeMe wallet,
/// a peeking payment card, floating savings coin, and financial sparkles.
class _LoginFinancePainter extends CustomPainter {
  final bool isDark;
  final double topPadding;

  _LoginFinancePainter({
    required this.isDark,
    required this.topPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sky / Ambient background gradient
    final bgRect = Offset.zero & size;
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [
              Color(0xFF0F121C),
              Color(0xFF131724),
              Color(0xFF191D2C),
            ]
          : const [
              Color(0xFFDFECFA),
              Color(0xFFEAF3FC),
              Color(0xFFF3F7FD),
            ],
    );
    final bgPaint = Paint()..shader = bgGradient.createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // 2. Far distant hills / mountain silhouettes for depth
    final farMountainPath = Path();
    farMountainPath.moveTo(0, size.height * 0.68);
    farMountainPath.cubicTo(
      size.width * 0.25,
      size.height * 0.50,
      size.width * 0.45,
      size.height * 0.58,
      size.width * 0.70,
      size.height * 0.46,
    );
    farMountainPath.cubicTo(
      size.width * 0.85,
      size.height * 0.38,
      size.width * 0.95,
      size.height * 0.44,
      size.width,
      size.height * 0.48,
    );
    farMountainPath.lineTo(size.width, size.height);
    farMountainPath.lineTo(0, size.height);
    farMountainPath.close();

    final farMountainPaint = Paint()
      ..color = isDark ? const Color(0xFF1A1F30) : const Color(0xFFD3E3F5);
    canvas.drawPath(farMountainPath, farMountainPaint);

    // 3. Near mountain silhouette
    final nearMountainPath = Path();
    nearMountainPath.moveTo(0, size.height * 0.60);
    nearMountainPath.cubicTo(
      size.width * 0.15,
      size.height * 0.48,
      size.width * 0.35,
      size.height * 0.62,
      size.width * 0.55,
      size.height * 0.53,
    );
    nearMountainPath.cubicTo(
      size.width * 0.75,
      size.height * 0.46,
      size.width * 0.90,
      size.height * 0.60,
      size.width,
      size.height * 0.55,
    );
    nearMountainPath.lineTo(size.width, size.height);
    nearMountainPath.lineTo(0, size.height);
    nearMountainPath.close();

    final nearMountainPaint = Paint()
      ..color = isDark ? const Color(0xFF22293F) : const Color(0xFFC5DAF2);
    canvas.drawPath(nearMountainPath, nearMountainPaint);

    // 4. Soft atmospheric clouds in the upper sky
    _drawCloud(
      canvas,
      center: Offset(size.width * 0.22, topPadding + 28),
      scale: 0.9,
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.white.withValues(alpha: 0.75),
    );
    _drawCloud(
      canvas,
      center: Offset(size.width * 0.82, topPadding + 32),
      scale: 1.1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white.withValues(alpha: 0.85),
    );

    // 5. Central Financial Visual (Wallet + Card + Gold Coin)
    final centerX = size.width * 0.5;
    final centerY = topPadding + (size.height - topPadding) * 0.40;

    // Ground shadow for the wallet
    final shadowPaint = Paint()
      ..color = (isDark ? Colors.black : const Color(0xFF1E355B))
          .withValues(alpha: isDark ? 0.4 : 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 6, centerY + 46),
        width: 140,
        height: 22,
      ),
      shadowPaint,
    );

    // A. Peeking Card (tilted behind wallet)
    canvas.save();
    canvas.translate(centerX - 10, centerY - 14);
    canvas.rotate(-12 * math.pi / 180);

    final cardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-48, -32, 96, 62),
      const Radius.circular(10),
    );
    final cardShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF8B7CFF),
        Color(0xFF6B58F8),
        Color(0xFFFF7AD9),
      ],
    ).createShader(cardRect.outerRect);
    canvas.drawRRect(cardRect, Paint()..shader = cardShader);

    // Card metallic chip
    final chipRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-36, -18, 16, 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      chipRect,
      Paint()..color = const Color(0xFFFFD166),
    );
    final chipLinePaint = Paint()
      ..color = const Color(0xFFC79800)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-28, -18), const Offset(-28, -6), chipLinePaint);
    canvas.drawLine(const Offset(-36, -12), const Offset(-20, -12), chipLinePaint);

    final cardLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawArc(
      const Rect.fromLTWH(-10, -25, 55, 55),
      math.pi * 0.8,
      math.pi * 0.6,
      false,
      cardLinePaint,
    );

    canvas.restore();

    // B. Main 3D Wallet Body
    canvas.save();
    canvas.translate(centerX + 4, centerY + 4);

    final walletRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-62, -26, 124, 68),
      const Radius.circular(16),
    );

    final walletShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [
              Color(0xFF5D96F8),
              Color(0xFF3B72DA),
              Color(0xFF2450A4),
            ]
          : const [
              Color(0xFF74A8FA),
              Color(0xFF4C8DF5),
              Color(0xFF2E6FD9),
            ],
    ).createShader(walletRRect.outerRect);
    canvas.drawRRect(walletRRect, Paint()..shader = walletShader);

    final flapPath = Path();
    flapPath.moveTo(-62, -26);
    flapPath.lineTo(62, -26);
    flapPath.lineTo(62, -4);
    flapPath.quadraticBezierTo(0, 16, -62, -4);
    flapPath.close();

    final flapShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: 0.25),
        Colors.white.withValues(alpha: 0.05),
      ],
    ).createShader(walletRRect.outerRect);
    canvas.drawPath(flapPath, Paint()..shader = flapShader);

    final walletEdgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(walletRRect, walletEdgePaint);

    final claspCenter = const Offset(0, 4);
    canvas.drawCircle(
      claspCenter,
      8.5,
      Paint()..color = const Color(0xFFFFC857),
    );
    canvas.drawCircle(
      claspCenter,
      8.5,
      Paint()
        ..color = const Color(0xFFFFAE19)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      claspCenter.translate(-2, -2),
      2.5,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );

    canvas.restore();

    // C. Floating Savings Gold Coin (right foreground)
    final coinCenter = Offset(centerX + 64, centerY - 6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(coinCenter.dx, coinCenter.dy + 26),
        width: 32,
        height: 8,
      ),
      shadowPaint,
    );

    final coinOuterShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFDF7A),
        Color(0xFFFFB800),
        Color(0xFFE59400),
      ],
    ).createShader(Rect.fromCircle(center: coinCenter, radius: 18));
    canvas.drawCircle(coinCenter, 18, Paint()..shader = coinOuterShader);

    final coinInnerShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFC83B),
        Color(0xFFFFA000),
      ],
    ).createShader(Rect.fromCircle(center: coinCenter, radius: 14));
    canvas.drawCircle(coinCenter, 14, Paint()..shader = coinInnerShader);

    final coinSymbolPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(coinCenter.dx - 6, coinCenter.dy),
      Offset(coinCenter.dx + 6, coinCenter.dy),
      coinSymbolPaint,
    );
    canvas.drawLine(
      Offset(coinCenter.dx, coinCenter.dy - 6),
      Offset(coinCenter.dx, coinCenter.dy + 6),
      coinSymbolPaint,
    );

    // D. Decorative Sparkles
    _drawSparkle(
      canvas,
      center: Offset(centerX - 68, centerY - 28),
      size: 9,
      color: isDark ? const Color(0xFF79AFFF) : const Color(0xFF4A90E2),
    );
    _drawSparkle(
      canvas,
      center: Offset(centerX + 86, centerY - 34),
      size: 7,
      color: const Color(0xFFFFC857),
    );
    _drawSparkle(
      canvas,
      center: Offset(centerX + 32, centerY - 48),
      size: 11,
      color: isDark ? const Color(0xFFFF7AD9) : const Color(0xFF8B7CFF),
    );
  }

  void _drawCloud(
    Canvas canvas, {
    required Offset center,
    required double scale,
    required Color color,
  }) {
    final paint = Paint()..color = color;
    canvas.drawCircle(center, 18 * scale, paint);
    canvas.drawCircle(Offset(center.dx - 14 * scale, center.dy + 4 * scale), 12 * scale, paint);
    canvas.drawCircle(Offset(center.dx + 16 * scale, center.dy + 2 * scale), 14 * scale, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 8 * scale),
          width: 44 * scale,
          height: 16 * scale,
        ),
        Radius.circular(8 * scale),
      ),
      paint,
    );
  }

  void _drawSparkle(
    Canvas canvas, {
    required Offset center,
    required double size,
    required Color color,
  }) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _LoginFinancePainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.topPadding != topPadding;
  }
}

/// Custom painter for Register screen illustration:
/// Airy cloud layers, welcoming savings vault/pot,
/// coin dropping with gentle trail, green sprout leaf (from MeMe logo!), and sparkles.
class _RegisterFinancePainter extends CustomPainter {
  final bool isDark;
  final double topPadding;

  _RegisterFinancePainter({
    required this.isDark,
    required this.topPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sky background gradient
    final bgRect = Offset.zero & size;
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [
              Color(0xFF0D1019),
              Color(0xFF141825),
              Color(0xFF1B1F30),
            ]
          : const [
              Color(0xFFDCEAF9),
              Color(0xFFE8F1FC),
              Color(0xFFF3F7FD),
            ],
    );
    canvas.drawRect(bgRect, Paint()..shader = bgGradient.createShader(bgRect));

    // 2. 3D Cloud Cluster
    final cloudCenter = Offset(size.width * 0.72, topPadding + 36);
    _draw3DCloudCluster(canvas, center: cloudCenter, isDark: isDark);

    // Left ambient cloud
    final leftCloudCenter = Offset(size.width * 0.16, topPadding + 58);
    _drawSoftCloud(
      canvas,
      center: leftCloudCenter,
      scale: 0.85,
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white.withValues(alpha: 0.75),
    );

    // 3. Central Financial Savings Element (Piggy Bank / Vault Pot with Sprout)
    final centerX = size.width * 0.44;
    final centerY = topPadding + (size.height - topPadding) * 0.42;

    // Soft ground shadow
    final shadowPaint = Paint()
      ..color = (isDark ? Colors.black : const Color(0xFF1A335A))
          .withValues(alpha: isDark ? 0.38 : 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY + 38),
        width: 110,
        height: 18,
      ),
      shadowPaint,
    );

    // Main Vault / Savings Pot Body
    final potRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, centerY + 4), width: 92, height: 64),
      const Radius.circular(24),
    );

    final potShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [
              Color(0xFF5A93F5),
              Color(0xFF3A72DA),
              Color(0xFF2652A8),
            ]
          : const [
              Color(0xFF78ACFB),
              Color(0xFF4C8DF5),
              Color(0xFF2C6ED8),
            ],
    ).createShader(potRect.outerRect);
    canvas.drawRRect(potRect, Paint()..shader = potShader);

    // Pot top rim / slot
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, centerY - 24), width: 54, height: 10),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      rimRect,
      Paint()
        ..color = isDark ? const Color(0xFF24488F) : const Color(0xFF255EBE),
    );

    final slotRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, centerY - 24), width: 26, height: 4),
      const Radius.circular(2),
    );
    canvas.drawRRect(
      slotRect,
      Paint()..color = const Color(0xFF122C5C),
    );

    // MeMe Sprout Leaf emerging from the pot
    canvas.save();
    canvas.translate(centerX - 16, centerY - 32);

    final leafPath = Path();
    leafPath.moveTo(0, 8);
    leafPath.quadraticBezierTo(-12, -4, -6, -14);
    leafPath.quadraticBezierTo(2, -6, 0, 8);
    leafPath.close();

    final leafShader = const LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        Color(0xFF2E9E5B),
        Color(0xFF47CF7F),
      ],
    ).createShader(const Rect.fromLTWH(-14, -14, 16, 22));
    canvas.drawPath(leafPath, Paint()..shader = leafShader);

    final leaf2Path = Path();
    leaf2Path.moveTo(0, 8);
    leaf2Path.quadraticBezierTo(10, 0, 8, -8);
    leaf2Path.quadraticBezierTo(0, -4, 0, 8);
    leaf2Path.close();
    canvas.drawPath(
      leaf2Path,
      Paint()..color = const Color(0xFF5CE393),
    );

    canvas.restore();

    // 4. Dropping Golden Coin
    final coinCenter = Offset(centerX + 8, centerY - 42);

    final motionPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF4A90E2))
          .withValues(alpha: 0.3)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final motionPath = Path();
    motionPath.moveTo(coinCenter.dx + 4, coinCenter.dy - 18);
    motionPath.quadraticBezierTo(
      coinCenter.dx + 6,
      coinCenter.dy - 8,
      coinCenter.dx,
      coinCenter.dy - 2,
    );
    canvas.drawPath(motionPath, motionPaint);

    final coinShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFDF7A),
        Color(0xFFFFB800),
        Color(0xFFE59400),
      ],
    ).createShader(Rect.fromCircle(center: coinCenter, radius: 15));
    canvas.drawCircle(coinCenter, 15, Paint()..shader = coinShader);

    final coinInnerShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFC83B),
        Color(0xFFFFA000),
      ],
    ).createShader(Rect.fromCircle(center: coinCenter, radius: 11));
    canvas.drawCircle(coinCenter, 11, Paint()..shader = coinInnerShader);

    _drawSparkle(
      canvas,
      center: coinCenter,
      size: 5,
      color: Colors.white.withValues(alpha: 0.95),
    );

    // 5. Celebration Sparkles
    _drawSparkle(
      canvas,
      center: Offset(centerX - 56, centerY + 8),
      size: 8,
      color: isDark ? const Color(0xFF79AFFF) : const Color(0xFF4A90E2),
    );
    _drawSparkle(
      canvas,
      center: Offset(centerX + 62, centerY + 18),
      size: 9,
      color: const Color(0xFFFFC857),
    );
    _drawSparkle(
      canvas,
      center: Offset(centerX + 44, centerY - 64),
      size: 7,
      color: const Color(0xFFFF7AD9),
    );
  }

  void _draw3DCloudCluster(Canvas canvas, {required Offset center, required bool isDark}) {
    final cloudBaseColor = isDark ? const Color(0xFF282F44) : Colors.white;
    final cloudShadowColor = isDark ? const Color(0xFF1E2333) : const Color(0xFFD6E3F2);

    void drawPuff(Offset offset, double radius) {
      final rect = Rect.fromCircle(center: offset, radius: radius);
      final puffShader = RadialGradient(
        center: const Alignment(-0.25, -0.35),
        radius: 0.85,
        colors: [
          cloudBaseColor,
          cloudBaseColor,
          cloudShadowColor,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect);

      canvas.drawCircle(offset, radius, Paint()..shader = puffShader);
    }

    drawPuff(Offset(center.dx - 22, center.dy + 4), 22);
    drawPuff(Offset(center.dx + 20, center.dy + 6), 24);
    drawPuff(Offset(center.dx - 2, center.dy - 10), 28);
    drawPuff(Offset(center.dx + 38, center.dy + 12), 16);
    drawPuff(Offset(center.dx - 38, center.dy + 10), 15);
  }

  void _drawSoftCloud(
    Canvas canvas, {
    required Offset center,
    required double scale,
    required Color color,
  }) {
    final paint = Paint()..color = color;
    canvas.drawCircle(center, 16 * scale, paint);
    canvas.drawCircle(Offset(center.dx - 12 * scale, center.dy + 3 * scale), 10 * scale, paint);
    canvas.drawCircle(Offset(center.dx + 14 * scale, center.dy + 2 * scale), 12 * scale, paint);
  }

  void _drawSparkle(
    Canvas canvas, {
    required Offset center,
    required double size,
    required Color color,
  }) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RegisterFinancePainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.topPadding != topPadding;
  }
}

/// Custom painter for Forgot Password screen illustration:
/// Soft sky backdrop, 3D MeMe safety padlock with metallic silver shackle,
/// a golden rescue key, and security sparkles.
class _ForgotPasswordFinancePainter extends CustomPainter {
  final bool isDark;
  final double topPadding;

  _ForgotPasswordFinancePainter({
    required this.isDark,
    required this.topPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sky background gradient
    final bgRect = Offset.zero & size;
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [
              Color(0xFF0F121C),
              Color(0xFF131724),
              Color(0xFF191D2C),
            ]
          : const [
              Color(0xFFDFECFA),
              Color(0xFFEAF3FC),
              Color(0xFFF3F7FD),
            ],
    );
    canvas.drawRect(bgRect, Paint()..shader = bgGradient.createShader(bgRect));

    // 2. Soft clouds
    _drawCloud(
      canvas,
      center: Offset(size.width * 0.20, topPadding + 28),
      scale: 0.9,
      color: Colors.white.withValues(alpha: 0.8),
    );
    _drawCloud(
      canvas,
      center: Offset(size.width * 0.80, topPadding + 32),
      scale: 1.05,
      color: Colors.white.withValues(alpha: 0.85),
    );

    // 3. Central Security Visual (Padlock + Key)
    final centerX = size.width * 0.5;
    final centerY = topPadding + (size.height - topPadding) * 0.42;

    // Ground shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF1E355B).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY + 44),
        width: 120,
        height: 20,
      ),
      shadowPaint,
    );

    // Padlock Shackle (curved arch behind the lock body)
    final shacklePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFD6DFEC),
          Color(0xFFA5B4C7),
        ],
      ).createShader(Rect.fromLTWH(centerX - 28, centerY - 52, 56, 56));

    final shacklePath = Path();
    shacklePath.moveTo(centerX - 24, centerY - 6);
    shacklePath.lineTo(centerX - 24, centerY - 28);
    shacklePath.arcToPoint(
      Offset(centerX + 24, centerY - 28),
      radius: const Radius.circular(24),
      clockwise: true,
    );
    shacklePath.lineTo(centerX + 24, centerY - 6);
    canvas.drawPath(shacklePath, shacklePaint);

    // Padlock Main Body
    final lockRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX - 8, centerY + 8), width: 90, height: 68),
      const Radius.circular(18),
    );

    final lockShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF74A8FA),
        Color(0xFF4C8DF5),
        Color(0xFF2E6FD9),
      ],
    ).createShader(lockRect.outerRect);
    canvas.drawRRect(lockRect, Paint()..shader = lockShader);

    // Edge highlight
    canvas.drawRRect(
      lockRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Keyhole circle & slot
    final keyholeCenter = Offset(centerX - 8, centerY + 4);
    canvas.drawCircle(
      keyholeCenter,
      7,
      Paint()..color = const Color(0xFF122C5C),
    );
    final keyholeSlot = Path();
    keyholeSlot.moveTo(keyholeCenter.dx - 3, keyholeCenter.dy + 4);
    keyholeSlot.lineTo(keyholeCenter.dx - 5, keyholeCenter.dy + 16);
    keyholeSlot.lineTo(keyholeCenter.dx + 5, keyholeCenter.dy + 16);
    keyholeSlot.lineTo(keyholeCenter.dx + 3, keyholeCenter.dy + 4);
    keyholeSlot.close();
    canvas.drawPath(keyholeSlot, Paint()..color = const Color(0xFF122C5C));

    // 4. Floating Golden Rescue Key
    canvas.save();
    canvas.translate(centerX + 48, centerY - 10);
    canvas.rotate(24 * math.pi / 180);

    // Key ring
    final keyRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFDF7A), Color(0xFFFFB800)],
      ).createShader(const Rect.fromLTWH(-12, -12, 24, 24));
    canvas.drawCircle(Offset.zero, 11, keyRingPaint);

    // Key shaft
    final keyShaftPaint = Paint()
      ..color = const Color(0xFFFFB800)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(11, 0), const Offset(36, 0), keyShaftPaint);

    // Key teeth
    canvas.drawLine(const Offset(28, 0), const Offset(28, 7), keyShaftPaint);
    canvas.drawLine(const Offset(34, 0), const Offset(34, 9), keyShaftPaint);

    canvas.restore();

    // 5. Sparkles
    _drawSparkle(
      canvas,
      center: Offset(centerX - 58, centerY - 24),
      size: 9,
      color: const Color(0xFF4A90E2),
    );
    _drawSparkle(
      canvas,
      center: Offset(centerX + 68, centerY - 38),
      size: 8,
      color: const Color(0xFFFFC857),
    );
    _drawSparkle(
      canvas,
      center: Offset(centerX + 36, centerY + 36),
      size: 7,
      color: const Color(0xFFFF7AD9),
    );
  }

  void _drawCloud(
    Canvas canvas, {
    required Offset center,
    required double scale,
    required Color color,
  }) {
    final paint = Paint()..color = color;
    canvas.drawCircle(center, 18 * scale, paint);
    canvas.drawCircle(Offset(center.dx - 14 * scale, center.dy + 4 * scale), 12 * scale, paint);
    canvas.drawCircle(Offset(center.dx + 16 * scale, center.dy + 2 * scale), 14 * scale, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 8 * scale),
          width: 44 * scale,
          height: 16 * scale,
        ),
        Radius.circular(8 * scale),
      ),
      paint,
    );
  }

  void _drawSparkle(
    Canvas canvas, {
    required Offset center,
    required double size,
    required Color color,
  }) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ForgotPasswordFinancePainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.topPadding != topPadding;
  }
}
