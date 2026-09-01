import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:videodownloader/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri.parse('mailto:contact@ignia.cc');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double horizontalPadding = 24.0;
    const double bodyFontSize = 16.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate("contactUs"),
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Image.asset(
            'assets/menuicon/backarrow.png',
            height: 30,
            width: 30,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Address : Ignia LLC, 1021 E Lincolnway Ste 9668, Cheyenne WY 82001-4851, USA.',
                style: TextStyle(fontSize: bodyFontSize, height: 1.45),
              ),
              const SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: bodyFontSize,
                    color: Colors.black,
                    height: 1.45,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Email: ',
                    ),
                    TextSpan(
                      text: 'contact@ignia.cc',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.blue,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _openEmail(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}