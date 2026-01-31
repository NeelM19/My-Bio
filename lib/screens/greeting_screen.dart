import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:folyo/services/storage/preferences_service.dart';
import 'package:just_audio/just_audio.dart'; // Import just_audio for PlayerState
import 'package:folyo/screens/bio/bio_screen.dart';
import '../services/analytics/analytics_service.dart';
import '../services/voice_greeting_service.dart';
import '../widgets/auth/custom_button.dart';
import '../theme/app_colors.dart';
import '../widgets/voice_wave_animation.dart';

class GreetingScreen extends StatefulWidget {
  const GreetingScreen({super.key});

  @override
  State<GreetingScreen> createState() => _GreetingScreenState();
}

class _GreetingScreenState extends State<GreetingScreen> {
  final VoiceGreetingService _voiceService = VoiceGreetingService();
  final AnalyticsService _analyticsService = AnalyticsService();
  String _userName = "User";

  @override
  void initState() {
    super.initState();
    _analyticsService.logScreenView('Greeting_Screen');
    _playGreeting();
  }

  Future<void> _playGreeting() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userName = user.displayName ?? "User";
      // If display name is empty (common in email login until profile updated), use "User"
      if (_userName.isEmpty) _userName = "User";
    }

    // Extract first name for a friendlier greeting
    final firstName = _userName.split(' ').first;

    await _voiceService.greetUser(firstName);
  }

  @override
  void dispose() {
    _voiceService.stop();
    super.dispose();
  }

  Future<void> _navigateToHome() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setFirstTimeUser(false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const BioScreen()),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: StreamBuilder<PlayerState>(
              stream: _voiceService.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final processingState = playerState?.processingState;
                final playing = playerState?.playing ?? false;

                // Show animation if buffering or playing (intent to play is true and not completed)
                // Note: when finished, processingState is completed.
                final isPlaying =
                    playing && processingState != ProcessingState.completed;
                final isFinished = processingState == ProcessingState.completed;

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
                    // Show button only if playback finished or not playing (initial state might be idle)
                    // But we want to hide it initially while it loads.
                    // If processingState is null (loading), hide.
                    // If processingState is idle (initial), hide or show? Logic: auto-play starts immediately.
                    // Let's hide until completed.
                    if (isFinished)
                      CustomButton(
                        text: 'START EXPLORING',
                        onPressed: _navigateToHome,
                      )
                    else
                      const SizedBox(
                        height: 56,
                      ), // Placeholder for button height
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
