import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:videodownloader/core/constants/prefs_constants.dart';
import 'package:videodownloader/core/storage/shared_preferences/shared_prefs.dart';
import 'package:videodownloader/screens/home_screen/home_screen.dart';


class InstagramLoginScreen extends StatefulWidget {
  @override
  _InstagramLoginScreenState createState() => _InstagramLoginScreenState();
}

class _InstagramLoginScreenState extends State<InstagramLoginScreen> {
  InAppWebViewController? webController;

  String? sessionId;
  String? csrfToken;
  String? dsUserId;
  String? igDid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login Instagram")),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri("https://www.instagram.com/accounts/login/"),
        ),
        onWebViewCreated: (controller) {
          webController = controller;
        },

        onLoadStop: (controller, url) async {
          if (url == null) return;

          if (url.toString().contains("instagram.com")) {
            final cookies =
            await CookieManager.instance().getCookies(url: url);

            for (var c in cookies) {
              if (c.name == "sessionid") sessionId = c.value;
              if (c.name == "csrftoken") csrfToken = c.value;
              if (c.name == "ds_user_id") dsUserId = c.value;
              if (c.name == "ig_did") igDid = c.value;
            }

            if (sessionId != null) {
              print("🔥 Instagram Login Success");
              print("sessionid: $sessionId");
              print("csrftoken: $csrfToken");
              print("ds_user_id: $dsUserId");
              print("ig_did: $igDid");
              isLoginSuccess();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HomePageScreen()),);
              // Send to backend API
              sendCookiesToBackend();
            }
          }
        },
      ),
    );
  }
  Future<void> isLoginSuccess() async {
    SharedPrefs.saveData(PrefsConstants.isLoggedIn, true);
  }
  Future<void> sendCookiesToBackend() async {
    final body = {
      "sessionid": sessionId,
      "csrftoken": csrfToken,
      "ds_user_id": dsUserId,
      "ig_did": igDid,
    };

    print("📤 Sending cookies to backend:");
    print(body);

    // TODO: call your API here using http.post(...)
  }

}


/*
class InstagramLoginScreen extends StatefulWidget {
  @override
  _InstagramLoginScreenState createState() => _InstagramLoginScreenState();
}

class _InstagramLoginScreenState extends State<InstagramLoginScreen> {
  InAppWebViewController? webController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login Instagram")),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri("https://www.instagram.com/accounts/login/"),
        ),
        onWebViewCreated: (controller) {
          webController = controller;
        },
        onLoadStop: (controller, url) async {
          if (url == null) return;
          // When user logs in, Instagram redirects to main page
          if (url.toString().contains("instagram.com")) {
            final cookies =
            await CookieManager.instance().getCookies(url: url);
            for (var c in cookies) {
              if (c.name == "sessionid") {
                print("🔥 SESSIONID FOUND: ID ==> ${c.name}");
                print(c.value);
                isLoginSuccess();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HomePageScreen()),);
              }
            }
          }
        },
      ),
    );
  }
  Future<void> isLoginSuccess() async {
    SharedPrefs.saveData(PrefsConstants.isLoggedIn, true);
  }
}
*/
