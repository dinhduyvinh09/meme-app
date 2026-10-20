import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../capture/screens/square_crop_screen.dart';
import '../controllers/profile_controller.dart';
import 'change_email_screen.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _EditProfileScreenBody();
  }
}

class _EditProfileScreenBody extends StatefulWidget {
  const _EditProfileScreenBody();

  @override
  State<_EditProfileScreenBody> createState() => _EditProfileScreenBodyState();
}

class _EditProfileScreenBodyState extends State<_EditProfileScreenBody> {
  final nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  File? selectedAvatar;
  bool didFillData = false;

  /// Trailing/leading spaces ignored when comparing drafts to baseline.
  String _baselineNameTrimmed = '';

  bool _hasProfileDraftChanges() {
    final draft = nameController.text.trim();
    return draft != _baselineNameTrimmed || selectedAvatar != null;
  }

  bool _canSaveDraft(ProfileController profile) {
    if (profile.isSaving) return false;
    final draft = nameController.text.trim();
    if (draft.isEmpty) return false;
    return _hasProfileDraftChanges();
  }

  @override
  void initState() {
    super.initState();
    nameController.addListener(_onNameChanged);
    _nameFocusNode.addListener(_onFocusChanged);
  }

  void _onNameChanged() {
    setState(() {});
  }

  void _onFocusChanged() {
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (didFillData) return;

    final profile = context.read<ProfileController>();
    final raw = profile.user?.name ?? '';
    _baselineNameTrimmed = raw.trim();
    nameController.text = raw;
    didFillData = true;
  }

  @override
  void dispose() {
    nameController.removeListener(_onNameChanged);
    _nameFocusNode.removeListener(_onFocusChanged);
    nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> pickAvatar() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();

    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );

    if (file == null || !mounted) return;

    final croppedFile = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (_) => SquareCropScreen(
          imageFile: File(file.path),
          title: context.l10n.cropAvatarTitle,
        ),
      ),
    );

    if (croppedFile == null || !mounted) return;

    setState(() {
      selectedAvatar = croppedFile;
    });
  }

  Future<void> _saveProfile() async {
    final profile = context.read<ProfileController>();
    final auth = context.read<AuthController>();
    final l10n = context.l10n;
    final uid = auth.user?.uid;

    if (uid == null || profile.isSaving) return;

    final name = nameController.text.trim();

    if (name.isEmpty) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(l10n.pleaseEnterName),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final ok = await profile.updateProfile(
      uid: uid,
      name: name,
      avatarFile: selectedAvatar,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: AppDurations.snackBar,
        content: Text(
          ok ? l10n.profileUpdated : l10n.profileUpdateFailed,
        ),
      ),
    );

    if (ok) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final l10n = context.l10n;
    final user = profile.user;
    final currentAvatar = user?.avatarUrl ?? '';
    final username = user?.username ?? '';
    final email = user?.email ?? '';
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final hasChanges = _hasProfileDraftChanges();

    final enteredName = nameController.text.trim();
    final previewDisplayName =
        enteredName.isNotEmpty ? enteredName : (user?.name ?? l10n.user);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // Top Bar
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
                      onTap: profile.isSaving
                          ? () {}
                          : () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        l10n.editProfile,
                        style: AppTextStyles.pageTitle(context),
                      ),
                    ),
                    if (hasChanges)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.14),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                        child: Text(
                          l10n.unsavedChangesLabel,
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
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
                    // LIVE HERO PROFILE PREVIEW
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryBlue.withValues(
                              alpha: AppColors.isDark(context) ? 0.28 : 0.12,
                            ),
                            AppColors.primaryBlue.withValues(
                              alpha: AppColors.isDark(context) ? 0.10 : 0.03,
                            ),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.28),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primaryBlue.withValues(alpha: 0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _AvatarPicker(
                            selectedAvatar: selectedAvatar,
                            currentAvatar: currentAvatar,
                            onTap: pickAvatar,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            previewDisplayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body(context).copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (username.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '@$username',
                              style: AppTextStyles.caption(context).copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: pickAvatar,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusPill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.card(context),
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusPill),
                                border: Border.all(
                                  color: AppColors.primaryBlue
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.photo_camera_outlined,
                                    size: 15,
                                    color: AppColors.primaryBlue,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.changePhoto,
                                    style: const TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontSize: 12.5,
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
                    const SizedBox(height: 18),

                    // SECTION 1: DISPLAY NAME EDIT
                    _SectionCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.badge_outlined,
                                color: AppColors.primaryBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.displayNameLabel,
                                style: AppTextStyles.sectionTitle(context)
                                    .copyWith(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _nameFocusNode.hasFocus
                                    ? AppColors.primaryBlue
                                    : AppColors.innerBorder(context),
                                width: _nameFocusNode.hasFocus ? 1.4 : 1.0,
                              ),
                            ),
                            child: TextField(
                              controller: nameController,
                              focusNode: _nameFocusNode,
                              maxLength: 50,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(50),
                              ],
                              cursorColor: AppColors.primaryBlue,
                              style: AppTextStyles.body(context).copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: InputDecoration(
                                hintText: l10n.displayNameHint,
                                counterText: '',
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  color: _nameFocusNode.hasFocus
                                      ? AppColors.primaryBlue
                                      : AppColors.textSecondary(context),
                                ),
                                suffixIcon: nameController.text.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          nameController.clear();
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Icon(
                                            Icons.cancel_rounded,
                                            color: AppColors.textSecondary(
                                                context),
                                            size: 20,
                                          ),
                                        ),
                                      )
                                    : null,
                                hintStyle: AppTextStyles.bodySecondary(context)
                                    .copyWith(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
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
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.displayNameHelper,
                                  style:
                                      AppTextStyles.caption(context).copyWith(
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${nameController.text.length}/50',
                                style: AppTextStyles.caption(context).copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // SECTION 2: ACCOUNT SECURITY / READ-ONLY DETAILS
                    _SectionCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                color: AppColors.primaryBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.personalInfo,
                                style: AppTextStyles.sectionTitle(context)
                                    .copyWith(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Username Tile
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.innerBorder(context),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.alternate_email_rounded,
                                  color: AppColors.textSecondary(context),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.usernameLabel,
                                        style: AppTextStyles.caption(context)
                                            .copyWith(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        username.isNotEmpty
                                            ? '@$username'
                                            : l10n.notSet,
                                        style: AppTextStyles.body(context)
                                            .copyWith(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.textSecondary(context),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Email Tile
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.innerBorder(context),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.mail_outline_rounded,
                                  color: AppColors.textSecondary(context),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.emailLabel,
                                        style: AppTextStyles.caption(context)
                                            .copyWith(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        email.isNotEmpty ? email : l10n.notSet,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.body(context)
                                            .copyWith(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const ChangeEmailScreen()));
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      l10n.changeEmailAction,
                                      style: const TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (isKeyboardOpen) ...[
                      const SizedBox(height: 20),
                      CustomButton(
                        height: 52,
                        borderRadius: AppSizes.radiusPill,
                        text: l10n.saveChanges,
                        isLoading: profile.isSaving,
                        onPressedAsync:
                            _canSaveDraft(profile) ? _saveProfile : null,
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
                text: l10n.saveChanges,
                isLoading: profile.isSaving,
                onPressedAsync: _canSaveDraft(profile) ? _saveProfile : null,
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

class _AvatarPicker extends StatelessWidget {
  final File? selectedAvatar;
  final String currentAvatar;
  final VoidCallback onTap;

  const _AvatarPicker({
    required this.selectedAvatar,
    required this.currentAvatar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCurrentAvatar = currentAvatar.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card(context),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.35),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.20),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: selectedAvatar != null
                  ? Image.file(
                      selectedAvatar!,
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                      cacheHeight: 300,
                    )
                  : hasCurrentAvatar
                      ? CachedNetworkImage(
                          imageUrl: currentAvatar.trim(),
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) =>
                              const _AvatarFallbackIcon(),
                        )
                      : const _AvatarFallbackIcon(),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.background(context),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallbackIcon extends StatelessWidget {
  const _AvatarFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.person_rounded,
      size: 52,
      color: AppColors.textSecondary(context),
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
