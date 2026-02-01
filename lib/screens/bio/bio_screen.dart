import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/resume_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/futuristic_widgets.dart';
import '../../services/analytics/analytics_service.dart';

import '../../services/auth/auth_service.dart';
import '../../services/storage/preferences_service.dart';
import '../auth/login_screen.dart';

import '../../services/voice_greeting_service.dart';

import '../../data/voice_scripts.dart';

class BioScreen extends StatefulWidget {
  final bool playVoice;
  const BioScreen({super.key, this.playVoice = false});

  @override
  State<BioScreen> createState() => _BioScreenState();
}

class _BioScreenState extends State<BioScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoggingOut = false;
  late bool _shouldPlayVoice; // Local state to control voice playback

  final AnalyticsService _analyticsService = AnalyticsService();
  final AuthService _authService = AuthService();
  final VoiceGreetingService _voiceService = VoiceGreetingService();

  @override
  void initState() {
    super.initState();
    _shouldPlayVoice = widget.playVoice; // Initialize from widget param
    _analyticsService.logScreenView('Bio_Intro');

    // Ensure scripts are loaded just in case we landed here directly
    // or previous screen didn't load them for some reason.
    if (_shouldPlayVoice) {
      // We can safely call this again, it just updates the map
      _voiceService.prefetchAll(VoiceScripts.getAllScripts());
      _playVoiceForPage(0);
    }
  }

  void _playVoiceForPage(int pageIndex) {
    if (!_shouldPlayVoice) return; // Check local state
    // Map page index to bio script key
    // bio_0, bio_1, etc.
    final key = 'bio_$pageIndex';
    _voiceService.play(key);
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    try {
      // Mark as first time user again so they see login/onboarding if applicable
      final prefs = await PreferencesService.getInstance();
      await prefs.setFirstTimeUser(true);

      await _authService.signOut();
      _analyticsService.logEvent('User_Logout');

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      setState(() => _isLoggingOut = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _voiceService.stop(); // Stop voice when leaving
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 800),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050510), Color(0xFF101025), Color(0xFF000000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Navigation/Progress Indicator
                  _buildProgressBar(),

                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        // Voice Logic
                        if (_shouldPlayVoice) {
                          _playVoiceForPage(index);
                        }
                        // Log analytics for page change
                        final pages = [
                          'Bio_Intro',
                          'Bio_About',
                          'Bio_Experience',
                          'Bio_Projects',
                          'Bio_Contact',
                        ];
                        if (index < pages.length) {
                          _analyticsService.logScreenView(pages[index]);
                        }
                      },
                      children: [
                        _buildIntroPage(),
                        _buildAboutPage(),
                        _buildExperiencePage(),
                        _buildProjectsPage(),
                        _buildContactPage(),
                      ],
                    ),
                  ),
                ],
              ),
              // Logout Button Overlay
              Positioned(
                top: 16,
                right: 24,
                child: _isLoggingOut
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.neonCyan,
                          strokeWidth: 2,
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white54),
                        onPressed: _handleLogout,
                        tooltip: 'Logout',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final isActive = index == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 32 : 8,
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? AppColors.neonCyan : Colors.white24,
              borderRadius: BorderRadius.circular(4),
              boxShadow: isActive
                  ? [
                      const BoxShadow(
                        color: AppColors.neonCyan,
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
          );
        }),
      ),
    );
  }

  // Page 1: Introduction
  Widget _buildIntroPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.neonCyan, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonCyan.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                  image: const DecorationImage(
                    image: AssetImage('assets/images/profilePhoto.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              )
              .animate()
              .scale(duration: 800.ms)
              .shimmer(duration: 2000.ms, delay: 1000.ms),
          const SizedBox(height: 40),
          GlowingText(
            "HELLO, I AM",
            fontSize: 14,
            color: AppColors.neonCyan,
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5, end: 0),
          const SizedBox(height: 16),
          GlowingText(
            ResumeData.name.toUpperCase(),
            fontSize: 40,
            isBold: true,
            color: Colors.white,
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5, end: 0),
          const SizedBox(height: 16),
          Text(
            ResumeData.tagline,
            textAlign: TextAlign.center,
            style: GoogleFonts.exo2(
              color: Colors.grey[400],
              fontSize: 18,
              letterSpacing: 1.2,
            ),
          ).animate().fadeIn(delay: 700.ms),
          const SizedBox(height: 60),
          NeonButton(
            text: "Explore Profile",
            onPressed: _nextPage,
            baseColor: AppColors.neonCyan,
          ).animate().fadeIn(delay: 1000.ms).moveY(begin: 20, end: 0),
        ],
      ),
    );
  }

  // Page 2: About & Skills
  Widget _buildAboutPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlowingText("About Me", fontSize: 28, isBold: true),
          const SizedBox(height: 24),
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Text(
              ResumeData.summary,
              style: GoogleFonts.exo2(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ).animate().fadeIn().slideX(begin: -0.1),

          const SizedBox(height: 40),
          const GlowingText("Education", fontSize: 24, isBold: true),
          const SizedBox(height: 16),
          ...ResumeData.education.map(
            (edu) => GlassContainer(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    edu.institution,
                    style: GoogleFonts.orbitron(
                      color: AppColors.neonCyan,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    edu.degree,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        edu.period,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      Text(
                        edu.score,
                        style: const TextStyle(color: AppColors.neonPurple),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          const GlowingText("Skills", fontSize: 24, isBold: true),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: ResumeData.skills
                .map((skill) => SkillChip(label: skill))
                .toList(),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Page 3: Experience
  Widget _buildExperiencePage() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: GlowingText("Experience", fontSize: 28, isBold: true),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: ResumeData.experience.length,
            itemBuilder: (context, index) {
              final exp = ResumeData.experience[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child:
                    GlassContainer(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      exp.role,
                                      style: GoogleFonts.orbitron(
                                        color: AppColors.neonCyan,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.neonPurple.withOpacity(
                                        0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      exp.period
                                          .split(' – ')
                                          .first, // Just start date or simple
                                      style: const TextStyle(
                                        color: AppColors.neonPurple,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${exp.company} | ${exp.location}",
                                style: GoogleFonts.exo2(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                exp.period,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...exp.points.map(
                                (point) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "• ",
                                        style: TextStyle(
                                          color: AppColors.neonCyan,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          point,
                                          style: TextStyle(
                                            color: Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .slideX(begin: 0.2, delay: (100 * index).ms)
                        .fadeIn(),
              );
            },
          ),
        ),
      ],
    );
  }

  // Page 4: Projects
  Widget _buildProjectsPage() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: GlowingText("Key Projects", fontSize: 28, isBold: true),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: ResumeData.projects.length,
            itemBuilder: (context, index) {
              final project = ResumeData.projects[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderColor: AppColors.neonPurple.withOpacity(0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        style: GoogleFonts.orbitron(
                          color: AppColors.neonPurple,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: project.tools
                            .map(
                              (tool) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tool,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      if (project.googlePlay != null ||
                          project.appStore != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (project.googlePlay != null)
                              _buildStoreButton(
                                icon: Icons.android,
                                label: "Play Store",
                                url: project.googlePlay!,
                                color: const Color(0xFF3DDC84),
                                projectName: project.title,
                                storeName: 'Play Store',
                              ),
                            if (project.googlePlay != null &&
                                project.appStore != null)
                              const SizedBox(width: 12),
                            if (project.appStore != null)
                              _buildStoreButton(
                                icon: Icons.apple,
                                label: "App Store",
                                url: project.appStore!,
                                color: Colors.white,
                                projectName: project.title,
                                storeName: 'App Store',
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ).animate().slideY(begin: 0.2, delay: (50 * index).ms).fadeIn(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoreButton({
    required IconData icon,
    required String label,
    required String url,
    required Color color,
    required String projectName,
    required String storeName,
  }) {
    return InkWell(
      onTap: () {
        _analyticsService.logEvent('store_link_clicked', {
          'project_name': projectName,
          'store_platform': storeName,
          'url': url,
        });
        _launchUrl(url);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.exo2(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Page 5: Contact
  Widget _buildContactPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.connect_without_contact,
              size: 80,
              color: AppColors.neonCyan,
            ),
            const SizedBox(height: 24),
            const GlowingText("Get In Touch", fontSize: 32, isBold: true),
            const SizedBox(height: 48),
            _buildContactItem(
              Icons.email,
              ResumeData.email,
              () => _launchUrl("mailto:${ResumeData.email}"),
            ),
            const SizedBox(height: 24),
            _buildContactItem(
              Icons.phone,
              ResumeData.phone,
              () => _launchUrl("tel:${ResumeData.phone}"),
            ),
            const SizedBox(height: 24),
            _buildContactItem(Icons.location_on, ResumeData.location, () {}),
            const SizedBox(height: 24),
            _buildContactItem(
              Icons.link,
              "LinkedIn",
              () => _launchUrl(ResumeData.linkedin),
            ),
            const SizedBox(height: 48),
            NeonButton(
              text: "Restart Tour",
              onPressed: () {
                // User wants to restart navigation but NOT hear the voice again
                // (as per request: "i do not want to play the audio now")
                setState(() {
                  _shouldPlayVoice = false;
                });
                _voiceService.stop(); // Ensure any current audio stops

                _pageController.animateToPage(
                  0,
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInCirc,
                );
              },
              baseColor: AppColors.neonPurple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.neonCyan),
            const SizedBox(width: 16),
            Text(
              text,
              style: GoogleFonts.exo2(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    ).animate().scale(delay: 200.ms);
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch \$url');
    }
  }
}
