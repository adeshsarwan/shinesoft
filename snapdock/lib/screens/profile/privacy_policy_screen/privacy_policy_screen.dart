import 'package:flutter/material.dart';
import 'package:videodownloader/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget sectionContent(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  Widget bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•  "),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate("privacyPolicy"),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Header
            const Text(
              "SnapDock Privacy Policy",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text("Last updated: February 24, 2026"),

            sectionTitle("Introduction"),
            sectionContent(
                "This Privacy Policy describes our policies and procedures on the collection, use and disclosure of your information when you use the SnapDock mobile application."),
            sectionContent(
                "SnapDock allows users to download publicly available Instagram Reels, videos, photos, and stories for personal offline use."),
            sectionContent(
                "We do not require login, account creation, or Instagram credentials."),

            /// Data Collection
            sectionTitle("What Kinds of Data We Collect"),
            bulletPoint("Usage Data"),
            bulletPoint("Trackers"),
            bulletPoint("Unique device identifiers for advertising (Google Advertiser ID / IDFA)"),
            bulletPoint("Application version and updates"),
            bulletPoint("Payment information (only for premium purchases)"),

            sectionTitle("We Do NOT Collect"),
            bulletPoint("Instagram usernames or passwords"),
            bulletPoint("Download history or specific URLs"),
            bulletPoint("Precise location data"),
            bulletPoint("Contacts, microphone, or camera access"),
            bulletPoint("Private or non-public Instagram content"),

            /// Data Processing
            sectionTitle("Mode and Place of Processing"),
            sectionContent(
                "We take appropriate security measures to prevent unauthorized access or disclosure."),
            sectionContent(
                "Data may be processed in the United States or other countries where our service providers are located."),

            sectionTitle("Legal Basis of Processing"),
            bulletPoint("User consent"),
            bulletPoint("Service performance"),
            bulletPoint("Legal compliance"),
            bulletPoint("Legitimate interests (app improvement, security)"),

            sectionTitle("Retention Time"),
            sectionContent(
                "Data is stored only as long as required for its purpose (typically 12–24 months for analytics)."),

            /// Purpose
            sectionTitle("Purposes of Processing"),
            bulletPoint("Analytics"),
            bulletPoint("Advertising (if applicable)"),
            bulletPoint("Handling payments"),
            bulletPoint("Hosting and infrastructure"),
            bulletPoint("Security and fraud prevention"),

            /// Third Party Services
            sectionTitle("Third-Party Services"),
            bulletPoint("Google Analytics for Firebase"),
            bulletPoint("AdMob"),
            bulletPoint("Google Cloud / Firebase"),
            bulletPoint("Google Play Store (for payments)"),

            sectionTitle("Opt-Out of Interest-Based Ads"),
            sectionContent(
                "You may opt-out via device settings by resetting your advertising ID or limiting ad tracking."),

            /// User Rights
            sectionTitle("Your Rights"),
            bulletPoint("Withdraw consent"),
            bulletPoint("Access your data"),
            bulletPoint("Request correction or deletion"),
            bulletPoint("Restrict processing"),
            bulletPoint("Data portability"),
            bulletPoint("Lodge a complaint"),

            sectionTitle("How to Exercise Your Rights"),
            sectionContent(
                "Contact us at: privacy@snapdock.app. Requests will be addressed within one month where required by law."),

            /// Children
            sectionTitle("Children’s Privacy"),
            sectionContent(
                "SnapDock is not directed to children under 13 and we do not knowingly collect data from children."),

            /// Regional
            sectionTitle("Information for Specific Regions"),
            sectionContent(
                "We comply with applicable laws such as CCPA (California), LGPD (Brazil), and DPDP Act (India)."),

            /// Changes
            sectionTitle("Changes to This Privacy Policy"),
            sectionContent(
                "We may update this Privacy Policy at any time. Users are encouraged to review it periodically."),

            sectionTitle("Owner and Data Controller"),
            sectionContent(
                "SnapDock\nContact: privacy@snapdock.app"),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}