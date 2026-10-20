import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_icon_registry.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/money_input_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/controllers/user_category_controller.dart';
import '../controllers/budget_controller.dart';
import '../services/budget_cycle_helper.dart';

class CreateBudgetScreen extends StatefulWidget {
  const CreateBudgetScreen({super.key});

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  final FocusNode amountFocusNode = FocusNode();

  String period = 'monthly';
  String budgetType = 'category';
  Color selectedColor = AppColors.primaryBlue;
  IconData selectedIcon = Icons.account_balance_wallet_rounded;
  String? selectedCategoryKey;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 30));
  bool _loadedCategories = false;
  bool _isCreating = false;

  List<_PeriodOption> get periodOptions => [
        _PeriodOption('daily', context.l10n.daily, Icons.wb_sunny_outlined),
        _PeriodOption(
            'weekly', context.l10n.weekly, Icons.calendar_view_week_outlined),
        _PeriodOption(
            'biweekly', context.l10n.biweekly, Icons.date_range_outlined),
        _PeriodOption(
            'monthly', context.l10n.monthly, Icons.calendar_month_outlined),
        _PeriodOption('yearly', context.l10n.yearly, Icons.event_note_outlined),
        _PeriodOption(
            'custom', context.l10n.custom, Icons.edit_calendar_outlined),
      ];

  static const List<Color> colorOptions = [
    AppColors.primaryBlue,
    AppColors.income,
    AppColors.expense,
    AppColors.warning,
    AppColors.primaryPurple,
    Color(0xFF5E5CE6),
    AppColors.primaryPink,
    Color(0xFF1CC5C0),
    Color(0xFFF6D32D),
    Color(0xFFA1A1AA),
  ];

  static const List<IconData> iconOptions = [
    Icons.account_balance_wallet_rounded,
    Icons.shopping_cart_rounded,
    Icons.shopping_bag_rounded,
    Icons.home_rounded,
    Icons.directions_car_rounded,
    Icons.restaurant_rounded,
    Icons.theater_comedy_rounded,
    Icons.favorite_rounded,
    Icons.school_rounded,
    Icons.work_rounded,
    Icons.flight_rounded,
    Icons.card_giftcard_rounded,
    Icons.sports_esports_rounded,
    Icons.checkroom_rounded,
    Icons.medication_rounded,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedCategories) {
      final uid = context.read<AuthController>().user?.uid;
      if (uid != null) {
        context.read<UserCategoryController>().load(uid);
      }
      _loadedCategories = true;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    amountFocusNode.dispose();
    super.dispose();
  }

  String get displayName {
    final text = nameController.text.trim();
    return text.isEmpty ? context.l10n.budgetNamePreview : text;
  }

  double _parseMoneyInput({
    required String raw,
    required String currency,
  }) {
    final cleaned = currency == 'USD'
        ? raw.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), '')
        : raw.replaceAll(RegExp(r'[^0-9]'), '');

    return double.tryParse(cleaned) ?? 0;
  }

  String displayAmount(BuildContext context) {
    final currency = context.watch<ProfileController>().currency;
    final raw = amountController.text.trim();

    if (raw.isEmpty) {
      return AppCurrencyFormatter.formatFromVnd(
        amountVnd: 0,
        currency: currency,
      );
    }

    final inputAmount = _parseMoneyInput(
      raw: raw,
      currency: currency,
    );

    final amountVnd = AppCurrencyFormatter.toVnd(
      inputAmount: inputAmount,
      currency: currency,
    );

    return AppCurrencyFormatter.formatFromVnd(
      amountVnd: amountVnd,
      currency: currency,
    );
  }

  String get displayPeriodText {
    if (period == 'custom') {
      final s =
          '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}';
      final e =
          '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}';
      return '$s - $e';
    }

    switch (period) {
      case 'daily':
        return context.l10n.daily;
      case 'weekly':
        return context.l10n.weekly;
      case 'biweekly':
        return context.l10n.biweekly;
      case 'monthly':
        return context.l10n.monthly;
      case 'yearly':
        return context.l10n.yearly;
      default:
        return context.l10n.monthly;
    }
  }

  String get displayTypeText {
    if (budgetType == 'total') {
      return context.l10n.total;
    }
    if (selectedCategoryKey != null && selectedCategoryKey!.isNotEmpty) {
      return '${context.l10n.category}: ${BudgetNameLocalizer.display(context, selectedCategoryKey!)}';
    }
    return context.l10n.category;
  }

  String _periodDescription(String p) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    switch (p) {
      case 'daily':
        return isEn
            ? 'Resets at 00:00 every day'
            : 'Làm mới vào 00:00 mỗi ngày';
      case 'weekly':
        return isEn
            ? 'Monday to Sunday every week'
            : 'Thứ Hai đến Chủ Nhật hàng tuần';
      case 'biweekly':
        return isEn ? 'Repeats every 14 days' : 'Chu kỳ lặp lại mỗi 14 ngày';
      case 'yearly':
        return isEn
            ? 'From Jan 1st to Dec 31st each year'
            : 'Từ 01/01 đến 31/12 hàng năm';
      case 'custom':
        return isEn
            ? 'Fixed period between chosen dates'
            : 'Khoảng ngày cố định được chọn';
      case 'monthly':
      default:
        return isEn
            ? 'From 1st to the last day of each month'
            : 'Từ ngày 1 đến ngày cuối cùng của tháng';
    }
  }

  Future<void> _pickStartDate() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
        if (endDate.isBefore(startDate)) {
          endDate = startDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate.isBefore(startDate) ? startDate : endDate,
      firstDate: startDate,
      lastDate: DateTime(2100),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
      });
    }
  }

  Widget _datePickerTheme(BuildContext ctx, Widget? child) {
    final isDark = AppColors.isDark(ctx);
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: isDark
            ? ColorScheme.dark(
                primary: selectedColor,
                surface: AppColors.card(ctx),
              )
            : ColorScheme.light(
                primary: selectedColor,
                surface: AppColors.card(ctx),
              ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  List<_CategoryOption> _buildCategoryOptions(BuildContext context) {
    final l10n = context.l10n;
    final List<_CategoryOption> list = [
      _CategoryOption(
        key: 'Ăn uống',
        displayName: l10n.food,
        icon: Icons.restaurant_rounded,
        color: AppColors.income,
        nameEn: 'Food',
      ),
      _CategoryOption(
        key: 'Mua sắm',
        displayName: l10n.shopping,
        icon: Icons.shopping_bag_rounded,
        color: AppColors.primaryPink,
        nameEn: 'Shopping',
      ),
      _CategoryOption(
        key: 'Đi lại',
        displayName: l10n.transport,
        icon: Icons.directions_car_rounded,
        color: AppColors.primaryBlue,
        nameEn: 'Transport',
      ),
      _CategoryOption(
        key: 'Giải trí',
        displayName: l10n.entertainment,
        icon: Icons.theater_comedy_rounded,
        color: AppColors.warning,
        nameEn: 'Entertainment',
      ),
      _CategoryOption(
        key: 'Học tập',
        displayName: l10n.education,
        icon: Icons.school_rounded,
        color: AppColors.primaryPurple,
        nameEn: 'Education',
      ),
      _CategoryOption(
        key: 'Khác',
        displayName: l10n.other,
        icon: Icons.more_horiz_rounded,
        color: const Color(0xFFAAAAAA),
        nameEn: 'Other',
      ),
    ];

    try {
      final userCatController = context.watch<UserCategoryController>();
      for (final uc in userCatController.categoriesForExpense()) {
        Color c;
        final hex = uc.colorHex.replaceAll('#', '');
        if (hex.length == 6) {
          c = Color(int.parse('FF$hex', radix: 16));
        } else {
          c = AppColors.primaryBlue;
        }

        final isEn = Localizations.localeOf(context).languageCode == 'en';
        final dName =
            (isEn && uc.nameEn != null && uc.nameEn!.trim().isNotEmpty)
                ? uc.nameEn!
                : uc.name;

        list.add(_CategoryOption(
          key: uc.name,
          displayName: dName,
          icon: AppIconRegistry.fromCodePoint(uc.iconCodePoint),
          color: c,
          nameEn: uc.nameEn,
        ));
      }
    } catch (_) {}

    return list;
  }

  void _onCategorySelected(_CategoryOption cat) {
    HapticFeedback.selectionClick();
    setState(() {
      selectedCategoryKey = cat.key;
      nameController.text = cat.displayName;
      selectedIcon = cat.icon;
      selectedColor = cat.color;
    });
  }

  void _applyPresetAmount(double amount, String currency) {
    HapticFeedback.selectionClick();
    final formatter = currency == 'USD'
        ? NumberFormat('#,##0.##', 'en_US')
        : NumberFormat.decimalPattern('vi_VN');
    setState(() {
      amountController.text = formatter.format(amount);
    });
  }

  Future<void> _createBudget() async {
    final uid = context.read<AuthController>().user?.uid;
    if (uid == null) return;

    final rawName = nameController.text.trim();
    final rawAmount = amountController.text.trim();

    if (rawName.isEmpty) {
      _showSnack(context.l10n.pleaseEnterBudgetName);
      return;
    }

    if (rawAmount.isEmpty) {
      _showSnack(context.l10n.pleaseEnterBudgetAmount);
      return;
    }

    if (period == 'custom' && endDate.isBefore(startDate)) {
      final isEn = Localizations.localeOf(context).languageCode == 'en';
      _showSnack(isEn
          ? 'End date must be on or after start date'
          : 'Ngày kết thúc phải sau hoặc bằng ngày bắt đầu');
      return;
    }

    final budget = context.read<BudgetController>();
    final currency = context.read<ProfileController>().currency;

    final inputAmount = _parseMoneyInput(
      raw: rawAmount,
      currency: currency,
    );

    if (inputAmount <= 0) {
      _showSnack(context.l10n.budgetAmountPositive);
      return;
    }

    final amount = AppCurrencyFormatter.toVnd(
      inputAmount: inputAmount,
      currency: currency,
    );

    final effectiveBudgetType =
        (budgetType == 'total' && BudgetCycleHelper.isTotalBudgetName(rawName))
            ? 'total'
            : 'category';

    setState(() {
      _isCreating = true;
    });

    try {
      await budget.createBudget(
        uid: uid,
        name: rawName,
        iconCodePoint: selectedIcon.codePoint,
        colorHex:
            '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        limitAmount: amount,
        period: period,
        budgetType: effectiveBudgetType,
        startDate: period == 'custom'
            ? startDate
            : (period == 'biweekly' ? startDate : null),
        endDate: period == 'custom' ? endDate : null,
        categoryKey:
            effectiveBudgetType == 'category' ? selectedCategoryKey : null,
        inputLocaleIsEnglish:
            Localizations.localeOf(context).languageCode == 'en',
      );

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreating = false;
      });
      final msg = e.toString().replaceAll('Exception: ', '');
      _showSnack(context.l10n.cannotCreateBudget(msg));
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: AppDurations.snackBar,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = amountController.text.trim().isNotEmpty &&
        nameController.text.trim().isNotEmpty &&
        !_isCreating;
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final categories = _buildCategoryOptions(context);
    final currency = context.watch<ProfileController>().currency;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: _CreateBudgetTopBar(
            onCancel: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // 1. Live Hero Card Preview
                  _HeroBudgetCardPreview(
                    color: selectedColor,
                    icon: selectedIcon,
                    title: displayName,
                    amount: displayAmount(context),
                    periodText: displayPeriodText,
                    typeText: displayTypeText,
                    currency: currency,
                  ),

                  const SizedBox(height: 20),

                  // 2. Budget Limit Amount Section
                  _SectionHeader(
                    icon: Icons.payments_rounded,
                    title: context.l10n.budgetAmountLabel,
                    badgeText: isEn ? 'Target' : 'Hạn mức',
                    accentColor: selectedColor,
                  ),
                  const SizedBox(height: 10),
                  _AmountInputCard(
                    controller: amountController,
                    focusNode: amountFocusNode,
                    selectedColor: selectedColor,
                    currency: currency,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  _QuickAmountPresets(
                    currency: currency,
                    selectedColor: selectedColor,
                    onSelectAmount: (val) => _applyPresetAmount(val, currency),
                  ),

                  const SizedBox(height: 22),

                  // 3. Budget Scope / Type Section
                  _SectionHeader(
                    icon: Icons.layers_rounded,
                    title: context.l10n.budgetType,
                    accentColor: selectedColor,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _BudgetTypeOptionCard(
                          title: context.l10n.category,
                          subtitle: isEn
                              ? 'Specific spending wallet'
                              : 'Giới hạn theo từng danh mục',
                          icon: Icons.folder_special_rounded,
                          selected: budgetType == 'category',
                          selectedColor: selectedColor,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              budgetType = 'category';
                              if (categories.isNotEmpty &&
                                  selectedCategoryKey == null) {
                                _onCategorySelected(categories.first);
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BudgetTypeOptionCard(
                          title: context.l10n.total,
                          subtitle: isEn
                              ? 'All categories combined'
                              : 'Toàn bộ khoản chi tiêu',
                          icon: Icons.public_rounded,
                          selected: budgetType == 'total',
                          selectedColor: selectedColor,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              budgetType = 'total';
                              selectedCategoryKey = null;
                              if (nameController.text.isEmpty) {
                                nameController.text =
                                    isEn ? 'Total Expenses' : 'Tổng chi tiêu';
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  if (budgetType == 'category') ...[
                    const SizedBox(height: 14),
                    _CategoryGridSelector(
                      categories: categories,
                      selectedKey: selectedCategoryKey,
                      onSelected: _onCategorySelected,
                    ),
                  ],

                  const SizedBox(height: 22),

                  // 4. Budget Name Field
                  _SectionHeader(
                    icon: Icons.label_important_rounded,
                    title: context.l10n.budgetNameLabel,
                    accentColor: selectedColor,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: nameController,
                    hintText: context.l10n.budgetNameHint,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.drive_file_rename_outline_rounded,
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 22),

                  // 5. Repeat Period & Timeline
                  _SectionHeader(
                    icon: Icons.schedule_rounded,
                    title: context.l10n.period,
                    accentColor: selectedColor,
                  ),
                  const SizedBox(height: 10),
                  _PeriodGridSelector(
                    periodOptions: periodOptions,
                    selectedPeriod: period,
                    selectedColor: selectedColor,
                    onSelected: (val) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        period = val;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  _CycleInfoBanner(
                    description: _periodDescription(period),
                    color: selectedColor,
                  ),

                  if (period == 'custom') ...[
                    const SizedBox(height: 14),
                    _CustomDateRangeCard(
                      startDate: startDate,
                      endDate: endDate,
                      selectedColor: selectedColor,
                      onTapStart: _pickStartDate,
                      onTapEnd: _pickEndDate,
                    ),
                  ],

                  const SizedBox(height: 22),

                  // 6. Visual Theme & Style
                  _SectionHeader(
                    icon: Icons.palette_rounded,
                    title: isEn ? 'Theme & Icon' : 'Màu sắc & Biểu tượng',
                    accentColor: selectedColor,
                  ),
                  const SizedBox(height: 12),
                  _ColorPaletteRow(
                    colors: colorOptions,
                    selectedColor: selectedColor,
                    onSelectColor: (c) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        selectedColor = c;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  _IconPickerGrid(
                    icons: iconOptions,
                    selectedIcon: selectedIcon,
                    selectedColor: selectedColor,
                    onSelectIcon: (ic) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        selectedIcon = ic;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Bottom Fixed CTA Action Bar
            _BottomActionBar(
              selectedColor: selectedColor,
              canSubmit: canSubmit,
              isCreating: _isCreating,
              onSubmit: _createBudget,
              buttonText: context.l10n.createBudget,
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

class _CreateBudgetTopBar extends StatelessWidget {
  final VoidCallback onCancel;

  const _CreateBudgetTopBar({
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

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
              onCancel();
            },
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                border: Border.all(
                  color: AppColors.innerBorder(context),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 13,
                    color: AppColors.textPrimary(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.l10n.cancelLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            context.l10n.addBudget,
            style: AppTextStyles.pageTitle(context).copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 60), // Optical balance for back button
        ],
      ),
    );
  }
}

class _HeroBudgetCardPreview extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String amount;
  final String periodText;
  final String typeText;
  final String currency;

  const _HeroBudgetCardPreview({
    required this.color,
    required this.icon,
    required this.title,
    required this.amount,
    required this.periodText,
    required this.typeText,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: 170,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            color,
            Color.lerp(color, isDark ? Colors.black : Colors.white, 0.35) ??
                color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle card pattern watermark
          Positioned(
            right: -15,
            bottom: -25,
            child: Icon(
              icon,
              size: 140,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Badges & Icon
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                typeText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.repeat_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          periodText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Bottom Row: Limit Amount Display
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.budgetLimitLegend,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    amount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badgeText;
  final Color accentColor;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.badgeText,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 14,
            color: accentColor,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.sectionTitle(context).copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (badgeText != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AmountInputCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color selectedColor;
  final String currency;
  final ValueChanged<String>? onChanged;

  const _AmountInputCard({
    required this.controller,
    required this.focusNode,
    required this.selectedColor,
    required this.currency,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: focusNode.hasFocus ? selectedColor : AppColors.border(context),
          width: focusNode.hasFocus ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        keyboardType: TextInputType.numberWithOptions(
          decimal: currency == 'USD',
        ),
        textAlign: TextAlign.center,
        cursorColor: selectedColor,
        inputFormatters: [
          MoneyInputFormatter(
            allowDecimal: currency == 'USD',
            maxDigits: currency == 'USD' ? 7 : 12,
          ),
        ],
        style: TextStyle(
          color: AppColors.textPrimary(context),
          fontSize: 30,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        decoration: InputDecoration(
          hintText: AppCurrencyFormatter.formatInputHint(currency),
          hintStyle: TextStyle(
            color: AppColors.textSecondary(context).withValues(alpha: 0.35),
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              widthFactor: 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppCurrencyFormatter.symbol(currency),
                  style: TextStyle(
                    color: selectedColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _QuickAmountPresets extends StatelessWidget {
  final String currency;
  final Color selectedColor;
  final ValueChanged<double> onSelectAmount;

  const _QuickAmountPresets({
    required this.currency,
    required this.selectedColor,
    required this.onSelectAmount,
  });

  @override
  Widget build(BuildContext context) {
    final presets = currency == 'USD'
        ? [50.0, 100.0, 200.0, 500.0, 1000.0]
        : [500000.0, 1000000.0, 2000000.0, 5000000.0, 10000000.0];

    String formatPreset(double val) {
      if (currency == 'USD') {
        return '\$${val.toInt()}';
      }
      if (val >= 1000000) {
        return '${(val / 1000000).toStringAsFixed(val % 1000000 == 0 ? 0 : 1)}tr';
      }
      return '${(val / 1000).toInt()}k';
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((amount) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelectAmount(amount),
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  border: Border.all(
                    color: AppColors.innerBorder(context),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 12,
                      color: selectedColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      formatPreset(amount),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BudgetTypeOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _BudgetTypeOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: 0.12)
              : AppColors.card(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? selectedColor : AppColors.border(context),
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        selected ? selectedColor : AppColors.surface(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 17,
                    color: selected
                        ? Colors.white
                        : AppColors.textSecondary(context),
                  ),
                ),
                const Spacer(),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: selectedColor,
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: selected
                    ? (AppColors.isDark(context) ? Colors.white : selectedColor)
                    : AppColors.textPrimary(context),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGridSelector extends StatelessWidget {
  final List<_CategoryOption> categories;
  final String? selectedKey;
  final ValueChanged<_CategoryOption> onSelected;

  const _CategoryGridSelector({
    required this.categories,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Localizations.localeOf(context).languageCode == 'en'
                ? 'Select a Category'
                : 'Chọn danh mục áp dụng',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((cat) {
              final isSelected = selectedKey != null &&
                  (selectedKey == cat.key ||
                      selectedKey!.toLowerCase() == cat.key.toLowerCase());

              return InkWell(
                onTap: () => onSelected(cat),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cat.color.withValues(alpha: 0.18)
                        : AppColors.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? cat.color
                          : AppColors.innerBorder(context),
                      width: isSelected ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat.icon,
                        size: 15,
                        color: isSelected
                            ? cat.color
                            : AppColors.textSecondary(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? (AppColors.isDark(context)
                                  ? Colors.white
                                  : cat.color)
                              : AppColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PeriodGridSelector extends StatelessWidget {
  final List<_PeriodOption> periodOptions;
  final String selectedPeriod;
  final Color selectedColor;
  final ValueChanged<String> onSelected;

  const _PeriodGridSelector({
    required this.periodOptions,
    required this.selectedPeriod,
    required this.selectedColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: periodOptions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final item = periodOptions[index];
        final selected = selectedPeriod == item.value;

        return InkWell(
          onTap: () => onSelected(item.value),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected
                  ? selectedColor.withValues(alpha: 0.14)
                  : AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? selectedColor : AppColors.border(context),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: selected
                      ? selectedColor
                      : AppColors.textSecondary(context),
                  size: 16,
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? (AppColors.isDark(context)
                            ? Colors.white
                            : selectedColor)
                        : AppColors.textPrimary(context),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CycleInfoBanner extends StatelessWidget {
  final String description;
  final Color color;

  const _CycleInfoBanner({
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomDateRangeCard extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Color selectedColor;
  final VoidCallback onTapStart;
  final VoidCallback onTapEnd;

  const _CustomDateRangeCard({
    required this.startDate,
    required this.endDate,
    required this.selectedColor,
    required this.onTapStart,
    required this.onTapEnd,
  });

  String _format(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final totalDays = endDate.difference(startDate).inDays + 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selectedColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.date_range_rounded,
                size: 18,
                color: selectedColor,
              ),
              const SizedBox(width: 8),
              Text(
                isEn ? 'Custom Date Range' : 'Khoảng thời gian áp dụng',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isEn ? '$totalDays days' : '$totalDays ngày',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: selectedColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onTapStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Start date' : 'Từ ngày',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _format(startDate),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Color(0xFFAAAAAA),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onTapEnd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'End date' : 'Đến ngày',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _format(endDate),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
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

class _ColorPaletteRow extends StatelessWidget {
  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onSelectColor;

  const _ColorPaletteRow({
    required this.colors,
    required this.selectedColor,
    required this.onSelectColor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: colors.map((color) {
          final selected = selectedColor.toARGB32() == color.toARGB32();

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onSelectColor(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(
                    color: selected ? Colors.white : AppColors.border(context),
                    width: selected ? 2.5 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _IconPickerGrid extends StatelessWidget {
  final List<IconData> icons;
  final IconData selectedIcon;
  final Color selectedColor;
  final ValueChanged<IconData> onSelectIcon;

  const _IconPickerGrid({
    required this.icons,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onSelectIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: icons.map((icon) {
        final selected = selectedIcon == icon;

        return GestureDetector(
          onTap: () => onSelectIcon(icon),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? selectedColor : AppColors.surface(context),
              border: Border.all(
                color:
                    selected ? selectedColor : AppColors.innerBorder(context),
              ),
            ),
            child: Icon(
              icon,
              color: selected ? Colors.white : AppColors.textSecondary(context),
              size: 19,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final Color selectedColor;
  final bool canSubmit;
  final bool isCreating;
  final VoidCallback onSubmit;
  final String buttonText;

  const _BottomActionBar({
    required this.selectedColor,
    required this.canSubmit,
    required this.isCreating,
    required this.onSubmit,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        border: Border(
          top: BorderSide(
            color: AppColors.border(context).withValues(alpha: 0.6),
            width: 0.7,
          ),
        ),
      ),
      child: CustomButton(
        text: buttonText,
        isLoading: isCreating,
        onPressedAsync: canSubmit ? () async => onSubmit() : null,
        backgroundColor: selectedColor,
        foregroundColor: AppColors.foregroundOnAccent(selectedColor),
        height: 50,
        borderRadius: 16,
      ),
    );
  }
}

class _CategoryOption {
  final String key;
  final String displayName;
  final IconData icon;
  final Color color;
  final String? nameEn;

  const _CategoryOption({
    required this.key,
    required this.displayName,
    required this.icon,
    required this.color,
    this.nameEn,
  });
}

class _PeriodOption {
  final String value;
  final String label;
  final IconData icon;

  const _PeriodOption(this.value, this.label, this.icon);
}
