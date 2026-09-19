import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// SMS bhejlan da function
Future<void> sendSMS(String phoneNumber, String message) async {
  final Uri smsUri = Uri(
    scheme: 'sms',
    path: phoneNumber,
    queryParameters: {
      'body': message, // Jo message tuc bhejna chahunde ho
    },
  );

  try {
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      print('SMS app launch nahi ho saki');
    }
  } catch (e) {
    print('Error: $e');
  }
}
