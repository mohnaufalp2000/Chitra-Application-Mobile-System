import '../styles/color.dart';
import '../styles/text_manager.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactDeveloperWidget extends StatelessWidget {
  const ContactDeveloperWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ElevatedButton(
        onPressed: () async {
          String phoneNumber = "+6281252073489";
          String url = "https://wa.me/$phoneNumber";
          Uri uri = Uri.parse(url);

          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            print('error whatsapp : $e');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: green00968A,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wechat,
              color: Colors.white,
            ),
            const SizedBox(
              width: 12,
            ),
            Text(
              "Contact Developer",
              style: getWhiteTextStyle(),
            ),
          ],
        ),
      ),
    );
  }
}
