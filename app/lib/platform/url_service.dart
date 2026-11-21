import 'package:url_launcher/url_launcher.dart';

/// Opens a link outside the app. Returns whether something handled it.
typedef UrlLauncher = Future<bool> Function(Uri uri);

Future<bool> _launchExternal(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

/// Mail to support and links to licence pages. Only https and mailto open.
class UrlService {
  UrlService({required this.supportEmail, UrlLauncher? launcher}) : _launcher = launcher ?? _launchExternal;

  final String supportEmail;
  final UrlLauncher _launcher;

  /// The mailto address for a support message. The query is encoded by hand
  /// because mail apps read a plus sign literally.
  Uri mailUri({String subject = '', String body = ''}) {
    final List<String> parts = <String>[
      if (subject.isNotEmpty) 'subject=${Uri.encodeComponent(subject)}',
      if (body.isNotEmpty) 'body=${Uri.encodeComponent(body)}',
    ];
    return Uri.parse('mailto:$supportEmail${parts.isEmpty ? '' : '?${parts.join('&')}'}');
  }

  Future<bool> openMail({String subject = '', String body = ''}) => _safe(mailUri(subject: subject, body: body));

  Future<bool> openLink(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return false;
    }
    return _safe(uri);
  }

  Future<bool> _safe(Uri uri) async {
    try {
      return await _launcher(uri);
    } on Object {
      return false;
    }
  }
}
