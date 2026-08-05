import 'package:http/http.dart' as http;

/// One-off, client-side fetch of a page's `<title>` to pre-fill the title
/// field when adding an entry. Offline-first: callers should treat failure as
/// "no title" and fall back to the URL / manual entry.
class TitleFetcher {
  const TitleFetcher();

  static const _timeout = Duration(seconds: 8);
  static const _userAgent = 'Mozilla/5.0 (compatible; WebNovelTracker/1.0)';

  /// Fetches [url] and returns the trimmed contents of its `<title>` tag, or
  /// null if the URL is invalid, the request fails or times out, or the page
  /// has no title. All errors are swallowed.
  Future<String?> fetchTitle(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.isAbsolute) return null;

    try {
      final response = await http
          .get(uri, headers: const {'User-Agent': _userAgent})
          .timeout(_timeout);
      if (response.statusCode != 200) return null;

      final match = RegExp(
        r'<title[^>]*>(.*?)</title>',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(response.body);

      final raw = match?.group(1);
      if (raw == null) return null;

      final title = _unescapeHtml(_collapseWhitespace(raw));
      return title.isEmpty ? null : title;
    } catch (_) {
      return null;
    }
  }

  String _collapseWhitespace(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Decodes the handful of HTML entities that show up in real page titles.
  String _unescapeHtml(String value) {
    var result = value
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ');

    result = result.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1)!);
      return code == null ? m.group(0)! : String.fromCharCode(code);
    });
    result = result.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
      final code = int.tryParse(m.group(1)!, radix: 16);
      return code == null ? m.group(0)! : String.fromCharCode(code);
    });

    // Decode &amp; last so an already-decoded entity isn't re-processed.
    return result.replaceAll('&amp;', '&');
  }
}
