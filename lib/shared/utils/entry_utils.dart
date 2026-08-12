// Text helpers for pulling a series title and a chapter apart, and for
// deciding whether two entries are the same novel.
//
// Matching is deliberately loose: sites decorate titles differently from one
// visit to the next, so anything strict would miss real duplicates. The sheet
// confirms with the user before overwriting, which is what makes that safe.

/// Matches a chapter marker and captures its number: "chapter 48", "ch. 47",
/// "Episode 12", "ep 12.5", or a "chapter-1024" / "ch_88" URL slug. Group 2 is
/// the split-release suffix, if there is one: "chapter 4 part 2" gives 4 and 2.
///
/// The trailing guard is `(?![a-z])` rather than `\b` because `_` counts as a
/// word character, so `\b` would refuse to match the underscore slugs some
/// sites use. The leading `\b` still stops "each"/"mech"/"research" matching.
final _chapterMarker = RegExp(
  r'\b(?:chapter|chap|ch|episode|ep)(?![a-z])[\s._-]*(\d+(?:\.\d+)?)'
  r'(?:[\s._-]*(?:part|pt)(?![a-z])[\s._-]*(\d+))?',
  caseSensitive: false,
);

/// The punctuation sites put between a title's parts.
const _separatorChars = r'[\s\-–—_|:,.]';

/// Runs of separators, collapsed when comparing.
final _separators = RegExp('$_separatorChars+');

/// Separators stranded at either end once a marker is excised
/// ("- Reverend Insanity", "Reverend Insanity -").
final _edgeSeparators = RegExp('^$_separatorChars+|$_separatorChars+\$');

final _whitespace = RegExp(r'\s+');

/// Splits a title into the parts sites join together. `:` and `,` are not
/// delimiters — a chapter's name hangs off its number with those ("Chapter 48:
/// The Beginning") and belongs to the chapter, not the series. A bare `-` needs
/// whitespace around it so hyphenated titles ("Re-Zero") stay in one piece.
final _segmentDelimiter = RegExp(r'\s*[|–—»·]\s*|\s+-\s+');

/// A page title pulled apart into the series and the chapter it belongs to.
typedef TitleParts = ({String title, String chapter});

/// Splits [raw] into a series title and a chapter: "Chapter 48 - Reverend
/// Insanity" and "Reverend Insanity - Ch. 48" both give ("Reverend Insanity",
/// "48").
///
/// The marker's whole segment goes, not just the marker text — "Chapter 48: The
/// Beginning" carries a name that would otherwise file every chapter of one
/// novel under a different title, so duplicates would never match. When that
/// leaves nothing ("Read Reverend Insanity Chapter 48 online free") only the
/// marker comes out; a blank title is worse than a redundant chapter in one.
TitleParts splitTitle(String raw) {
  final trimmed = raw.trim();
  final match = _chapterMarker.firstMatch(trimmed);
  if (match == null) return (title: trimmed, chapter: '');

  final part = match.group(2);
  final chapter = part == null
      ? match.group(1)!
      : '${match.group(1)} part $part';

  final kept = trimmed
      .split(_segmentDelimiter)
      .where((s) => s.trim().isNotEmpty && !_chapterMarker.hasMatch(s));
  final title = kept.isEmpty
      ? _trimSeparators(trimmed.replaceAll(_chapterMarker, ' '))
      : kept.join(' - ');

  return title.isEmpty
      ? (title: trimmed, chapter: '')
      : (title: title, chapter: chapter);
}

/// The chapter number in [url]'s path, or an empty string. Used when the page
/// title carries no marker but the slug does: `.../novel/chapter-48`.
String chapterInUrl(String url) =>
    _chapterMarker.firstMatch(url)?.group(1) ?? '';

/// Host of [url] without a `www.` prefix, or null if it has no parseable host.
String? hostOf(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase();
  if (host == null || host.isEmpty) return null;
  return host.startsWith('www.') ? host.substring(4) : host;
}

/// [title] flattened to a key two entries can be compared on: case and
/// separators normalised, any chapter marker dropped.
///
/// [splitTitle] has usually taken the chapter out already; the strip here
/// catches what it can't — rows whose title fell back to the URL, so
/// ".../chapter-48" and ".../chapter-49" still land on the same key.
String titleKey(String title) {
  final lower = title.toLowerCase();
  final stripped = _flatten(lower.replaceAll(_chapterMarker, ' '));
  return stripped.isEmpty ? _flatten(lower) : stripped;
}

String _flatten(String value) => value.replaceAll(_separators, ' ').trim();

/// Tidies up where a marker was excised: strips the separators it stranded at
/// either end, then closes the gap it left inside.
String _trimSeparators(String value) =>
    value.replaceAll(_edgeSeparators, '').replaceAll(_whitespace, ' ');
