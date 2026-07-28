# Web Novel Reading Tracker — Project Summary

> Purpose of this doc: capture the goal of the project and the key decisions
> behind it, so any contributor (human or AI) can get oriented without
> re-deriving the context. Living document — update it when decisions change.
> The code is the source of truth; where this doc and the code disagree, the
> code wins and this doc should be updated.

## Concept

An **offline-first mobile app** (Flutter/Dart, **Android-first**) for tracking
web novels read across many different websites. It solves the problem of reading
bookmarks being scattered across dozens of sites, with mobile browser bookmarks
going unused and forgotten.

The differentiator is **reading-specific tracking** (progress notes, chapter
awareness) — not generic bookmarking.

## Key decisions

- **No browser extension.** Chrome for Android has no extension support and no
  plans to add it. Kiwi Browser (the old Chrome-extensions-on-Android
  workaround) was discontinued and pulled from the Play Store in Jan 2026.
  Firefox for Android supports extensions but is a separate, incompatible
  ecosystem with a small user base. Not a viable path.
- **Android Share Sheet is the real equivalent.** Any browser can Share a URL to
  the app via Android's OS-level share intent — this replaces the "extension"
  idea entirely, with no extension APIs needed.
- **Book-first (narrow), not a general bookmark tool.** We considered
  generalizing into a broader bookmarking tool (compared against Raindrop.io,
  which already does share-sheet capture, tagging, collections, sync, and
  full-text search). Decided against competing there — the features that
  actually differentiate this app (progress tracking, chapter awareness) only
  make sense for reading/novels, and get diluted in a generic tool.
- **Offline-first, no backend.** Explicitly ruled out: update-checking for new
  chapters and automatic chapter-of-total counts, since both require scraping or
  server infrastructure. Everything runs locally, with zero-to-minimal API calls.
- **Sync is deferred, but export/import isn't.** Cross-device sync is out of
  scope until a later phase. Manual JSON export/import (to move data to a new
  device or back it up) was judged cheap enough to include now.
- **Auto progress tracking requires an in-app browser — deferred to Phase 2.**
  There's no way to observe what a user does inside their normal browser between
  shares (Android doesn't expose it; Accessibility Services are invasive/risky
  for Play Store approval; server-side scraping was already ruled out). The only
  real path is making the app's own in-app WebView the reading surface, so it can
  watch URL/navigation changes directly — no scraping needed, since many novel
  sites already encode the chapter number in the URL. This is a bigger scope
  commitment (separate cookie/login session from the user's normal browser; loses
  ad-block/reader-mode/etc. unless rebuilt), so it's explicitly Phase 2, not POC.

## POC scope (build first)

**Includes:**
- Capture a URL via Android Share Sheet, or manual paste fallback.
- Entry fields: URL, title (auto-filled from the page's `<title>` tag via a
  one-off client-side fetch, editable), tags/collection, free-text progress note
  (e.g. "ch. 47"), date added, last-opened timestamp.
- List view — sortable by last opened / date added, filterable by tag.
- Tap an entry → opens in the **external** browser (not in-app), updates
  "last opened".
- Edit / delete an entry.
- JSON export and import (manual backup / device-to-device transfer).

**Excludes (deliberately, for now):**
- In-app WebView / automatic progress tracking.
- Ad-blocking.
- Any live cross-device sync.
- Update-checking or chapter-count scraping.

## Architecture

### Stack

| Concern         | Choice                                          |
| --------------- | ----------------------------------------------- |
| Persistence     | **Drift** (SQLite) via `drift_flutter`          |
| State management | **flutter_bloc**, with `freezed` states/events  |
| Dependency injection | **get_it** service locator                 |
| Models          | **freezed** immutable classes                   |

Supporting packages (`pubspec.yaml`): `receive_sharing_intent` (share intent),
`url_launcher` (open in external browser), `http` + `title_fetcher` (page
`<title>` fetch), `share_plus` + `path_provider` (export), `file_picker`
(import), `uuid` (entry IDs), `intl` (formatting).

### Data model

Single Drift table, `entries` (`lib/data/database/app_database.dart`):

```
id (uuid, PK), url, title, tags (JSON list), progress_note,
date_added, last_opened (nullable)
```

Tags are stored as a JSON-encoded `List<String>` in one text column via a
`TypeConverter` — no relational tag table in the POC.

### Code layout

- `lib/data/database/` — Drift `AppDatabase` + `Entries` table.
- `lib/data/entry_repository.dart` — repository over the database.
- `lib/features/entries/` — home/list + add/edit screens, entry card/text-field
  widgets, and the `EntryListBloc` / `NewEntryBloc` (with freezed
  events/states).
- `lib/features/share_capture/` — the share-intent capture bottom sheet.
- `lib/services/` — `title_fetcher` (page `<title>` fetch), `backup_service`
  (JSON export/import), `share_intent_service` (Android share-intent wiring).
- `lib/core/di.dart` — `get_it` registrations (DB + repo + services as
  singletons; blocs as factories).

### UI — three screens

1. **List** — home screen; entries as cards (title, tags, progress note).
2. **Add/Edit** — shared form for manual add and editing.
3. **Share-intent capture** — a lightweight bottom sheet triggered by an incoming
   shared URL, pre-filled with the URL, asking for title/tags/progress before
   saving.

### Export/import flow

Serialize the entries to a JSON string, write via `path_provider`, share/save via
`share_plus`. Import via `file_picker`, parse JSON, repopulate — likely with a
merge-vs-replace choice.

## Phase 2 (later, once POC is validated)

1. **In-app WebView reader** (`flutter_inappwebview` recommended over
   `webview_flutter` for headroom) — replaces external browser launch, auto-saves
   "last read URL" on navigation change, parses chapter numbers out of URLs
   client-side where possible.
2. **Basic ad-blocking** — via `flutter_inappwebview`'s request-interception hook
   against a bundled domain blocklist (e.g. EasyList). Not full uBlock-level.
3. **Cross-device sync** — no design decided yet; explicitly deferred.

## Status / next steps

- **Scaffolding stage.** The structure, tables, blocs, and DI are wired, but
  several services are still `UnimplementedError` / stub-commented
  (`share_intent_service`, some DB queries labelled "stubs").
- Implement the stubbed share-intent wiring end-to-end.
- Flesh out the add/edit and share-capture screen flows in more detail.
