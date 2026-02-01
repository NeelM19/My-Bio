import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'resume_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          final ResumeService resumeService = ResumeService();
          await resumeService.openResume(response.payload!);
        }
      },
    );
  }

  Future<void> showDownloadSuccessNotification(String filePath) async {
    const BigTextStyleInformation bigTextStyleInformation =
        BigTextStyleInformation(
          'Resume has been saved to your Downloads folder. Tap to open.',
          htmlFormatBigText: true,
          contentTitle: 'Resume Downloaded',
          htmlFormatContentTitle: true,
          summaryText: 'Download Complete',
          htmlFormatSummaryText: true,
        );

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'download_channel_id',
          'Downloads',
          channelDescription: 'Notifications for completed downloads',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          styleInformation: bigTextStyleInformation,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Resume Downloaded',
      'Resume has been saved to your Downloads folder. Tap to open.',
      notificationDetails,
      payload: filePath,
    );
  }
}
