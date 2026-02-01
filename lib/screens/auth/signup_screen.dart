import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/custom_button.dart';
import '../../services/auth/auth_service.dart';
import '../../services/storage/preferences_service.dart';
import '../../services/analytics/analytics_service.dart';

import '../../screens/greeting_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final AuthService _authService = AuthService();
  final AnalyticsService _analyticsService = AnalyticsService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _analyticsService.logScreenView('Signup_Screen');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    // Phone validation
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(phone)) {
      _showError('Please enter a valid phone number');
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
        phoneNumber: phone,
        displayName: name,
      );

      _analyticsService.logEvent('User_Signup');

      if (mounted) {
        // Navigate to home screen
        _navigateToHome();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> _navigateToHome() async {
    // Mark as first-time user
    final prefs = await PreferencesService.getInstance();
    await prefs.setFirstTimeUser(true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GreetingScreen()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Logo
                _buildLogo(),
                const SizedBox(height: 30),
                // Title
                const Text(
                  'CREATE ACCOUNT',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 40),
                // Name field
                CustomTextField(
                  hintText: 'Full Name',
                  controller: _nameController,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),
                // Email field
                CustomTextField(
                  hintText: 'Email',
                  controller: _emailController,
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 20),
                // Phone field
                CustomTextField(
                  hintText: 'Phone Number',
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                // Password field
                CustomTextField(
                  hintText: 'Password',
                  isPassword: true,
                  controller: _passwordController,
                  icon: Icons.lock_outline,
                ),
                const SizedBox(height: 20),
                // Confirm Password field
                CustomTextField(
                  hintText: 'Confirm Password',
                  isPassword: true,
                  controller: _confirmPasswordController,
                  icon: Icons.lock_outline,
                ),
                const SizedBox(height: 40),
                // Signup button
                _isLoading
                    ? const SizedBox(
                        height: 56,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gradientStart,
                          ),
                        ),
                      )
                    : CustomButton(text: 'SIGN UP', onPressed: _handleSignup),
                const SizedBox(height: 30),
                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: AppColors.gradientStart,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.logoGradientStart, AppColors.logoGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
