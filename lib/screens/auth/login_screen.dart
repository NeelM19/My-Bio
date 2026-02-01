import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/custom_button.dart';
import '../../widgets/auth/social_login_button.dart';
import '../../services/auth/auth_service.dart';

import '../../services/analytics/analytics_service.dart';

import 'signup_screen.dart';
import '../../screens/greeting_screen.dart';
import '../../screens/bio/bio_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _analyticsService.logScreenView('Login_Screen');
  }

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Email/Password login
  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        _navigateToHome();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  // Google Sign In
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      final result = await _authService.signInWithGoogle();

      if (result != null && mounted) {
        _navigateToHome();
      } else {
        setState(() => _isGoogleLoading = false);
      }
    } catch (e) {
      setState(() => _isGoogleLoading = false);
      _showError(e.toString());
    }
  }

  // Apple Sign In
  Future<void> _handleAppleSignIn() async {
    setState(() => _isAppleLoading = true);

    try {
      final result = await _authService.signInWithApple();

      if (result != null && mounted) {
        _navigateToHome();
      } else {
        setState(() => _isAppleLoading = false);
      }
    } catch (e) {
      setState(() => _isAppleLoading = false);
      _showError(e.toString());
    }
  }

  // Forgot Password
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('Please enter your email address');
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(email);

      if (mounted) {
        _showSuccess('Password reset email sent! Check your inbox.');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _navigateToHome() async {
    final user = _authService.currentUser;
    bool hasSeenIntro = false;

    if (user != null) {
      hasSeenIntro = await _authService.checkIfUserHasSeenIntro(user.uid);
    }

    if (!mounted) return;

    if (!hasSeenIntro) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GreetingScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const BioScreen()),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Logo
                  _buildLogo(),
                  const SizedBox(height: 40),
                  // Title
                  const Text(
                    'LOGIN TO FOLYO',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Email field
                  CustomTextField(
                    hintText: 'Email',
                    controller: _emailController,
                  ),
                  const SizedBox(height: 20),
                  // Password field
                  CustomTextField(
                    hintText: 'Password',
                    isPassword: true,
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 24),
                  // Login button
                  _isLoading
                      ? const SizedBox(
                          height: 56,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.gradientStart,
                            ),
                          ),
                        )
                      : CustomButton(
                          text: 'LOG IN',
                          onPressed: _handleEmailLogin,
                        ),
                  const SizedBox(height: 16),
                  // Forgot password & Magic link row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _handleForgotPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // OR divider
                  _buildOrDivider(),
                  const SizedBox(height: 30),
                  // Social login buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isGoogleLoading
                          ? const SizedBox(
                              width: 80,
                              height: 80,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.gradientStart,
                                ),
                              ),
                            )
                          : SocialLoginButton(
                              icon: Icons.g_mobiledata,
                              label: 'Sign in with\nGoogle',
                              onPressed: _handleGoogleSignIn,
                            ),
                      const SizedBox(width: 40),
                      _isAppleLoading
                          ? const SizedBox(
                              width: 80,
                              height: 80,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.gradientStart,
                                ),
                              ),
                            )
                          : SocialLoginButton(
                              icon: Icons.apple,
                              label: 'Sign in with\nApple',
                              onPressed: _handleAppleSignIn,
                            ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SignupScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppColors.gradientStart,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.logoGradientStart, AppColors.logoGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.logoGradientEnd.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'F',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 56,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.inputBorder)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: AppColors.inputBorder)),
      ],
    );
  }
}
