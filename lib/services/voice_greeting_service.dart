import 'dart:async';
import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;
// import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

class VoiceGreetingService {
  static final VoiceGreetingService _instance =
      VoiceGreetingService._internal();
  factory VoiceGreetingService() => _instance;

  // final AudioPlayer _player = AudioPlayer();
  // // Rachel voice ID
  // final String _voiceId = "hpp4J3VqNfWAUOO0d1Us";
  // // Model ID for low latency
  // final String _modelId = "eleven_flash_v2_5";

  // // Cache for file paths: key -> filePath
  // final Map<String, String> _audioCache = {};

  final FlutterTts _flutterTts = FlutterTts();
  Map<String, String> _scripts = {};
  final StreamController<bool> _playingStateController =
      StreamController<bool>.broadcast();

  // Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get isPlayingStream => _playingStateController.stream;

  VoiceGreetingService._internal() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _playingStateController.add(true);
      });

      _flutterTts.setCompletionHandler(() {
        _playingStateController.add(false);
      });

      _flutterTts.setCancelHandler(() {
        _playingStateController.add(false);
      });

      _flutterTts.setErrorHandler((msg) {
        _playingStateController.add(false);
        debugPrint("TTS Error: $msg");
      });
    } catch (e) {
      debugPrint("TTS Init Error: $e");
    }
  }

  /// Prefetch all audio files in the background - Refactored to just store scripts
  Future<void> prefetchAll(Map<String, String> scripts) async {
    _scripts = scripts;
    // Old implementation commented out:
    /*
    final directory = await getTemporaryDirectory();
    final apiKey = dotenv.env['ELEVEN_LAB_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('ElevenLabs API Key is missing');
      return;
    }

    for (var entry in scripts.entries) {
      final key = entry.key;
      final text = entry.value;
      final filePath = '${directory.path}/greeting_$key.mp3';
      final file = File(filePath);

      // Check if already cached in memory
      if (_audioCache.containsKey(key)) continue;

      // Check if file exists on disk
      if (await file.exists()) {
        _audioCache[key] = filePath;
        continue;
      }

      // Generate if not found
      try {
        await _generateAndSave(text, filePath, apiKey);
        _audioCache[key] = filePath;
      } catch (e) {
        debugPrint('Error generating audio for $key: $e');
      }
    }
    */
  }

  /// Play audio by key
  Future<void> play(String key) async {
    try {
      final text = _scripts[key];
      if (text == null) {
        debugPrint("No script found for key: $key");
        return;
      }

      await _flutterTts.speak(text);

      // Old implementation:
      /*
      final filePath = _audioCache[key];
      if (filePath == null) {
        debugPrint('Audio not found for key: $key');
        return;
      }

      await _player.setFilePath(filePath);
      await _player.play();
      */
    } catch (e) {
      debugPrint('Error playing audio for $key: $e');
    }
  }

  /// Generate and save audio file
  // Future<void> _generateAndSave(
  //   String text,
  //   String filePath,
  //   String apiKey,
  // ) async {
  //   final url = Uri.parse(
  //     'https://api.elevenlabs.io/v1/text-to-speech/$_voiceId',
  //   );
  //
  //   final response = await http.post(
  //     url,
  //     headers: {'xi-api-key': apiKey, 'Content-Type': 'application/json'},
  //     body: jsonEncode({
  //       "text": text,
  //       "model_id": _modelId,
  //       "voice_settings": {"stability": 0.5, "similarity_boost": 0.75},
  //     }),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     final file = File(filePath);
  //     await file.writeAsBytes(response.bodyBytes);
  //   } else {
  //     throw Exception(
  //       'ElevenLabs API Error: ${response.statusCode} - ${response.body}',
  //     );
  //   }
  // }

  Future<void> stop() async {
    await _flutterTts.stop();
    // await _player.stop();
  }

  Future<void> dispose() async {
    await _flutterTts.stop();
    _playingStateController.close();
    // await _player.dispose();
  }
}
