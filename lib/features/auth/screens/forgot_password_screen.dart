import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_curved_header.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();

  bool _recoveryBusy = false;
  String? localError;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController auth) async {
    final l10n = AppLocalizations.of(context)!;
    final email = emailController.text.trim();

    setState(() {
      localError = null;
    });

    final emailError = AppValidators.email(email);
    if (emailError != null) {
      setState(() => localError = emailError);
      return;
    }

    final ok = await auth.sendResetPassword(email);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: AppDurations.snackBar,
          content: Text(l10n.recoveryEmailSent),
        ),
      );

      Navigator.pop(context);
    } else {
      setState(() {
        localError = auth.error ?? l10n.couldNotSendRecoveryEmail;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    final l10n = context.l10n;

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
                        onBack: _recoveryBusy
                            ? null
                            : () => Navigator.pop(context),
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
                                l10n.forgotPasswordTitle,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF14151B),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.forgotPasswordInstruction,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF74788A),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Email Field
                              _AuthLabeledField(
                                label: l10n.email,
                                child: TextField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
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

                              if (localError != null &&
                                  localError!.trim().isNotEmpty) ...[
                                const SizedBox(height: 14),
                                _AuthErrorBox(text: localError!),
                              ],

                              const SizedBox(height: 24),

                              // Submit Button (MeMe Brand Blue)
                              CustomButton(
                                text: l10n.sendRecoveryEmail,
                                isLoading: _recoveryBusy,
                                backgroundColor: AppColors.primaryBlueDark,
                                foregroundColor: Colors.white,
                                borderRadius: 27,
                                height: 54,
                                onPressedAsync: () => _submit(auth),
                                onBusyChanged: (busy) =>
                                    setState(() => _recoveryBusy = busy),
                              ),

                              const Spacer(),
                              const SizedBox(height: 20),

                              // Bottom Link back to Login
                              SafeArea(
                                top: false,
                                child: Center(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _recoveryBusy
                                        ? null
                                        : () => Navigator.pop(context),
                                    child: Text(
                                      l10n.backToLogin,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryBlueDark,
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

  const _AuthLabeledField({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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