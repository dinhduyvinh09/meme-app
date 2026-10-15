import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/meme_logo.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? localError;
  bool _primaryAuthBusy = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(AuthController auth) async {
    if (auth.isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      localError = null;
    });

    final emailError = AppValidators.email(email);
    if (emailError != null) {
      setState(() => localError = emailError);
      return;
    }

    final l10n = context.l10n;
    final passwordError = AppValidators.requiredText(
      password,
      message: l10n.pleaseEnterPasswordLogin,
    );
    if (passwordError != null) {
      setState(() => localError = passwordError);
      return;
    }

    final ok = await auth.login(email, password);

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
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFFBFBFD),
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
                      // Header with sweeping curve
                      _AuthCurvedHeader(
                        subtitle: l10n.loginSubtitle,
                      ),

                      // Form Body
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),

                              // Screen Title
                              Text(
                                l10n.login,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary(context),
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Email Field
                              _AuthLabeledField(
                                label: l10n.email,
                                child: TextField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  cursorColor: AppColors.primaryBlue,
                                  style: TextStyle(
                                    color: AppColors.textPrimary(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: _authInputDecoration(
                                    context,
                                    hintText: 'name@example.com',
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
                                  textInputAction: TextInputAction.done,
                                  cursorColor: AppColors.primaryBlue,
                                  style: TextStyle(
                                    color: AppColors.textPrimary(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: _authInputDecoration(
                                    context,
                                    hintText: '••••••••',
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? l10n.showPassword
                                          : l10n.hidePassword,
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColors.textSecondary(context),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Forgot Password Link
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: authBusy
                                      ? null
                                      : () => Navigator.pushNamed(
                                            context,
                                            RouteNames.forgotPassword,
                                          ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 2,
                                    ),
                                    child: Text(
                                      l10n.forgotPassword,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.primaryBlue
                                            : const Color(0xFF121520),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              if (errorText != null && errorText.trim().isNotEmpty) ...[
                                const SizedBox(height: 14),
                                _AuthErrorBox(text: errorText),
                              ],

                              const SizedBox(height: 24),

                              // Primary Login Button
                              CustomButton(
                                text: l10n.login,
                                isLoading: auth.isLoading,
                                backgroundColor: isDark
                                    ? AppColors.primaryBlue
                                    : const Color(0xFF121520),
                                foregroundColor: Colors.white,
                                borderRadius: 27,
                                height: 54,
                                onPressedAsync: () => _login(auth),
                                onBusyChanged: (busy) =>
                                    setState(() => _primaryAuthBusy = busy),
                              ),

                              const Spacer(),

                              // Bottom Link to Register
                              SafeArea(
                                top: false,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: authBusy
                                          ? null
                                          : () => Navigator.pushNamed(
                                                context,
                                                RouteNames.register,
                                              ),
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textSecondary(context),
                                          ),
                                          children: [
                                            TextSpan(text: l10n.dontHaveAccount),
                                            TextSpan(
                                              text: l10n.register,
                                              style: TextStyle(
                                                color: isDark
                                                    ? AppColors.primaryBlue
                                                    : const Color(0xFF121520),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
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
          },
        ),
      ),
    );
  }
}

class _AuthCurvedHeader extends StatelessWidget {
  final String subtitle;

  const _AuthCurvedHeader({
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = AppColors.isDark(context);
    final headerColor = isDark ? const Color(0xFF141724) : const Color(0xFF121520);
    final headerHeight = topPadding + 165.0;

    return SizedBox(
      height: headerHeight,
      width: double.infinity,
      child: Stack(
        children: [
          // Background with organic curve
          Positioned.fill(
            child: ClipPath(
              clipper: const _CurvedHeaderClipper(),
              child: Container(
                color: headerColor,
              ),
            ),
          ),
          // Header Content
          Positioned(
            top: topPadding + 14,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MemeLogo(
                      height: 28,
                      showSubtitle: false,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'MEME',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurvedHeaderClipper extends CustomClipper<Path> {
  const _CurvedHeaderClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.74);

    path.cubicTo(
      size.width * 0.28,
      size.height * 0.98,
      size.width * 0.64,
      size.height * 0.85,
      size.width,
      size.height * 0.28,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

InputDecoration _authInputDecoration(
  BuildContext context, {
  required String hintText,
  Widget? suffixIcon,
}) {
  final isDark = AppColors.isDark(context);

  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary(context).withValues(alpha: 0.55),
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: isDark ? AppColors.darkSurface : Colors.white,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: AppColors.innerBorder(context),
        width: 1.2,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: AppColors.innerBorder(context),
        width: 1.2,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: isDark ? AppColors.primaryBlue : const Color(0xFF121520),
        width: 1.5,
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
    final errorColor = AppColors.isDark(context)
        ? const Color(0xFFFFB0B0)
        : AppColors.expenseDark;

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
          Icon(
            Icons.error_outline_rounded,
            color: errorColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
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