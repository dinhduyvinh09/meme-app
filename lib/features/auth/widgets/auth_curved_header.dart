import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Minimalist curved header for MeMe authentication screens.
/// Features a brand-blue gradient with an expanded, deep sweeping organic curve,
/// leaving the corner uncluttered (no logo/subtitle inside) and providing a clean back button.
class AuthCurvedHeader extends StatelessWidget {
  final bool showBackButton;
  final VoidCallback? onBack;

  const AuthCurvedHeader({
    super.key,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + (showBackButton ? 185.0 : 172.0);

    return SizedBox(
      height: headerHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // Background with organic curve in MeMe's authentic brand colors
          Positioned.fill(
            child: ClipPath(
              clipper: const CurvedHeaderClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3273D6),
                      AppColors.primaryBlueDark, // 0xFF4A90E2
                      Color(0xFF6EA8FE),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Optional back button positioned cleanly on the brand header
          if (showBackButton)
            Positioned(
              top: topPadding + 10,
              left: 20,
              child: GestureDetector(
                onTap: onBack ?? () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CurvedHeaderClipper extends CustomClipper<Path> {
  const CurvedHeaderClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.78);

    path.cubicTo(
      size.width * 0.28,
      size.height * 0.99,
      size.width * 0.65,
      size.height * 0.84,
      size.width,
      size.height * 0.24,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
