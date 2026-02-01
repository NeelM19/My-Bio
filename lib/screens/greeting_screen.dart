import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:folyo/services/storage/preferences_service.dart';
// import 'package:just_audio/just_audio.dart';
import 'package:folyo/screens/bio/bio_screen.dart';
import '../services/analytics/analytics_service.dart';
import '../services/voice_greeting_service.dart';
import '../widgets/auth/custom_button.dart';
import '../theme/app_colors.dart';
import '../widgets/voice_wave_animation.dart';
import '../data/voice_scripts.dart';
import '../services/auth/auth_service.dart';

class GreetingScreen extends StatefulWidget {
  const GreetingScreen({super.key});

  @override
  State<GreetingScreen> createState() => _GreetingScreenState();
}

class _GreetingScreenState extends State<GreetingScreen> {
  final VoiceGreetingService _voiceService = VoiceGreetingService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final AuthService _authService = AuthService();
  String _userName = "User";

  @override
  void initState() {
    super.initState();
    _analyticsService.logScreenView('Greeting_Screen');
    _loadUserName();
    _initializeVoiceAndPlay();
  }

  void _loadUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? "User";
        if (_userName.isEmpty) _userName = "User";
      });
    }
  }

  Future<void> _initializeVoiceAndPlay() async {
    // 1. Prefetch all scripts with personalized greeting
    // Use the first name for a friendlier greeting
    final firstName = _userName.split(' ').first;
    final scripts = VoiceScripts.getAllScripts(userName: firstName);
    await _voiceService.prefetchAll(scripts);

    // 2. Play greeting
    await _voiceService.play('greeting');
  }

  @override
  void dispose() {
    // _voiceService.stop(); // Don't stop here, let it continue to BioScreen
    super.dispose();
  }

  Future<void> _navigateToBio() async {
    // Mark user as having seen intro in Firestore
    final user = _authService.currentUser;
    if (user != null) {
      await _authService.markUserAsSeenIntro(user.uid);
    }

    // Also update local prefs
    final prefs = await PreferencesService.getInstance();
    await prefs.setFirstTimeUser(false);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const BioScreen(playVoice: true),
        ),
      );
    }
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: StreamBuilder<bool>(
              stream: _voiceService.isPlayingStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;

                // Show animation if buffering or playing (intent to play is true and not completed)
                // final isPlaying =
                //    playing && processingState != ProcessingState.completed;
                // final isFinished = processingState == ProcessingState.completed;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    VoiceWaveAnimation(isPlaying: isPlaying),
                    const SizedBox(height: 40),
                    Text(
                      'Welcome, $_userName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'I\'m your AI assistant, ready to guide you through Folyo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 60),
                    // Show button when finished or at least initialized logic allows
                    if (!isPlaying)
                      CustomButton(
                        text: 'START EXPLORING',
                        onPressed: _navigateToBio,
                      )
                    else
                      const SizedBox(height: 56),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
