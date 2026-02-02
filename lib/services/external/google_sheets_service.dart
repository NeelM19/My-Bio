import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleSheetsService {
  static const String _envKey = 'GOOGLE_SHEET_API_URL';

  /// Appends user data to Google Sheets via the Apps Script Web App.
  ///
  /// [name]: User's full name
  /// [email]: User's email address
  /// [phone]: User's phone number
  Future<bool> appendUserData({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final String? apiUrl = dotenv.env[_envKey];

      if (apiUrl == null || apiUrl.isEmpty) {
        print('Google Sheets API URL not found in .env');
        return false;
      }

      // Use form data (application/x-www-form-urlencoded) to avoid CORS preflight issues on Web
      final response = await http.post(
        Uri.parse(apiUrl),
        body: <String, String>{'name': name, 'email': email, 'phone': phone},
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        // 302 Redirect is common with Google Apps Script
        print('Successfully sent data to Google Sheets');
        return true;
      } else {
        print(
          'Failed to send data to Google Sheets. Status: ${response.statusCode}',
        );
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending data to Google Sheets: $e');
      return false;
    }
  }
}
