import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_icon_registry.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/budget_name_localizer.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/user_category_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/user_category_controller.dart';

/// Builtin expense categories visual constants
const List<IconData> _kBuiltinExpenseIcons = [
  Icons.restaurant_rounded,
  Icons.shopping_bag_rounded,
  Icons.directions_bus_rounded,
  Icons.movie_rounded,
  Icons.menu_book_rounded,
  Icons.more_horiz_rounded,
];

const List<Color> _kBuiltinExpenseColors = [
  AppColors.income,
  AppColors.primaryPink,
  AppColors.primaryBlue,
  AppColors.warning,
  AppColors.primaryPurple,
  Color(0xFFAAAAAA),
];

/// Builtin income categories visual constants
const List<IconData> _kBuiltinIncomeIcons = [
  Icons.payments_rounded,
  Icons.card_giftcard_rounded,
  Icons.more_horiz_rounded,
];

const List<Color> _kBuiltinIncomeColors = [
  AppColors.income,
  AppColors.expense,
  Color(0xFFAAAAAA),
];

Color _colorFromHex(String hex) {
  final cleaned = hex.replaceAll('#', '');
  if (cleaned.length == 6) {
    return Color(int.parse('FF$cleaned', radix: 16));
  }
  return AppColors.primaryBlue;
}

String _normalizeCategoryHex(String raw) {
  final s = raw.trim().replaceAll('#', '').toUpperCase();
  if (s.length == 6) {
    return '#$s';
  }
  return raw.trim().toUpperCase();
}

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _requestedLoad = false;
  String _searchQuery = '';

  final List<Color> _colorOptions = const [
    AppColors.primaryBlue,
    AppColors.income,
    AppColors.expense,
    AppColors.warning,
    AppColors.primaryPurple,
    Color(0xFF6366F1), // Indigo
    AppColors.primaryPink,
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF8B5CF6), // Violet
    Color(0xFF64748B), // Slate
  ];

  final List<IconData> _iconOptions = const [
    Icons.restaurant_rounded,
    Icons.fastfood_rounded,
    Icons.local_cafe_rounded,
    Icons.shopping_bag_rounded,
    Icons.shopping_cart_rounded,
    Icons.storefront_rounded,
    Icons.checkroom_rounded,
    Icons.directions_car_rounded,
    Icons.directions_bus_rounded,
    Icons.flight_rounded,
    Icons.local_gas_station_rounded,
    Icons.home_rounded,
    Icons.apartment_rounded,
    Icons.water_drop_rounded,
    Icons.bolt_rounded,
    Icons.movie_rounded,
    Icons.theater_comedy_rounded,
    Icons.sports_esports_rounded,
    Icons.fitness_center_rounded,
    Icons.favorite_rounded,
    Icons.medication_rounded,
    Icons.school_rounded,
    Icons.menu_book_rounded,
    Icons.work_rounded,
    Icons.card_giftcard_rounded,
    Icons.celebration_rounded,
    Icons.pets_rounded,
    Icons.savings_rounded,
    Icons.payments_rounded,
    Icons.account_balance_rounded,
    Icons.trending_up_rounded,
    Icons.paid_rounded,
    Icons.volunteer_activism_rounded,
    Icons.pending_actions_rounded,
    Icons.spa_rounded,
    Icons.more_horiz_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  void _onSearchFocusChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedLoad) return;
    _requestedLoad = true;

    final uid = context.read<AuthController>().user?.uid;
    if (uid != null) {
      context.read<UserCategoryController>().load(uid);
    }
  }

  String _categoryTypeForTab(int index) {
    return index == 0 ? 'expense' : 'income';
  }

  Future<void> _confirmDelete(UserCategoryModel model) async {
    HapticFeedback.mediumImpact();
    final color = _colorFromHex(model.colorHex);
    final icon = AppIconRegistry.fromCodePoint(model.iconCodePoint);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card(ctx),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: AppColors.border(ctx),
            ),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.16),
                  border: Border.all(
                    color: color.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ctx.l10n.deleteCategoryTitle,
                  style: AppTextStyles.sectionTitle(ctx).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            ctx.l10n.deleteCategoryMessage(
              BudgetNameLocalizer.display(ctx, model.name),
            ),
            style: AppTextStyles.bodySecondary(ctx).copyWith(
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(ctx, false);
              },
              child: Text(
                ctx.l10n.cancel,
                style: TextStyle(
                  color: AppColors.textSecondary(ctx),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx, true);
              },
              child: Text(
                ctx.l10n.deleteCategoryConfirmAction,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (ok != true || !mounted) return;

    final uid = context.read<AuthController>().user?.uid;
    if (uid == null) return;

    try {
      await context.read<UserCategoryController>().deleteCategory(
            uid: uid,
            categoryId: model.id,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.categoryDeleted),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.categoryDeleteFailed),
        ),
      );
    }
  }

  void _showAddSheet() {
    HapticFeedback.selectionClick();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final sheetInitialType = _categoryTypeForTab(_tabController.index);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AddCategorySheet(
          initialDraftType: sheetInitialType,
          colorOptions: _colorOptions,
          iconOptions: _iconOptions,
          mapCreateError: _mapCreateError,
          onSaved: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  duration: AppDurations.snackBar,
                  content: Text(context.l10n.categorySaved),
                ),
              );
            });
          },
        );
      },
    );
  }

  String _mapCreateError(BuildContext context, Object? code) {
    switch (code) {
      case 'duplicate_category':
        return context.l10n.categoryDuplicate;
      case 'reserved_category_name':
        return context.l10n.categoryReserved;
      case 'category_name_too_long':
        return context.l10n.categoryNameTooLong;
      case 'empty_category_name':
        return context.l10n.categoryNameRequired;
      case 'category_not_found':
        return context.l10n.categoryNotFound;
      default:
        return context.l10n.categorySaveFailed;
    }
  }

  void _showEditSheet(UserCategoryModel model) {
    HapticFeedback.selectionClick();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AddCategorySheet(
          initialDraftType: model.isExpense ? 'expense' : 'income',
          colorOptions: _colorOptions,
          iconOptions: _iconOptions,
          mapCreateError: _mapCreateError,
          editingCategory: model,
          onSaved: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  duration: AppDurations.snackBar,
                  content: Text(context.l10n.categoryUpdated),
                ),
              );
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UserCategoryController>();
    final isExpenseTab = _tabController.index == 0;
    final expenseCategories = controller.categoriesForExpense();
    final incomeCategories = controller.categoriesForIncome();

    final builtinExpenseNames = [
      context.l10n.food,
      context.l10n.shopping,
      context.l10n.transport,
      context.l10n.entertainment,
      context.l10n.education,
      context.l10n.other,
    ];

    final builtinIncomeNames = [
      context.l10n.salary,
      context.l10n.gift,
      context.l10n.other,
    ];

    final currentBuiltinCount =
        isExpenseTab ? builtinExpenseNames.length : builtinIncomeNames.length;
    final currentCustomCount =
        isExpenseTab ? expenseCategories.length : incomeCategories.length;
    final currentTotalCount = currentBuiltinCount + currentCustomCount;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: isExpenseTab ? AppColors.expense : AppColors.income,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          context.l10n.createCategoryAction,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.1,
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: _CategoriesHeader(
                  title: context.l10n.manageCategories,
                  totalCount: currentTotalCount,
                  onBack: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  onAdd: _showAddSheet,
                ),
              ),
              const SizedBox(height: 14),

              // Hero Summary Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _HeroCategoryBanner(
                  isExpense: isExpenseTab,
                  totalCount: currentTotalCount,
                  builtinCount: currentBuiltinCount,
                  customCount: currentCustomCount,
                  onAddPressed: _showAddSheet,
                ),
              ),
              const SizedBox(height: 14),

              // Segmented Tab Switcher (Expense / Income)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _CategoryTypeSegment(
                  controller: _tabController,
                  expenseLabel: context.l10n.categoriesExpenseTab,
                  incomeLabel: context.l10n.categoriesIncomeTab,
                  expenseCount:
                      expenseCategories.length + builtinExpenseNames.length,
                  incomeCount:
                      incomeCategories.length + builtinIncomeNames.length,
                ),
              ),
              const SizedBox(height: 12),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _searchFocusNode.hasFocus
                          ? (isExpenseTab
                              ? AppColors.expense
                              : AppColors.income)
                          : AppColors.innerBorder(context),
                      width: _searchFocusNode.hasFocus ? 1.4 : 1.0,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    cursorColor:
                        isExpenseTab ? AppColors.expense : AppColors.income,
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: context.l10n.searchCategoriesHint,
                      hintStyle: AppTextStyles.bodySecondary(context).copyWith(
                        fontSize: 14,
                        color: AppColors.textSecondary(context)
                            .withValues(alpha: 0.65),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: _searchFocusNode.hasFocus
                            ? (isExpenseTab
                                ? AppColors.expense
                                : AppColors.income)
                            : AppColors.textSecondary(context),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _searchController.clear();
                              },
                              child: Icon(
                                Icons.cancel_rounded,
                                size: 18,
                                color: AppColors.textSecondary(context),
                              ),
                            )
                          : null,
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _CategoryListPane(
                      isExpense: true,
                      builtinLabels: builtinExpenseNames,
                      builtinIcons: _kBuiltinExpenseIcons,
                      builtinColors: _kBuiltinExpenseColors,
                      items: expenseCategories,
                      searchQuery: _searchQuery,
                      onEdit: _showEditSheet,
                      onDelete: _confirmDelete,
                      onAddFirst: _showAddSheet,
                      emptyHint: context.l10n.categoriesExpenseEmpty,
                    ),
                    _CategoryListPane(
                      isExpense: false,
                      builtinLabels: builtinIncomeNames,
                      builtinIcons: _kBuiltinIncomeIcons,
                      builtinColors: _kBuiltinIncomeColors,
                      items: incomeCategories,
                      searchQuery: _searchQuery,
                      onEdit: _showEditSheet,
                      onDelete: _confirmDelete,
                      onAddFirst: _showAddSheet,
                      emptyHint: context.l10n.categoriesIncomeEmpty,
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

class _CategoriesHeader extends StatelessWidget {
  final String title;
  final int totalCount;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  const _CategoriesHeader({
    required this.title,
    required this.totalCount,
    required this.onBack,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TopCircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.pageTitle(context).copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.l10n.totalCategoriesCount(totalCount),
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onAdd();
          },
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              border: Border.all(
                color: AppColors.border(context),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 4),
                Text(
                  context.l10n.addCustomCategory,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlue,
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

class _TopCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.card(context),
          border: Border.all(
            color: AppColors.border(context),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: AppColors.textPrimary(context),
        ),
      ),
    );
  }
}

class _HeroCategoryBanner extends StatelessWidget {
  final bool isExpense;
  final int totalCount;
  final int builtinCount;
  final int customCount;
  final VoidCallback onAddPressed;

  const _HeroCategoryBanner({
    required this.isExpense,
    required this.totalCount,
    required this.builtinCount,
    required this.customCount,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = isExpense ? AppColors.expense : AppColors.income;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColor.withValues(
              alpha: AppColors.isDark(context) ? 0.22 : 0.10,
            ),
            themeColor.withValues(
              alpha: AppColors.isDark(context) ? 0.08 : 0.02,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: themeColor.withValues(alpha: 0.32),
                width: 1.5,
              ),
            ),
            child: Icon(
              isExpense
                  ? Icons.account_balance_wallet_rounded
                  : Icons.savings_rounded,
              color: themeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isExpense ? context.l10n.expense : context.l10n.income,
                      style: TextStyle(
                        color: themeColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusPill),
                      ),
                      child: Text(
                        '$totalCount',
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  children: [
                    Text(
                      context.l10n.builtinCategoriesCount(builtinCount),
                      style: AppTextStyles.caption(context).copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      context.l10n.customCategoriesCount(customCount),
                      style: AppTextStyles.caption(context).copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTypeSegment extends StatelessWidget {
  final TabController controller;
  final String expenseLabel;
  final String incomeLabel;
  final int expenseCount;
  final int incomeCount;

  const _CategoryTypeSegment({
    required this.controller,
    required this.expenseLabel,
    required this.incomeLabel,
    required this.expenseCount,
    required this.incomeCount,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIndex = controller.index;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Row(
        children: [
          _SegmentItem(
            selected: selectedIndex == 0,
            label: expenseLabel,
            count: expenseCount,
            icon: Icons.north_east_rounded,
            color: AppColors.expense,
            onTap: () {
              HapticFeedback.selectionClick();
              controller.animateTo(0);
            },
          ),
          _SegmentItem(
            selected: selectedIndex == 1,
            label: incomeLabel,
            count: incomeCount,
            icon: Icons.south_west_rounded,
            color: AppColors.income,
            onTap: () {
              HapticFeedback.selectionClick();
              controller.animateTo(1);
            },
          ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  final bool selected;
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SegmentItem({
    required this.selected,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color:
                    selected ? Colors.white : AppColors.textSecondary(context),
                size: 16,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '$label ($count)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : AppColors.textSecondary(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
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

class _CategoryListPane extends StatelessWidget {
  final bool isExpense;
  final List<String> builtinLabels;
  final List<IconData> builtinIcons;
  final List<Color> builtinColors;
  final List<UserCategoryModel> items;
  final String searchQuery;
  final void Function(UserCategoryModel) onEdit;
  final void Function(UserCategoryModel) onDelete;
  final VoidCallback onAddFirst;
  final String emptyHint;

  const _CategoryListPane({
    required this.isExpense,
    required this.builtinLabels,
    required this.builtinIcons,
    required this.builtinColors,
    required this.items,
    required this.searchQuery,
    required this.onEdit,
    required this.onDelete,
    required this.onAddFirst,
    required this.emptyHint,
  }) : assert(
          builtinLabels.length == builtinIcons.length &&
              builtinLabels.length == builtinColors.length,
        );

  @override
  Widget build(BuildContext context) {
    final filteredBuiltins = <int>[];
    for (int i = 0; i < builtinLabels.length; i++) {
      if (searchQuery.isEmpty ||
          builtinLabels[i].toLowerCase().contains(searchQuery)) {
        filteredBuiltins.add(i);
      }
    }

    final filteredItems = items.where((item) {
      if (searchQuery.isEmpty) return true;
      final matchVi = item.name.toLowerCase().contains(searchQuery);
      final matchEn = (item.nameEn ?? '').toLowerCase().contains(searchQuery);
      return matchVi || matchEn;
    }).toList();

    final hasNoResults = filteredBuiltins.isEmpty &&
        filteredItems.isEmpty &&
        searchQuery.isNotEmpty;

    if (hasNoResults) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 54,
                color: AppColors.textSecondary(context).withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.noMatchingCategories,
                style: AppTextStyles.body(context).copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 110),
      children: [
        // Builtin System Categories
        if (filteredBuiltins.isNotEmpty) ...[
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.builtinCategoriesHeading,
                style: AppTextStyles.sectionTitle(context).copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${filteredBuiltins.length}',
                style: AppTextStyles.caption(context).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredBuiltins.map((i) {
              final label = builtinLabels[i];
              final icon = builtinIcons[i];
              final color = builtinColors[i];

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  border: Border.all(
                    color: AppColors.border(context),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: AppColors.isDark(context) ? 0.12 : 0.03,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        icon,
                        size: 15,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: AppTextStyles.caption(context).copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Custom User Categories
        Row(
          children: [
            Icon(
              Icons.stars_rounded,
              size: 17,
              color: isExpense ? AppColors.expense : AppColors.income,
            ),
            const SizedBox(width: 6),
            Text(
              context.l10n.yourCategoriesHeading,
              style: AppTextStyles.sectionTitle(context).copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              '${filteredItems.length}',
              style: AppTextStyles.caption(context).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (filteredItems.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 28,
            ),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.border(context),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (isExpense ? AppColors.expense : AppColors.income)
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.category_outlined,
                    size: 28,
                    color: isExpense ? AppColors.expense : AppColors.income,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  emptyHint,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary(context).copyWith(
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onAddFirst();
                  },
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: (isExpense ? AppColors.expense : AppColors.income)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                      border: Border.all(
                        color:
                            (isExpense ? AppColors.expense : AppColors.income)
                                .withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          size: 18,
                          color:
                              isExpense ? AppColors.expense : AppColors.income,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.addCustomCategory,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isExpense
                                ? AppColors.expense
                                : AppColors.income,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...filteredItems.map((item) {
            final color = _colorFromHex(item.colorHex);
            final icon = AppIconRegistry.fromCodePoint(item.iconCodePoint);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => onEdit(item),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.border(context),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(
                            alpha: AppColors.isDark(context) ? 0.08 : 0.04,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Category Icon with Color
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: 0.16),
                            border: Border.all(
                              color: color.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Type subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                BudgetNameLocalizer.display(context, item.name),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body(context).copyWith(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.isExpense
                                    ? context.l10n.expense
                                    : context.l10n.income,
                                style: AppTextStyles.caption(context).copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Edit and Delete Buttons
                        _CategoryActionButton(
                          icon: Icons.edit_outlined,
                          color: AppColors.primaryBlue,
                          onTap: () => onEdit(item),
                        ),
                        const SizedBox(width: 6),
                        _CategoryActionButton(
                          icon: Icons.delete_outline_rounded,
                          color: AppColors.expense,
                          onTap: () => onDelete(item),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _CategoryActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          border: Border.all(
            color: color.withValues(alpha: 0.20),
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 18,
        ),
      ),
    );
  }
}

class _AddCategorySheet extends StatefulWidget {
  final String initialDraftType;
  final List<Color> colorOptions;
  final List<IconData> iconOptions;
  final String Function(BuildContext context, Object? code) mapCreateError;
  final UserCategoryModel? editingCategory;
  final VoidCallback onSaved;

  const _AddCategorySheet({
    required this.initialDraftType,
    required this.colorOptions,
    required this.iconOptions,
    required this.mapCreateError,
    this.editingCategory,
    required this.onSaved,
  });

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  late final TextEditingController _nameController;
  final FocusNode _nameFocusNode = FocusNode();

  late String _draftType;
  late IconData _pickedIcon;
  late Color _pickedColor;

  String? _snapshotName;
  String? _snapshotType;
  int? _snapshotIconCp;
  String? _snapshotHex;

  bool _seededEditLocaleFields = false;

  void _onFormFieldChanged() {
    setState(() {});
  }

  bool get _hasChangesFromSnapshot {
    final e = widget.editingCategory;
    if (e == null || _snapshotName == null) {
      return true;
    }

    final hex = _normalizeCategoryHex(
      '#${_pickedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
    );

    return _nameController.text.trim() != _snapshotName ||
        _draftType != _snapshotType ||
        _pickedIcon.codePoint != _snapshotIconCp ||
        hex != _snapshotHex;
  }

  bool get _saveEnabled {
    if (widget.editingCategory == null) {
      return _nameController.text.trim().isNotEmpty;
    }
    return _nameController.text.trim().isNotEmpty && _hasChangesFromSnapshot;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    final edit = widget.editingCategory;
    if (edit != null) {
      _draftType = edit.isExpense ? 'expense' : 'income';
      _pickedIcon = AppIconRegistry.fromCodePoint(edit.iconCodePoint);
      _pickedColor = _colorFromHex(edit.colorHex);

      _snapshotType = edit.isExpense ? 'expense' : 'income';
      _snapshotIconCp = edit.iconCodePoint;
      _snapshotHex = _normalizeCategoryHex(edit.colorHex);
    } else {
      final t = widget.initialDraftType;
      _draftType = t == 'income' ? 'income' : 'expense';
      _pickedIcon = widget.iconOptions.first;
      _pickedColor = widget.colorOptions.first;
    }

    _nameController.addListener(_onFormFieldChanged);
    _nameFocusNode.addListener(_onFormFieldChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final edit = widget.editingCategory;
    if (edit != null && !_seededEditLocaleFields) {
      _seededEditLocaleFields = true;

      final lang = Localizations.localeOf(context).languageCode;
      final seed = lang == 'en' && (edit.nameEn ?? '').trim().isNotEmpty
          ? edit.nameEn!.trim()
          : edit.name.trim();

      _nameController.text = seed;
      _snapshotName = seed;
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFormFieldChanged);
    _nameFocusNode.removeListener(_onFormFieldChanged);
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final uid = context.read<AuthController>().user?.uid;
    if (uid == null) return;

    final raw = _nameController.text.trim();
    if (raw.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.categoryNameRequired),
        ),
      );
      return;
    }

    if (widget.editingCategory != null && !_hasChangesFromSnapshot) {
      return;
    }

    final hex =
        '#${_pickedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    final inputLocaleIsEnglish =
        Localizations.localeOf(context).languageCode == 'en';

    try {
      final edit = widget.editingCategory;
      if (edit != null) {
        await context.read<UserCategoryController>().updateCategory(
              uid: uid,
              categoryId: edit.id,
              name: raw,
              type: _draftType,
              iconCodePoint: _pickedIcon.codePoint,
              colorHex: hex,
              inputLocaleIsEnglish: inputLocaleIsEnglish,
            );
      } else {
        await context.read<UserCategoryController>().addCategory(
              uid: uid,
              name: raw,
              type: _draftType,
              iconCodePoint: _pickedIcon.codePoint,
              colorHex: hex,
              inputLocaleIsEnglish: inputLocaleIsEnglish,
            );
      }

      if (!mounted) return;
      nav.pop();
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      final code = e is ArgumentError
          ? (e.message is String ? e.message as String : '')
          : '';

      messenger.showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(widget.mapCreateError(context, code)),
        ),
      );
    }
  }

  void _setDraftType(String next) {
    HapticFeedback.selectionClick();
    setState(() {
      _draftType = next == 'income' ? 'income' : 'expense';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.editingCategory != null;
    final displayName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : context.l10n.categoryNameHint;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
            border: Border.all(
              color: AppColors.border(context),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: AppColors.isDark(context) ? 0.35 : 0.14,
                ),
                blurRadius: 28,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border(context),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  isEditing
                      ? context.l10n.editCustomCategory
                      : context.l10n.addCustomCategory,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pageTitle(context).copyWith(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),

                // LIVE CATEGORY CARD PREVIEW
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _pickedColor.withValues(
                          alpha: AppColors.isDark(context) ? 0.22 : 0.12,
                        ),
                        _pickedColor.withValues(
                          alpha: AppColors.isDark(context) ? 0.08 : 0.03,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _pickedColor.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _pickedColor.withValues(alpha: 0.22),
                          border: Border.all(
                            color: _pickedColor,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _pickedColor.withValues(alpha: 0.25),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(
                          _pickedIcon,
                          color: _pickedColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body(context).copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _draftType == 'expense'
                                  ? context.l10n.expense
                                  : context.l10n.income,
                              style: AppTextStyles.caption(context).copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _pickedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                          border: Border.all(
                            color: _pickedColor.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Text(
                          context.l10n.categoryPreviewTitle,
                          style: TextStyle(
                            color: _pickedColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // NAME INPUT
                Text(
                  context.l10n.displayNameLabel,
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _nameFocusNode.hasFocus
                          ? _pickedColor
                          : AppColors.innerBorder(context),
                      width: _nameFocusNode.hasFocus ? 1.4 : 1.0,
                    ),
                  ),
                  child: TextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    maxLength: 50,
                    cursorColor: _pickedColor,
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      hintText: context.l10n.categoryNameHint,
                      counterText: '',
                      prefixIcon: Icon(
                        Icons.edit_note_rounded,
                        color: _nameFocusNode.hasFocus
                            ? _pickedColor
                            : AppColors.textSecondary(context),
                      ),
                      suffixIcon: _nameController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _nameController.clear();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  Icons.cancel_rounded,
                                  color: AppColors.textSecondary(context),
                                  size: 18,
                                ),
                              ),
                            )
                          : null,
                      hintStyle: AppTextStyles.bodySecondary(context).copyWith(
                        fontSize: 14,
                        color: AppColors.textSecondary(context)
                            .withValues(alpha: 0.65),
                      ),
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // TYPE SELECTOR
                Text(
                  context.l10n.categoryTypeLabel,
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    border: Border.all(
                      color: AppColors.innerBorder(context),
                    ),
                  ),
                  child: Row(
                    children: [
                      _SheetTypeOption(
                        selected: _draftType == 'expense',
                        label: context.l10n.expense,
                        icon: Icons.north_east_rounded,
                        color: AppColors.expense,
                        onTap: () => _setDraftType('expense'),
                      ),
                      _SheetTypeOption(
                        selected: _draftType == 'income',
                        label: context.l10n.income,
                        icon: Icons.south_west_rounded,
                        color: AppColors.income,
                        onTap: () => _setDraftType('income'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ICON PICKER GRID
                Text(
                  context.l10n.categoryIconLabel,
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.innerBorder(context),
                    ),
                  ),
                  child: GridView.builder(
                    itemCount: widget.iconOptions.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemBuilder: (context, i) {
                      final icon = widget.iconOptions[i];
                      final selected = icon.codePoint == _pickedIcon.codePoint;

                      return Material(
                        color: selected
                            ? _pickedColor.withValues(alpha: 0.22)
                            : AppColors.card(context),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _pickedIcon = icon;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? _pickedColor
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: selected
                                  ? _pickedColor
                                  : AppColors.textSecondary(context),
                              size: 22,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // COLOR PALETTE (6 columns x 2 rows = 12 colors, perfectly balanced!)
                Text(
                  context.l10n.categoryColorLabel,
                  style: AppTextStyles.caption(context).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.innerBorder(context),
                    ),
                  ),
                  child: GridView.builder(
                    itemCount: widget.colorOptions.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (context, i) {
                      final c = widget.colorOptions[i];
                      final selected = c.toARGB32() == _pickedColor.toARGB32();

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _pickedColor = c;
                          });
                        },
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c,
                              border: Border.all(
                                color: selected
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 2.8,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: c.withValues(alpha: 0.45),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),

                // SUBMIT BUTTON
                CustomButton(
                  height: 52,
                  borderRadius: AppSizes.radiusPill,
                  text: context.l10n.saveCategory,
                  backgroundColor: _pickedColor,
                  foregroundColor: AppColors.foregroundOnAccent(_pickedColor),
                  onPressedAsync: _saveEnabled ? _save : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetTypeOption extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SheetTypeOption({
    required this.selected,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color:
                    selected ? Colors.white : AppColors.textSecondary(context),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : AppColors.textSecondary(context),
                  fontSize: 13.5,
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
