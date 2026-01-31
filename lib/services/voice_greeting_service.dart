import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import '../data/resume_data.dart';

class VoiceGreetingService {
  static final VoiceGreetingService _instance =
      VoiceGreetingService._internal();
  factory VoiceGreetingService() => _instance;
  VoiceGreetingService._internal();

  final AudioPlayer _player = AudioPlayer();
  // Rachel voice ID
  final String _voiceId = "hpp4J3VqNfWAUOO0d1Us";
  // Model ID for low latency
  // Model ID for low latency
  final String _modelId = "eleven_flash_v2_5";

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> greetUser(String name) async {
    try {
      final apiKey = dotenv.env['ELEVEN_LAB_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('ElevenLabs API Key is missing in .env');
        return;
      }

      final url = Uri.parse(
        'https://api.elevenlabs.io/v1/text-to-speech/$_voiceId',
      );

      final response = await http.post(
        url,
        headers: {'xi-api-key': apiKey, 'Content-Type': 'application/json'},
        body: jsonEncode({
          "text":
              "Hello $name. Welcome to Folyo. I'm the AI assistant for ${ResumeData.name}, a mobile app developer. Feel free to explore his projects.",
          "model_id": _modelId,
          "voice_settings": {"stability": 0.5, "similarity_boost": 0.75},
        }),
      );

      if (response.statusCode == 200) {
        // Save the audio to a temporary file
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/greeting.mp3';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Play the audio
        await _player.setFilePath(filePath);
        // We handle playing, but maybe we want to await completion or just start it?
        // The requirement says "greet users on login". It implies playing it.
        // We'll play it.
        await _player.play();
      } else {
        debugPrint(
          'ElevenLabs API Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error generating greeting: $e');
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
