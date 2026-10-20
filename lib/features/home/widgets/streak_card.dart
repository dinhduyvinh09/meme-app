import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/avatar_frames.dart';
import '../../../core/constants/streak_milestones.dart';
import '../../../core/extensions/localization_extension.dart';
import 'streak_detail_sheet.dart';

/// Modern Streak Card inspired by Gen-Z fintech card designs
/// featuring:
/// 1. Tilted stacked card deck effect ("xếp chồng chéo") with user-configured angles.
/// 2. Dynamic Avatar Frame Tier Color Themes (0 -> 3 -> 10 -> 30 -> 60 -> 100 -> 200 -> 300 -> 400 -> 500 -> 600)
/// 3. Dynamic mascot expressions matching each unlock milestone.
/// 4. Snug, cohesive spacing that eliminates awkward empty gaps.
/// 5. Responsive frosted capsule pill bar with zero-overflow layout.
class StreakCard extends StatelessWidget {
  final int streak;
  final DateTime? lastActiveDate;
  final VoidCallback? onStartTap;

  const StreakCard({
    super.key,
    required this.streak,
    this.lastActiveDate,
    this.onStartTap,
  });

  bool get canStart => streak < 3;

  bool get isCompletedToday {
    if (lastActiveDate != null) {
      final now = DateTime.now();
      return lastActiveDate!.year == now.year &&
          lastActiveDate!.month == now.month &&
          lastActiveDate!.day == now.day;
    }
    return false;
  }

  int get nextMilestoneDays {
    final nextFrame = AvatarFrames.getNextMilestone(streak);
    if (nextFrame != null) {
      return nextFrame.requiredStreak;
    }
    for (final m in StreakMilestones.all) {
      if (m.days > streak) {
        return m.days;
      }
    }
    return ((streak ~/ 100) + 1) * 100;
  }

  String badgeText(BuildContext context) {
    if (streak >= 600) return 'Bất Tử';
    if (streak >= 500) return 'Long Vương';
    if (streak >= 400) return 'Phượng Hoàng';
    if (streak >= 300) return 'Thần Thoại';
    if (streak >= 200) return 'Thái Dương';
    if (streak >= 100) return 'Vũ Trụ';
    if (streak >= 60) return 'Cực Quang';
    if (streak >= 30) return context.l10n.streakLevel1;
    if (streak >= 10) return context.l10n.streakLevel2;
    if (streak >= 3) return context.l10n.streakLevel4;
    return context.l10n.streakLevel5;
  }

  /// Dynamic mascot expression asset matching each milestone tier:
  /// 0: Vẫy tay chào cổ vũ
  /// 3: Chạy tăng tốc lên đà
  /// 10: Nhảy vui mừng cầm xu vàng
  /// 30: Bật bóng đèn sáng ý tưởng
  /// 60: Ôm trái tim yêu thích
  /// 100: Đeo kính râm cầm tiền cực ngầu
  /// 200: Quyết tâm thói quen thép
  /// 300+: Bậc thầy tài chính thần thoại
  String get mascotAsset {
    if (streak >= 500) {
      return 'assets/icons/stickers/meme_mascot_streak.png';
    }
    if (streak >= 400) {
      return 'assets/icons/stickers/mascot_sunglasses_sticker.png';
    }
    if (streak >= 300) {
      return 'assets/icons/stickers/mascot_coin_phone_sticker.png';
    }
    if (streak >= 200) {
      return 'assets/icons/stickers/mascot_angry_sticker.png';
    }
    if (streak >= 100) {
      return 'assets/icons/stickers/mascot_sunglasses_sticker.png';
    }
    if (streak >= 60) {
      return 'assets/icons/stickers/mascot_love_heart_sticker.png';
    }
    if (streak >= 30) {
      return 'assets/icons/stickers/mascot_idea_sticker.png';
    }
    if (streak >= 10) {
      return 'assets/icons/stickers/meme_mascot_streak.png';
    }
    if (streak >= 3) {
      return 'assets/icons/stickers/mascot_run_sticker.png';
    }
    return 'assets/icons/stickers/mascot_cheer_sticker.png';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    // Dynamic Tier Color Theme based on Avatar Frame milestones (0 -> 600)
    final theme = _StreakVisualTheme.resolve(streak, isDark);

    return Padding(
      // Snug, natural padding that eliminates awkward gap between cards
      padding: const EdgeInsets.only(top: 10, bottom: 2, left: 4, right: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── LAYER 1: BACK DECK (User configured angle -0.06 ~ -3.5°) ──
          Positioned.fill(
            child: Transform.rotate(
              angle: -0.06,
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: theme.backDeckColor,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.28),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(
                        alpha: isDark ? 0.16 : 0.12,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── LAYER 2: MIDDLE DECK (User configured angle 0.045 ~ +2.5°) ──
          Positioned.fill(
            child: Transform.rotate(
              angle: 0.045,
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: theme.midDeckColor,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.20 : 0.35),
                    width: 1.1,
                  ),
                ),
              ),
            ),
          ),

          // ── LAYER 3: MAIN FRONT CARD (Subtle natural tilt ~ -0.7°) ──
          Transform.rotate(
            angle: -0.012,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                StreakDetailSheet.show(context);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: theme.gradient,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(
                        alpha: isDark ? 0.32 : 0.24,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    children: [
                      // Organic decorative wave pattern matching theme
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _StreakCardPatternPainter(
                            primary: theme.patternPrimary,
                            secondary: theme.patternSecondary,
                          ),
                        ),
                      ),

                      // Card Internal Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── TOP SECTION (Padding right prevents overlap with mascot) ──
                            Padding(
                              padding: const EdgeInsets.only(right: 76),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Title + (?) help button
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          context.l10n.dailyMemeStreak,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: theme.deepTextColor,
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.3,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          StreakDetailSheet.show(context);
                                        },
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          width: 19,
                                          height: 19,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: theme.helpBtnBg,
                                            border: Border.all(
                                              color: theme.helpBtnBorder,
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.help_outline_rounded,
                                              size: 12,
                                              color: theme.deepTextColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 3),

                                  // Subtitle row with mini icon badge
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(2.5),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.08),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          isCompletedToday
                                              ? Icons
                                                  .local_fire_department_rounded
                                              : Icons.flash_on_rounded,
                                          size: 12,
                                          color: isCompletedToday
                                              ? const Color(0xFFFF4500)
                                              : const Color(0xFFFF9500),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          isCompletedToday
                                              ? (isVi
                                                  ? 'Đã thắp lửa hôm nay, giữ vững phong độ! ✨'
                                                  : 'Streak active today, stay awesome! ✨')
                                              : (isVi
                                                  ? 'Thắp lửa hôm nay để không mất chuỗi!'
                                                  : 'Ignite today to protect streak!'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: theme.subTextColor,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ── BOTTOM HERO CAPSULE BAR (Zero-overflow responsive layout) ──
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.capsuleBg,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusPill,
                                ),
                                border: Border.all(
                                  color: theme.capsuleBorder,
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // 3 Overlapping Avatar badges (Compact & Responsive)
                                  SizedBox(
                                    width: 48,
                                    height: 24,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        // 1st badge: Fire Flame
                                        const Positioned(
                                          left: 0,
                                          child: _MiniAvatarBadge(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFFFF3B30),
                                                Color(0xFFFF9500),
                                              ],
                                            ),
                                            icon: Icons
                                                .local_fire_department_rounded,
                                          ),
                                        ),
                                        // 2nd badge: Milestone medal
                                        Positioned(
                                          left: 13,
                                          child: _MiniAvatarBadge(
                                            gradient:
                                                theme.milestoneBadgeGradient,
                                            icon: theme.milestoneIcon,
                                          ),
                                        ),
                                        // 3rd badge: Mascot avatar face
                                        Positioned(
                                          left: 26,
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1.3,
                                              ),
                                              color: const Color(0xFF90D5FF),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: Image.asset(
                                              mascotAsset,
                                              fit: BoxFit.cover,
                                              alignment: Alignment.topCenter,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 7),

                                  // Streak Text (Flexible, never overflows)
                                  Expanded(
                                    child: Text(
                                      streak > 0
                                          ? '$streak+ ${isVi ? 'ngày duy trì' : 'days streak'}'
                                          : (isVi
                                              ? '0 ngày · Bắt đầu ngay'
                                              : '0 days · Start now'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: theme.deepTextColor,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 5),

                                  // Action Button (Style matched to tier theme)
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      if (!isCompletedToday &&
                                          onStartTap != null) {
                                        onStartTap!();
                                      } else {
                                        StreakDetailSheet.show(context);
                                      }
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 11,
                                        vertical: 6.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.buttonBg,
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radiusPill,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.22,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1.5),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isCompletedToday
                                                ? (isVi
                                                    ? 'Chi tiết'
                                                    : 'Details')
                                                : (isVi
                                                    ? 'Thắp lửa'
                                                    : 'Ignite'),
                                            style: TextStyle(
                                              color: theme.buttonTextColor,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.1,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 12,
                                            color: theme.buttonTextColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── OVERFLOWING MASCOT STICKER (Positioned over top-right corner) ──
          Positioned(
            top: -24,
            right: 8,
            child: IgnorePointer(
              child: Image.asset(
                mascotAsset,
                width: 86,
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini circular avatar badge used inside the overlapping avatar row
class _MiniAvatarBadge extends StatelessWidget {
  final LinearGradient gradient;
  final IconData icon;

  const _MiniAvatarBadge({
    required this.gradient,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        border: Border.all(
          color: Colors.white,
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Custom painter for organic decorative background curves
class _StreakCardPatternPainter extends CustomPainter {
  final Color primary;
  final Color secondary;

  const _StreakCardPatternPainter({
    required this.primary,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Primary Loop Curve on the left
    final pPaint = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0
      ..strokeCap = StrokeCap.round;

    final pPath = Path();
    pPath.addArc(
      Rect.fromCircle(
        center: Offset(-12, size.height * 0.65),
        radius: 44,
      ),
      -0.6,
      3.2,
    );
    canvas.drawPath(pPath, pPaint);

    // 2. Primary accent curve at the bottom
    final pBottomPath = Path();
    pBottomPath.addArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.24, size.height + 12),
        radius: 46,
      ),
      3.0,
      2.6,
    );
    canvas.drawPath(pBottomPath, pPaint);

    // 3. Secondary deeper curved accents
    final sPaint = Paint()
      ..color = secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22.0
      ..strokeCap = StrokeCap.round;

    final sPath = Path();
    sPath.addArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.42, size.height + 18),
        radius: 54,
      ),
      3.1,
      2.4,
    );
    canvas.drawPath(sPath, sPaint);

    // 4. Subtle top-right soft glow ring behind the mascot
    final softRingPaint = Paint()
      ..color = primary.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0;

    canvas.drawCircle(
      Offset(size.width - 25, 10),
      36,
      softRingPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StreakCardPatternPainter oldDelegate) =>
      oldDelegate.primary != primary || oldDelegate.secondary != secondary;
}

/// Visual theme configuration mapped directly to Avatar Frame unlock milestones:
/// 0 -> 3 -> 10 -> 30 -> 60 -> 100 -> 200 -> 300 -> 400 -> 500 -> 600
class _StreakVisualTheme {
  final LinearGradient gradient;
  final Color shadowColor;
  final Color backDeckColor;
  final Color midDeckColor;
  final Color deepTextColor;
  final Color subTextColor;
  final Color capsuleBg;
  final Color capsuleBorder;
  final Color buttonBg;
  final Color buttonTextColor;
  final Color helpBtnBg;
  final Color helpBtnBorder;
  final Color patternPrimary;
  final Color patternSecondary;
  final LinearGradient milestoneBadgeGradient;
  final IconData milestoneIcon;

  const _StreakVisualTheme({
    required this.gradient,
    required this.shadowColor,
    required this.backDeckColor,
    required this.midDeckColor,
    required this.deepTextColor,
    required this.subTextColor,
    required this.capsuleBg,
    required this.capsuleBorder,
    required this.buttonBg,
    required this.buttonTextColor,
    required this.helpBtnBg,
    required this.helpBtnBorder,
    required this.patternPrimary,
    required this.patternSecondary,
    required this.milestoneBadgeGradient,
    required this.milestoneIcon,
  });

  factory _StreakVisualTheme.resolve(int streak, bool isDark) {
    // ═════════════════════════════════════════════════════════════════════════
    // 600+ DAYS: BẤT TỬ TỐI THƯỢNG (Eternal Deity Holographic)
    // ═════════════════════════════════════════════════════════════════════════
    if (streak >= 600) {
      return _StreakVisualTheme(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00F2FE), // Pure Prism Cyan
            Color(0xFFFF00CC), // Pure Prism Magenta
            Color(0xFFFFD700), // Sovereign Gold
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: const Color(0xFF00F2FE),
        backDeckColor:
            const Color(0xFF00F2FE).withValues(alpha: isDark ? 0.28 : 0.42),
        midDeckColor:
            const Color(0xFFFF00CC).withValues(alpha: isDark ? 0.35 : 0.50),
        deepTextColor: Colors.white,
        subTextColor: Colors.white.withValues(alpha: 0.92),
        capsuleBg: Colors.black.withValues(alpha: 0.25),
        capsuleBorder: Colors.white.withValues(alpha: 0.45),
        buttonBg: Colors.white,
        buttonTextColor: const Color(0xFF140026),
        helpBtnBg: Colors.white.withValues(alpha: 0.20),
        helpBtnBorder: Colors.white.withValues(alpha: 0.35),
        patternPrimary: const Color(0xFFFFFFFF).withValues(alpha: 0.45),
        patternSecondary: const Color(0xFFFFE600).withValues(alpha: 0.35),
        milestoneBadgeGradient: const LinearGradient(
          colors: [Color(0xFF00FFFF), Color(0xFFFF00FF)],
        ),
        milestoneIcon: Icons.workspace_premium_rounded,
      );
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 500+ DAYS: LONG VƯƠNG HOÀNG KIM (Dragon Sovereign Emerald & Gold)
    // ═════════════════════════════════════════════════════════════════════════
    if (streak >= 500) {
      return _StreakVisualTheme(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD700), // Dragon Royal Gold
            Color(0xFF00B0FF), // Imperial Blue
            Color(0xFF00E676), // Jade Emerald
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: const Color(0xFFFFD700),
        backDeckColor:
            const Color(0xFFFFD700).withValues(alpha: isDark ? 0.25 : 0.40),
        midDeckColor:
            const Color(0xFF00B0FF).withValues(alpha: isDark ? 0.30 : 0.48),
        deepTextColor: const Color(0xFF141A06),
        subTextColor: const Color(0xFF202C0A),
        capsuleBg: Colors.black.withValues(alpha: 0.22),
        capsuleBorder: Colors.white.withValues(alpha: 0.45),
        buttonBg: const Color(0xFF141A06),
        buttonTextColor: Colors.white,
        helpBtnBg: Colors.black.withValues(alpha: 0.12),
        helpBtnBorder: Colors.black.withValues(alpha: 0.18),
        patternPrimary: const Color(0xFFFFFFFF).withValues(alpha: 0.40),
        patternSecondary: const Color(0xFF0575E6).withValues(alpha: 0.30),
        milestoneBadgeGradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFF00E676)],
        ),
        milestoneIcon: Icons.military_tech_rounded,
      );
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 400+ DAYS: PHƯỢNG HOÀNG LỬA (Phoenix Blaze Crimson Gold)
    // ═════════════════════════════════════════════════════════════════════════
    if (streak >= 400) {
      return _StreakVisualTheme(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD700), // Phoenix Gold
            Color(0xFFFF2200), // Blazing Red
            Color(0xFF8800CC), // Imperial Violet
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: const Color(0xFFFF2200),
        backDeckColor:
            const Color(0xFFFFD700).withValues(alpha: isDark ? 0.25 : 0.40),
        midDeckColor:
            const Color(0xFFFF2200).withValues(alpha: isDark ? 0.32 : 0.50),
        deepTextColor: Colors.white,
        subTextColor: Colors.white.withValues(alpha: 0.92),
        capsuleBg: Colors.black.withValues(alpha: 0.24),
        capsuleBorder: Colors.white.withValues(alpha: 0.40),
        buttonBg: Colors.white,
        buttonTextColor: const Color(0xFF2A000A),
        helpBtnBg: Colors.white.withValues(alpha: 0.18),
        helpBtnBorder: Colors.white.withValues(alpha: 0.32),
        patternPrimary: const Color(0xFFFFD700).withValues(alpha: 0.40),
        patternSecondary: const Color(0xFFFF0055).withValues(alpha: 0.35),
        milestoneBadgeGradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFF2200)],
        ),
        milestoneIcon: Icons.whatshot_rounded,
      );
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 300+ DAYS: THẦN THOẠI KIM CƯƠNG (Mythic Prism Rainbow)
    // ═════════════════════════════════════════════════════════════════════════
    if (streak >= 300) {
      return _StreakVisualTheme(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFA709A), // Prism Pink
            Color(0xFFFEE140), // Prism Gold
            Color(0xFF30CFD0), // Diamond Aqua
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: const Color(0xFF30CFD0),
        backDeckColor:
            const Color(0xFFFA709A).withValues(alpha: isDark ? 0.25 : 0.40),
        midDeckColor:
            const Color(0xFF30CFD0).withValues(alpha: isDark ? 0.30 : 0.48),
        deepTextColor: const Color(0xFF1E1030),
        subTextColor: const Color(0xFF341C52),
        capsuleBg: Colors.black.withValues(alpha: 0.18),
        capsuleBorder: Colors.white.withValues(alpha: 0.45),
        buttonBg: const Color(0xFF1E1030),
        buttonTextColor: Colors.white,
        helpBtnBg: Colors.black.withValues(alpha: 0.08),
        helpBtnBorder: Colors.black.withValues(alpha: 0.14),
        patternPrimary: const Color(0xFFFFFFFF).withValues(alpha: 0.40),
        patternSecondary: const Color(0xFF667EEA).withValues(alpha: 0.30),
        milestoneBadgeGradient: const LinearGradient(
          colors: [Color(0xFFFA709A), Color(0xFF30CFD0)],
        ),
        milestoneIcon: Icons.diamond_rounded,
      );
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 200+ DAYS: BÃO THÁI DƯƠNG (Solar Flare Radiant Orange-Red)
    // ═════════════════════════════════════════════════════════════════════════
    if (streak >= 200) {
      return _StreakVisualTheme(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFE600), // Pure Solar Yellow
            Color(0xFFFF5500), // Intense Solar Flare
            Color(0xFFFF0055), // Crimson Corona
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: const Color(0xFFFF5500),
        backDeckColor:
            const Color(0xFFFFE600).withValues(alpha: isDark ? 0.26 : 0.42),
        midDeckColor:
            const Color(0xFFFF5500).withValues(alpha: isDark ? 0.32 : 0.50),
        deepTextColor: Colors.white,
        subTextColor: Colors.white.withValues(alpha: 0.90),
        capsuleBg: Colors.black.withValues(alpha: 0.22),
        capsuleBorder: Colors.white.withValues(alpha: 0.40),
        buttonBg: Colors.white,
        buttonTextColor: const Color(0xFF330A00),
        helpBtnBg: Colors.white.withValues(alpha: 0.18),
        helpBtnBorder: Colors.white.withValues(alpha: 0.32),
        patternPrimary: const Color(0xFFFFE600).withValues(alpha: 0.40),
        patternSecondary: const Color(0xFFFF0044).withValues(alpha: 0.30),
        milestoneBadgeGradient: const LinearGradient(
          colors: [Color(0xFFFFE600), Color(0xFFFF5500)],
        ),
        milestoneIcon: Icons.wb_sunny_rounded,
      );
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 100+ DAYS: VŨ TRỤ HUYỀN BÍ (Cosmic Nebula Violet & Neon Rose)
    // ═════════════════════════════════════════════════════════════════════════
    if (streak >= 100) {
      return _StreakVisualTheme(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7928CA), // Deep Nebula Violet
            Color(0xFFFF0080), // Neon Cosmic Rose
            Color(0xFF00DFD8), // Starlight Cyan
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: const Color(0xFFFF0080),
        backDeckColor:
            const Color(0xFF7928CA).withValues(alpha: isDark ? 0.25 : 0.40),
        midDeckColor:
            const Color(0xFFFF0080).withValues(alpha: isDark ? 0.32 : 0.50),
        deepTextColor: Colors.white,
        subTextColor: Colors.white.withValues(alpha: 0.90),
        capsuleBg: Colors.black.withValues(alpha: 0.22),
        capsuleBorder: Colors.white.withValues(alpha: 0.38),
        buttonBg: Colors.white,
        buttonTextColor: const Color(0xFF280320),
        helpBtnBg: Colors.white.withValues(alpha: 0.18),
        helpBtnBorder: Colors.white.withValues(alpha: 0.32),
        patternPrimary: const Color(0xFF00DFD8).withValues(alpha: 0.38),
        patternSecondary: const Color(0xFF4C1D95).withValues(alpha: 0.32),
        milestoneBadgeGradient: const LinearGradient(
          colors: [Color(0xFF7928CA), Color(0xFFFF0080)],
        ),
        milestoneIcon: Icons.auto_awesome_rounded,
      );
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 60+ DAYS: CỰC QUANG BẮC CỰC (Aurora Borealis Arctic Jade & Purple)
    // ═════════════════════════════════════════════════════════════════════════
    if (streak >= 60) {
      return _StreakVisualTheme(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00DFD8), // Arctic Cyan
            Color(0xFF38EF7D), // Northern Lights Green
            Color(0xFF8A2387), // Deep Aurora Purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: const Color(0xFF00DFD8),
        backDeckColor:
            const Color(0xFF00DFD8).withValues(alpha: isDark ? 0.24 : 0.40),
        midDeckColor:
            const Color(0xFF38EF7D).withValues(alpha: isDark ? 0.30 : 0.48),
        deepTextColor: Colors.white,
        subTextColor: Colors.white.withValues(alpha: 0.90),
        capsuleBg: Colors.black.withValues(alpha: 0.20),
        capsuleBorder: Colors.white.withValues(alpha: 0.38),
        buttonBg: Colors.white,
        buttonTextColor: const Color(0xFF052B1E),
        helpBtnBg: Colors.white.withValues(alpha: 0.18),
        helpBtnBorder: Colors.white.withValues(alpha: 0.30),
        patternPrimary: const Color(0xFF92EFFD).withValues(alpha: 0.40),
        patternSecondary: const Color(0xFF4E65FF).withValues(alpha: 0.30),
        milestoneBadgeGradient: const LinearGradient(
          colors: [Color(0xFF00DFD8), Color(0xFF38EF7D)],
        ),
        milestoneIcon: Icons.wb_twilight_rounded,
      );
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 30+ DAYS: TINH TÚ NGỌC LỤC BẢO (Sparkle Star Emerald Jade)
    // ═════════════════════════════════════════════════════════════════════════
    if (streak >= 30) {
      return _StreakVisualTheme(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00F5A0), // Emerald Glow
            Color(0xFF00D9F5), // Star Cyan
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: const Color(0xFF00F5A0),
        backDeckColor:
            const Color(0xFF00F5A0).withValues(alpha: isDark ? 0.22 : 0.40),
        midDeckColor:
            const Color(0xFF00D9F5).withValues(alpha: isDark ? 0.30 : 0.50),
        deepTextColor: const Color(0xFF04241B),
        subTextColor: const Color(0xFF0C3D30),
        capsuleBg: const Color(0xFF047857).withValues(alpha: 0.26),
        capsuleBorder: Colors.white.withValues(alpha: 0.50),
        buttonBg: const Color(0xFF04241B),
        buttonTextColor: Colors.white,
        helpBtnBg: Colors.black.withValues(alpha: 0.08),
        helpBtnBorder: Colors.black.withValues(alpha: 0.14),
        patternPrimary: const Color(0xFFFFFFFF).withValues(alpha: 0.45),
        patternSecondary: const Color(0xFF11998E).withValues(alpha: 0.35),
        milestoneBadgeGradient: const LinearGradient(
          colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)],
        ),
        milestoneIcon: Icons.auto_awesome_rounded,
      );
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 10+ DAYS: NGỌN LỬA RỰC CHÁY (Fire Flame Gold & Blaze Orange)
    // ═════════════════════════════════════════════════════════════════════════
    if (streak >= 10) {
      return _StreakVisualTheme(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD200), // Flame Gold
            Color(0xFFFF6A00), // Fire Orange
            Color(0xFFFF2D55), // Blazing Crimson
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: const Color(0xFFFF6A00),
        backDeckColor:
            const Color(0xFFFFD200).withValues(alpha: isDark ? 0.25 : 0.42),
        midDeckColor:
            const Color(0xFFFF6A00).withValues(alpha: isDark ? 0.32 : 0.52),
        deepTextColor: Colors.white,
        subTextColor: Colors.white.withValues(alpha: 0.90),
        capsuleBg: Colors.black.withValues(alpha: 0.20),
        capsuleBorder: Colors.white.withValues(alpha: 0.40),
        buttonBg: Colors.white,
        buttonTextColor: const Color(0xFF330E00),
        helpBtnBg: Colors.white.withValues(alpha: 0.18),
        helpBtnBorder: Colors.white.withValues(alpha: 0.30),
        patternPrimary: const Color(0xFFFFD200).withValues(alpha: 0.40),
        patternSecondary: const Color(0xFFFF416C).withValues(alpha: 0.32),
        milestoneBadgeGradient: const LinearGradient(
          colors: [Color(0xFFFFD200), Color(0xFFFF4B2B)],
        ),
        milestoneIcon: Icons.local_fire_department_rounded,
      );
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 3+ DAYS: GRADIENT NEON PULSE (Cyan & Magenta Pulse)
    // ═════════════════════════════════════════════════════════════════════════
    if (streak >= 3) {
      return _StreakVisualTheme(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00F2FE), // Electric Cyan
            Color(0xFF4FACFE), // Blue Meme Pulse
            Color(0xFFFF7AD9), // Coral Pink Pulse
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadowColor: const Color(0xFF4FACFE),
        backDeckColor:
            const Color(0xFF00F2FE).withValues(alpha: isDark ? 0.22 : 0.40),
        midDeckColor:
            const Color(0xFFFF7AD9).withValues(alpha: isDark ? 0.28 : 0.48),
        deepTextColor: const Color(0xFF0B1B36),
        subTextColor: const Color(0xFF1C3660),
        capsuleBg: const Color(0xFF2563EB).withValues(alpha: 0.25),
        capsuleBorder: Colors.white.withValues(alpha: 0.45),
        buttonBg: const Color(0xFF0B1B36),
        buttonTextColor: Colors.white,
        helpBtnBg: Colors.black.withValues(alpha: 0.08),
        helpBtnBorder: Colors.black.withValues(alpha: 0.12),
        patternPrimary: const Color(0xFFFFFFFF).withValues(alpha: 0.40),
        patternSecondary: const Color(0xFF9B51E0).withValues(alpha: 0.30),
        milestoneBadgeGradient: const LinearGradient(
          colors: [Color(0xFF00F2FE), Color(0xFFFF7AD9)],
        ),
        milestoneIcon: Icons.flash_on_rounded,
      );
    }

    // ═════════════════════════════════════════════════════════════════════════
    // 0+ DAYS: CLASSIC MEME BLUE (Meme Brand Primary Blue)
    // ═════════════════════════════════════════════════════════════════════════
    return _StreakVisualTheme(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF93C5FD), // Gentle Blue
          Color(0xFF3B82F6), // Meme Primary Blue
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: const Color(0xFF3B82F6),
      backDeckColor:
          const Color(0xFF93C5FD).withValues(alpha: isDark ? 0.20 : 0.38),
      midDeckColor:
          const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.26 : 0.46),
      deepTextColor: const Color(0xFF061833),
      subTextColor: const Color(0xFF0F3260),
      capsuleBg: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
      capsuleBorder: Colors.white.withValues(alpha: 0.45),
      buttonBg: const Color(0xFF0B192C),
      buttonTextColor: Colors.white,
      helpBtnBg: Colors.black.withValues(alpha: 0.08),
      helpBtnBorder: Colors.black.withValues(alpha: 0.12),
      patternPrimary: const Color(0xFFE0F2FE).withValues(alpha: 0.45),
      patternSecondary: const Color(0xFF1E40AF).withValues(alpha: 0.30),
      milestoneBadgeGradient: const LinearGradient(
        colors: [Color(0xFF93C5FD), Color(0xFF3B82F6)],
      ),
      milestoneIcon: Icons.star_rounded,
    );
  }
}
