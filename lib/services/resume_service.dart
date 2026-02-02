import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;

class ResumeService {
  static const MethodChannel _channel = MethodChannel(
    'com.folyo.neelbio/resume',
  );

  Future<String> downloadResume() async {
    if (kIsWeb) {
      // On web, trigger a direct download of the asset
      final anchor =
          html.AnchorElement(href: 'assets/assets/resume/Neel_Modi_Resume.pdf')
            ..target = 'blank'
            ..download = 'Neel_Modi_Resume.pdf';
      anchor.click();
      return 'Resume download started';
    }

    try {
      final String result = await _channel.invokeMethod('downloadResume');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to download resume: ${e.message}');
    }
  }

  Future<void> openDownloads() async {
    if (kIsWeb) return; // Not applicable on web
    try {
      await _channel.invokeMethod('openDownloads');
    } on PlatformException catch (e) {
      throw Exception('Failed to open downloads: ${e.message}');
    }
  }

  Future<void> openResume(String fileNameOrPath) async {
    if (kIsWeb) return; // Not applicable on web
    try {
      await _channel.invokeMethod('openResume', fileNameOrPath);
    } on PlatformException catch (e) {
      throw Exception('Failed to open resume: ${e.message}');
    }
  }
}
