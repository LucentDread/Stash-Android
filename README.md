# Stash Android

Android client for [Stash](https://github.com/stashapp/stash), written in
Flutter. Inspired by [StashAppAndroidTV](https://github.com/damontecres/StashAppAndroidTV),
but designed for phones and tablets (touch screens).

The app talks directly to your Stash server's GraphQL API: no third-party
service, no data sent anywhere else.

## Features

- **Home**: continue watching, recently added scenes, recent releases,
  favorite performers, random picks, recent galleries and library
  statistics.
- **Scenes**: infinite-scroll grid, search, sort (date added, date, title,
  rating, plays, O counter, duration, size, random), video preview on long
  press.
- **Field filters**: performers, tags, studio, groups (at least one / all /
  none of / empty / not empty, with sub-tags, sub-studios and sub-groups),
  minimum rating, minimum resolution, duration, watched or never watched,
  organized, markers, favorite performer.
- **Saved views**: a search + filters + sort of scenes, performers, studios,
  groups, galleries, tags, markers or images can be saved (More > Saved
  views, or the bookmark icon in Scenes) and added to the home page (house
  icon); several views stack there, a single one names the page. Filters
  saved in the Stash web UI are offered too (converted using the server's
  schema; an orange warning flags ignored criteria). The default home stays
  reachable from the button at the top right, and views also show as rows
  on it. A view's filter is only edited from **More > Saved views**
  (create, edit, reorder, delete). Example: "Groups: Empty" shows every
  scene outside a group.
- **Images** (in **More**): every image of the library, with search, sort
  and a full-screen viewer. Views can list images too.
- **Editing**: pencil button on scene, performer, studio, tag, group and
  gallery pages (title, date, rating, studio, performers, tags, groups,
  links, description, images…). Images can come from the phone or a URL; a
  scene's cover can also be taken from the frame being played (player's ⋮
  menu).
- **Markers**: added from the player (button next to the quality, at the
  current position), edited or deleted by long press. Only changed fields
  are sent to Stash; a scene's position in its groups is kept.
- **Scraping** from the edit screen (magnifier button) of scenes,
  performers, groups, galleries and studios: stash-box and scrapers set up
  on the server (depending on what each supports), or a URL. A comparison
  screen picks the values to keep; performers, tags, studios and groups
  missing from Stash can be created there, then linked.
- **Offline**: download a scene, a group (all its scenes), a gallery
  (button on their page) or an image (button in the viewer), in the
  background with a notification. Copies are in **More > Downloads** and
  play without the server. When the server cannot be reached, a window says
  so and leads to the downloads.
- **Library scan** from **More > Server**, with Stash's default scan
  options. Progress (percentage, current file) shows at the bottom of every
  page; at the end, open pages reload without changing the navigation.
- **Studio logo** as a watermark on thumbnails and the scene page, when the
  studio has one.
- **Home page** (**More > Home page**): the custom home stacks views and
  sections of the default home ("Continue watching"…) in the chosen order;
  the rows of the default home can be chosen and ordered too.
- **Tabs** of your choice (**More > Display > Tabs**): up to 4 screens in
  the bottom bar, in the chosen order; the others are in **More**.
- **Groups**: dedicated tab, page with covers and scenes in group order.
- **Scene page**: performers, studio, tags, galleries, markers,
  description, file details, editable rating (stars) and O counter.
- **Video player**: resumes where you stopped (position can be cleared from
  the scene page), double-tap ±10 s, jump to markers (ticks on the progress
  bar), playback speed, stream choice (direct or transcoded HLS/DASH/MP4)
  with automatic fallback to a transcoded stream when the codec is not
  supported. Position and watch time are sent back to Stash. Leaving the
  app during playback keeps the video in a small window (popup player, can
  be turned off).
- **Languages**: English, French, German, Italian and Spanish (vocabulary
  of Stash's own translations). The app follows the phone's language
  (English by default) or the one chosen in the settings.
- **Settings** (**More > Application**): language, popup player, black
  preview in recent apps, password at launch (create, change, remove, delay
  before asking again), updates.
- **Updates**: at startup, the app checks the project's GitHub releases; a
  new version is offered with its changes, downloaded then installed
  (Android asks for confirmation, and the first time for permission to
  install apps).
- **Performers**, **studios**, **tags**, **galleries** (in **More**):
  detailed pages with their scenes, galleries, markers; add/remove
  favorites (performers).
- **Galleries**: image grid and full-screen viewer (swipe, pinch to zoom,
  double-tap).
- **Markers**: list of every marker, played straight at the right moment.

## Installation

### Building the APK

Requirements: [Flutter](https://docs.flutter.dev/get-started/install)
(stable) and the Android SDK (easiest: install Android Studio, then run
`flutter doctor --android-licenses`).

```bash
flutter pub get
flutter run                 # on a connected device
flutter build apk --release --split-per-abi
```

The APKs are in `build/app/outputs/flutter-apk/`; for most recent phones,
install `app-arm64-v8a-release.apk`.

### Signing

Release APKs are signed with the key described by `android/key.properties`
(file and keystore excluded from git):

```properties
storePassword=…
keyPassword=…
keyAlias=stash
storeFile=../stash-release.jks
```

Put `stash-release.jks` and `key.properties` in `android/` before building.
Without them, the APK is signed with the debug key and cannot update an
installed version signed with the release key. **Keep the key somewhere
safe**: if it is lost, the app has to be uninstalled before a new version
can be installed.

## Configuration

1. At first launch, enter your server's address, for example
   `http://192.168.1.10:9999`.
2. If authentication is enabled in Stash, generate an API key in
   **Settings > Security > API Key** and paste it into the app.

Plain HTTP traffic is allowed so a local server can be reached; use HTTPS
(reverse proxy) if your server is exposed on the Internet.

## Code layout

```
lib/
  api/stash_client.dart      GraphQL client (API key auth, media URLs)
  api/stash_repository.dart  Stash queries and mutations
  models/models.dart         Scene, Performer, Studio, Tag, Gallery…
  services/app_state.dart    Server configuration and preferences
  screens/                   Screens (home, lists, pages, player…)
  widgets/                   Cards, paged grid, network images…
  l10n/                      Translations (app_<lang>.arb; the
                             app_localizations*.dart code is generated
                             from them by `flutter gen-l10n`)
test/                        Unit and widget tests
```

## Translations and releases

The app's texts are in `lib/l10n/app_<lang>.arb` (`app_en.arb` is the
reference). After a change, `flutter gen-l10n` (or `flutter pub get`)
regenerates `app_localizations*.dart`.

The changelog (`CHANGELOG.md`) and the GitHub release notes are written in
English; release notes are taken from `CHANGELOG.md` and updated when it
changes.

## License

Independent project, not affiliated with the Stash team.
