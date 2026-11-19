import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// يفتح الرابط في متصفح الجهاز الافتراضي (Chrome غالبًا).
/// يعيد true عند النجاح.
Future<bool> openExternalUrl(String url) async {
  // رابط تجريبي (وضع العرض الاحتياطي): لا يوجد متصفح لنفتحه
  if (url.startsWith('mock://')) return true;
  try {
    return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (e) {
    if (kDebugMode) debugPrint('openExternalUrl failed: $e');
    return false;
  }
}
