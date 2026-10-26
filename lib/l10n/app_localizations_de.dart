// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get cancel => 'Abbrechen';

  @override
  String get close => 'Schließen';

  @override
  String get download => 'Herunterladen';

  @override
  String get downloads => 'Downloads';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get show => 'Anzeigen';

  @override
  String get hide => 'Verbergen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get ok => 'OK';

  @override
  String get home => 'Startseite';

  @override
  String get more => 'Mehr';

  @override
  String get settings => 'Einstellungen';

  @override
  String get scenes => 'Szenen';

  @override
  String get performers => 'Darsteller';

  @override
  String get studios => 'Studios';

  @override
  String get groups => 'Gruppen';

  @override
  String get galleries => 'Galerien';

  @override
  String get tags => 'Tags';

  @override
  String get markers => 'Markierungen';

  @override
  String get images => 'Bilder';

  @override
  String get studio => 'Studio';

  @override
  String get group => 'Gruppe';

  @override
  String get modeAny => 'Mindestens eins';

  @override
  String get modeAll => 'Alle';

  @override
  String get modeExclude => 'Keins von';

  @override
  String get modeNone => 'Leer';

  @override
  String get modeNotNone => 'Nicht leer';

  @override
  String criterionAny(Object label, Object names) {
    return '$label: $names';
  }

  @override
  String criterionAll(Object label, Object names) {
    return '$label (alle): $names';
  }

  @override
  String criterionExclude(Object label, Object names) {
    return '$label außer: $names';
  }

  @override
  String get withoutPerformer => 'Ohne Darsteller';

  @override
  String get withPerformer => 'Mit Darstellern';

  @override
  String get withoutTag => 'Ohne Tags';

  @override
  String get withTag => 'Mit Tags';

  @override
  String get withoutStudio => 'Ohne Studio';

  @override
  String get withStudio => 'Mit Studio';

  @override
  String get withoutGroup => 'Ohne Gruppe';

  @override
  String get withGroup => 'Mit Gruppe';

  @override
  String minutesRange(Object min, Object max) {
    return '$min–$max Min.';
  }

  @override
  String atLeastMinutes(Object min) {
    return '≥ $min Min.';
  }

  @override
  String atMostMinutes(Object max) {
    return '≤ $max Min.';
  }

  @override
  String organizedState(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scenes': 'Organisiert',
      'other': 'Organisiert',
    });
    return '$_temp0';
  }

  @override
  String notOrganizedState(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scenes': 'Nicht organisiert',
      'other': 'Nicht organisiert',
    });
    return '$_temp0';
  }

  @override
  String playedState(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scenes': 'Gesehen',
      'other': 'Gesehen',
    });
    return '$_temp0';
  }

  @override
  String notPlayedState(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scenes': 'Nie gesehen',
      'other': 'Nie gesehen',
    });
    return '$_temp0';
  }

  @override
  String get withMarkers => 'Mit Markierungen';

  @override
  String get withoutMarkers => 'Ohne Markierungen';

  @override
  String get favoritePerformer => 'Lieblingsdarsteller';

  @override
  String get noFavoritePerformer => 'Ohne Lieblingsdarsteller';

  @override
  String get favorites => 'Favoriten';

  @override
  String get notFavorites => 'Keine Favoriten';

  @override
  String get sectionStats => 'Statistiken';

  @override
  String get sectionResume => 'Weiterschauen';

  @override
  String get sectionRecent => 'Kürzlich hinzugefügt';

  @override
  String get sectionReleases => 'Kürzlich erschienen';

  @override
  String get sectionFavoritePerformers => 'Lieblingsdarsteller';

  @override
  String get sectionRandom => 'Zufällig';

  @override
  String get sectionGalleries => 'Neue Galerien';

  @override
  String sceneNumber(Object id) {
    return 'Szene $id';
  }

  @override
  String galleryNumber(Object id) {
    return 'Galerie $id';
  }

  @override
  String get genderMale => 'Männlich';

  @override
  String get genderFemale => 'Weiblich';

  @override
  String get genderTransMale => 'Trans* männlich';

  @override
  String get genderTransFemale => 'Trans* weiblich';

  @override
  String get genderIntersex => 'Intersexuell';

  @override
  String get genderNonBinary => 'Nicht-binär';

  @override
  String get bytesUnits => 'B,KB,MB,GB,TB';

  @override
  String get sortCreatedAt => 'Hinzugefügt am';

  @override
  String get sortReleaseDate => 'Erscheinungsdatum';

  @override
  String get sortDate => 'Datum';

  @override
  String get sortTitle => 'Titel';

  @override
  String get sortName => 'Name';

  @override
  String get sortRating => 'Wertung';

  @override
  String get sortLastPlayed => 'Zuletzt abgespielt';

  @override
  String get sortPlayCount => 'Anzahl der Wiedergaben';

  @override
  String get sortOCounter => 'O-Zähler';

  @override
  String get sortDuration => 'Dauer';

  @override
  String get sortFileSize => 'Dateigröße';

  @override
  String get sortRandom => 'Zufällig';

  @override
  String get sortSceneCount => 'Szenenanzahl';

  @override
  String get sortImageCount => 'Bilderanzahl';

  @override
  String get sortBirthdate => 'Geburtsdatum';

  @override
  String get sortGroupOrder => 'Reihenfolge in der Gruppe';

  @override
  String get sortPath => 'Pfad';

  @override
  String get sortPosition => 'Position';

  @override
  String get sceneNotFound => 'Szene nicht gefunden';

  @override
  String get performerNotFound => 'Darsteller nicht gefunden';

  @override
  String get studioNotFound => 'Studio nicht gefunden';

  @override
  String get tagNotFound => 'Tag nicht gefunden';

  @override
  String get groupNotFound => 'Gruppe nicht gefunden';

  @override
  String get galleryNotFound => 'Galerie nicht gefunden';

  @override
  String get imageNotFound => 'Bild nicht gefunden';

  @override
  String serverUnreachable(Object error) {
    return 'Server nicht erreichbar: $error';
  }

  @override
  String accessDenied(Object status) {
    return 'Zugriff verweigert (HTTP $status). Prüfen Sie den API-Schlüssel.';
  }

  @override
  String httpError(Object status) {
    return 'HTTP-Fehler $status';
  }

  @override
  String get invalidResponse =>
      'Ungültige Antwort: Der Server scheint kein Stash zu sein.';

  @override
  String get lockAtLaunchOnly => 'Nur beim Start';

  @override
  String get lockImmediately => 'Sobald die App in den Hintergrund geht';

  @override
  String lockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Nach $minutes Minuten im Hintergrund',
      one: 'Nach 1 Minute im Hintergrund',
    );
    return '$_temp0';
  }

  @override
  String get notifDownloading => 'Wird heruntergeladen';

  @override
  String get notifDownloaded => 'Heruntergeladen';

  @override
  String get notifDownloadFailed => 'Download fehlgeschlagen';

  @override
  String get notifPaused => 'Pausiert';

  @override
  String githubError(Object status) {
    return 'GitHub antwortete $status';
  }

  @override
  String downloadRefused(Object status) {
    return 'Download abgelehnt ($status)';
  }

  @override
  String get downloadIncomplete => 'Unvollständiger Download';

  @override
  String get noServerConfigured => 'Kein Server eingerichtet';

  @override
  String get fileUnavailable => 'Datei nicht verfügbar';

  @override
  String imageNumber(Object id) {
    return 'Bild $id';
  }

  @override
  String countItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Elemente',
      one: '$count Element',
    );
    return '$_temp0';
  }

  @override
  String countScenes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Szenen',
      one: '$count Szene',
    );
    return '$_temp0';
  }

  @override
  String countPerformers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Darsteller',
      one: '$count Darsteller',
    );
    return '$_temp0';
  }

  @override
  String countStudios(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Studios',
      one: '$count Studio',
    );
    return '$_temp0';
  }

  @override
  String countGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Gruppen',
      one: '$count Gruppe',
    );
    return '$_temp0';
  }

  @override
  String countGalleries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Galerien',
      one: '$count Galerie',
    );
    return '$_temp0';
  }

  @override
  String countTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tags',
      one: '$count Tag',
    );
    return '$_temp0';
  }

  @override
  String countMarkers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Markierungen',
      one: '$count Markierung',
    );
    return '$_temp0';
  }

  @override
  String countImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bilder',
      one: '$count Bild',
    );
    return '$_temp0';
  }

  @override
  String countPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wiedergaben',
      one: '$count Wiedergabe',
    );
    return '$_temp0';
  }

  @override
  String countO(Object count) {
    return '$count O';
  }

  @override
  String yearsOld(int age) {
    String _temp0 = intl.Intl.pluralLogic(
      age,
      locale: localeName,
      other: '$age Jahre',
      one: '$age Jahr',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Suchen…';

  @override
  String get sort => 'Sortieren';

  @override
  String get descending => 'Absteigend';

  @override
  String get ascending => 'Aufsteigend';

  @override
  String get noResults => 'Keine Ergebnisse';

  @override
  String framesPerSecond(Object fps) {
    return '$fps fps';
  }

  @override
  String addedOn(Object date) {
    return 'Hinzugefügt am $date';
  }

  @override
  String starsOutOfFive(Object stars) {
    return '$stars / 5';
  }

  @override
  String get openScene => 'Szene öffnen';

  @override
  String get editMarker => 'Markierung bearbeiten';

  @override
  String get downloadTitle => 'Herunterladen?';

  @override
  String downloadSceneQuestion(Object size) {
    return 'Diese Szene herunterladen, um sie offline anzusehen$size?';
  }

  @override
  String downloadGroupQuestion(Object size) {
    return 'Alle Szenen dieser Gruppe herunterladen, um sie offline anzusehen$size?';
  }

  @override
  String downloadGalleryQuestion(Object size) {
    return 'Alle Bilder dieser Galerie herunterladen, um sie offline anzusehen$size?';
  }

  @override
  String downloadImageQuestion(Object size) {
    return 'Dieses Bild herunterladen, um es offline anzusehen$size?';
  }

  @override
  String get downloadInBackground =>
      'Der Download läuft im Hintergrund weiter.';

  @override
  String get preparingDownload => 'Download wird vorbereitet…';

  @override
  String get downloadStarted => 'Download gestartet (Mehr > Downloads)';

  @override
  String get downloadInProgress => 'Wird heruntergeladen';

  @override
  String get connectionRestored => 'Verbindung zum Server wiederhergestellt';

  @override
  String get offlineTitle => 'Offline';

  @override
  String offlineMessage(Object url) {
    return 'Der Stash-Server ($url) ist nicht erreichbar. Heruntergeladene Szenen, Gruppen, Galerien und Bilder bleiben verfügbar.';
  }

  @override
  String get scanRunning => 'Bibliothek wird gescannt…';

  @override
  String scanProgress(Object percent) {
    return 'Bibliothek wird gescannt · $percent %';
  }

  @override
  String get scanFailed => 'Scan fehlgeschlagen';

  @override
  String get scanStopped => 'Scan gestoppt · Daten aktualisiert';

  @override
  String get scanFinished => 'Scan abgeschlossen · Daten aktualisiert';

  @override
  String get stopScan => 'Scan stoppen';

  @override
  String get lockedTitle => 'Stash ist gesperrt';

  @override
  String get password => 'Passwort';

  @override
  String get wrongPassword => 'Falsches Passwort';

  @override
  String get unlock => 'Entsperren';

  @override
  String get clearRating => 'Wertung entfernen';

  @override
  String get notRated => 'Nicht bewertet';

  @override
  String get select => 'Auswählen';

  @override
  String get selectAll => 'Alle';

  @override
  String get selectNone => 'Keine';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String downloadSelectionQuestion(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Die $count ausgewählten Elemente herunterladen, um sie offline anzusehen?',
      one: 'Das ausgewählte Element herunterladen, um es offline anzusehen?',
    );
    return '$_temp0';
  }

  @override
  String get info => 'Infos';

  @override
  String get information => 'Informationen';

  @override
  String get parentStudio => 'Übergeordnetes Studio';

  @override
  String get description => 'Beschreibung';

  @override
  String get links => 'Links';

  @override
  String get favorite => 'Favorit';

  @override
  String get disambiguation => 'Begriffsklärung';

  @override
  String get aliases => 'Aliase';

  @override
  String get gender => 'Geschlecht';

  @override
  String get birth => 'Geburt';

  @override
  String get country => 'Land';

  @override
  String get ethnicity => 'Ethnizität';

  @override
  String get height => 'Größe';

  @override
  String get measurements => 'Maße';

  @override
  String get hairColor => 'Haare';

  @override
  String get eyeColor => 'Augen';

  @override
  String get date => 'Datum';

  @override
  String get duration => 'Dauer';

  @override
  String get director => 'Regisseur';

  @override
  String get synopsis => 'Zusammenfassung';

  @override
  String get path => 'Pfad';

  @override
  String get emptyGallery => 'Leere Galerie';

  @override
  String get enterServerAddress => 'Geben Sie die Serveradresse ein.';

  @override
  String connectedTo(Object version) {
    return 'Mit Stash $version verbunden';
  }

  @override
  String get stashServer => 'Stash-Server';

  @override
  String get connectPrompt => 'Verbinden Sie sich mit Ihrem Stash-Server';

  @override
  String get serverAddress => 'Serveradresse';

  @override
  String get apiKeyOptional => 'API-Schlüssel (optional)';

  @override
  String get apiKeyHelp =>
      'Stash > Einstellungen > Sicherheit > API-Schlüssel. Nötig, wenn die Anmeldung aktiviert ist.';

  @override
  String get connect => 'Verbinden';

  @override
  String get scanLibraryQuestion => 'Bibliothek scannen?';

  @override
  String get scanConfirmMessage =>
      'Stash durchsucht Ihre Ordner mit seinen Standard-Scanoptionen (Einstellungen > Aufgaben). Der Fortschritt erscheint unten am Bildschirm; danach werden die Seiten neu geladen.';

  @override
  String get scan => 'Scannen';

  @override
  String get homePage => 'Startseite';

  @override
  String get defaultHome => 'Standard-Startseite';

  @override
  String customHomeItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eigene: $count Elemente',
      one: 'Eigene: $count Element',
    );
    return '$_temp0';
  }

  @override
  String get savedViews => 'Gespeicherte Ansichten';

  @override
  String get noViews => 'Keine';

  @override
  String countViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ansichten',
      one: '$count Ansicht',
    );
    return '$_temp0';
  }

  @override
  String get downloadsSubtitle =>
      'Szenen, Gruppen, Galerien und Bilder offline';

  @override
  String get displayHeader => 'Anzeige';

  @override
  String get serverHeader => 'Server';

  @override
  String get applicationHeader => 'App';

  @override
  String get tabsTitle => 'Tabs';

  @override
  String get sceneColumns => 'Szenenspalten (Hochformat)';

  @override
  String get longPressPreview => 'Videovorschau bei langem Drücken';

  @override
  String get longPressPreviewSubtitle =>
      'Spielt die Vorschau einer Szene ab, solange Sie sie gedrückt halten';

  @override
  String get serverVersion => 'Serverversion';

  @override
  String get scanLibrary => 'Bibliothek scannen';

  @override
  String get scanInProgressSubtitle => 'Scan läuft (unten am Bildschirm)';

  @override
  String get scanSubtitle =>
      'Findet hinzugefügte, geänderte oder gelöschte Dateien';

  @override
  String get logout => 'Abmelden';

  @override
  String get logoutQuestion => 'Abmelden?';

  @override
  String get logoutMessage =>
      'Serveradresse und API-Schlüssel werden vergessen.';

  @override
  String get appVersion => 'App-Version';

  @override
  String get settingsSubtitle => 'Sprache, Popup-Player, Passwort, Updates';

  @override
  String get language => 'Sprache';

  @override
  String get appLanguage => 'App-Sprache';

  @override
  String systemLanguage(Object name) {
    return 'Systemsprache ($name)';
  }

  @override
  String get playbackHeader => 'Wiedergabe';

  @override
  String get popupPlayer => 'Popup-Player';

  @override
  String get popupPlayerSubtitle =>
      'Das laufende Video wird in einem kleinen Fenster fortgesetzt, wenn Sie die App verlassen';

  @override
  String get privacyHeader => 'Datenschutz';

  @override
  String get hideInRecents => 'In den letzten Apps ausblenden';

  @override
  String get hideInRecentsSubtitle =>
      'Schwarze Vorschau im App-Umschalter (blockiert auch Screenshots)';

  @override
  String get createPassword => 'Passwort erstellen';

  @override
  String get createPasswordSubtitle => 'Wird beim Öffnen der App abgefragt';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get removePassword => 'Passwort entfernen';

  @override
  String get askPasswordAgain => 'Passwort erneut abfragen';

  @override
  String get passwordRemoved => 'Passwort entfernt';

  @override
  String get passwordCreated => 'Passwort erstellt';

  @override
  String get passwordChanged => 'Passwort geändert';

  @override
  String get updatesHeader => 'Updates';

  @override
  String get checkAtStartup => 'Beim Start prüfen';

  @override
  String get checkAtStartupSubtitle =>
      'Bietet neue, auf GitHub veröffentlichte Versionen an';

  @override
  String get checkForUpdate => 'Nach Updates suchen';

  @override
  String get passwordTooShort => 'Mindestens 4 Zeichen';

  @override
  String get passwordsDiffer => 'Die Passwörter stimmen nicht überein';

  @override
  String get create => 'Erstellen';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get confirmation => 'Bestätigung';

  @override
  String get forgottenPasswordHint =>
      'Wenn Sie es vergessen, müssen Sie die App-Daten löschen (und sie neu einrichten).';

  @override
  String updateCheckFailed(Object error) {
    return 'Prüfung nicht möglich: $error';
  }

  @override
  String get upToDate => 'Die App ist aktuell';

  @override
  String installFailed(Object error) {
    return 'Installation nicht möglich: $error';
  }

  @override
  String versionAvailable(Object version) {
    return 'Version $version verfügbar';
  }

  @override
  String whatsNewIn(Object version) {
    return 'Neu in $version';
  }

  @override
  String get later => 'Später';

  @override
  String get install => 'Installieren';

  @override
  String installWithSize(Object size) {
    return 'Installieren ($size)';
  }

  @override
  String downloadingVersion(Object version) {
    return '$version wird heruntergeladen';
  }

  @override
  String failedWith(Object error) {
    return 'Fehlgeschlagen: $error';
  }

  @override
  String get installHint =>
      'Android fragt dann nach einer Bestätigung der Installation (und beim ersten Mal nach der Erlaubnis, dass Stash Apps installieren darf).';

  @override
  String get criterionFolder => 'Ordner';

  @override
  String get criterionCustomFields => 'benutzerdefinierte Felder';

  @override
  String deleteNamedQuestion(Object name) {
    return '„$name“ löschen?';
  }

  @override
  String webFilterOf(Object kind) {
    return 'Stash-Filter (Web) · $kind';
  }

  @override
  String get noFilter => 'ohne Filter';

  @override
  String get viewsIntro =>
      'Erstellen Sie eine Ansicht (Szenen, Darsteller, Studios…) mit der Schaltfläche „Neue Ansicht“ oder im Tab Szenen (Lesezeichen-Symbol). In der Stash-Weboberfläche gespeicherte Filter erscheinen ebenfalls (Wolken-Symbol); sie werden im Web bearbeitet.';

  @override
  String unsupportedWebFilters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Webfilter eines der App unbekannten Typs werden nicht übernommen',
      one:
          '$count Webfilter eines der App unbekannten Typs wird nicht übernommen',
    );
    return '$_temp0';
  }

  @override
  String skippedCriteriaWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Webfilter nutzen Kriterien, die die App nicht übernehmen kann (unter jedem Filter aufgeführt). Sie werden ignoriert: Die Ansicht zeigt mehr Elemente als im Web.',
      one: 'Ein Webfilter nutzt Kriterien, die die App nicht übernehmen kann (unter dem Filter aufgeführt). Sie werden ignoriert: Die Ansicht zeigt mehr Elemente als im Web.',
    );
    return '$_temp0';
  }

  @override
  String get composeHomePages => 'Startseiten zusammenstellen';

  @override
  String get homeIsDefault => 'Startseite: Standard';

  @override
  String homeItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Startseite: $count Elemente',
      one: 'Startseite: $count Element',
    );
    return '$_temp0';
  }

  @override
  String get noSavedViews => 'Keine gespeicherten Ansichten';

  @override
  String get homeIconHint =>
      'Das Haus-Symbol fügt eine Ansicht am Ende der Startseite hinzu oder entfernt sie. Reihenfolge, Abschnitte und Standard-Startseite werden unter „Startseiten zusammenstellen“ festgelegt.';

  @override
  String get removeFromHome => 'Von der Startseite entfernen';

  @override
  String get addToHome => 'Zur Startseite hinzufügen';

  @override
  String ignored(Object criteria) {
    return 'Ignoriert: $criteria';
  }

  @override
  String get reloadWebFilters => 'Stash-Filter neu laden';

  @override
  String get newView => 'Neue Ansicht';

  @override
  String get webFiltersUnavailable => 'Stash-Filter nicht verfügbar';

  @override
  String get nameTheView => 'Geben Sie der Ansicht einen Namen';

  @override
  String get editView => 'Ansicht bearbeiten';

  @override
  String get content => 'Inhalt';

  @override
  String get nameRequired => 'Name *';

  @override
  String get searchOptional => 'Suche (optional)';

  @override
  String get sortField => 'Sortierung';

  @override
  String get filter => 'Filter';

  @override
  String noFilterAll(Object kind) {
    return 'Ohne Filter (alle $kind)';
  }

  @override
  String get editFilter => 'Filter bearbeiten';

  @override
  String tabsIntro(Object max) {
    return 'Wählen Sie bis zu $max Bildschirme für die untere Leiste („Mehr“ bleibt immer dort, als Letztes). Die anderen sind unter Mehr. Ziehen Sie, um die Reihenfolge zu ändern; der erste Tab öffnet sich beim Start.';
  }

  @override
  String tabsCount(Object count, Object max) {
    return '$count / $max Tabs';
  }

  @override
  String get tab => 'Tab';

  @override
  String get inMore => 'Unter Mehr';

  @override
  String get byDefault => 'Standard';

  @override
  String get homeLayoutIntro =>
      'Auf der Startseite gestapelte Elemente, in dieser Reihenfolge. Ist nichts ausgewählt, wird die Standard-Startseite verwendet; eine einzelne Ansicht füllt die Seite und gibt ihr ihren Namen.';

  @override
  String get dashboardLayoutIntro =>
      'Zeilen der Standard-Startseite (über die Schaltfläche oben rechts einer eigenen Startseite), in dieser Reihenfolge.';

  @override
  String get defaultRows => 'Standardzeilen';

  @override
  String get homeSection => 'Startseiten-Abschnitt';

  @override
  String viewOf(Object kind) {
    return 'Ansicht · $kind';
  }

  @override
  String errorWith(Object error) {
    return 'Fehler: $error';
  }

  @override
  String get nothingYet => 'Noch nichts';

  @override
  String showMore(Object count) {
    return 'Mehr anzeigen ($count)';
  }

  @override
  String serverUnreachableShort(Object error) {
    return 'Server nicht erreichbar: $error';
  }

  @override
  String countHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stunden',
      one: '$count Stunde',
    );
    return '$_temp0';
  }

  @override
  String get seeAll => 'Alle anzeigen';

  @override
  String viewSaved(Object name) {
    return 'Ansicht „$name“ gespeichert';
  }

  @override
  String get showOnHome => 'Auf der Startseite anzeigen';

  @override
  String get clear => 'Leeren';

  @override
  String get filters => 'Filter';

  @override
  String get saveAsNewView => 'Als neue Ansicht speichern';

  @override
  String get saveView => 'Ansicht speichern';

  @override
  String get noMarkers => 'Keine Markierungen';

  @override
  String get noImages => 'Keine Bilder';

  @override
  String get noDownloads =>
      'Keine Downloads.\n\nNutzen Sie die Download-Schaltfläche einer Szene, einer Gruppe, einer Galerie oder eines Bildes (im Betrachter), um es auf dem Telefon zu behalten.';

  @override
  String deleteFromPhoneQuestion(Object title) {
    return '„$title“ vom Telefon löschen?';
  }

  @override
  String get groupScenesDeletedToo =>
      'Die Szenen dieser Gruppe werden ebenfalls gelöscht.';

  @override
  String get downloadFailedRetry =>
      'Fehlgeschlagen: ⋮ antippen zum Wiederholen';

  @override
  String get downloadQueued => 'Wartend';

  @override
  String get downloadRunning => 'Wird heruntergeladen…';

  @override
  String downloadProgress(Object percent) {
    return 'Download · $percent %';
  }

  @override
  String resumeAt(Object time) {
    return 'Fortsetzen bei $time';
  }

  @override
  String get play => 'Abspielen';

  @override
  String get fromStart => 'Von vorn';

  @override
  String get forgetResumePosition => 'Fortsetzungsposition vergessen';

  @override
  String get resumePositionCleared => 'Fortsetzungsposition gelöscht';

  @override
  String get code => 'Code';

  @override
  String get file => 'Datei';

  @override
  String get fileSize => 'Größe';

  @override
  String get dimensions => 'Abmessungen';

  @override
  String get format => 'Format';

  @override
  String get video => 'Video';

  @override
  String get audio => 'Audio';

  @override
  String get framesPerSecondLabel => 'Bilder/s';

  @override
  String get bitRate => 'Bitrate';

  @override
  String megabitsPerSecond(Object value) {
    return '$value Mbit/s';
  }

  @override
  String get offlineCopy => 'Offline-Kopie';

  @override
  String get noStream => 'Kein Stream verfügbar';

  @override
  String get directStream => 'Direkt (Original)';

  @override
  String directPlaybackFailed(Object source) {
    return 'Direkte Wiedergabe nicht möglich, versuche „$source“';
  }

  @override
  String playbackFailed(Object error) {
    return 'Wiedergabe nicht möglich: $error';
  }

  @override
  String get playbackError => 'Wiedergabefehler';

  @override
  String get coverGenerating => 'Stash erzeugt das Titelbild';

  @override
  String get playbackSpeed => 'Wiedergabegeschwindigkeit';

  @override
  String get useFrameAsCover => 'Dieses Bild als Titelbild verwenden';

  @override
  String get addMarkerHere => 'Hier eine Markierung hinzufügen';

  @override
  String get streams => 'Streams';

  @override
  String get pause => 'Pause';

  @override
  String get soundOn => 'Ton einschalten';

  @override
  String get soundOff => 'Ton ausschalten';

  @override
  String get back10 => '10 s zurück';

  @override
  String get forward10 => '10 s vor';

  @override
  String filterKind(Object kind) {
    return 'Filtern: $kind';
  }

  @override
  String get allRatings => 'Alle';

  @override
  String get allResolutions => 'Alle';

  @override
  String get withLabel => 'Mit';

  @override
  String get withoutLabel => 'Ohne';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get anyValue => 'Alle';

  @override
  String confirmCount(Object count) {
    return 'Übernehmen ($count)';
  }

  @override
  String get clearAll => 'Alles löschen';

  @override
  String get includeSubTags => 'Untergeordnete Tags einschließen';

  @override
  String get includeSubStudios => 'Untergeordnete Studios einschließen';

  @override
  String get includeSubGroups => 'Untergeordnete Gruppen einschließen';

  @override
  String get minRating => 'Mindestwertung';

  @override
  String get minResolution => 'Mindestauflösung';

  @override
  String get durationMinutes => 'Dauer (Minuten)';

  @override
  String get min => 'Min.';

  @override
  String get max => 'Max.';

  @override
  String get apply => 'Übernehmen';

  @override
  String get choose => 'Auswählen';

  @override
  String get watchStatus => 'Angesehen';

  @override
  String get cover => 'Titelbild';

  @override
  String get organized => 'Organisiert';

  @override
  String get scrape => 'Scrapen';

  @override
  String get editScene => 'Szene bearbeiten';

  @override
  String get photo => 'Foto';

  @override
  String get deathDate => 'Sterbedatum';

  @override
  String get weight => 'Gewicht';

  @override
  String get fakeTits => 'Brustvergrößerung';

  @override
  String get tattoos => 'Tätowierungen';

  @override
  String get piercings => 'Piercings';

  @override
  String get editPerformer => 'Darsteller bearbeiten';

  @override
  String get logo => 'Logo';

  @override
  String get editStudio => 'Studio bearbeiten';

  @override
  String get image => 'Bild';

  @override
  String get parentTags => 'Übergeordnete Tags';

  @override
  String get editTag => 'Tag bearbeiten';

  @override
  String get frontCover => 'Cover (vorne)';

  @override
  String get backCover => 'Cover (hinten)';

  @override
  String get editGroup => 'Gruppe bearbeiten';

  @override
  String get photographer => 'Fotograf';

  @override
  String get editGallery => 'Galerie bearbeiten';

  @override
  String get start => 'Anfang';

  @override
  String get endOptional => 'Ende (optional)';

  @override
  String get primaryTag => 'Haupt-Tag';

  @override
  String get otherTags => 'Weitere Tags';

  @override
  String get deleteMarker => 'Markierung löschen';

  @override
  String get newMarker => 'Neue Markierung';

  @override
  String fieldRequired(Object label) {
    return '$label ist erforderlich';
  }

  @override
  String get dateHint => 'JJJJ-MM-TT';

  @override
  String dateFormatExpected(Object label, Object format) {
    return '$label: Format $format erwartet';
  }

  @override
  String integerExpected(Object label) {
    return '$label: ganze Zahl erwartet';
  }

  @override
  String timeFormatExpected(Object label) {
    return '$label: Format m:ss erwartet';
  }

  @override
  String get change => 'Ändern';

  @override
  String get add => 'Hinzufügen';

  @override
  String get addHint => 'Hinzufügen…';

  @override
  String questionOf(Object action) {
    return '$action?';
  }

  @override
  String get saved => 'Gespeichert';

  @override
  String get deleted => 'Gelöscht';

  @override
  String get use => 'Verwenden';

  @override
  String get fromPhone => 'Vom Telefon';

  @override
  String get fromUrl => 'Von einer URL';

  @override
  String get cannotBeUndone => 'Dies kann nicht rückgängig gemacht werden.';

  @override
  String get discardChangesQuestion => 'Änderungen verwerfen?';

  @override
  String get continueEditing => 'Weiter bearbeiten';

  @override
  String get discard => 'Verwerfen';

  @override
  String get newGroup => 'Neue Gruppe';

  @override
  String get newGallery => 'Neue Galerie';

  @override
  String get newPerformer => 'Neuer Darsteller';

  @override
  String get newStudio => 'Neues Studio';

  @override
  String get newTag => 'Neuer Tag';

  @override
  String get deletePerformer => 'Darsteller löschen';

  @override
  String get deleteStudio => 'Studio löschen';

  @override
  String get deleteTag => 'Tag löschen';

  @override
  String get deleteGroup => 'Gruppe löschen';

  @override
  String get deleteGallery => 'Galerie löschen';

  @override
  String createNamed(Object name) {
    return '„$name“ erstellen';
  }

  @override
  String createdNamed(Object name) {
    return '„$name“ in Stash erstellt';
  }

  @override
  String get untitled => 'Ohne Titel';

  @override
  String get newImage => 'Neues Bild';

  @override
  String get nothingNewInResult => 'Nichts Neues in diesem Ergebnis';

  @override
  String searchOn(Object source) {
    return 'Auf $source suchen';
  }

  @override
  String get titleCodeHint => 'Titel, Code…';

  @override
  String get scrapeWith => 'Scrapen mit…';

  @override
  String get byFingerprintThenSearch => 'Per Fingerabdruck, sonst per Suche';

  @override
  String get bySearch => 'Per Suche';

  @override
  String get byScene => 'per Szene';

  @override
  String get bySearchLower => 'per Suche';

  @override
  String get scrapersHeader => 'Scraper';

  @override
  String get noScraperConfigured =>
      'Auf dem Server ist für diesen Typ weder ein Scraper noch eine Stash-Box eingerichtet (Einstellungen > Metadaten).';

  @override
  String countResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ergebnisse',
      one: '$count Ergebnis',
    );
    return '$_temp0';
  }

  @override
  String createdInStash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Elemente in Stash erstellt',
      one: '$count Element in Stash erstellt',
    );
    return '$_temp0';
  }

  @override
  String get scrapeResultIntro =>
      'Wählen Sie die zu übernehmenden Werte. Sie füllen das Bearbeitungsformular und werden erst mit „Speichern“ gespeichert (außer den unten zu erstellenden Elementen).';

  @override
  String currentValue(Object value) {
    return 'Aktuell: $value';
  }

  @override
  String get missingFromStash => 'Fehlen in Stash';

  @override
  String get missingFromStashHint =>
      'Ausgewählte Elemente werden bei „Übernehmen“ in Stash erstellt (mit den Infos des Scrapers) und dann verknüpft.';

  @override
  String createAndLink(Object label) {
    return 'Erstellen und verknüpfen · $label';
  }

  @override
  String get search => 'Suchen';

  @override
  String get scrapeUrl => 'URL scrapen';

  @override
  String get otherUrl => 'Andere URL…';

  @override
  String get scrapeResult => 'Scraping-Ergebnis';
}
