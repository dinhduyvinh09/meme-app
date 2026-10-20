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

class EditGroupScreen extends StatefulWidget {
  final Map<String, dynamic> groupData;

  const EditGroupScreen({
    super.key,
    required this.groupData,
  });

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  static const int kMaxGroupNameLength = UserRepository.maxGroupNameLength;

  late final TextEditingController nameController;
  late final TextEditingController goalController;
  late Color selectedColor;

  String originalName = '';
  late final double _storedGoalAmountVnd;
  late final String _originalColorCanonical;
  Set<String> originalMemberIds = {};

  bool _didSeedGoalField = false;

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

  Set<String> selectedMemberIds = {};
  bool isLoadingMembers = true;

  List<Map<String, dynamic>> currentMemberProfiles = [];
  Stream<List<Map<String, dynamic>>>? _friendsStream;

  final TextEditingController searchController = TextEditingController();
  String searchKeyword = '';

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final myUid = context.read<AuthController>().user?.uid;
    if (myUid != null && _friendsStream == null) {
      _friendsStream = context.read<UserRepository>().streamFriends(myUid);
    }
  }

  @override
  void initState() {
    super.initState();

    originalName = (widget.groupData['name'] ?? '').toString().trim();
    _storedGoalAmountVnd = _toDouble(widget.groupData['goalAmount']);

    nameController = TextEditingController(
      text: originalName,
    );

    goalController = TextEditingController();

    final colorRaw = (widget.groupData['color'] ?? '#79AFFF').toString();
    _originalColorCanonical = _normalizeStoredHex(colorRaw);
    selectedColor = _parseHexColor(colorRaw);

    final memberIds = (widget.groupData['memberIds'] as List?)
            ?.map((e) => e.toString())
            .toSet() ??
        <String>{};

    selectedMemberIds = memberIds;
    originalMemberIds = {...memberIds};

    nameController.addListener(_scheduleRebuildForDirty);
    goalController.addListener(_scheduleRebuildForDirty);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentMembers();
      _seedGoalFieldDisplay();
    });
  }

  void _scheduleRebuildForDirty() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    nameController.removeListener(_scheduleRebuildForDirty);
    goalController.removeListener(_scheduleRebuildForDirty);
    nameController.dispose();
    goalController.dispose();
    searchController.dispose();
    super.dispose();
  }

  String _normalizeStoredHex(String hex) {
    final raw = hex.replaceAll('#', '').trim().toUpperCase();
    return raw.length == 6 ? '#$raw' : '#79AFFF';
  }

  void _seedGoalFieldDisplay() {
    if (!mounted) return;

    final currency = context.read<ProfileController>().currency;

    if (_storedGoalAmountVnd <= 0) {
      goalController.clear();
      setState(() {
        _didSeedGoalField = true;
      });
      return;
    }

    switch (AppCurrencyFormatter.normalizeCurrency(currency)) {
      case 'USD':
        final amount = AppCurrencyFormatter.fromVnd(
          amountVnd: _storedGoalAmountVnd,
          currency: 'USD',
        );
        goalController.text = NumberFormat.currency(
          locale: 'en_US',
          decimalDigits: 2,
          symbol: '',
        ).format(amount).trim();
        break;
      default:
        goalController.text = NumberFormat.decimalPattern(
          'vi_VN',
        ).format(_storedGoalAmountVnd.round());
        break;
    }

    setState(() {
      _didSeedGoalField = true;
    });
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  bool _membersChanged() {
    if (selectedMemberIds.length != originalMemberIds.length) return true;
    for (final id in selectedMemberIds) {
      if (!originalMemberIds.contains(id)) return true;
    }
    return false;
  }

  bool _goalChanged(String? currency) {
    if (!_didSeedGoalField) return false;

    final c = AppCurrencyFormatter.normalizeCurrency(currency);
    final raw = goalController.text.trim();

    if (raw.isEmpty) {
      return _storedGoalAmountVnd.round() != 0;
    }

    final parsed = _parseMoney(raw, c);
    if (parsed <= 0) {
      return _storedGoalAmountVnd.round() != 0;
    }

    final editedVnd = AppCurrencyFormatter.toVnd(
      inputAmount: parsed,
      currency: currency,
    );
    return editedVnd.round() != _storedGoalAmountVnd.round();
  }

  bool _hasPendingEdits(String? currency) {
    if (nameController.text.trim() != originalName) return true;
    if (_colorToHex(selectedColor) != _originalColorCanonical) return true;
    if (_membersChanged()) return true;
    return _goalChanged(currency);
  }

  String get groupId {
    return (widget.groupData['id'] ?? '').toString();
  }

  String get ownerUid {
    return (widget.groupData['ownerUid'] ?? '').toString();
  }

  Future<void> _loadCurrentMembers() async {
    final repo = context.read<UserRepository>();
    final defaultMemberName = context.l10n.member;

    final ids = (widget.groupData['memberIds'] as List?)
            ?.map((e) => e.toString().trim())
            .where((id) => id.isNotEmpty)
            .toList() ??
        [];

    final results = await Future.wait(
      ids.map((uid) async {
        try {
          final user = await repo.getUserProfile(uid);
          if (user != null) {
            return {
              'uid': user.uid,
              'name': user.name,
              'username': user.username,
              'email': user.email,
              'avatarUrl': user.avatarUrl,
              'isCurrentMember': true,
            };
          }
        } catch (_) {}
        return {
          'uid': uid,
          'name': defaultMemberName,
          'username': '',
          'email': '',
          'avatarUrl': '',
          'isCurrentMember': true,
        };
      }),
    );

    if (!mounted) return;

    setState(() {
      currentMemberProfiles = results;
      isLoadingMembers = false;
    });
  }

  double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  double _parseMoney(String value, String currency) {
    final cleaned = currency == 'USD'
        ? value.replaceAll(RegExp(r'[^0-9.]'), '')
        : value.replaceAll(RegExp(r'[^0-9]'), '');

    return double.tryParse(cleaned) ?? 0;
  }

  Color _parseHexColor(String hex) {
    final cleaned = hex.replaceAll('#', '');

    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }

    return AppColors.primaryBlue;
  }

  void _applyQuickPreset(double amount, String currency) {
    HapticFeedback.selectionClick();
    if (currency == 'USD') {
      goalController.text = NumberFormat.currency(
        locale: 'en_US',
        decimalDigits: 0,
        symbol: '',
      ).format(amount).trim();
    } else {
      goalController.text = NumberFormat.decimalPattern(
        'vi_VN',
      ).format(amount.round());
    }
  }

  List<Map<String, dynamic>> _mergeMembersAndFriends({
    required List<Map<String, dynamic>> currentMembers,
    required List<Map<String, dynamic>> friends,
  }) {
    final map = <String, Map<String, dynamic>>{};

    for (final member in currentMembers) {
      final uid = (member['uid'] ?? '').toString();
      if (uid.isEmpty) continue;

      map[uid] = {
        ...member,
        'source': 'member',
      };
    }

    for (final friend in friends) {
      final uid = (friend['uid'] ?? '').toString();
      if (uid.isEmpty) continue;

      map[uid] = {
        ...?map[uid],
        ...friend,
        'source': map.containsKey(uid) ? 'member_friend' : 'friend',
      };
    }

    final items = map.values.toList();

    items.sort((a, b) {
      final aIsOwner = (a['uid'] ?? '').toString() == ownerUid;
      final bIsOwner = (b['uid'] ?? '').toString() == ownerUid;

      if (aIsOwner && !bIsOwner) return -1;
      if (!aIsOwner && bIsOwner) return 1;

      final aSelected = selectedMemberIds.contains((a['uid'] ?? '').toString());
      final bSelected = selectedMemberIds.contains((b['uid'] ?? '').toString());

      if (aSelected && !bSelected) return -1;
      if (!aSelected && bSelected) return 1;

      final aName = (a['name'] ?? a['username'] ?? '').toString();
      final bName = (b['name'] ?? b['username'] ?? '').toString();

      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

    return items;
  }

  void _toggleMember(String uid) {
    if (uid == ownerUid) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.ownerMustBeInGroup),
        ),
      );
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      if (selectedMemberIds.contains(uid)) {
        selectedMemberIds.remove(uid);
      } else {
        selectedMemberIds.add(uid);
      }

      selectedMemberIds.add(ownerUid);
    });
  }

  Future<void> _save() async {
    final myUid = context.read<AuthController>().user?.uid;
    final currency = context.read<ProfileController>().currency;

    if (myUid == null) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.currentUserNotFound),
        ),
      );
      return;
    }

    if (myUid != ownerUid) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.onlyOwnerCanEditGroup),
        ),
      );
      return;
    }

    if (groupId.isEmpty) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.groupInfoNotFound),
        ),
      );
      return;
    }

    final name = nameController.text.trim();
    final inputAmount = _parseMoney(goalController.text, currency);

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

    final finalMemberIds = {
      ...selectedMemberIds,
      ownerUid,
    }.toList();

    try {
      await context.read<UserRepository>().updateGroup(
            myUid: myUid,
            groupId: groupId,
            name: name,
            memberIds: finalMemberIds,
            colorHex: _colorToHex(selectedColor),
            goalAmount: goalAmount,
          );

      if (!mounted) return;

      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.groupUpdated),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(context.l10n.groupUpdateFailedWithError(e.toString())),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = context.read<AuthController>().user?.uid;
    final currency = context.watch<ProfileController>().currency;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final isOwner = myUid != null && myUid == ownerUid;
    final pendingEdits = isOwner ? _hasPendingEdits(currency) : false;

    if (!isOwner) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.pagePadding),
            child: Column(
              children: [
                Row(
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
                        context.l10n.editGroup,
                        style: AppTextStyles.pageTitle(context),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.border(context),
                    ),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 46,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.l10n.noPermissionToEditGroup,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle(context).copyWith(
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.l10n.onlyOwnerCanEditNote,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary(context).copyWith(
                    height: 1.45,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    final enteredName = nameController.text.trim();
    final displayName =
        enteredName.isNotEmpty ? enteredName : context.l10n.group;
    final parsedGoal = _parseMoney(goalController.text, currency);
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
                        context.l10n.editGroup,
                        style: AppTextStyles.pageTitle(context),
                      ),
                    ),
                    if (pendingEdits)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: selectedColor.withValues(alpha: 0.14),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                        child: Text(
                          context.l10n.unsavedChangesLabel,
                          style: TextStyle(
                            color: selectedColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
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
                                  context.l10n.groupMembersCount(
                                    selectedMemberIds.length,
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
                                Icons.edit_note_rounded,
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
                            controller: nameController,
                            label: context.l10n.groupName,
                            hintText: context.l10n.groupNameHint,
                            icon: Icons.groups_2_outlined,
                            cursorColor: selectedColor,
                            maxLength: kMaxGroupNameLength,
                          ),
                          const SizedBox(height: 14),
                          _EditInputField(
                            controller: goalController,
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
                          // Quick Presets
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

                    // SECTION 3: THÀNH VIÊN NHÓM
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _friendsStream ??
                          context.read<UserRepository>().streamFriends(myUid),
                      builder: (context, snapshot) {
                        final friends = snapshot.data ?? [];

                        final mergedItems = _mergeMembersAndFriends(
                          currentMembers: currentMemberProfiles,
                          friends: friends,
                        );

                        final filteredItems = mergedItems.where((item) {
                          if (searchKeyword.trim().isEmpty) return true;
                          final name =
                              (item['name'] ?? '').toString().toLowerCase();
                          final username =
                              (item['username'] ?? '').toString().toLowerCase();
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

                        if (isLoadingMembers) {
                          return _SectionCard(
                            padding: const EdgeInsets.all(22),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        return _SectionCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.group_outlined,
                                    color: selectedColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      context.l10n.groupMembers,
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
                                        selectedMemberIds.length,
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
                              const SizedBox(height: 14),
                              _SearchMemberBox(
                                controller: searchController,
                                color: selectedColor,
                                onChanged: (val) {
                                  setState(() {
                                    searchKeyword = val;
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
                              if (mergedItems.isEmpty)
                                Text(
                                  context.l10n.noMembersOrFriends,
                                  style: AppTextStyles.bodySecondary(context),
                                )
                              else if (filteredItems.isEmpty)
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
                                ...filteredItems.map((item) {
                                  final uid = (item['uid'] ?? '').toString();
                                  final name =
                                      (item['name'] ?? context.l10n.user)
                                          .toString();
                                  final username =
                                      (item['username'] ?? '').toString();
                                  final avatarUrl =
                                      (item['avatarUrl'] ?? '').toString();

                                  final selected =
                                      selectedMemberIds.contains(uid);
                                  final itemIsOwner = uid == ownerUid;

                                  final source =
                                      (item['source'] ?? '').toString();
                                  final isOldMember = source.contains('member');
                                  final isFriend = source.contains('friend');

                                  return _MemberSelectTile(
                                    uid: uid,
                                    name: name,
                                    username: username,
                                    avatarUrl: avatarUrl,
                                    selected: selected,
                                    isOwner: itemIsOwner,
                                    isOldMember: isOldMember,
                                    isFriend: isFriend,
                                    color: selectedColor,
                                    onTap: () => _toggleMember(uid),
                                  );
                                }),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    _InfoNoteCard(
                      selectedColor: selectedColor,
                    ),

                    if (isKeyboardOpen && pendingEdits) ...[
                      const SizedBox(height: 20),
                      CustomButton(
                        height: 52,
                        borderRadius: AppSizes.radiusPill,
                        text: context.l10n.saveChanges,
                        backgroundColor: selectedColor,
                        foregroundColor:
                            AppColors.foregroundOnAccent(selectedColor),
                        onPressedAsync: () {
                          HapticFeedback.mediumImpact();
                          return _save();
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
                text: context.l10n.saveChanges,
                backgroundColor: selectedColor,
                foregroundColor: AppColors.foregroundOnAccent(selectedColor),
                onPressedAsync: pendingEdits
                    ? () {
                        HapticFeedback.mediumImpact();
                        return _save();
                      }
                    : null,
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
    final subtitleParts = <String>[];

    if (isOwner) {
      subtitleParts.add(context.l10n.groupOwner);
    } else if (isOldMember) {
      subtitleParts.add(context.l10n.currentMember);
    }

    if (isFriend) {
      subtitleParts.add(context.l10n.friendsTitle);
    } else if (isOldMember) {
      subtitleParts.add(context.l10n.notFriendsAnymore);
    }

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
          [
            if (username.trim().isNotEmpty) '@${username.trim()}',
            ...subtitleParts,
          ].join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption(context).copyWith(
            fontSize: 12,
          ),
        ),
        trailing: isOwner
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: color,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.groupOwner,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
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

class _InfoNoteCard extends StatelessWidget {
  final Color selectedColor;

  const _InfoNoteCard({
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selectedColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: selectedColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.groupMemberManagementNote,
              style: AppTextStyles.bodySecondary(context).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
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
          color: AppColors.textPrimary(context),
          size: 18,
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
