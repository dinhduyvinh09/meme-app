import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icon_registry.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../capture/widgets/transaction_moment_image.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/home_controller.dart';
import 'moment_viewer_screen.dart';

enum TimeFilterOption {
  all,
  today,
  last7days,
  thisMonth,
  lastMonth,
  thisYear,
  customRange,
}

enum TypeFilterOption {
  all,
  expense,
  income,
}

enum SortOption {
  newest,
  oldest,
  highestAmount,
  lowestAmount,
}

enum ViewMode {
  grid,
  list,
}

class TransactionBrowseScreen extends StatefulWidget {
  final List<TransactionModel>? initialTransactions;

  const TransactionBrowseScreen({
    super.key,
    this.initialTransactions,
  });

  @override
  State<TransactionBrowseScreen> createState() =>
      _TransactionBrowseScreenState();
}

class _TransactionBrowseScreenState extends State<TransactionBrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _timeFilterKey = GlobalKey();

  String _searchQuery = '';
  TimeFilterOption _timeFilter = TimeFilterOption.all;
  DateTimeRange? _customDateRange;
  TypeFilterOption _typeFilter = TypeFilterOption.all;
  String? _selectedCategory;
  bool _hasPhotoOnly = false;
  SortOption _sortOption = SortOption.newest;
  ViewMode _viewMode = ViewMode.grid;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final text = _searchController.text.trim();
      if (text != _searchQuery) {
        setState(() {
          _searchQuery = text;
        });
      }
    });
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _matchesTimeFilter(DateTime date, DateTime now) {
    switch (_timeFilter) {
      case TimeFilterOption.all:
        return true;
      case TimeFilterOption.today:
        return _isSameDay(date, now);
      case TimeFilterOption.last7days:
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        return date.isAfter(start) || _isSameDay(date, start);
      case TimeFilterOption.thisMonth:
        return date.year == now.year && date.month == now.month;
      case TimeFilterOption.lastMonth:
        final prevYear = now.month == 1 ? now.year - 1 : now.year;
        final prevMonth = now.month == 1 ? 12 : now.month - 1;
        return date.year == prevYear && date.month == prevMonth;
      case TimeFilterOption.thisYear:
        return date.year == now.year;
      case TimeFilterOption.customRange:
        if (_customDateRange == null) return true;
        final start = DateTime(
          _customDateRange!.start.year,
          _customDateRange!.start.month,
          _customDateRange!.start.day,
        );
        final end = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
        );
        return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            date.isBefore(end.add(const Duration(seconds: 1)));
    }
  }

  String _getTimeFilterLabel(BuildContext context, TimeFilterOption option) {
    final l10n = context.l10n;
    switch (option) {
      case TimeFilterOption.all:
        return l10n.timeFilterAll;
      case TimeFilterOption.today:
        return l10n.timeFilterToday;
      case TimeFilterOption.last7days:
        return l10n.timeFilterLast7Days;
      case TimeFilterOption.thisMonth:
        return l10n.timeFilterThisMonth;
      case TimeFilterOption.lastMonth:
        return l10n.timeFilterLastMonth;
      case TimeFilterOption.thisYear:
        return l10n.timeFilterThisYear;
      case TimeFilterOption.customRange:
        if (_customDateRange != null) {
          final isVi = Localizations.localeOf(context).languageCode == 'vi';
          if (isVi) {
            return '${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}';
          }
          return '${DateFormat('d MMM').format(_customDateRange!.start)} - ${DateFormat('d MMM').format(_customDateRange!.end)}';
        }
        return isVietnamese(context) ? 'Tùy chọn ngày' : 'Custom range';
    }
  }

  bool isVietnamese(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'vi';
  }

  String _formatDateShort(BuildContext context, DateTime date) {
    if (isVietnamese(context)) {
      return '${date.day} thg ${date.month}';
    } else {
      return DateFormat('d MMM').format(date);
    }
  }

  String _formatDateHeader(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final isVi = isVietnamese(context);

    if (_isSameDay(date, now)) {
      return isVi ? 'Hôm nay' : 'Today';
    } else if (_isSameDay(date, yesterday)) {
      return isVi ? 'Hôm qua' : 'Yesterday';
    }

    if (isVi) {
      return DateFormat('EEEE, d MMMM', 'vi').format(date);
    } else {
      return DateFormat('EEEE, d MMMM').format(date);
    }
  }

  Color _parseHexColor(String? value,
      {Color fallback = const Color(0xFF4CAF50)}) {
    if (value == null || value.trim().isEmpty) return fallback;
    var cleaned = value.trim().replaceAll('#', '');
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    if (cleaned.length != 8) return fallback;
    try {
      return Color(int.parse(cleaned, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  Color _getCategoryColor(
      String category, List<TransactionModel> transactions) {
    final lower = category.toLowerCase().trim();
    for (final tx in transactions) {
      if (tx.category.toLowerCase().trim() == lower &&
          tx.categoryColorHex != null &&
          tx.categoryColorHex!.trim().isNotEmpty) {
        final parsed = _parseHexColor(tx.categoryColorHex);
        if (parsed != const Color(0xFF4CAF50)) {
          return parsed;
        }
      }
    }

    if (lower.contains('lương') ||
        lower.contains('salary') ||
        lower.contains('thu nhập')) {
      return AppColors.income;
    }
    if (lower.contains('ăn') ||
        lower.contains('food') ||
        lower.contains('uống') ||
        lower.contains('cafe')) {
      return const Color(0xFFFF8A00);
    }
    if (lower.contains('mua') || lower.contains('shop')) {
      return const Color(0xFFEC4899);
    }
    if (lower.contains('đi') ||
        lower.contains('transport') ||
        lower.contains('xe')) {
      return const Color(0xFF3B82F6);
    }
    if (lower.contains('học') ||
        lower.contains('education') ||
        lower.contains('sách')) {
      return const Color(0xFF8B7CFF);
    }
    if (lower.contains('giải trí') ||
        lower.contains('entertainment') ||
        lower.contains('game')) {
      return const Color(0xFFF43F5E);
    }
    if (lower.contains('quà') || lower.contains('gift')) {
      return const Color(0xFFF59E0B);
    }
    if (lower.contains('nhà') ||
        lower.contains('bills') ||
        lower.contains('điện') ||
        lower.contains('nước')) {
      return const Color(0xFF06B6D4);
    }
    return AppColors.primaryBlue;
  }

  IconData _getCategoryIcon(String category,
      [List<TransactionModel>? transactions]) {
    final lower = category.toLowerCase().trim();
    if (transactions != null) {
      for (final tx in transactions) {
        if (tx.category.toLowerCase().trim() == lower &&
            tx.categoryIconCodePoint != null &&
            tx.categoryIconCodePoint! > 0) {
          return AppIconRegistry.fromCodePoint(tx.categoryIconCodePoint!);
        }
      }
    }
    if (lower.contains('lương') || lower.contains('salary')) {
      return Icons.payments_outlined;
    }
    if (lower.contains('ăn') ||
        lower.contains('food') ||
        lower.contains('uống')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('mua') || lower.contains('shop')) {
      return Icons.shopping_bag_outlined;
    }
    if (lower.contains('đi') ||
        lower.contains('transport') ||
        lower.contains('xe')) {
      return Icons.directions_car_outlined;
    }
    if (lower.contains('học') || lower.contains('education')) {
      return Icons.school_outlined;
    }
    if (lower.contains('giải trí') || lower.contains('entertainment')) {
      return Icons.sports_esports_outlined;
    }
    if (lower.contains('quà') || lower.contains('gift')) {
      return Icons.card_giftcard_outlined;
    }
    return Icons.category_outlined;
  }

  void _showTimeFilterMenu() async {
    final renderBox =
        _timeFilterKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + size.height + 6,
      offset.dx + size.width,
      0,
    );

    final l10n = context.l10n;
    final isVi = isVietnamese(context);

    final options = [
      {
        'option': TimeFilterOption.all,
        'label': l10n.timeFilterAll,
        'symbol': '∞'
      },
      {
        'option': TimeFilterOption.today,
        'label': l10n.timeFilterToday,
        'icon': Icons.wb_sunny_outlined
      },
      {
        'option': TimeFilterOption.last7days,
        'label': l10n.timeFilterLast7Days,
        'icon': Icons.view_week_outlined
      },
      {
        'option': TimeFilterOption.thisMonth,
        'label': l10n.timeFilterThisMonth,
        'icon': Icons.calendar_month_outlined
      },
      {
        'option': TimeFilterOption.lastMonth,
        'label': l10n.timeFilterLastMonth,
        'icon': Icons.calendar_today_outlined
      },
      {
        'option': TimeFilterOption.thisYear,
        'label': l10n.timeFilterThisYear,
        'icon': Icons.event_available_outlined
      },
      {
        'option': TimeFilterOption.customRange,
        'label': isVi ? 'Tùy chọn khoảng ngày...' : 'Custom date range...',
        'icon': Icons.date_range_outlined
      },
    ];

    final selected = await showMenu<TimeFilterOption>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppColors.border(context),
          width: 0.8,
        ),
      ),
      color: AppColors.card(context),
      elevation: 8,
      items: options.map((item) {
        final opt = item['option'] as TimeFilterOption;
        final label = item['label'] as String;
        final icon = item['icon'] as IconData?;
        final symbol = item['symbol'] as String?;
        final isCurrent = _timeFilter == opt;

        return PopupMenuItem<TimeFilterOption>(
          value: opt,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                child: isCurrent
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.primaryBlue,
                        size: 18,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 6),
              if (symbol != null)
                Text(
                  symbol,
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (icon != null)
                Icon(
                  icon,
                  color: AppColors.textSecondary(context),
                  size: 18,
                ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isCurrent
                      ? AppColors.primaryBlue
                      : AppColors.textPrimary(context),
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

    if (selected != null) {
      AppHaptics.selectionClick();
      if (selected == TimeFilterOption.customRange) {
        _pickCustomDateRange();
      } else {
        setState(() {
          _timeFilter = selected;
          _customDateRange = null;
        });
      }
    }
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final initialRange = _customDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 14)),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
      initialDateRange: initialRange,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: AppColors.primaryBlue,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      AppHaptics.lightImpact();
      setState(() {
        _timeFilter = TimeFilterOption.customRange;
        _customDateRange = picked;
      });
    }
  }

  void _showSortOptionSheet() {
    final isVi = isVietnamese(context);
    final sortItems = [
      {
        'option': SortOption.newest,
        'label': isVi ? 'Mới nhất trước' : 'Newest first',
        'icon': Icons.arrow_downward_rounded
      },
      {
        'option': SortOption.oldest,
        'label': isVi ? 'Cũ nhất trước' : 'Oldest first',
        'icon': Icons.arrow_upward_rounded
      },
      {
        'option': SortOption.highestAmount,
        'label': isVi ? 'Số tiền: Cao đến Thấp' : 'Amount: High to Low',
        'icon': Icons.trending_up_rounded
      },
      {
        'option': SortOption.lowestAmount,
        'label': isVi ? 'Số tiền: Thấp đến Cao' : 'Amount: Low to High',
        'icon': Icons.trending_down_rounded
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border(ctx),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isVi ? 'Sắp xếp theo' : 'Sort by',
                  style: TextStyle(
                    color: AppColors.textPrimary(ctx),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...sortItems.map((item) {
                  final opt = item['option'] as SortOption;
                  final label = item['label'] as String;
                  final icon = item['icon'] as IconData;
                  final isSelected = _sortOption == opt;

                  return InkWell(
                    onTap: () {
                      AppHaptics.lightImpact();
                      setState(() => _sortOption = opt);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                      .withValues(alpha: 0.15)
                                  : AppColors.surface(ctx),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              icon,
                              size: 18,
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.textSecondary(ctx),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.textPrimary(ctx),
                                fontSize: 14.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primaryBlue,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAllCategoriesSheet(
      List<String> categories, List<TransactionModel> rawTransactions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final l10n = ctx.l10n;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border(ctx),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.allCategories,
                          style: TextStyle(
                            color: AppColors.textPrimary(ctx),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_selectedCategory != null)
                          TextButton(
                            onPressed: () {
                              AppHaptics.lightImpact();
                              setState(() => _selectedCategory = null);
                              Navigator.pop(ctx);
                            },
                            child: Text(
                              l10n.timeFilterAll,
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: categories.map((cat) {
                            final isSelected =
                                _selectedCategory?.toLowerCase() ==
                                    cat.toLowerCase();
                            final displayName =
                                BudgetNameLocalizer.display(context, cat);
                            final catColor =
                                _getCategoryColor(cat, rawTransactions);
                            final icon = _getCategoryIcon(cat, rawTransactions);
                            final count = rawTransactions
                                .where((t) =>
                                    t.category.toLowerCase() ==
                                    cat.toLowerCase())
                                .length;

                            return InkWell(
                              onTap: () {
                                AppHaptics.lightImpact();
                                setState(() {
                                  _selectedCategory = isSelected ? null : cat;
                                });
                                Navigator.pop(ctx);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? catColor.withValues(alpha: 0.22)
                                      : catColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? catColor
                                        : catColor.withValues(alpha: 0.3),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon, color: catColor, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      displayName,
                                      style: TextStyle(
                                        color: isSelected
                                            ? catColor
                                            : AppColors.textPrimary(ctx),
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: catColor.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          color: catColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _resetAllFilters() {
    AppHaptics.mediumImpact();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _timeFilter = TimeFilterOption.all;
      _customDateRange = null;
      _typeFilter = TypeFilterOption.all;
      _selectedCategory = null;
      _hasPhotoOnly = false;
      _sortOption = SortOption.newest;
    });
  }

  bool get _hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _timeFilter != TimeFilterOption.all ||
        _customDateRange != null ||
        _typeFilter != TypeFilterOption.all ||
        _selectedCategory != null ||
        _hasPhotoOnly ||
        _sortOption != SortOption.newest;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isVi = isVietnamese(context);
    final homeController = context.watch<HomeController>();
    final rawTransactions = (widget.initialTransactions != null &&
            widget.initialTransactions!.isNotEmpty)
        ? widget.initialTransactions!
        : homeController.transactions;

    final profileController = context.watch<ProfileController>();
    final currency = profileController.currency;
    final now = DateTime.now();

    // 1. Filter Transactions
    final filteredTransactions = rawTransactions.where((tx) {
      // 1.1 Time Filter
      if (!_matchesTimeFilter(tx.createdAt, now)) return false;

      // 1.2 Type Filter
      if (_typeFilter == TypeFilterOption.expense && !tx.isPersonalExpense) {
        return false;
      }
      if (_typeFilter == TypeFilterOption.income && !tx.isPersonalIncome) {
        return false;
      }

      // 1.3 Category Filter
      if (_selectedCategory != null &&
          tx.category.toLowerCase() != _selectedCategory!.toLowerCase()) {
        return false;
      }

      // 1.4 Has Photo Filter
      if (_hasPhotoOnly) {
        final hasMedia = tx.displayImageUrl.trim().isNotEmpty ||
            tx.imageUrl.trim().isNotEmpty;
        if (!hasMedia) return false;
      }

      // 1.5 Keyword Search Filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final caption = tx.caption.toLowerCase();
        final note = tx.note.toLowerCase();
        final category = tx.category.toLowerCase();
        final localizedCat =
            BudgetNameLocalizer.display(context, tx.category).toLowerCase();
        final location = tx.locationName.toLowerCase();
        final group = (tx.groupName ?? '').toLowerCase();
        final amountStr = tx.amount.toStringAsFixed(0);
        final formattedMoney = AppCurrencyFormatter.formatFromVnd(
                amountVnd: tx.amount, currency: currency)
            .toLowerCase();

        final matches = caption.contains(q) ||
            note.contains(q) ||
            category.contains(q) ||
            localizedCat.contains(q) ||
            location.contains(q) ||
            group.contains(q) ||
            amountStr.contains(q) ||
            formattedMoney.contains(q);

        if (!matches) return false;
      }

      return true;
    }).toList();

    // 2. Sort Transactions
    switch (_sortOption) {
      case SortOption.newest:
        filteredTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.oldest:
        filteredTransactions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.highestAmount:
        filteredTransactions.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortOption.lowestAmount:
        filteredTransactions.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    // 3. Stats Calculation
    double totalExpense = 0;
    double totalIncome = 0;
    for (final tx in filteredTransactions) {
      if (tx.isPersonalExpense) {
        totalExpense += tx.amount;
      } else if (tx.isPersonalIncome) {
        totalIncome += tx.amount;
      }
    }
    final netAmount = totalIncome - totalExpense;

    // 4. Unique Categories
    final uniqueCategories = rawTransactions
        .map((e) => e.category.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (uniqueCategories.isEmpty) {
      uniqueCategories
          .addAll(['Lương', 'Ăn uống', 'Mua sắm', 'Giải trí', 'Đi lại']);
    }

    // Labels
    final timeLabel = _timeFilter == TimeFilterOption.all
        ? '∞ ${l10n.timeFilterLabel}'
        : _getTimeFilterLabel(context, _timeFilter);

    final periodCardTitle = _timeFilter == TimeFilterOption.all
        ? l10n.timeFilterAll
        : _getTimeFilterLabel(context, _timeFilter);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar: Back button, Title + Results Badge, Sort & View Mode Switcher
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Back / Close button
                    InkWell(
                      onTap: () {
                        AppHaptics.lightImpact();
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.card(context),
                          border: Border.all(
                            color: AppColors.border(context),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Title & Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.browseTransactionsTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isVi
                                ? '${filteredTransactions.length} giao dịch'
                                : '${filteredTransactions.length} transactions',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Sort Button
                    InkWell(
                      onTap: _showSortOptionSheet,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: _sortOption != SortOption.newest
                              ? AppColors.primaryBlue.withValues(alpha: 0.15)
                              : AppColors.card(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _sortOption != SortOption.newest
                                ? AppColors.primaryBlue
                                : AppColors.border(context),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          Icons.swap_vert_rounded,
                          size: 20,
                          color: _sortOption != SortOption.newest
                              ? AppColors.primaryBlue
                              : AppColors.textPrimary(context),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // View Mode Switcher (Grid <-> List)
                    InkWell(
                      onTap: () {
                        AppHaptics.selectionClick();
                        setState(() {
                          _viewMode = _viewMode == ViewMode.grid
                              ? ViewMode.list
                              : ViewMode.grid;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.border(context),
                            width: 0.8,
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            _viewMode == ViewMode.grid
                                ? Icons.view_agenda_rounded
                                : Icons.grid_view_rounded,
                            key: ValueKey(_viewMode),
                            size: 19,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: GestureDetector(
                  onTap: () => _searchFocusNode.requestFocus(),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: _searchFocusNode.hasFocus
                            ? AppColors.primaryBlue
                            : AppColors.border(context),
                        width: _searchFocusNode.hasFocus ? 1.4 : 0.8,
                      ),
                      boxShadow: _searchFocusNode.hasFocus
                          ? [
                              BoxShadow(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.16),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: _searchFocusNode.hasFocus
                              ? AppColors.primaryBlue
                              : AppColors.textSecondary(context),
                          size: 21,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: TextStyle(
                              color: AppColors.textPrimary(context),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                            cursorColor: AppColors.primaryBlue,
                            decoration: InputDecoration(
                              hintText: l10n.browseTransactionsSearchHint,
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary(context)
                                    .withValues(alpha: 0.65),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              AppHaptics.lightImpact();
                              _searchController.clear();
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary(context)
                                      .withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textPrimary(context),
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Scrollable Filter & Results Section
              Expanded(
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Filter Row 1: Time selector + Type Segment (Tất cả / Chi tiêu / Thu nhập)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Time Filter Pill Button
                                  GestureDetector(
                                    key: _timeFilterKey,
                                    onTap: _showTimeFilterMenu,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 7.5),
                                      decoration: BoxDecoration(
                                        color:
                                            _timeFilter != TimeFilterOption.all
                                                ? AppColors.primaryBlue
                                                    .withValues(alpha: 0.12)
                                                : AppColors.surface(context),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _timeFilter !=
                                                  TimeFilterOption.all
                                              ? AppColors.primaryBlue
                                              : AppColors.border(context),
                                          width: _timeFilter !=
                                                  TimeFilterOption.all
                                              ? 1.2
                                              : 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            timeLabel,
                                            style: TextStyle(
                                              color: _timeFilter !=
                                                      TimeFilterOption.all
                                                  ? AppColors.primaryBlue
                                                  : AppColors.textPrimary(
                                                      context),
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: _timeFilter !=
                                                    TimeFilterOption.all
                                                ? AppColors.primaryBlue
                                                : AppColors.textSecondary(
                                                    context),
                                            size: 17,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // Segmented Type Selector
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface(context),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: AppColors.border(context),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildTypeSegmentItem(
                                          label: l10n.typeFilterAll,
                                          isSelected: _typeFilter ==
                                              TypeFilterOption.all,
                                          activeColor: AppColors.primaryBlue,
                                          onTap: () {
                                            if (_typeFilter !=
                                                TypeFilterOption.all) {
                                              AppHaptics.lightImpact();
                                              setState(() => _typeFilter =
                                                  TypeFilterOption.all);
                                            }
                                          },
                                        ),
                                        _buildTypeSegmentItem(
                                          label: l10n.typeFilterExpense,
                                          isSelected: _typeFilter ==
                                              TypeFilterOption.expense,
                                          activeColor: AppColors.expense,
                                          onTap: () {
                                            if (_typeFilter !=
                                                TypeFilterOption.expense) {
                                              AppHaptics.lightImpact();
                                              setState(() => _typeFilter =
                                                  TypeFilterOption.expense);
                                            }
                                          },
                                        ),
                                        _buildTypeSegmentItem(
                                          label: l10n.typeFilterIncome,
                                          isSelected: _typeFilter ==
                                              TypeFilterOption.income,
                                          activeColor: AppColors.income,
                                          onTap: () {
                                            if (_typeFilter !=
                                                TypeFilterOption.income) {
                                              AppHaptics.lightImpact();
                                              setState(() => _typeFilter =
                                                  TypeFilterOption.income);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Summary Card with Background Bubbles
                          _buildSummaryCard(
                            context: context,
                            periodCardTitle: periodCardTitle,
                            totalExpense: totalExpense,
                            totalIncome: totalIncome,
                            netAmount: netAmount,
                            totalCount: filteredTransactions.length,
                            currency: currency,
                            isVi: isVi,
                          ),

                          const SizedBox(height: 12),

                          // Horizontal Category Pills & Media Filter
                          SizedBox(
                            height: 38,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                // Has Photo filter chip
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      AppHaptics.lightImpact();
                                      setState(() {
                                        _hasPhotoOnly = !_hasPhotoOnly;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: _hasPhotoOnly
                                            ? AppColors.primaryPurple
                                                .withValues(alpha: 0.2)
                                            : AppColors.surface(context),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _hasPhotoOnly
                                              ? AppColors.primaryPurple
                                              : AppColors.border(context),
                                          width: _hasPhotoOnly ? 1.2 : 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.photo_camera_rounded,
                                            size: 15,
                                            color: _hasPhotoOnly
                                                ? AppColors.primaryPurple
                                                : AppColors.textSecondary(
                                                    context),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isVi ? 'Có ảnh' : 'Has photo',
                                            style: TextStyle(
                                              color: _hasPhotoOnly
                                                  ? AppColors.primaryPurple
                                                  : AppColors.textPrimary(
                                                      context),
                                              fontSize: 13,
                                              fontWeight: _hasPhotoOnly
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Top Category chips
                                ...uniqueCategories.take(5).map((cat) {
                                  final isSelected =
                                      _selectedCategory?.toLowerCase() ==
                                          cat.toLowerCase();
                                  final catName =
                                      BudgetNameLocalizer.display(context, cat);
                                  final catColor =
                                      _getCategoryColor(cat, rawTransactions);
                                  final icon =
                                      _getCategoryIcon(cat, rawTransactions);

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () {
                                        AppHaptics.lightImpact();
                                        setState(() {
                                          _selectedCategory =
                                              isSelected ? null : cat;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? catColor.withValues(alpha: 0.24)
                                              : catColor.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected
                                                ? catColor
                                                : catColor.withValues(
                                                    alpha: 0.28),
                                            width: isSelected ? 1.2 : 0.8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(icon,
                                                color: catColor, size: 14),
                                            const SizedBox(width: 6),
                                            Text(
                                              catName,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? catColor
                                                    : catColor.withValues(
                                                        alpha: 0.9),
                                                fontSize: 13,
                                                fontWeight: isSelected
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),

                                // "All categories" button
                                GestureDetector(
                                  onTap: () {
                                    AppHaptics.lightImpact();
                                    _showAllCategoriesSheet(
                                        uniqueCategories, rawTransactions);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface(context),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _selectedCategory != null &&
                                                !uniqueCategories
                                                    .take(5)
                                                    .contains(_selectedCategory)
                                            ? AppColors.primaryBlue
                                            : AppColors.border(context),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.category_outlined,
                                          color:
                                              AppColors.textSecondary(context),
                                          size: 15,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          l10n.allCategories,
                                          style: TextStyle(
                                            color:
                                                AppColors.textPrimary(context),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Active Filter Chips Bar (if any filters active)
                          if (_hasActiveFilters) ...[
                            const SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          if (_searchQuery.isNotEmpty)
                                            _buildActiveChip(
                                              label: '"$_searchQuery"',
                                              onDelete: () =>
                                                  _searchController.clear(),
                                            ),
                                          if (_timeFilter !=
                                              TimeFilterOption.all)
                                            _buildActiveChip(
                                              label: _getTimeFilterLabel(
                                                  context, _timeFilter),
                                              onDelete: () => setState(() {
                                                _timeFilter =
                                                    TimeFilterOption.all;
                                                _customDateRange = null;
                                              }),
                                            ),
                                          if (_typeFilter !=
                                              TypeFilterOption.all)
                                            _buildActiveChip(
                                              label: _typeFilter ==
                                                      TypeFilterOption.expense
                                                  ? l10n.typeFilterExpense
                                                  : l10n.typeFilterIncome,
                                              onDelete: () => setState(() =>
                                                  _typeFilter =
                                                      TypeFilterOption.all),
                                            ),
                                          if (_selectedCategory != null)
                                            _buildActiveChip(
                                              label:
                                                  BudgetNameLocalizer.display(
                                                      context,
                                                      _selectedCategory!),
                                              onDelete: () => setState(() =>
                                                  _selectedCategory = null),
                                            ),
                                          if (_hasPhotoOnly)
                                            _buildActiveChip(
                                              label: isVi
                                                  ? 'Chỉ có ảnh'
                                                  : 'Photo only',
                                              onDelete: () => setState(
                                                  () => _hasPhotoOnly = false),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: _resetAllFilters,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface(context),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isVi ? 'Đặt lại' : 'Reset',
                                        style: const TextStyle(
                                          color: AppColors.primaryBlue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),

                    // Results: Grid View / List View / Empty State
                    if (filteredTransactions.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue
                                        .withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.search_off_rounded,
                                    color: AppColors.primaryBlue,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.noTransactionsFound,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textPrimary(context),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isVi
                                      ? 'Thử thay đổi từ khóa hoặc xóa bớt các bộ lọc để xem nhiều giao dịch hơn'
                                      : 'Try modifying your search or clearing filters to see more results',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary(context),
                                    fontSize: 13.5,
                                    height: 1.4,
                                  ),
                                ),
                                if (_hasActiveFilters) ...[
                                  const SizedBox(height: 18),
                                  ElevatedButton.icon(
                                    onPressed: _resetAllFilters,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 18),
                                    label: Text(
                                      isVi
                                          ? 'Xóa tất cả bộ lọc'
                                          : 'Clear all filters',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (_viewMode == ViewMode.grid)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          2,
                          16,
                          MediaQuery.of(context).padding.bottom + 32,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.74,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, index) {
                              final tx = filteredTransactions[index];
                              return _buildMomentGridItem(
                                context: ctx,
                                transaction: tx,
                                currency: currency,
                                index: index,
                                allFiltered: filteredTransactions,
                              );
                            },
                            childCount: filteredTransactions.length,
                          ),
                        ),
                      )
                    else
                      _buildGroupedListView(
                        context: context,
                        transactions: filteredTransactions,
                        currency: currency,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveChip({
    required String label,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                AppHaptics.lightImpact();
                onDelete();
              },
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBigAmount(double net, String currency) {
    final absFormatted = AppCurrencyFormatter.formatFromVnd(
      amountVnd: net.abs(),
      currency: currency,
    );
    if (net > 0) {
      return '+$absFormatted';
    } else if (net < 0) {
      return '-$absFormatted';
    }
    return absFormatted;
  }

  Widget _buildTypeSegmentItem({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary(context),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMomentGridItem({
    required BuildContext context,
    required TransactionModel transaction,
    required String currency,
    required int index,
    required List<TransactionModel> allFiltered,
  }) {
    final formattedMoney = AppCurrencyFormatter.formatFromVnd(
      amountVnd: transaction.amount,
      currency: currency,
    );
    final amountDisplay =
        transaction.type == 'expense' ? '-$formattedMoney' : '+$formattedMoney';

    final dateDisplay = _formatDateShort(context, transaction.createdAt);
    final categoryDisplay =
        BudgetNameLocalizer.display(context, transaction.category);
    final categoryColor = _parseHexColor(
      transaction.categoryColorHex,
      fallback: transaction.type == 'expense'
          ? const Color(0xFF4CAF50)
          : const Color(0xFF4CAF50),
    );

    final caption = transaction.caption.trim();

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          AppHaptics.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MomentViewerScreen(
                transactions: allFiltered,
                initialIndex: index,
              ),
            ),
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Card with Overlay
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    TransactionMomentImage(
                      imageUrl: transaction.displayImageUrl,
                      category: transaction.category,
                      categoryIconCodePoint: transaction.categoryIconCodePoint,
                      categoryColorHex: transaction.categoryColorHex,
                      caption: transaction.caption,
                      width: double.infinity,
                      height: double.infinity,
                      isVideo: transaction.isVideo,
                    ),

                    // Top Right Badges (Video badge if video)
                    if (transaction.isVideo)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.videocam_rounded,
                                  color: Colors.white, size: 12),
                            ],
                          ),
                        ),
                      ),

                    // Bottom Gradient Shadow for legibility
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 75,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.88),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Overlay Content
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 8,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Amount on Bottom-Left
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                amountDisplay,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 6),

                          // Date & Category on Bottom-Right
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                dateDisplay,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: categoryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 65),
                                    child: Text(
                                      categoryDisplay,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Caption underneath card
            if (caption.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedListView({
    required BuildContext context,
    required List<TransactionModel> transactions,
    required String currency,
  }) {
    // Group transactions by date
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in transactions) {
      final dateKey =
          '${tx.createdAt.year}-${tx.createdAt.month}-${tx.createdAt.day}';
      grouped.putIfAbsent(dateKey, () => []).add(tx);
    }

    final dateKeys = grouped.keys.toList();

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        MediaQuery.of(context).padding.bottom + 32,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, index) {
            final key = dateKeys[index];
            final dayTxList = grouped[key]!;
            final firstDate = dayTxList.first.createdAt;
            final dayHeader = _formatDateHeader(ctx, firstDate);

            // Calculate day total
            double dayTotal = 0;
            for (final tx in dayTxList) {
              if (tx.isPersonalExpense) {
                dayTotal -= tx.amount;
              } else if (tx.isPersonalIncome) {
                dayTotal += tx.amount;
              }
            }

            final dayTotalFormatted = AppCurrencyFormatter.formatFromVnd(
              amountVnd: dayTotal.abs(),
              currency: currency,
            );
            final dayTotalSign =
                dayTotal > 0 ? '+$dayTotalFormatted' : '-$dayTotalFormatted';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day Header Bar
                Padding(
                  padding: const EdgeInsets.only(
                      top: 14, bottom: 8, left: 4, right: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dayHeader,
                        style: TextStyle(
                          color: AppColors.textPrimary(ctx),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        dayTotalSign,
                        style: TextStyle(
                          color: dayTotal >= 0
                              ? AppColors.income
                              : AppColors.textSecondary(ctx),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Transactions for this day
                ...dayTxList.map((tx) {
                  final globalIndex = transactions.indexOf(tx);
                  return _buildTransactionListItem(
                    context: ctx,
                    transaction: tx,
                    currency: currency,
                    index: globalIndex,
                    allFiltered: transactions,
                  );
                }),
              ],
            );
          },
          childCount: dateKeys.length,
        ),
      ),
    );
  }

  Widget _buildTransactionListItem({
    required BuildContext context,
    required TransactionModel transaction,
    required String currency,
    required int index,
    required List<TransactionModel> allFiltered,
  }) {
    final isExpense = transaction.isPersonalExpense;
    final amountColor = isExpense ? AppColors.expense : AppColors.income;
    final sign = isExpense ? '-' : '+';
    final formattedAmount = AppCurrencyFormatter.formatFromVnd(
      amountVnd: transaction.amount,
      currency: currency,
    );

    final categoryLabel =
        BudgetNameLocalizer.display(context, transaction.category);
    final categoryColor = _getCategoryColor(transaction.category, allFiltered);
    final caption = transaction.caption.trim();
    final title = caption.isNotEmpty ? caption : categoryLabel;
    final timeStr = DateFormat('HH:mm').format(transaction.createdAt);

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
            color: AppColors.border(context),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppColors.isDark(context) ? 0.12 : 0.03,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          onTap: () {
            AppHaptics.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MomentViewerScreen(
                  transactions: allFiltered,
                  initialIndex: index < 0 ? 0 : index,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Thumbnail / Moment image
                TransactionMomentImage(
                  imageUrl: transaction.displayImageUrl,
                  category: transaction.category,
                  categoryIconCodePoint: transaction.categoryIconCodePoint,
                  categoryColorHex: transaction.categoryColorHex,
                  caption: null,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(14),
                  isVideo: transaction.isVideo,
                ),

                const SizedBox(width: 12),

                // Title, Subtitle, Category Tag
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: categoryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            categoryLabel,
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• $timeStr',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (transaction.groupName != null &&
                              transaction.groupName!.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '• ${transaction.groupName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Amount
                Text(
                  '$sign$formattedAmount',
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String periodCardTitle,
    required double totalExpense,
    required double totalIncome,
    required double netAmount,
    required int totalCount,
    required String currency,
    required bool isVi,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF5394ED),
              Color(0xFF4384DE),
              Color(0xFF3274CE),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A8AE2).withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 1. Soft atmospheric ambient glow in top-right
              Positioned(
                top: -50,
                right: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF93C5FD).withValues(alpha: 0.18),
                        const Color(0xFF60A5FA).withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // 2. Soft atmospheric ambient glow in bottom-left
              Positioned(
                bottom: -60,
                left: -40,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF2563EB).withValues(alpha: 0.25),
                        const Color(0xFF1D4ED8).withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Custom Geometric Wave & Sparkles Pattern Overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: _CardPatternPainter(),
                ),
              ),

              // Main Content with padding: 18
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hàng trên: Icon Lịch + Thời gian & Pill Chi Tiêu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.calendar_month_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  periodCardTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Pill chi tiêu (↓ 1.488.966.279 đ)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '↓ ${AppCurrencyFormatter.formatFromVnd(amountVnd: totalExpense, currency: currency)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Số tiền lớn nổi bật ở giữa (+8.927.613.501 đ)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatBigAmount(netAmount, currency),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Hàng dưới: Matches count & Pill thu nhập (↑ 10.416.579.780 đ)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          isVi
                              ? '$totalCount kết quả khớp'
                              : '$totalCount results matched',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Pill thu nhập
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '↑ ${AppCurrencyFormatter.formatFromVnd(amountVnd: totalIncome, currency: currency)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom pattern painter for financial summary card background.
/// Renders modern smooth wave ribbons, dot matrix grid, and delicate sparkles.
class _CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Flowing Wave Ribbon 1 (Top right flowing through bottom right)
    final path1 = Path();
    path1.moveTo(size.width * 0.40, 0);
    path1.cubicTo(
      size.width * 0.62,
      size.height * 0.32,
      size.width * 0.82,
      size.height * 0.60,
      size.width * 1.05,
      size.height * 0.80,
    );

    final wavePaint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path1, wavePaint1);

    // 2. Parallel Wave Ribbon 2
    final path2 = Path();
    path2.moveTo(size.width * 0.52, 0);
    path2.cubicTo(
      size.width * 0.72,
      size.height * 0.38,
      size.width * 0.88,
      size.height * 0.68,
      size.width * 1.15,
      size.height * 0.88,
    );

    final wavePaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path2, wavePaint2);

    // 3. Wave Ribbon 3 (Bottom left curve)
    final path3 = Path();
    path3.moveTo(-15, size.height * 0.40);
    path3.cubicTo(
      size.width * 0.18,
      size.height * 0.62,
      size.width * 0.32,
      size.height * 0.90,
      size.width * 0.45,
      size.height + 15,
    );

    canvas.drawPath(path3, wavePaint2);

    // 4. Wave Ribbon 4 (Parallel to 3)
    final path4 = Path();
    path4.moveTo(-15, size.height * 0.55);
    path4.cubicTo(
      size.width * 0.15,
      size.height * 0.72,
      size.width * 0.28,
      size.height * 0.95,
      size.width * 0.38,
      size.height + 15,
    );

    canvas.drawPath(path4, wavePaint2..strokeWidth = 0.8);

    // 5. Geometric micro dot grid in top-right
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 4; c++) {
        canvas.drawCircle(
          Offset(size.width * 0.74 + c * 10, 16.0 + r * 10),
          1.2,
          dotPaint,
        );
      }
    }

    // 6. Concentric delicate rings in bottom-left corner
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: 0.10);

    canvas.drawCircle(
        Offset(size.width * 0.12, size.height * 0.85), 32, ringPaint);
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.85), 52,
        ringPaint..color = Colors.white.withValues(alpha: 0.05));

    // 7. Delicate 4-point Sparkle Stars
    _drawSparkle(canvas, Offset(size.width * 0.42, size.height * 0.20), 5.5,
        Colors.white.withValues(alpha: 0.35));
    _drawSparkle(canvas, Offset(size.width * 0.88, size.height * 0.75), 6.5,
        Colors.white.withValues(alpha: 0.32));
    _drawSparkle(canvas, Offset(size.width * 0.22, size.height * 0.35), 4.0,
        Colors.white.withValues(alpha: 0.22));
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius);
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
