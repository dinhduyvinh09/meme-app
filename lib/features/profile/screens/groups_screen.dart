import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/money_input_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthController>().user?.uid;
    final currency = context.watch<ProfileController>().currency;

    if (uid == null) {
      return Scaffold(
        body: Center(
          child: Text(context.l10n.user),
        ),
      );
    }

    String money(double value) {
      return AppCurrencyFormatter.formatFromVnd(
        amountVnd: value,
        currency: currency,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: context.read<UserRepository>().streamGroups(uid),
          builder: (context, snapshot) {
            final isLoadingGroups =
                snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;

            final groups = snapshot.data ?? [];
            final isEmpty = !isLoadingGroups && groups.isEmpty;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.pagePadding,
                    12,
                    AppSizes.pagePadding,
                    0,
                  ),
                  child: Row(
                    children: [
                      _TopCircleButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.groupsTitle,
                              style: AppTextStyles.pageTitle(context),
                            ),
                            if (!isLoadingGroups && groups.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  context.l10n.activeGroupsCount(groups.length),
                                  style:
                                      AppTextStyles.caption(context).copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _openCreateGroupScreen(context);
                        },
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusPill),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusPill),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue
                                    .withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                context.l10n.createGroup,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: isLoadingGroups
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : isEmpty
                          ? _EmptyGroupsView(
                              onCreateGroup: () {
                                HapticFeedback.lightImpact();
                                _openCreateGroupScreen(context);
                              },
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                AppSizes.pagePadding,
                                12,
                                AppSizes.pagePadding,
                                32,
                              ),
                              itemCount: groups.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final item = groups[index];

                                final groupName =
                                    (item['name'] ?? context.l10n.group)
                                        .toString();

                                final colorHex =
                                    (item['color'] ?? '#79AFFF').toString();

                                final memberCount =
                                    (item['memberCount'] ?? 0) is int
                                        ? item['memberCount'] as int
                                        : int.tryParse(
                                              (item['memberCount'] ?? '0')
                                                  .toString(),
                                            ) ??
                                            0;

                                final goalAmount =
                                    _toDouble(item['goalAmount']);

                                final currentAmount =
                                    _toDouble(item['currentAmount']);

                                final spentAmount =
                                    _toDouble(item['spentAmount']);

                                final remainingBalance =
                                    currentAmount - spentAmount;

                                final progress = goalAmount <= 0
                                    ? 0.0
                                    : (currentAmount / goalAmount)
                                        .clamp(0.0, 1.0)
                                        .toDouble();

                                final groupColor = _parseHexColor(colorHex);

                                return _GroupTile(
                                  groupName: groupName,
                                  groupColor: groupColor,
                                  memberCount: memberCount,
                                  currentAmountText: money(currentAmount),
                                  spentAmount: spentAmount,
                                  spentAmountText: money(spentAmount),
                                  remainingBalance: remainingBalance,
                                  remainingBalanceText: money(remainingBalance),
                                  goalAmount: goalAmount,
                                  goalAmountText: money(goalAmount),
                                  progress: progress,
                                  onTap: () async {
                                    HapticFeedback.lightImpact();
                                    final changed = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => GroupDetailScreen(
                                          groupData: item,
                                        ),
                                      ),
                                    );

                                    if (changed == true && mounted) {
                                      setState(() {});
                                    }
                                  },
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openCreateGroupScreen(BuildContext context) async {
    final uid = context.read<AuthController>().user?.uid;
    final repo = context.read<UserRepository>();

    if (uid == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateGroupScreen(
          myUid: uid,
          repo: repo,
        ),
      ),
    );
  }

  double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  Color _parseHexColor(String hex) {
    final cleaned = hex.replaceAll('#', '');

    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }

    return AppColors.primaryBlue;
  }
}

class _GroupTile extends StatelessWidget {
  final String groupName;
  final Color groupColor;
  final int memberCount;
  final String currentAmountText;
  final double spentAmount;
  final String spentAmountText;
  final double remainingBalance;
  final String remainingBalanceText;
  final double goalAmount;
  final String goalAmountText;
  final double progress;
  final VoidCallback onTap;

  const _GroupTile({
    required this.groupName,
    required this.groupColor,
    required this.memberCount,
    required this.currentAmountText,
    required this.spentAmount,
    required this.spentAmountText,
    required this.remainingBalance,
    required this.remainingBalanceText,
    required this.goalAmount,
    required this.goalAmountText,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSurplus = remainingBalance >= 0;
    final percentInt = (progress * 100).toInt();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.border(context),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: AppColors.isDark(context) ? 0.20 : 0.04,
                ),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Icon + Title + Member count + Arrow
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            groupColor.withValues(alpha: 0.24),
                            groupColor.withValues(alpha: 0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: groupColor.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        Icons.groups_2_rounded,
                        color: groupColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(context).copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface(context),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.innerBorder(context),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_rounded,
                                      size: 13,
                                      color: AppColors.textSecondary(context),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      memberCount > 0
                                          ? context.l10n
                                              .membersCount(memberCount)
                                          : context.l10n.noFriends,
                                      style: AppTextStyles.caption(context)
                                          .copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface(context),
                        border: Border.all(
                          color: AppColors.innerBorder(context),
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary(context),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Middle Highlights: 2 Metric Cards (Balance & Spent)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSurplus
                              ? AppColors.income.withValues(
                                  alpha:
                                      AppColors.isDark(context) ? 0.14 : 0.08,
                                )
                              : AppColors.expense.withValues(
                                  alpha:
                                      AppColors.isDark(context) ? 0.14 : 0.08,
                                ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSurplus
                                ? AppColors.income.withValues(alpha: 0.22)
                                : AppColors.expense.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 14,
                                  color: isSurplus
                                      ? AppColors.income
                                      : AppColors.expense,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  context.l10n.groupFundBalance,
                                  style:
                                      AppTextStyles.caption(context).copyWith(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSurplus
                                        ? AppColors.income
                                        : AppColors.expense,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              remainingBalanceText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSurplus
                                    ? AppColors.income
                                    : AppColors.expense,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.innerBorder(context),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary(context),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  context.l10n.groupFundSpent,
                                  style:
                                      AppTextStyles.caption(context).copyWith(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              spentAmountText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body(context).copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Goal Progress
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.groupGoalWithAmount(goalAmountText),
                          style: AppTextStyles.caption(context).copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        Text(
                          '$percentInt%',
                          style: TextStyle(
                            color: groupColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: AppColors.innerBorder(context),
                        valueColor: AlwaysStoppedAnimation<Color>(groupColor),
                      ),
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

class CreateGroupScreen extends StatefulWidget {
  final String myUid;
  final UserRepository repo;

  const CreateGroupScreen({
    super.key,
    required this.myUid,
    required this.repo,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  static const int kMaxGroupNameLength = UserRepository.maxGroupNameLength;

  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController goalAmountController = TextEditingController();

  final List<Color> groupColors = const [
    AppColors.primaryBlue,
    AppColors.income,
    AppColors.expense,
    AppColors.warning,
    AppColors.primaryPurple,
    AppColors.primaryPink,
    Color(0xFF55B9B2),
    Color(0xFF7B8AD3),
    Color(0xFF4FC3DC),
    Color(0xFFF2D14A),
    Color(0xFFB29B90),
    Color(0xFFA3B3BE),
  ];

  Color selectedColor = AppColors.primaryBlue;
  bool isCreating = false;
  String searchKeyword = '';
  final Set<String> selectedFriendIds = {};
  late final Stream<List<Map<String, dynamic>>> _friendsStream;

  @override
  void initState() {
    super.initState();
    _friendsStream = widget.repo.streamFriends(widget.myUid);
    groupNameController.addListener(_onFieldChanged);
    goalAmountController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    groupNameController.removeListener(_onFieldChanged);
    goalAmountController.removeListener(_onFieldChanged);
    groupNameController.dispose();
    searchController.dispose();
    goalAmountController.dispose();
    super.dispose();
  }

  double _parseMoney(String value, String currency) {
    final cleaned = currency == 'USD'
        ? value.replaceAll(RegExp(r'[^0-9.]'), '')
        : value.replaceAll(RegExp(r'[^0-9]'), '');

    return double.tryParse(cleaned) ?? 0;
  }

  void _applyQuickPreset(double amount, String currency) {
    HapticFeedback.selectionClick();
    if (currency == 'USD') {
      goalAmountController.text = NumberFormat.currency(
        locale: 'en_US',
        decimalDigits: 0,
        symbol: '',
      ).format(amount).trim();
    } else {
      goalAmountController.text = NumberFormat.decimalPattern(
        'vi_VN',
      ).format(amount.round());
    }
  }

  Future<void> _createGroup() async {
    if (isCreating) return;

    final name = groupNameController.text.trim();

    if (name.isEmpty) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.pleaseEnterGroupName),
        ),
      );
      return;
    }

    if (name.length > kMaxGroupNameLength) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.groupNameTooLong),
        ),
      );
      return;
    }

    final currency = context.read<ProfileController>().currency;
    final inputAmount = _parseMoney(goalAmountController.text, currency);

    if (inputAmount <= 0) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.pleaseEnterGoalAmount),
        ),
      );
      return;
    }

    final goalAmount = AppCurrencyFormatter.toVnd(
      inputAmount: inputAmount,
      currency: currency,
    );

    setState(() {
      isCreating = true;
    });

    try {
      await widget.repo.createGroup(
        uid: widget.myUid,
        name: name,
        memberIds: selectedFriendIds.toList(),
        colorHex:
            '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        goalAmount: goalAmount,
      );

      if (!mounted) return;

      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.groupCreated),
        ),
      );

      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;

      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.profileUpdateFailed),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCreating = false;
        });
      }
    }
  }

  static String _removeVietnameseDiacritics(String str) {
    const withDia =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđĐ';
    const withoutDia =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydD';
    var result = str;
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<ProfileController>().currency;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    final enteredName = groupNameController.text.trim();
    final displayName =
        enteredName.isNotEmpty ? enteredName : context.l10n.newGroupDefaultName;
    final parsedGoal = _parseMoney(goalAmountController.text, currency);
    final goalText = parsedGoal > 0
        ? (currency == 'USD'
            ? '\$${parsedGoal.toStringAsFixed(0)}'
            : '${NumberFormat.decimalPattern('vi_VN').format(parsedGoal.round())} ₫')
        : context.l10n.noGoalSetYet;

    final isVnd = currency == 'VND';
    final presets = isVnd
        ? [500000.0, 1000000.0, 2000000.0, 5000000.0, 10000000.0]
        : [50.0, 100.0, 200.0, 500.0, 1000.0];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePadding,
                  12,
                  AppSizes.pagePadding,
                  10,
                ),
                child: Row(
                  children: [
                    _TopCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        context.l10n.createGroup,
                        style: AppTextStyles.pageTitle(context),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.pagePadding,
                    6,
                    AppSizes.pagePadding,
                    isKeyboardOpen ? 24 : 100,
                  ),
                  children: [
                    // LIVE HERO CARD PREVIEW
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            selectedColor.withValues(
                              alpha: AppColors.isDark(context) ? 0.32 : 0.16,
                            ),
                            selectedColor.withValues(
                              alpha: AppColors.isDark(context) ? 0.14 : 0.04,
                            ),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: selectedColor.withValues(alpha: 0.36),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: selectedColor.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: selectedColor,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          selectedColor.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.groups_2_rounded,
                                  color: Colors.white,
                                  size: 30,
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
                                      style:
                                          AppTextStyles.body(context).copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      context.l10n
                                          .groupFundGoalWithAmount(goalText),
                                      style: TextStyle(
                                        color: selectedColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.card(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.border(context),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_pin_rounded,
                                      size: 16,
                                      color: selectedColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      context.l10n.members,
                                      style: AppTextStyles.caption(context)
                                          .copyWith(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  selectedFriendIds.isEmpty
                                      ? context.l10n.groupOwnerYou
                                      : context.l10n.groupYouAndFriends(
                                          selectedFriendIds.length,
                                        ),
                                  style: TextStyle(
                                    color: selectedColor,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // SECTION 1: THÔNG TIN NHÓM
                    _SectionCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: selectedColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.l10n.groupInfoTitle,
                                style: AppTextStyles.sectionTitle(context)
                                    .copyWith(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _EditInputField(
                            controller: groupNameController,
                            label: context.l10n.groupName,
                            hintText: context.l10n.groupNameHint,
                            icon: Icons.groups_2_outlined,
                            cursorColor: selectedColor,
                            maxLength: kMaxGroupNameLength,
                          ),
                          const SizedBox(height: 14),
                          _EditInputField(
                            controller: goalAmountController,
                            label: context.l10n.goalAmount,
                            hintText:
                                AppCurrencyFormatter.formatInputHint(currency),
                            icon: Icons.flag_rounded,
                            suffixText: AppCurrencyFormatter.symbol(currency),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters:
                                isVnd ? [MoneyInputFormatter()] : [],
                            cursorColor: selectedColor,
                          ),
                          const SizedBox(height: 12),
                          // Quick Preset Amount Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: presets.map((amount) {
                              final label = isVnd
                                  ? (amount >= 1000000
                                      ? '${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)}Tr'
                                      : '${(amount / 1000).round()}k')
                                  : '\$${amount.round()}';

                              return InkWell(
                                onTap: () =>
                                    _applyQuickPreset(amount, currency),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface(context),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.innerBorder(context),
                                    ),
                                  ),
                                  child: Text(
                                    '+$label',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // SECTION 2: MÀU SẮC NHẬN DIỆN
                    _SectionCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.palette_outlined,
                                color: selectedColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.l10n.groupColor,
                                style: AppTextStyles.sectionTitle(context)
                                    .copyWith(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.innerBorder(context),
                              ),
                            ),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: groupColors.map((color) {
                                final isSelected = selectedColor.toARGB32() ==
                                    color.toARGB32();

                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      selectedColor = color;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: color,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.transparent,
                                        width: 2.8,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: color.withValues(
                                                  alpha: 0.36,
                                                ),
                                                blurRadius: 12,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // SECTION 3: THÊM THÀNH VIÊN
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _friendsStream,
                      builder: (context, snapshot) {
                        final friends = snapshot.data ?? [];

                        final filteredFriends = friends.where((friend) {
                          if (searchKeyword.trim().isEmpty) return true;

                          final name =
                              (friend['name'] ?? '').toString().toLowerCase();
                          final username = (friend['username'] ?? '')
                              .toString()
                              .toLowerCase();
                          final keyword = searchKeyword.trim().toLowerCase();
                          final cleanKeyword =
                              _removeVietnameseDiacritics(keyword);
                          final cleanName = _removeVietnameseDiacritics(name);
                          final cleanUsername =
                              _removeVietnameseDiacritics(username);

                          return name.contains(keyword) ||
                              username.contains(keyword) ||
                              cleanName.contains(cleanKeyword) ||
                              cleanUsername.contains(cleanKeyword);
                        }).toList();

                        final selectedFriendsList = friends
                            .where((f) => selectedFriendIds
                                .contains((f['uid'] ?? '').toString()))
                            .toList();

                        return _SectionCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.group_add_rounded,
                                    color: selectedColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      context.l10n.addMembers,
                                      style: AppTextStyles.sectionTitle(context)
                                          .copyWith(fontSize: 16),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          selectedColor.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      context.l10n.selectedCount(
                                        selectedFriendIds.length,
                                      ),
                                      style: TextStyle(
                                        color: selectedColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                context.l10n.groupMembersNote,
                                style: AppTextStyles.bodySecondary(context)
                                    .copyWith(
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),

                              // Selected Friends Horizontal Tray
                              if (selectedFriendsList.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 72,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: selectedFriendsList.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 10),
                                    itemBuilder: (context, idx) {
                                      final item = selectedFriendsList[idx];
                                      final fUid =
                                          (item['uid'] ?? '').toString();
                                      final fName =
                                          (item['name'] ?? context.l10n.user)
                                              .toString();
                                      final fAvatar =
                                          (item['avatarUrl'] ?? '').toString();

                                      return Column(
                                        children: [
                                          Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              CircleAvatar(
                                                radius: 22,
                                                backgroundColor:
                                                    AppColors.surface(context),
                                                backgroundImage: fAvatar
                                                        .isNotEmpty
                                                    ? CachedNetworkImageProvider(
                                                        fAvatar,
                                                      )
                                                    : null,
                                                child: fAvatar.isEmpty
                                                    ? Icon(
                                                        Icons.person_rounded,
                                                        color: AppColors
                                                            .textSecondary(
                                                          context,
                                                        ),
                                                        size: 20,
                                                      )
                                                    : null,
                                              ),
                                              Positioned(
                                                top: -2,
                                                right: -2,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    HapticFeedback
                                                        .selectionClick();
                                                    setState(() {
                                                      selectedFriendIds
                                                          .remove(fUid);
                                                    });
                                                  },
                                                  child: Container(
                                                    width: 18,
                                                    height: 18,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.redAccent,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.close_rounded,
                                                      color: Colors.white,
                                                      size: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: 54,
                                            child: Text(
                                              fName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary(
                                                  context,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],

                              const SizedBox(height: 14),
                              _SearchMemberBox(
                                controller: searchController,
                                color: selectedColor,
                                onChanged: (value) {
                                  setState(() {
                                    searchKeyword = value;
                                  });
                                },
                                onClear: () {
                                  setState(() {
                                    searchController.clear();
                                    searchKeyword = '';
                                  });
                                },
                              ),
                              const SizedBox(height: 14),
                              if (friends.isEmpty)
                                const _NoFriendState()
                              else if (filteredFriends.isEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      context.l10n.noUsersFound,
                                      style:
                                          AppTextStyles.bodySecondary(context)
                                              .copyWith(
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...filteredFriends.map((friend) {
                                  final friendUid =
                                      (friend['uid'] ?? '').toString();
                                  final friendName =
                                      (friend['name'] ?? context.l10n.user)
                                          .toString();
                                  final friendUsername =
                                      (friend['username'] ?? '').toString();
                                  final avatarUrl =
                                      (friend['avatarUrl'] ?? '').toString();

                                  final isSelected =
                                      selectedFriendIds.contains(friendUid);

                                  return _MemberSelectTile(
                                    uid: friendUid,
                                    name: friendName,
                                    username: friendUsername,
                                    avatarUrl: avatarUrl,
                                    selected: isSelected,
                                    isOwner: false,
                                    isOldMember: false,
                                    isFriend: true,
                                    color: selectedColor,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        if (isSelected) {
                                          selectedFriendIds.remove(friendUid);
                                        } else {
                                          selectedFriendIds.add(friendUid);
                                        }
                                      });
                                    },
                                  );
                                }),
                            ],
                          ),
                        );
                      },
                    ),

                    if (isKeyboardOpen) ...[
                      const SizedBox(height: 20),
                      CustomButton(
                        height: 52,
                        borderRadius: AppSizes.radiusPill,
                        text: context.l10n.createGroup,
                        backgroundColor: selectedColor,
                        foregroundColor:
                            AppColors.foregroundOnAccent(selectedColor),
                        isLoading: isCreating,
                        onPressedAsync: () {
                          HapticFeedback.mediumImpact();
                          return _createGroup();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isKeyboardOpen
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                10,
                AppSizes.pagePadding,
                MediaQuery.paddingOf(context).bottom > 0
                    ? MediaQuery.paddingOf(context).bottom + 4
                    : 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.background(context),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: AppColors.isDark(context) ? 0.35 : 0.08,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: CustomButton(
                height: 52,
                borderRadius: AppSizes.radiusPill,
                text: context.l10n.createGroup,
                backgroundColor: selectedColor,
                foregroundColor: AppColors.foregroundOnAccent(selectedColor),
                isLoading: isCreating,
                onPressedAsync: () {
                  HapticFeedback.mediumImpact();
                  return _createGroup();
                },
              ),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SectionCard({
    required this.child,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: child,
    );
  }
}

class _EditInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final String? suffixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final Color cursorColor;

  const _EditInputField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.cursorColor,
    this.suffixText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
  });

  @override
  State<_EditInputField> createState() => _EditInputFieldState();
}

class _EditInputFieldState extends State<_EditInputField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counterLimit = widget.maxLength;
    final hasFocus = _focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasFocus ? widget.cursorColor : AppColors.innerBorder(context),
          width: hasFocus ? 1.4 : 1.0,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        cursorColor: widget.cursorColor,
        maxLength: counterLimit,
        buildCounter: counterLimit == null || counterLimit <= 0
            ? null
            : (_,
                {required currentLength,
                required isFocused,
                required maxLength}) {
                final lim = maxLength ?? counterLimit;
                return Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 6),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$currentLength/$lim',
                      style: AppTextStyles.caption(context).copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                );
              },
        style: AppTextStyles.body(context).copyWith(
          fontSize: 16.5,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hintText,
          suffixText: widget.suffixText,
          counterText: counterLimit != null ? '' : null,
          prefixIcon: Icon(
            widget.icon,
            color: hasFocus
                ? widget.cursorColor
                : AppColors.textSecondary(context),
          ),
          labelStyle: AppTextStyles.caption(context).copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: hasFocus ? widget.cursorColor : null,
          ),
          hintStyle: AppTextStyles.caption(context).copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary(context).withValues(alpha: 0.65),
          ),
          suffixStyle: AppTextStyles.caption(context).copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
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
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _SearchMemberBox extends StatefulWidget {
  final TextEditingController controller;
  final Color color;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchMemberBox({
    required this.controller,
    required this.color,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<_SearchMemberBox> createState() => _SearchMemberBoxState();
}

class _SearchMemberBoxState extends State<_SearchMemberBox> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _focusNode.hasFocus;

    return GestureDetector(
      onTap: () {
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFocus ? widget.color : AppColors.innerBorder(context),
            width: hasFocus ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: hasFocus ? widget.color : AppColors.textSecondary(context),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                cursorColor: widget.color,
                style: AppTextStyles.body(context).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: context.l10n.friendsSearchHint,
                  hintStyle: AppTextStyles.bodySecondary(context).copyWith(
                    color:
                        AppColors.textSecondary(context).withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  isDense: true,
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (widget.controller.text.isNotEmpty)
              GestureDetector(
                onTap: widget.onClear,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.cancel_rounded,
                    color: AppColors.textSecondary(context),
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberSelectTile extends StatelessWidget {
  final String uid;
  final String name;
  final String username;
  final String avatarUrl;
  final bool selected;
  final bool isOwner;
  final bool isOldMember;
  final bool isFriend;
  final Color color;
  final VoidCallback onTap;

  const _MemberSelectTile({
    required this.uid,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.selected,
    required this.isOwner,
    required this.isOldMember,
    required this.isFriend,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected
            ? color.withValues(alpha: AppColors.isDark(context) ? 0.16 : 0.08)
            : AppColors.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? color.withValues(alpha: 0.45)
              : AppColors.innerBorder(context),
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        onTap: isOwner ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.card(context),
          backgroundImage: avatarUrl.trim().isNotEmpty
              ? CachedNetworkImageProvider(avatarUrl.trim())
              : null,
          child: avatarUrl.trim().isEmpty
              ? Icon(
                  Icons.person_rounded,
                  color: AppColors.textSecondary(context),
                  size: 20,
                )
              : null,
        ),
        title: Text(
          name.trim().isEmpty ? context.l10n.user : name.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body(context).copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
          ),
        ),
        subtitle: Text(
          username.trim().isNotEmpty ? '@${username.trim()}' : '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context).copyWith(
            fontSize: 12,
          ),
        ),
        trailing: isOwner
            ? Icon(
                Icons.lock_rounded,
                color: color,
                size: 20,
              )
            : AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? color : Colors.transparent,
                  border: Border.all(
                    color: selected ? color : AppColors.textSecondary(context),
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
      ),
    );
  }
}

class _NoFriendState extends StatelessWidget {
  const _NoFriendState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      child: Column(
        children: [
          Icon(
            Icons.group_off_rounded,
            size: 52,
            color: AppColors.textSecondary(context).withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.noFriends,
            style: AppTextStyles.bodySecondary(context).copyWith(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGroupsView extends StatelessWidget {
  final VoidCallback onCreateGroup;

  const _EmptyGroupsView({
    required this.onCreateGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.22),
                    AppColors.primaryBlue.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: const Icon(
                Icons.groups_2_outlined,
                size: 52,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.noGroups,
              style: AppTextStyles.pageTitle(context).copyWith(
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.noGroupsSubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary(context).copyWith(
                fontSize: 15,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 52,
              child: FilledButton.icon(
                onPressed: onCreateGroup,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  context.l10n.createGroup,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
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
