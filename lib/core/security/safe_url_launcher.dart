import 'package:url_launcher/url_launcher.dart';
import 'link_validator.dart';

class SafeUrlLauncher {
  static Future<bool> open(String url) async {
    if (!LinkValidator.isSafeUrl(url)) return false;

    final uri = Uri.parse(url);

    if (!await canLaunchUrl(uri)) return false;

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
