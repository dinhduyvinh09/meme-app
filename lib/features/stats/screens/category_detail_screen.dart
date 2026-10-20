import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../capture/widgets/transaction_moment_image.dart';
import '../../home/screens/moment_viewer_screen.dart';
import '../../home/screens/transaction_browse_screen.dart';
import '../../profile/controllers/profile_controller.dart';
import 'category_photos_screen.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String category;
  final String type;
  final String periodTitle;
  final List<TransactionModel> transactions;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.type,
    required this.periodTitle,
    required this.transactions,
  });

  Color _categoryColor(String categoryName, String categoryType) {
    if (categoryType == 'income') {
      return AppColors.income;
    }

    switch (categoryName.trim()) {
      case 'Ăn uống':
      case 'Food':
        return const Color(0xFFFF8A00);
      case 'Mua sắm':
      case 'Shopping':
        return const Color(0xFF8B5CF6);
      case 'Đi lại':
      case 'Transport':
        return const Color(0xFF388AF6);
      case 'Giải trí':
      case 'Entertainment':
        return const Color(0xFFEC4899);
      case 'Học tập':
      case 'Education':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _categoryIcon(String categoryName, String categoryType) {
    if (categoryType == 'income') {
      return Icons.account_balance_wallet_rounded;
    }

    switch (categoryName.trim()) {
      case 'Ăn uống':
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Mua sắm':
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Đi lại':
      case 'Transport':
        return Icons.directions_bus_rounded;
      case 'Giải trí':
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Học tập':
      case 'Education':
        return Icons.menu_book_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  String _formatMoney(double value, String currency) {
    return AppCurrencyFormatter.formatFromVnd(
      amountVnd: value,
      currency: currency,
    );
  }

  String _formatCompactMoney(TransactionModel tx, String currency) {
    final formatted = AppCurrencyFormatter.formatFromVnd(
      amountVnd: tx.amount,
      currency: currency,
    );
    return '${tx.type == 'expense' ? '-' : '+'}$formatted';
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('HH:mm - dd/MM/yyyy').format(date);
  }

  String _localizedCategoryLabel(BuildContext context, String value) {
    final l10n = context.l10n;
    switch (value.trim()) {
      case 'Ăn uống':
      case 'Food':
        return l10n.food;
      case 'Mua sắm':
      case 'Shopping':
        return l10n.shopping;
      case 'Đi lại':
      case 'Transport':
        return l10n.transport;
      case 'Giải trí':
      case 'Entertainment':
        return l10n.entertainment;
      case 'Học tập':
      case 'Education':
        return l10n.education;
      case 'Lương':
      case 'Salary':
        return l10n.salary;
      case 'Quà tặng':
      case 'Gift':
        return l10n.gift;
      case 'Khác':
      case 'Other':
        return l10n.other;
      default:
        return BudgetNameLocalizer.display(context, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = context.watch<ProfileController>().currency;

    final bgColor = AppColors.background(context);
    final secondaryText = AppColors.textSecondary(context);

    final accent = _categoryColor(category, type);
    final icon = _categoryIcon(category, type);

    final total = transactions.fold<double>(
      0,
      (sum, tx) => sum + tx.amount,
    );

    final average = transactions.isEmpty ? 0.0 : total / transactions.length;

    final photoTransactions = transactions
        .where((tx) => tx.displayImageUrl.trim().isNotEmpty)
        .toList();
    final imageCount = photoTransactions.length;
    final previewTransactions = photoTransactions.take(3).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: _CategoryDetailTopBar(
            title: _localizedCategoryLabel(context, category),
            periodTitle: periodTitle,
            onBack: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // 1. Hero Spending Card
            _HeroCategoryCard(
              categoryName: _localizedCategoryLabel(context, category),
              periodTitle: periodTitle,
              totalAmountText: _formatMoney(total, currency),
              transactionCount: transactions.length,
              accentColor: accent,
              icon: icon,
            ),

            const SizedBox(height: 14),

            // 2. Quick Key Performance Metrics
            Row(
              children: [
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.receipt_long_rounded,
                    iconColor: AppColors.primaryBlue,
                    value: '${transactions.length}',
                    label: l10n.total,
                    onTap: transactions.isEmpty
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionBrowseScreen(
                                  initialTransactions: transactions,
                                ),
                              ),
                            );
                          },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.query_stats_rounded,
                    iconColor: const Color(0xFF10B981),
                    value: _formatMoney(average, currency),
                    label: l10n.average,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.photo_library_rounded,
                    iconColor: const Color(0xFFEC4899),
                    value: '$imageCount',
                    label: l10n.allPhotos,
                    onTap: photoTransactions.isEmpty
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryPhotosScreen(
                                  category: category,
                                  type: type,
                                  periodTitle: periodTitle,
                                  transactions: photoTransactions,
                                ),
                              ),
                            );
                          },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 3. Photo Moments Section (if photos exist)
            if (photoTransactions.isNotEmpty) ...[
              _SectionContainer(
                title: l10n.allPhotos,
                icon: Icons.camera_alt_rounded,
                badgeCount: photoTransactions.length,
                actionText: photoTransactions.length > 3 ? l10n.seeAll : null,
                onActionTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryPhotosScreen(
                        category: category,
                        type: type,
                        periodTitle: periodTitle,
                        transactions: photoTransactions,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: previewTransactions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final tx = entry.value;

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 0 : 4,
                          right:
                              index == previewTransactions.length - 1 ? 0 : 4,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MomentViewerScreen(
                                  transactions: photoTransactions,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
                          child: _MomentThumbnailCard(
                            transaction: tx,
                            amountText: _formatCompactMoney(tx, currency),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 4. Recent Transactions Timeline Section
            _SectionContainer(
              title: l10n.recentTransactions,
              icon: Icons.history_rounded,
              badgeCount: transactions.length,
              actionText: transactions.length > 5 ? l10n.seeAll : null,
              onActionTap: transactions.length > 5
                  ? () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionBrowseScreen(
                            initialTransactions: transactions,
                          ),
                        ),
                      );
                    }
                  : null,
              child: transactions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 40,
                              color: secondaryText.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noTransactions,
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: (transactions.length > 5
                              ? transactions.take(5)
                              : transactions)
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final tx = entry.value;

                        return _TransactionTimelineTile(
                          transaction: tx,
                          icon: icon,
                          accent: accent,
                          amountText: _formatCompactMoney(tx, currency),
                          categoryText:
                              _localizedCategoryLabel(context, tx.category),
                          timeText: _formatDateTime(tx.createdAt),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MomentViewerScreen(
                                  transactions: transactions,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// UI SUBCOMPONENTS
// -------------------------------------------------------------

class _CategoryDetailTopBar extends StatelessWidget {
  final String title;
  final String periodTitle;
  final VoidCallback onBack;

  const _CategoryDetailTopBar({
    required this.title,
    required this.periodTitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border(context).withValues(alpha: 0.6),
            width: 0.7,
          ),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onBack();
            },
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.card(context),
                border: Border.all(
                  color: AppColors.border(context),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary(context),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageTitle(context).copyWith(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  periodTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCategoryCard extends StatelessWidget {
  final String categoryName;
  final String periodTitle;
  final String totalAmountText;
  final int transactionCount;
  final Color accentColor;
  final IconData icon;

  const _HeroCategoryCard({
    required this.categoryName,
    required this.periodTitle,
    required this.totalAmountText,
    required this.transactionCount,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            accentColor,
            Color.lerp(
                    accentColor, isDark ? Colors.black : Colors.white, 0.35) ??
                accentColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -20,
            child: Icon(
              icon,
              size: 130,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.40),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            periodTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.total,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  totalAmountText,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _QuickStatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border(context),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.14),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 16,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? badgeCount;
  final String? actionText;
  final VoidCallback? onActionTap;
  final Widget child;

  const _SectionContainer({
    required this.title,
    required this.icon,
    this.badgeCount,
    this.actionText,
    this.onActionTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.sectionTitle(context).copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (badgeCount != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (actionText != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onActionTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionText!,
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primaryBlue,
                        size: 18,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MomentThumbnailCard extends StatelessWidget {
  final TransactionModel transaction;
  final String amountText;

  const _MomentThumbnailCard({
    required this.transaction,
    required this.amountText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TransactionMomentImage(
                  imageUrl: transaction.imageUrl,
                  category: transaction.category,
                  caption: transaction.caption,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: BorderRadius.circular(14),
                ),
                Positioned(
                  bottom: 6,
                  left: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      amountText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionTimelineTile extends StatelessWidget {
  final TransactionModel transaction;
  final IconData icon;
  final Color accent;
  final String amountText;
  final String categoryText;
  final String timeText;
  final VoidCallback onTap;

  const _TransactionTimelineTile({
    required this.transaction,
    required this.icon,
    required this.accent,
    required this.amountText,
    required this.categoryText,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = transaction.caption.trim().isEmpty
        ? categoryText
        : transaction.caption.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.innerBorder(context),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.14),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeText,
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amountText,
                style: TextStyle(
                  color: transaction.type == 'expense'
                      ? AppColors.expense
                      : AppColors.income,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
