import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/avatar_frames.dart';
import '../../../core/constants/genz_reminder_quotes.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/models/user_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/widgets/avatar_with_frame.dart';
import '../controllers/home_controller.dart';

class StreakDetailSheet extends StatefulWidget {
  final UserModel? user;
  final bool hasPostedToday;

  const StreakDetailSheet({
    super.key,
    required this.user,
    this.hasPostedToday = false,
  });

  static Future<void> show(
    BuildContext context, {
    UserModel? user,
    bool? hasPostedToday,
  }) {
    HapticFeedback.lightImpact();
    final home = context.read<HomeController>();
    final targetUser = user ?? home.profile;
    final now = DateTime.now();

    final postedToday = hasPostedToday ??
        home.transactions.any((tx) {
          return tx.createdAt.year == now.year &&
              tx.createdAt.month == now.month &&
              tx.createdAt.day == now.day;
        });

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreakDetailSheet(
        user: targetUser,
        hasPostedToday: postedToday,
      ),
    );
  }

  @override
  State<StreakDetailSheet> createState() => _StreakDetailSheetState();
}

class _StreakDetailSheetState extends State<StreakDetailSheet> {
  late String _equippedFrameId;

  @override
  void initState() {
    super.initState();
    _equippedFrameId = widget.user?.avatarFrame ?? 'plain';
  }

  Future<void> _handleSelectFrame(AvatarFrameItem frame) async {
    final currentUser = context.read<ProfileController>().user ??
        context.read<HomeController>().profile;
    final user = currentUser ?? widget.user;
    final streak = user?.currentStreak ?? 0;
    final bestStreak = user?.bestStreak ?? 0;

    if (!frame.isUnlocked(streak, bestStreak: bestStreak)) {
      HapticFeedback.lightImpact();
      AppToast.show(
        context,
        context.l10n.needStreakToUnlock(
          frame.requiredStreak,
          frame.getName(context),
        ),
        icon: Icons.lock_rounded,
      );
      return;
    }

    if (_equippedFrameId == frame.id) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _equippedFrameId = frame.id;
    });

    final uid = widget.user?.uid ?? context.read<AuthController>().user?.uid;
    if (uid != null) {
      await context.read<ProfileController>().updateAvatarFrame(uid, frame.id);
      if (mounted) {
        await context.read<HomeController>().refreshProfile(uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    final currentUser = context.watch<ProfileController>().user ??
        context.watch<HomeController>().profile;
    final user = (widget.user != null && widget.user?.uid == currentUser?.uid)
        ? (currentUser ?? widget.user)
        : (widget.user ?? currentUser);

    final currentStreak = user?.currentStreak ?? 0;
    final bestStreak = user?.bestStreak ?? 0;
    final effectiveStreak =
        currentStreak > bestStreak ? currentStreak : bestStreak;
    final avatarUrl = user?.avatarUrl ?? '';
    final nextMilestone =
        AvatarFrames.getNextMilestone(currentStreak, bestStreak: bestStreak);

    final quotesList =
        isVi ? GenZReminderQuotes.listVi : GenZReminderQuotes.listEn;
    final quoteIndex = currentStreak % quotesList.length;
    final genZQuote = quotesList[quoteIndex];

    final sheetBg = isDark ? const Color(0xFF141722) : AppColors.card(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    final screenHeight = MediaQuery.of(context).size.height;
    final maxRatio = screenHeight < 700 ? 0.88 : 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: screenHeight * maxRatio,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Top Drag Handle & Close Button Row
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: textSecondary.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Title with Flame Icon
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF416C).withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFF416C).withValues(alpha: 0.32),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFFF416C),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.dailyMemeStreak,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 4, bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 2. STATS 3-COLUMN CARDS (Current | Best | Collection)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Current Streak
                            Expanded(
                              child: _StatMetricTile(
                                icon: Icons.local_fire_department_rounded,
                                iconColor: const Color(0xFFFF5722),
                                value: context.l10n.daysStreak(currentStreak),
                                label: context.l10n.streakMaintaining,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Best Streak
                            Expanded(
                              child: _StatMetricTile(
                                icon: Icons.emoji_events_rounded,
                                iconColor: const Color(0xFFFFB300),
                                value: context.l10n.daysStreak(bestStreak),
                                label: context.l10n.bestStreakLabel,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Collection Unlocked
                            Expanded(
                              child: _StatMetricTile(
                                icon: Icons.workspace_premium_rounded,
                                iconColor: const Color(0xFF388AF6),
                                value: context.l10n.framesCount(
                                  AvatarFrames.getUnlockedCount(currentStreak,
                                      bestStreak: bestStreak),
                                  AvatarFrames.all.length,
                                ),
                                label: context.l10n.unlockedStatus,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 3. TODAY'S FLAME STATUS BANNER
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: widget.hasPostedToday
                              ? const Color(0xFF10B981).withValues(alpha: 0.14)
                              : const Color(0xFFFF9800).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: widget.hasPostedToday
                                ? const Color(0xFF10B981)
                                    .withValues(alpha: 0.32)
                                : const Color(0xFFFF9800)
                                    .withValues(alpha: 0.32),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.hasPostedToday
                                  ? Icons.check_circle_rounded
                                  : Icons.access_time_rounded,
                              size: 18,
                              color: widget.hasPostedToday
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFFF9800),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.hasPostedToday
                                        ? context.l10n.streakFlameActiveToday
                                        : context.l10n.streakFlamePendingToday,
                                    style: TextStyle(
                                      color: widget.hasPostedToday
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFFF9800),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.hasPostedToday
                                        ? context.l10n.hasPostedStreakMotivation
                                        : context.l10n.streakFlameKeepHint,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 4. WEEKLY 7-DAY STREAK TIMELINE
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C1F2B)
                              : AppColors.surface(context),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppColors.innerBorder(context),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 17,
                                  color: Color(0xFFFF5722),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.l10n.streakWeeklyTracker,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _WeeklyStreakRow(
                              currentStreak: currentStreak,
                              hasPostedToday: widget.hasPostedToday,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 5. BILINGUAL GEN-Z MOTIVATIONAL REMINDER QUOTE
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E2230)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.innerBorder(context),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '💡',
                              style: TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    genZQuote.title,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    genZQuote.body,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // 6. AVATAR FRAMES HORIZONTAL COLLECTION
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.15),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.workspace_premium_rounded,
                                color: Color(0xFFFFD700),
                                size: 17,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.avatarFrameCollectionTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusPill),
                              border: Border.all(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              context.l10n.unlockedBadgeCount(
                                AvatarFrames.getUnlockedCount(currentStreak,
                                    bestStreak: bestStreak),
                                AvatarFrames.all.length,
                              ),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFFD700),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Avatar Frames Horizontal List
                      SizedBox(
                        height: 148,
                        child: ListView.separated(
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: AvatarFrames.all.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final frame = AvatarFrames.all[index];
                            final isUnlocked = frame.isUnlocked(currentStreak,
                                bestStreak: bestStreak);
                            final isEquipped = _equippedFrameId == frame.id;

                            return GestureDetector(
                              onTap: () => _handleSelectFrame(frame),
                              behavior: HitTestBehavior.opaque,
                              child: SizedBox(
                                width: 72,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Frame Avatar Preview
                                    Stack(
                                      clipBehavior: Clip.none,
                                      alignment: Alignment.center,
                                      children: [
                                        if (isEquipped)
                                          Container(
                                            width: 58,
                                            height: 58,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (frame.glowColor !=
                                                              Colors.transparent
                                                          ? frame.glowColor
                                                          : const Color(
                                                              0xFF388AF6))
                                                      .withValues(alpha: 0.6),
                                                  blurRadius: 14,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        Opacity(
                                          opacity: isUnlocked ? 1.0 : 0.42,
                                          child: AvatarWithFrame(
                                            avatarUrl: avatarUrl,
                                            frameId: frame.id,
                                            size: 52,
                                            showGlow: isEquipped,
                                          ),
                                        ),
                                        if (!isUnlocked)
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(3.5),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF1E212E)
                                                    : const Color(0xFF4A4E5C),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: sheetBg,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.lock_rounded,
                                                size: 10,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    // Frame Name
                                    Text(
                                      frame.getName(context),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: isEquipped
                                            ? FontWeight.w900
                                            : FontWeight.w600,
                                        color: isEquipped
                                            ? (isDark
                                                ? Colors.white
                                                : AppColors.primaryBlueDark)
                                            : textPrimary,
                                      ),
                                    ),

                                    const SizedBox(height: 2),

                                    if (isEquipped)
                                      Container(
                                        margin: const EdgeInsets.only(top: 2),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E3A8A)
                                              .withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(
                                              AppSizes.radiusPill),
                                        ),
                                        child: Text(
                                          context.l10n.currentEquipped,
                                          style: const TextStyle(
                                            color: Color(0xFF60A5FA),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            height: 1.0,
                                          ),
                                        ),
                                      )
                                    else
                                      Text(
                                        '${frame.requiredStreak}+',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 7. NEXT MILESTONE PROGRESS CARD
                      Text(
                        context.l10n.nextMilestone,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C1F2B)
                              : AppColors.surface(context),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppColors.innerBorder(context),
                          ),
                        ),
                        child: nextMilestone != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.daysLeftToUnlock(
                                      nextMilestone.requiredStreak -
                                          effectiveStreak,
                                      nextMilestone.getName(context),
                                    ),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (effectiveStreak /
                                              nextMilestone.requiredStreak)
                                          .clamp(0.0, 1.0),
                                      minHeight: 8,
                                      backgroundColor: isDark
                                          ? Colors.white.withValues(alpha: 0.10)
                                          : Colors.black
                                              .withValues(alpha: 0.08),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF388AF6),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '$effectiveStreak / ${nextMilestone.requiredStreak}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.15),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.celebration_rounded,
                                        color: Color(0xFF10B981),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      context.l10n.allFramesUnlocked,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 20),

                      // 8. HOW STREAKS WORK GUIDE CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF181B26)
                              : AppColors.surface(context),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppColors.innerBorder(context),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: Color(0xFFFF9800),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.l10n.streakHowItWorksTitle,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _GuideBullet(
                              icon: Icons.flash_on_rounded,
                              text: context.l10n.streakRule1,
                            ),
                            const SizedBox(height: 8),
                            _GuideBullet(
                              icon: Icons.trending_up_rounded,
                              text: context.l10n.streakRule2,
                            ),
                            const SizedBox(height: 8),
                            _GuideBullet(
                              icon: Icons.card_giftcard_rounded,
                              text: context.l10n.streakRule3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatMetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatMetricTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2232) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.14),
            ),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyStreakRow extends StatelessWidget {
  final int currentStreak;
  final bool hasPostedToday;

  const _WeeklyStreakRow({
    required this.currentStreak,
    required this.hasPostedToday,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayWeekday = now.weekday; // 1 = Mon, 7 = Sun
    final isDark = AppColors.isDark(context);
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    final weekLabels = isVi
        ? ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
        : ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayNum = index + 1;
        final isPast = dayNum < todayWeekday;
        final isToday = dayNum == todayWeekday;
        final isActive = (isPast && currentStreak > (todayWeekday - dayNum)) ||
            (isToday && hasPostedToday);

        return Column(
          children: [
            Text(
              weekLabels[index],
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                color: isToday
                    ? const Color(0xFFFF5722)
                    : AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isActive
                    ? null
                    : (isDark
                        ? const Color(0xFF262A38)
                        : const Color(0xFFE5E7EB)),
                border: isToday
                    ? Border.all(
                        color: const Color(0xFFFF5722),
                        width: 2,
                      )
                    : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF5722).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isActive
                    ? const Icon(
                        Icons.local_fire_department_rounded,
                        size: 20,
                        color: Colors.white,
                      )
                    : (isPast
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          )
                        : null),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _GuideBullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _GuideBullet({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFFFF5722),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
