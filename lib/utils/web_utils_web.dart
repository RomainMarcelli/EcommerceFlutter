// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class WebUtils {
  static bool isChrome() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    return userAgent.contains('chrome') && !userAgent.contains('edge');
  }

  static void openPlayStore() {
    const url =
        "https://play.google.com/store/apps/details?id=com.snapchat.android"; // 🔗 remplace par ton vrai ID
    html.window.open(url, '_blank');
  }
}
