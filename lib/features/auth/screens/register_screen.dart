import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_curved_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  DateTime? _dateOfBirth;
  String? localError;
  bool _primaryAuthBusy = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  _PasswordStrength _passwordStrength(
    BuildContext context,
    String password,
  ) {
    final l10n = context.l10n;
    final text = password.trim();

    if (text.isEmpty) {
      return _PasswordStrength(
        label: l10n.passwordStrengthNone,
        progress: 0,
        color: const Color(0xFF74788A),
        description: l10n.passwordDescEmpty,
      );
    }

    final hasLower = RegExp(r'[a-zà-ỹ]').hasMatch(text);
    final hasUpper = RegExp(r'[A-ZÀ-Ỹ]').hasMatch(text);
    final hasNumber = RegExp(r'[0-9]').hasMatch(text);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\[\]~` ]').hasMatch(text);
    final hasMinLength = text.length >= 6;
    final hasGoodLength = text.length >= 8;

    int passedCount = 0;
    if (hasMinLength) passedCount++;
    if (hasLower) passedCount++;
    if (hasUpper) passedCount++;
    if (hasNumber) passedCount++;
    if (hasSpecial) passedCount++;

    final meetsAllRequirements =
        hasMinLength && hasLower && hasUpper && hasNumber && hasSpecial;

    if (!hasMinLength) {
      return _PasswordStrength(
        label: l10n.passwordStrengthWeak,
        progress: (passedCount / 5.0) * 0.35,
        color: AppColors.expense,
        description: l10n.passwordDescTooShort,
      );
    }

    if (meetsAllRequirements) {
      if (hasGoodLength) {
        return _PasswordStrength(
          label: l10n.passwordStrengthStrong,
          progress: 1.0,
          color: AppColors.income,
          description: l10n.passwordDescStrong,
        );
      }

      return _PasswordStrength(
        label: l10n.passwordStrengthMedium,
        progress: 0.8,
        color: AppColors.warning,
        description: l10n.passwordDescMedium,
      );
    }

    return _PasswordStrength(
      label: l10n.passwordStrengthWeak,
      progress: (passedCount / 5.0) * 0.65,
      color: AppColors.expense,
      description: l10n.passwordDescNeedBoth,
    );
  }

  bool _isPasswordComplex(String password) {
    final text = password.trim();
    if (text.length < 6) return false;
    final hasLower = RegExp(r'[a-zà-ỹ]').hasMatch(text);
    final hasUpper = RegExp(r'[A-ZÀ-Ỹ]').hasMatch(text);
    final hasNumber = RegExp(r'[0-9]').hasMatch(text);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\[\]~` ]').hasMatch(text);

    return hasLower && hasUpper && hasNumber && hasSpecial;
  }

  Future<void> _pickDateOfBirth() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    DateTime tempDate = _dateOfBirth ?? DateTime(now.year, now.month, now.day);
    final l10n = context.l10n;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.black12,
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryPink.withValues(alpha: 0.15),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.cake_outlined,
                              color: AppColors.primaryPink,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.selectBirthday,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF14151B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd/MM/yyyy').format(tempDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryPink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(
                      height: 1,
                      color: Colors.black12,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 300,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primaryBlueDark,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Colors.black87,
                          ),
                        ),
                        child: CalendarDatePicker(
                          initialDate: tempDate.isAfter(now) ? now : tempDate,
                          firstDate: DateTime(1900),
                          lastDate: now,
                          onDateChanged: (newDate) {
                            setSheetState(() {
                              tempDate = newDate;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(
                                color: Colors.black12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              l10n.cancel,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF74788A),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(sheetCtx, tempDate),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppColors.primaryBlueDark,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              l10n.confirm,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _register(AuthController auth) async {
    if (auth.isLoading) return;

    final name = nameController.text.trim();
    final username = usernameController.text.trim().toLowerCase();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    setState(() {
      localError = null;
    });

    final l10n = context.l10n;
    final nameError = AppValidators.requiredText(
      name,
      message: l10n.pleaseEnterName,
    );
    if (nameError != null) {
      setState(() => localError = nameError);
      return;
    }

    final usernameError = AppValidators.username(
      username,
      requiredMessage: l10n.pleaseEnterUsername,
      invalidMessage: l10n.invalidUsername,
    );
    if (usernameError != null) {
      setState(() => localError = usernameError);
      return;
    }

    final emailError = AppValidators.email(
      email,
      requiredMessage: l10n.pleaseEnterEmail,
      invalidMessage: l10n.invalidEmailGeneric,
    );
    if (emailError != null) {
      setState(() => localError = emailError);
      return;
    }

    final passwordError = AppValidators.password(
      password,
      requiredMessage: l10n.pleaseEnterPasswordLogin,
      minLengthMessage: l10n.passwordMinLength,
    );
    if (passwordError != null) {
      setState(() => localError = passwordError);
      return;
    }

    if (!_isPasswordComplex(password)) {
      setState(() {
        localError = l10n.passwordNeedsLetterAndNumber;
      });
      return;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        localError = l10n.pleaseConfirmPassword;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        localError = l10n.passwordsDoNotMatch;
      });
      return;
    }

    final ok = await auth.register(
      name: name,
      username: username,
      email: email,
      password: password,
      dateOfBirth: _dateOfBirth,
    );

    if (ok && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.mainShell,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthController>();
    final errorText = localError ?? auth.error;
    final authBusy = auth.isLoading || _primaryAuthBusy;
    final passwordStrength = _passwordStrength(
      context,
      passwordController.text,
    );
    final passwordsMatch = confirmPasswordController.text.trim().isNotEmpty &&
        passwordController.text.trim() == confirmPasswordController.text.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Expanded MeMe brand blue curved header with back button
                      AuthCurvedHeader(
                        showBackButton: true,
                        onBack: authBusy ? null : () => Navigator.pop(context),
                      ),

                      // Form Body (seamless pure white canvas)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),

                              // Screen Title
                              Text(
                                l10n.register,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF14151B),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.registerSubtitle,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF74788A),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Display Name Field
                              _AuthLabeledField(
                                label: l10n.displayName,
                                child: TextField(
                                  controller: nameController,
                                  textInputAction: TextInputAction.next,
                                  cursorColor: AppColors.primaryBlueDark,
                                  style: const TextStyle(
                                    color: Color(0xFF14151B),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: _authInputDecoration(
                                    context,
                                    hintText: 'Nguyễn Văn A',
                                    prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                      size: 20,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Username Field
                              _AuthLabeledField(
                                label: l10n.username,
                                note: l10n.usernameHint,
                                child: TextField(
                                  controller: usernameController,
                                  textInputAction: TextInputAction.next,
                                  cursorColor: AppColors.primaryBlueDark,
                                  style: const TextStyle(
                                    color: Color(0xFF14151B),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: _authInputDecoration(
                                    context,
                                    hintText: 'nguyenvana',
                                    prefixIcon: const Icon(
                                      Icons.alternate_email_rounded,
                                      size: 20,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Date of Birth (Optional)
                              _AuthLabeledField(
                                label: l10n.selectBirthday,
                                note: l10n.birthdayOptional,
                                child: InkWell(
                                  onTap: authBusy ? null : _pickDateOfBirth,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFD),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 19,
                                          color: Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _dateOfBirth != null
                                                ? DateFormat('dd/MM/yyyy')
                                                    .format(_dateOfBirth!)
                                                : 'DD/MM/YYYY',
                                            style: _dateOfBirth != null
                                                ? const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF14151B),
                                                  )
                                                : const TextStyle(
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                          ),
                                        ),
                                        if (_dateOfBirth != null)
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _dateOfBirth = null;
                                              });
                                            },
                                            child: const Icon(
                                              Icons.close_rounded,
                                              size: 19,
                                              color: Color(0xFF74788A),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Email Field
                              _AuthLabeledField(
                                label: l10n.email,
                                child: TextField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  cursorColor: AppColors.primaryBlueDark,
                                  style: const TextStyle(
                                    color: Color(0xFF14151B),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: _authInputDecoration(
                                    context,
                                    hintText: 'name@example.com',
                                    prefixIcon: const Icon(
                                      Icons.mail_outline_rounded,
                                      size: 20,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Password Field
                              _AuthLabeledField(
                                label: l10n.password,
                                child: TextField(
                                  controller: passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.next,
                                  cursorColor: AppColors.primaryBlueDark,
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(
                                    color: Color(0xFF14151B),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: _authInputDecoration(
                                    context,
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 20,
                                      color: Color(0xFF64748B),
                                    ),
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? l10n.showPassword
                                          : l10n.hidePassword,
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword =
                                              !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF74788A),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Password Strength Indicator View
                              _PasswordStrengthView(
                                strength: passwordStrength,
                              ),
                              const SizedBox(height: 18),

                              // Confirm Password Field
                              _AuthLabeledField(
                                label: l10n.confirmPassword,
                                child: TextField(
                                  controller: confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  textInputAction: TextInputAction.done,
                                  cursorColor: AppColors.primaryBlueDark,
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(
                                    color: Color(0xFF14151B),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: _authInputDecoration(
                                    context,
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 20,
                                      color: Color(0xFF64748B),
                                    ),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (confirmPasswordController
                                            .text
                                            .trim()
                                            .isNotEmpty) ...[
                                          Icon(
                                            passwordsMatch
                                                ? Icons.check_circle_rounded
                                                : Icons.error_rounded,
                                            color: passwordsMatch
                                                ? AppColors.income
                                                : AppColors.expense,
                                            size: 19,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        IconButton(
                                          tooltip: _obscureConfirmPassword
                                              ? l10n.showPassword
                                              : l10n.hidePassword,
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword;
                                            });
                                          },
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: const Color(0xFF74788A),
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              if (errorText != null &&
                                  errorText.trim().isNotEmpty) ...[
                                const SizedBox(height: 14),
                                _AuthErrorBox(text: errorText),
                              ],

                              const SizedBox(height: 24),

                              // Primary Register Button (MeMe Brand Blue)
                              CustomButton(
                                text: l10n.register,
                                isLoading: auth.isLoading,
                                backgroundColor: AppColors.primaryBlueDark,
                                foregroundColor: Colors.white,
                                borderRadius: 27,
                                height: 54,
                                onPressedAsync: () => _register(auth),
                                onBusyChanged: (busy) =>
                                    setState(() => _primaryAuthBusy = busy),
                              ),

                              const Spacer(),
                              const SizedBox(height: 20),

                              // Bottom Link to Login
                              SafeArea(
                                top: false,
                                child: Center(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: authBusy
                                        ? null
                                        : () => Navigator.pop(context),
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF74788A),
                                        ),
                                        children: [
                                          TextSpan(
                                              text:
                                                  '${l10n.alreadyHaveAccount} '),
                                          TextSpan(
                                            text: l10n.login,
                                            style: const TextStyle(
                                              color: AppColors.primaryBlueDark,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuthLabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  final String? note;

  const _AuthLabeledField({
    required this.label,
    required this.child,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF14151B),
                letterSpacing: -0.2,
              ),
            ),
            if (note != null)
              Flexible(
                child: Text(
                  note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF74788A),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

InputDecoration _authInputDecoration(
  BuildContext context, {
  required String hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF8FAFD),
    hintStyle: const TextStyle(
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      color: Color(0xFF94A3B8),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Color(0xFFE2E8F0),
        width: 1.2,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Color(0xFFE2E8F0),
        width: 1.2,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: AppColors.primaryBlueDark,
        width: 1.6,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: AppColors.expense,
        width: 1.2,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: AppColors.expense,
        width: 1.5,
      ),
    ),
  );
}

class _PasswordStrength {
  final String label;
  final double progress;
  final Color color;
  final String description;

  const _PasswordStrength({
    required this.label,
    required this.progress,
    required this.color,
    required this.description,
  });
}

class _PasswordStrengthView extends StatelessWidget {
  final _PasswordStrength strength;

  const _PasswordStrengthView({
    required this.strength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: strength.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: strength.color.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: strength.color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.l10n.passwordStrengthTitle(strength.label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: strength.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: strength.progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                strength.color,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strength.description,
            style: AppTextStyles.caption(context).copyWith(
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF74788A),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthErrorBox extends StatelessWidget {
  final String text;

  const _AuthErrorBox({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    const errorColor = AppColors.expenseDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.expense.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.expense.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: errorColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: errorColor,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}