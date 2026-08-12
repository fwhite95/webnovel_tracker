import 'package:http/http.dart' as http;
import 'package:webnovel_tracker/shared/utils/entry_utils.dart';

/// One-off, client-side fetch of a page's `<title>`, split into the series and
/// the chapter it is on. Offline-first: callers should treat failure as "no
/// title" and fall back to the URL / manual entry.
///
/// There is no markup that states a chapter directly — the number is carried
/// in the title text ("Chapter 48 - Series") or the URL slug, so it comes out
/// of parsing the one response rather than a request of its own.
class TitleFetcher {
  const TitleFetcher();

  static const _timeout = Duration(seconds: 8);
  static const _userAgent = 'Mozilla/5.0 (compatible; WebNovelTracker/1.0)';

  /// Fetches [url] and returns its title split into series and chapter, or
  /// null if the URL is invalid, the request fails or times out, or the page
  /// has no title. `chapter` is empty when neither the title nor the URL says
  /// what chapter this is. All errors are swallowed.
  Future<TitleParts?> fetch(String url) async {
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
      if (title.isEmpty) return null;

      final parts = splitTitle(title);
      // Plenty of sites put the chapter only in the path.
      return parts.chapter.isEmpty
          ? (title: parts.title, chapter: chapterInUrl(url))
          : parts;
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
