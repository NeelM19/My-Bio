import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/auth/login_screen.dart';
import 'screens/bio/bio_screen.dart';
import 'services/storage/preferences_service.dart';
import 'services/auth/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/greeting_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Handle background message
  print('Handling background message: ${message.messageId}');
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(); // Check if .env is loaded
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Crashlytics: record uncaught Flutter errors
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true); // Disable for debugging if needed

    // Messaging: background handler and request permission / token
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // getToken can hang on web if VAPID key is missing or SW is not ready.
    // We wrap it in a timeout to ensure app startup doesn't block indefinitely.
    String? token;
    try {
      token = await messaging
          .getToken(
            vapidKey:
                "BMk6LKmPsRohBu7IefAY-Co8flUg6adE8xII3euZeIsiJfThr7MtylGxAfZwcK38r3TsyW6-foeRq06S2IjQGwk",
          )
          .timeout(const Duration(seconds: 10));
      print('FCM token: $token');
    } catch (e) {
      print('Warning: Failed to get FCM token: $e');
    }

    // Analytics: log app_open
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    await analytics.logEvent(name: 'main');

    runApp(const MyApp());
  } catch (e, stack) {
    print('Error during initialization: $e');
    print(stack);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FOLYO',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      home: const AuthWrapper(),
    );
  }
}

// Wrapper to check authentication state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _hasSeenIntro =
      true; // Default to true to be safe, but will be checked logic
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await PreferencesService.getInstance();
      final isLoggedIn = prefs.isLoggedIn();
      final user = _authService.currentUser;

      // Check local preferences first (robust fallback)
      bool localHasSeenIntro = !prefs.isFirstTimeUser();

      bool firestoreHasSeenIntro = false;
      if (isLoggedIn && user != null) {
        // Try to get from Firestore (source of truth for cross-device)
        try {
          firestoreHasSeenIntro = await _authService.checkIfUserHasSeenIntro(
            user.uid,
          );
        } catch (e) {
          print('Firestore check failed, relying on local prefs: $e');
        }
      }

      // If either says we've seen it, we've seen it.
      final hasSeenIntro = localHasSeenIntro || firestoreHasSeenIntro;

      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
          _hasSeenIntro = hasSeenIntro;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking login status: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _hasSeenIntro = true; // Fallback
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF5B4FC7)),
        ),
      );
    }

    // Not logged in -> Login Screen
    if (!_isLoggedIn) {
      return const LoginScreen();
    }

    // Logged in + Not seen intro -> Greeting Screen (plays voice)
    // Logged in + Seen intro -> Bio Screen (returning user)
    return !_hasSeenIntro ? const GreetingScreen() : const BioScreen();
  }
}
