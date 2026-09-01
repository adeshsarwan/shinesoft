import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:videodownloader/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

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
          AppLocalizations.of(context).translate("about"),
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
                "SnapDock lets you easily save public Instagram Reels, videos, photos, and stories directly to your phone — no login required.\n\n"
                "We made SnapDock because we love great Instagram content but wanted a simple and private way to keep it offline.\n\n"
                "With SnapDock you get no Instagram login ever, no tracking of what you download, very little data collected, fast direct downloads to your gallery, and regular updates so it keeps working.\n\n"
                "We care about your privacy and keeping things simple. Use SnapDock only for public content and for personal use. Please support creators by liking and following them on Instagram.",
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
                      text: "Questions or feedback? Email us at ",
                    ),
                    TextSpan(
                      text: "contact@ignia.cc",
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
              const SizedBox(height: 20),
              const Text(
                "© 2026 SnapDock",
                style: TextStyle(fontSize: bodyFontSize),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}