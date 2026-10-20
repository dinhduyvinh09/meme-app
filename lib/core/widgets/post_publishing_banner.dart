import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_icon_registry.dart';
import '../services/post_publishing_service.dart';

class PostPublishingBannerHost extends StatefulWidget {
  const PostPublishingBannerHost({super.key});

  @override
  State<PostPublishingBannerHost> createState() => _PostPublishingBannerHostState();
}

class _PostPublishingBannerHostState extends State<PostPublishingBannerHost>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    PostPublishingService.instance.addListener(_handleStateChange);
  }

  @override
  void dispose() {
    PostPublishingService.instance.removeListener(_handleStateChange);
    _animController.dispose();
    super.dispose();
  }

  void _handleStateChange() {
    if (!mounted) return;
    final service = PostPublishingService.instance;
    final isVisible = service.isVisible;

    if (isVisible) {
      if (!_animController.isCompleted && !_animController.isAnimating) {
        HapticFeedback.lightImpact();
        _animController.forward();
      }
      setState(() {});
    } else {
      if (_animController.isCompleted || _animController.isAnimating) {
        _animController.reverse().then((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = PostPublishingService.instance;
    if (!service.isVisible && _animController.isDismissed) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.maybeLocaleOf(context);
    final isEn = locale?.languageCode.toLowerCase() == 'en';
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isCollapsed = service.isNavbarCollapsed;
    final hasRightFab = service.hasRightFab;

    // Khi navbar thu gọn:
    // - Nút navbar tròn bên trái: left 16, width 50 => kết thúc ở x = 66 => bannerLeft = 74.0
    // - Phía bên phải:
    //   + Nếu ở tab Trang chủ (index == 0): có nút FAB tròn (right 20, width 55) => bannerRight = 83.0 (để nằm giữa 2 nút)
    //   + Nếu ở tab khác (Thống kê, Bạn bè, Ví, Cá nhân): KHÔNG CÓ nút FAB => bannerRight = 16.0 (kéo dài đều sang phải đẹp mắt)
    final bannerBottom = bottomInset + (isCollapsed ? 24.0 : 104.0);
    final bannerLeft = isCollapsed ? 74.0 : 16.0;
    final bannerRight = isCollapsed ? (hasRightFab ? 83.0 : 16.0) : 16.0;
    final bannerHeight = isCollapsed ? 52.0 : null;

    return AnimatedPositioned(
      duration: Duration(milliseconds: isCollapsed ? 280 : 240),
      curve: isCollapsed ? Curves.easeInOutCubic : Curves.easeOutCubic,
      left: bannerLeft,
      right: bannerRight,
      bottom: bannerBottom,
      height: bannerHeight,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Dismissible(
            key: const Key('post_publishing_banner_dismissible'),
            direction: DismissDirection.down,
            onDismissed: (_) {
              service.dismiss();
            },
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isCollapsed ? 25 : 26),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: isCollapsed ? 280 : 240),
                        curve: isCollapsed ? Curves.easeInOutCubic : Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          // Popup trong suốt hơn với hiệu ứng frosted glass / blur
                          color: isDark
                              ? const Color(0xFF161922).withValues(alpha: 0.70)
                              : const Color(0xFF141720).withValues(alpha: 0.66),
                          borderRadius: BorderRadius.circular(isCollapsed ? 25 : 26),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.22),
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.32),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AnimatedSize(
                          duration: Duration(milliseconds: isCollapsed ? 280 : 240),
                          curve: isCollapsed ? Curves.easeInOutCubic : Curves.easeOutCubic,
                          child: isCollapsed
                              ? _buildCollapsedContent(service, isEn)
                              : _buildExpandedContent(service, isEn),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent(PostPublishingService service, bool isEn) {
    return GestureDetector(
      onTap: service.isSuccess
          ? () {
              HapticFeedback.selectionClick();
              service.viewPost();
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 52.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thumbnail nhỏ 34x34
              _buildMediaThumbnailWithClip(service, isMini: true),

              const SizedBox(width: 8),

              // Text tiêu đề & trạng thái
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      service.isUploading
                          ? (isEn ? 'Posting...' : 'Đang đăng...')
                          : (service.isSuccess
                              ? (isEn ? 'Posted' : 'Đã đăng')
                              : (isEn ? 'Failed' : 'Đăng lỗi')),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: service.isError
                            ? const Color(0xFFEF4444)
                            : Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.isUploading
                          ? (isEn ? 'Uploading moment' : 'Đang tải lên...')
                          : (service.isSuccess
                              ? (isEn ? 'Tap to view' : 'Chạm để xem')
                              : (isEn ? 'Tap to retry' : 'Thử lại')),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: service.isSuccess
                            ? const Color(0xFF60A5FA)
                            : Colors.white.withValues(alpha: 0.70),
                        fontSize: 10.0,
                        fontWeight: FontWeight.w500,
                        height: 1.15,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Progress / Status indicator on right
              if (service.isUploading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else if (service.isSuccess)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isEn ? 'View' : 'Xem',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(PostPublishingService service, bool isEn) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      child: Row(
        children: [
          // Status Icon & Status Text
          Expanded(
            child: _buildStatusSection(service, isEn),
          ),

          const SizedBox(width: 12),

          // Media Thumbnail with Paperclip
          _buildMediaThumbnailWithClip(service, isMini: false),

          // "Xem" action button when success
          if (service.isSuccess) ...[
            const SizedBox(width: 14),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                service.viewPost();
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
                child: Text(
                  isEn ? 'View' : 'Xem',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusSection(PostPublishingService service, bool isEn) {
    if (service.isUploading) {
      if (service.isFinalizing) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                isEn ? 'Posting...' : 'Đang đăng...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        );
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEn ? 'Posting...' : 'Đang đăng...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEn
                      ? 'Keep Meme open until upload completes.'
                      : 'Mở Meme cho đến khi tải lên xong.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (service.isSuccess) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              isEn ? 'Posted' : 'Đã đăng',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      );
    }

    // Error
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Color(0xFFEF4444),
          size: 20,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            isEn ? 'Failed to post' : 'Đăng thất bại',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  static const Map<String, Map<String, dynamic>> _defaultCategoryMeta = {
    'Ăn uống': {
      'icon': Icons.shopping_cart_outlined,
      'color': Color(0xFF59D46F),
    },
    'Food': {
      'icon': Icons.shopping_cart_outlined,
      'color': Color(0xFF59D46F),
    },
    'Mua sắm': {
      'icon': Icons.shopping_bag_outlined,
      'color': Color(0xFFFF4D8D),
    },
    'Shopping': {
      'icon': Icons.shopping_bag_outlined,
      'color': Color(0xFFFF4D8D),
    },
    'Di chuyển': {
      'icon': Icons.directions_bus_outlined,
      'color': Color(0xFF2F9BFF),
    },
    'Đi lại': {
      'icon': Icons.directions_bus_outlined,
      'color': Color(0xFF2F9BFF),
    },
    'Transport': {
      'icon': Icons.directions_bus_outlined,
      'color': Color(0xFF2F9BFF),
    },
    'Giải trí': {
      'icon': Icons.movie_outlined,
      'color': Color(0xFFFFA52F),
    },
    'Entertainment': {
      'icon': Icons.movie_outlined,
      'color': Color(0xFFFFA52F),
    },
    'Giáo dục': {
      'icon': Icons.menu_book_outlined,
      'color': Color(0xFF8B7CFF),
    },
    'Học tập': {
      'icon': Icons.menu_book_outlined,
      'color': Color(0xFF8B7CFF),
    },
    'Education': {
      'icon': Icons.menu_book_outlined,
      'color': Color(0xFF8B7CFF),
    },
    'Lương': {
      'icon': Icons.payments_outlined,
      'color': Color(0xFF7DFFA1),
    },
    'Salary': {
      'icon': Icons.payments_outlined,
      'color': Color(0xFF7DFFA1),
    },
    'Quà tặng': {
      'icon': Icons.card_giftcard_rounded,
      'color': Color(0xFFFF4D4D),
    },
    'Gift': {
      'icon': Icons.card_giftcard_rounded,
      'color': Color(0xFFFF4D4D),
    },
    'Quỹ nhóm': {
      'icon': Icons.groups_rounded,
      'color': Color(0xFFFFD166),
    },
    'Group Fund': {
      'icon': Icons.groups_rounded,
      'color': Color(0xFFFFD166),
    },
    'Khác': {
      'icon': Icons.more_horiz_rounded,
      'color': Color(0xFFAAAAAA),
    },
    'Other': {
      'icon': Icons.more_horiz_rounded,
      'color': Color(0xFFAAAAAA),
    },
  };

  Widget _buildMediaThumbnailWithClip(PostPublishingService service, {bool isMini = false}) {
    final displayFile = service.thumbnailFile ??
        (!service.isVideo ? service.mediaFile : null);

    final double size = isMini ? 34.0 : 42.0;
    final double radius = isMini ? 8.0 : 10.0;
    final double innerRadius = isMini ? 7.0 : 9.0;
    final double clipW = isMini ? 11.0 : 14.0;
    final double clipH = isMini ? 19.0 : 25.0;
    final double clipTop = isMini ? -5.0 : -8.0;
    final double clipRight = isMini ? 1.0 : 3.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2F38),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(innerRadius),
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                if (displayFile != null && displayFile.existsSync())
                  Image.file(
                    displayFile,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    cacheWidth: isMini ? 80 : 120,
                    cacheHeight: isMini ? 80 : 120,
                    errorBuilder: (_, __, ___) =>
                        _buildFallbackThumbnail(service, isMini: isMini),
                  )
                else
                  _buildFallbackThumbnail(service, isMini: isMini),

                // Video play indicator icon overlay
                if (service.isVideo)
                  Center(
                    child: Container(
                      width: isMini ? 16 : 20,
                      height: isMini ? 16 : 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.55),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: isMini ? 11 : 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Silver Metallic Paperclip pinned over top edge
        Positioned(
          top: clipTop,
          right: clipRight,
          child: PaperclipWidget(
            width: clipW,
            height: clipH,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackThumbnail(PostPublishingService service, {bool isMini = false}) {
    final double size = isMini ? 34.0 : 42.0;

    if (service.isVideo) {
      return Container(
        width: size,
        height: size,
        color: const Color(0xFF333642),
        child: Icon(
          Icons.videocam_rounded,
          color: Colors.white54,
          size: isMini ? 16 : 20,
        ),
      );
    }

    Color catColor = const Color(0xFF79AFFF);
    if (service.categoryColorHex != null &&
        service.categoryColorHex!.trim().isNotEmpty) {
      var cleaned = service.categoryColorHex!.trim().replaceAll('#', '');
      if (cleaned.length == 6) cleaned = 'FF$cleaned';
      if (cleaned.length == 8) {
        try {
          catColor = Color(int.parse(cleaned, radix: 16));
        } catch (_) {}
      }
    } else if (service.category != null && service.category!.trim().isNotEmpty) {
      final meta = _defaultCategoryMeta[service.category!.trim()];
      if (meta != null && meta['color'] is Color) {
        catColor = meta['color'] as Color;
      }
    }

    IconData catIcon = Icons.account_balance_wallet_rounded;
    if (service.categoryIconCodePoint != null &&
        service.categoryIconCodePoint! > 0) {
      catIcon = AppIconRegistry.fromCodePoint(service.categoryIconCodePoint!);
    } else if (service.category != null && service.category!.trim().isNotEmpty) {
      final meta = _defaultCategoryMeta[service.category!.trim()];
      if (meta != null && meta['icon'] is IconData) {
        catIcon = meta['icon'] as IconData;
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMini ? 7 : 9),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            catColor.withValues(alpha: 0.38),
            catColor.withValues(alpha: 0.18),
            const Color(0xFF1B1D24),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          catIcon,
          size: isMini ? 17 : 21,
          color: catColor,
        ),
      ),
    );
  }
}

class PaperclipWidget extends StatelessWidget {
  final double width;
  final double height;

  const PaperclipWidget({
    super.key,
    this.width = 14,
    this.height = 25,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.15, // Slight natural tilt
      child: CustomPaint(
        size: Size(width, height),
        painter: _PaperclipPainter(),
      ),
    );
  }
}

class _PaperclipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shadow path
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

    final path = Path();
    // Start inside bottom inner curve
    path.moveTo(w * 0.42, h * 0.62);
    path.lineTo(w * 0.42, h * 0.28);
    // Inner top curve
    path.arcToPoint(
      Offset(w * 0.76, h * 0.28),
      radius: Radius.circular(w * 0.17),
      clockwise: true,
    );
    // Outer down right line
    path.lineTo(w * 0.76, h * 0.78);
    // Bottom big outer curve
    path.arcToPoint(
      Offset(w * 0.18, h * 0.78),
      radius: Radius.circular(w * 0.29),
      clockwise: true,
    );
    // Outer up left line
    path.lineTo(w * 0.18, h * 0.20);
    // Top big outer curve
    path.arcToPoint(
      Offset(w * 0.94, h * 0.20),
      radius: Radius.circular(w * 0.38),
      clockwise: true,
    );
    // Down right end line
    path.lineTo(w * 0.94, h * 0.68);

    canvas.drawPath(path.shift(const Offset(0.8, 1.2)), shadowPaint);

    // Silver metallic gradient for paperclip wire
    final metallicPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFE2E8F0),
          Color(0xFFCBD5E1),
          Color(0xFFFFFFFF),
          Color(0xFF94A3B8),
          Color(0xFFE2E8F0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, metallicPaint);

    // White shine highlight
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    final shinePath = Path()
      ..moveTo(w * 0.18, h * 0.40)
      ..lineTo(w * 0.18, h * 0.22);
    canvas.drawPath(shinePath, shinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
