import 'package:flutter/services.dart';

class ResumeService {
  static const MethodChannel _channel = MethodChannel(
    'com.folyo.neelbio/resume',
  );

  Future<String> downloadResume() async {
    try {
      final String result = await _channel.invokeMethod('downloadResume');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to download resume: ${e.message}');
    }
  }

  Future<void> openDownloads() async {
    try {
      await _channel.invokeMethod('openDownloads');
    } on PlatformException catch (e) {
      throw Exception('Failed to open downloads: ${e.message}');
    }
  }

  Future<void> openResume(String fileNameOrPath) async {
    try {
      await _channel.invokeMethod('openResume', fileNameOrPath);
    } on PlatformException catch (e) {
      throw Exception('Failed to open resume: ${e.message}');
    }
  }
}
