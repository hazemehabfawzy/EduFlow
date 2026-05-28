// lib/screens/auth/auth_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_text_field.dart';

/// The single Auth screen that houses Login and Register as sliding tabs.
/// Forgot-password appears as a modal bottom-sheet.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── Login controllers ───────────────────────────────────────────────────
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();

  // ── Register controllers ────────────────────────────────────────────────
  final _registerFormKey = GlobalKey<FormState>();
  final _registerName = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerPassword = TextEditingController();
  final _registerConfirmPass = TextEditingController();

  // ── Focus nodes ─────────────────────────────────────────────────────────
  final _loginPasswordFocus = FocusNode();
  final _registerEmailFocus = FocusNode();
  final _registerPasswordFocus = FocusNode();
  final _registerConfirmFocus = FocusNode();

  Timer? _gradientTimer;
  int _colorIndex = 0;
  final List<List<Color>> _gradientColors = [
    [AppColors.primary, const Color(0xFF7C74FF)],
    [const Color(0xFF7C74FF), AppColors.accent],
    [AppColors.accent, AppColors.primary],
  ];

  @override
  void initState() {
    super.initState();
    _loginEmail.text = 'hazemehabsat@gamil.com';
    _loginPassword.text = 'H123456';
    _tabController = TabController(length: 2, vsync: this);
    // Clear provider error when tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        context.read<AuthProvider>().clearError();
      }
    });

    _gradientTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _colorIndex = (_colorIndex + 1) % _gradientColors.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _gradientTimer?.cancel();
    _tabController.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _registerName.dispose();
    _registerEmail.dispose();
    _registerPassword.dispose();
    _registerConfirmPass.dispose();
    _loginPasswordFocus.dispose();
    _registerEmailFocus.dispose();
    _registerPasswordFocus.dispose();
    _registerConfirmFocus.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(
      email: _loginEmail.text,
      password: _loginPassword.text,
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      _showError(auth.errorMessage ?? 'Login failed');
    }
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      name: _registerName.text,
      email: _registerEmail.text,
      password: _registerPassword.text,
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      _showError(auth.errorMessage ?? 'Registration failed');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.cardDark
            : AppColors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ForgotPasswordSheet(),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Decorative gradient header ─────────────────────────────────
          _buildHeader(size),

          // ── Main scrollable content ───────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Logo + tagline
                _buildBranding()
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.3, curve: Curves.easeOut),

                const SizedBox(height: 24),

                // White / dark card with tabs
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, -8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        // Tab bar
                        _buildTabBar(isDark),
                        const SizedBox(height: 8),
                        // Tab views
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _LoginTab(
                                formKey: _loginFormKey,
                                emailCtrl: _loginEmail,
                                passwordCtrl: _loginPassword,
                                passwordFocus: _loginPasswordFocus,
                                onLogin: _login,
                                onForgotPassword: _showForgotPassword,
                              ),
                              _RegisterTab(
                                formKey: _registerFormKey,
                                nameCtrl: _registerName,
                                emailCtrl: _registerEmail,
                                passwordCtrl: _registerPassword,
                                confirmPasswordCtrl: _registerConfirmPass,
                                emailFocus: _registerEmailFocus,
                                passwordFocus: _registerPasswordFocus,
                                confirmFocus: _registerConfirmFocus,
                                onRegister: _register,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 200.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return AnimatedContainer(
      duration: const Duration(seconds: 2),
      height: size.height * 0.35,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradientColors[_colorIndex],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: _Circle(size: 160, opacity: 0.12),
          ),
          Positioned(
            top: 60,
            left: -30,
            child: _Circle(size: 120, opacity: 0.08),
          ),
          Positioned(
            bottom: 40,
            right: 60,
            child: _Circle(size: 80, opacity: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildBranding() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          // Logo mark
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.white.withOpacity(0.4), width: 1.5),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'EduFlow',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Learn. Grow. Succeed.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.white.withOpacity(0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          labelColor: AppColors.white,
          unselectedLabelColor:
              isDark ? const Color(0xFF6B7280) : AppColors.textSecondary,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Sign In'),
            Tab(text: 'Sign Up'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN TAB
// ─────────────────────────────────────────────────────────────────────────────

class _LoginTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final FocusNode passwordFocus;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;

  const _LoginTab({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.passwordFocus,
    required this.onLogin,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back! 👋',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Sign in to continue your learning journey.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),

            // Email
            CustomTextField(
              label: 'Email Address',
              hint: 'you@example.com',
              controller: emailCtrl,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onEditingComplete: () => passwordFocus.requestFocus(),
              validator: Validators.email,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .slideX(begin: -0.05),

            const SizedBox(height: 20),

            // Password
            CustomTextField(
              label: 'Password',
              hint: '••••••••',
              controller: passwordCtrl,
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              focusNode: passwordFocus,
              textInputAction: TextInputAction.done,
              onEditingComplete: onLogin,
              validator: Validators.password,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 150.ms)
                .slideX(begin: -0.05),

            const SizedBox(height: 12),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPassword,
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

            const SizedBox(height: 8),

            // Sign In button
            GradientButton(
              label: 'Sign In',
              isLoading: auth.isLoading,
              onPressed: auth.isLoading ? null : onLogin,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 250.ms)
                .slideY(begin: 0.1),

            const SizedBox(height: 20),
            _OrDivider().animate().fadeIn(duration: 400.ms, delay: 280.ms),
            const SizedBox(height: 16),
            _SocialButton(
              label: 'Continue with Google',
              icon: Icons.g_mobiledata_rounded,
              onTap: () {},
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms)
                .slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REGISTER TAB
// ─────────────────────────────────────────────────────────────────────────────

class _RegisterTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmPasswordCtrl;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final FocusNode confirmFocus;
  final VoidCallback onRegister;

  const _RegisterTab({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmPasswordCtrl,
    required this.emailFocus,
    required this.passwordFocus,
    required this.confirmFocus,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create account 🚀',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Start your learning journey today.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),

            // Full Name
            CustomTextField(
              label: 'Full Name',
              hint: 'John Doe',
              controller: nameCtrl,
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              onEditingComplete: () => emailFocus.requestFocus(),
              validator: Validators.fullName,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .slideX(begin: 0.05),

            const SizedBox(height: 20),

            // Email
            CustomTextField(
              label: 'Email Address',
              hint: 'you@example.com',
              controller: emailCtrl,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              focusNode: emailFocus,
              textInputAction: TextInputAction.next,
              onEditingComplete: () => passwordFocus.requestFocus(),
              validator: Validators.email,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 150.ms)
                .slideX(begin: 0.05),

            const SizedBox(height: 20),

            // Password
            CustomTextField(
              label: 'Password',
              hint: '••••••••',
              controller: passwordCtrl,
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              focusNode: passwordFocus,
              textInputAction: TextInputAction.next,
              onEditingComplete: () => confirmFocus.requestFocus(),
              validator: Validators.password,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .slideX(begin: 0.05),

            const SizedBox(height: 20),

            // Confirm password
            CustomTextField(
              label: 'Confirm Password',
              hint: '••••••••',
              controller: confirmPasswordCtrl,
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              focusNode: confirmFocus,
              textInputAction: TextInputAction.done,
              onEditingComplete: onRegister,
              validator: (v) =>
                  Validators.confirmPassword(v, passwordCtrl.text),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 250.ms)
                .slideX(begin: 0.05),

            const SizedBox(height: 10),

            // Create account button
            GradientButton(
              label: 'Create Account',
              isLoading: auth.isLoading,
              onPressed: auth.isLoading ? null : onRegister,
              gradientColors: const [AppColors.secondary, AppColors.primary],
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 320.ms)
                .slideY(begin: 0.1),

            const SizedBox(height: 20),
            _OrDivider().animate().fadeIn(duration: 400.ms, delay: 340.ms),
            const SizedBox(height: 16),
            _SocialButton(
              label: 'Continue with Google',
              icon: Icons.g_mobiledata_rounded,
              onTap: () {},
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 360.ms)
                .slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORGOT PASSWORD BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet();

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final msg =
          await context.read<AuthProvider>().sendPasswordReset(_emailCtrl.text);
      if (!mounted) return;
      setState(() {
        _sent = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textHint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          if (_sent) ...[
            // ── Success state ───────────────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_outlined,
                  color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Check your inbox',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              "We've sent a password reset link to ${_emailCtrl.text}",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ] else ...[
            // ── Input state ─────────────────────────────────────────────
            const Icon(Icons.lock_reset_rounded,
                size: 40, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Reset Password',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              "Enter your email and we'll send you a link to reset your password.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            Form(
              key: _formKey,
              child: CustomTextField(
                label: 'Email Address',
                hint: 'you@example.com',
                controller: _emailCtrl,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onEditingComplete: _send,
                validator: Validators.email,
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Send Reset Link',
              isLoading: _loading,
              onPressed: _loading ? null : _send,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.textHint.withOpacity(0.5))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: GoogleFonts.dmSans(
              color: AppColors.textHint,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.textHint.withOpacity(0.5))),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final double opacity;

  const _Circle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withOpacity(opacity),
      ),
    );
  }
}
