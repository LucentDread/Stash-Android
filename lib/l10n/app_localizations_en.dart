// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get download => 'Download';

  @override
  String get downloads => 'Downloads';

  @override
  String get retry => 'Retry';

  @override
  String get show => 'Show';

  @override
  String get hide => 'Hide';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get ok => 'OK';

  @override
  String get home => 'Home';

  @override
  String get more => 'More';

  @override
  String get settings => 'Settings';

  @override
  String get scenes => 'Scenes';

  @override
  String get performers => 'Performers';

  @override
  String get studios => 'Studios';

  @override
  String get groups => 'Groups';

  @override
  String get galleries => 'Galleries';

  @override
  String get tags => 'Tags';

  @override
  String get markers => 'Markers';

  @override
  String get images => 'Images';

  @override
  String get studio => 'Studio';

  @override
  String get group => 'Group';

  @override
  String get modeAny => 'At least one';

  @override
  String get modeAll => 'All';

  @override
  String get modeExclude => 'None of';

  @override
  String get modeNone => 'Empty';

  @override
  String get modeNotNone => 'Not empty';

  @override
  String criterionAny(Object label, Object names) {
    return '$label: $names';
  }

  @override
  String criterionAll(Object label, Object names) {
    return '$label (all): $names';
  }

  @override
  String criterionExclude(Object label, Object names) {
    return '$label except: $names';
  }

  @override
  String get withoutPerformer => 'No performer';

  @override
  String get withPerformer => 'With performers';

  @override
  String get withoutTag => 'No tag';

  @override
  String get withTag => 'With tags';

  @override
  String get withoutStudio => 'No studio';

  @override
  String get withStudio => 'With a studio';

  @override
  String get withoutGroup => 'No group';

  @override
  String get withGroup => 'In a group';

  @override
  String minutesRange(Object min, Object max) {
    return '$min–$max min';
  }

  @override
  String atLeastMinutes(Object min) {
    return '≥ $min min';
  }

  @override
  String atMostMinutes(Object max) {
    return '≤ $max min';
  }

  @override
  String organizedState(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scenes': 'Organized',
      'other': 'Organized',
    });
    return '$_temp0';
  }

  @override
  String notOrganizedState(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scenes': 'Not organized',
      'other': 'Not organized',
    });
    return '$_temp0';
  }

  @override
  String playedState(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scenes': 'Watched',
      'other': 'Watched',
    });
    return '$_temp0';
  }

  @override
  String notPlayedState(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scenes': 'Never watched',
      'other': 'Never watched',
    });
    return '$_temp0';
  }

  @override
  String get withMarkers => 'With markers';

  @override
  String get withoutMarkers => 'No markers';

  @override
  String get favoritePerformer => 'Favorite performer';

  @override
  String get noFavoritePerformer => 'No favorite performer';

  @override
  String get favorites => 'Favorites';

  @override
  String get notFavorites => 'Not favorites';

  @override
  String get sectionStats => 'Statistics';

  @override
  String get sectionResume => 'Continue watching';

  @override
  String get sectionRecent => 'Recently added';

  @override
  String get sectionReleases => 'Recently released';

  @override
  String get sectionFavoritePerformers => 'Favorite performers';

  @override
  String get sectionRandom => 'Random';

  @override
  String get sectionGalleries => 'Recent galleries';

  @override
  String sceneNumber(Object id) {
    return 'Scene $id';
  }

  @override
  String galleryNumber(Object id) {
    return 'Gallery $id';
  }

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderTransMale => 'Transgender male';

  @override
  String get genderTransFemale => 'Transgender female';

  @override
  String get genderIntersex => 'Intersex';

  @override
  String get genderNonBinary => 'Non-binary';

  @override
  String get bytesUnits => 'B,KB,MB,GB,TB';

  @override
  String get sortCreatedAt => 'Date added';

  @override
  String get sortReleaseDate => 'Release date';

  @override
  String get sortDate => 'Date';

  @override
  String get sortTitle => 'Title';

  @override
  String get sortName => 'Name';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortLastPlayed => 'Last played';

  @override
  String get sortPlayCount => 'Play count';

  @override
  String get sortOCounter => 'O counter';

  @override
  String get sortDuration => 'Duration';

  @override
  String get sortFileSize => 'File size';

  @override
  String get sortRandom => 'Random';

  @override
  String get sortSceneCount => 'Scene count';

  @override
  String get sortImageCount => 'Image count';

  @override
  String get sortBirthdate => 'Birthdate';

  @override
  String get sortGroupOrder => 'Group order';

  @override
  String get sortPath => 'Path';

  @override
  String get sortPosition => 'Position';

  @override
  String get sceneNotFound => 'Scene not found';

  @override
  String get performerNotFound => 'Performer not found';

  @override
  String get studioNotFound => 'Studio not found';

  @override
  String get tagNotFound => 'Tag not found';

  @override
  String get groupNotFound => 'Group not found';

  @override
  String get galleryNotFound => 'Gallery not found';

  @override
  String get imageNotFound => 'Image not found';

  @override
  String serverUnreachable(Object error) {
    return 'Cannot reach the server: $error';
  }

  @override
  String accessDenied(Object status) {
    return 'Access denied (HTTP $status). Check the API key.';
  }

  @override
  String httpError(Object status) {
    return 'HTTP error $status';
  }

  @override
  String get invalidResponse =>
      'Invalid response: the server does not seem to be Stash.';

  @override
  String get lockAtLaunchOnly => 'Only at launch';

  @override
  String get lockImmediately => 'As soon as the app goes to the background';

  @override
  String lockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'After $minutes minutes in the background',
      one: 'After 1 minute in the background',
    );
    return '$_temp0';
  }

  @override
  String get notifDownloading => 'Downloading';

  @override
  String get notifDownloaded => 'Downloaded';

  @override
  String get notifDownloadFailed => 'Download failed';

  @override
  String get notifPaused => 'Paused';

  @override
  String githubError(Object status) {
    return 'GitHub answered $status';
  }

  @override
  String downloadRefused(Object status) {
    return 'Download refused ($status)';
  }

  @override
  String get downloadIncomplete => 'Incomplete download';

  @override
  String get noServerConfigured => 'No server configured';

  @override
  String get fileUnavailable => 'File unavailable';

  @override
  String imageNumber(Object id) {
    return 'Image $id';
  }

  @override
  String countItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String countScenes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scenes',
      one: '$count scene',
    );
    return '$_temp0';
  }

  @override
  String countPerformers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count performers',
      one: '$count performer',
    );
    return '$_temp0';
  }

  @override
  String countStudios(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count studios',
      one: '$count studio',
    );
    return '$_temp0';
  }

  @override
  String countGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groups',
      one: '$count group',
    );
    return '$_temp0';
  }

  @override
  String countGalleries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count galleries',
      one: '$count gallery',
    );
    return '$_temp0';
  }

  @override
  String countTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '$count tag',
    );
    return '$_temp0';
  }

  @override
  String countMarkers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count markers',
      one: '$count marker',
    );
    return '$_temp0';
  }

  @override
  String countImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images',
      one: '$count image',
    );
    return '$_temp0';
  }

  @override
  String countPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plays',
      one: '$count play',
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
      other: '$age years old',
      one: '$age year old',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Search…';

  @override
  String get sort => 'Sort';

  @override
  String get descending => 'Descending';

  @override
  String get ascending => 'Ascending';

  @override
  String get noResults => 'No results';

  @override
  String framesPerSecond(Object fps) {
    return '$fps fps';
  }

  @override
  String addedOn(Object date) {
    return 'Added $date';
  }

  @override
  String get noRating => 'No rating';

  @override
  String starsOutOfFive(Object stars) {
    return '$stars / 5';
  }

  @override
  String get openScene => 'Open the scene';

  @override
  String get editMarker => 'Edit the marker';

  @override
  String get downloadTitle => 'Download?';

  @override
  String downloadSceneQuestion(Object size) {
    return 'Download this scene to watch it offline$size?';
  }

  @override
  String downloadGroupQuestion(Object size) {
    return 'Download every scene of this group to watch them offline$size?';
  }

  @override
  String downloadGalleryQuestion(Object size) {
    return 'Download every image of this gallery to view them offline$size?';
  }

  @override
  String downloadImageQuestion(Object size) {
    return 'Download this image to view it offline$size?';
  }

  @override
  String get downloadInBackground =>
      'The download continues in the background.';

  @override
  String get preparingDownload => 'Preparing the download…';

  @override
  String get downloadStarted => 'Download started (More > Downloads)';

  @override
  String get downloadInProgress => 'Downloading';

  @override
  String get connectionRestored => 'Connection to the server restored';

  @override
  String get offlineTitle => 'Offline';

  @override
  String offlineMessage(Object url) {
    return 'The Stash server ($url) cannot be reached. Downloaded scenes, groups, galleries and images are still available.';
  }

  @override
  String get scanRunning => 'Scanning the library…';

  @override
  String scanProgress(Object percent) {
    return 'Scanning the library · $percent %';
  }

  @override
  String get scanFailed => 'Scan failed';

  @override
  String get scanStopped => 'Scan stopped · data refreshed';

  @override
  String get scanFinished => 'Scan finished · data refreshed';

  @override
  String get stopScan => 'Stop the scan';

  @override
  String get lockedTitle => 'Stash is locked';

  @override
  String get password => 'Password';

  @override
  String get wrongPassword => 'Wrong password';

  @override
  String get unlock => 'Unlock';

  @override
  String get info => 'Info';

  @override
  String get information => 'Information';

  @override
  String get parentStudio => 'Parent studio';

  @override
  String get description => 'Description';

  @override
  String get links => 'Links';

  @override
  String get favorite => 'Favorite';

  @override
  String get disambiguation => 'Disambiguation';

  @override
  String get aliases => 'Aliases';

  @override
  String get gender => 'Gender';

  @override
  String get birth => 'Birth';

  @override
  String get country => 'Country';

  @override
  String get ethnicity => 'Ethnicity';

  @override
  String get height => 'Height';

  @override
  String get measurements => 'Measurements';

  @override
  String get hairColor => 'Hair';

  @override
  String get eyeColor => 'Eyes';

  @override
  String get date => 'Date';

  @override
  String get duration => 'Duration';

  @override
  String get director => 'Director';

  @override
  String get synopsis => 'Synopsis';

  @override
  String get path => 'Path';

  @override
  String get emptyGallery => 'Empty gallery';

  @override
  String get enterServerAddress => 'Enter the server\'s address.';

  @override
  String connectedTo(Object version) {
    return 'Connected to Stash $version';
  }

  @override
  String get stashServer => 'Stash server';

  @override
  String get connectPrompt => 'Connect to your Stash server';

  @override
  String get serverAddress => 'Server address';

  @override
  String get apiKeyOptional => 'API key (optional)';

  @override
  String get apiKeyHelp =>
      'Stash > Settings > Security > API key. Required when authentication is on.';

  @override
  String get connect => 'Connect';

  @override
  String get scanLibraryQuestion => 'Scan the library?';

  @override
  String get scanConfirmMessage =>
      'Stash will go through your folders with its default scan options (Settings > Tasks). Progress shows at the bottom of the screen; pages reload when it is done.';

  @override
  String get scan => 'Scan';

  @override
  String get homePage => 'Home page';

  @override
  String get defaultHome => 'Default home';

  @override
  String customHomeItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Custom: $count items',
      one: 'Custom: $count item',
    );
    return '$_temp0';
  }

  @override
  String get savedViews => 'Saved views';

  @override
  String get noViews => 'None';

  @override
  String countViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count views',
      one: '$count view',
    );
    return '$_temp0';
  }

  @override
  String get downloadsSubtitle =>
      'Offline scenes, groups, galleries and images';

  @override
  String get displayHeader => 'Display';

  @override
  String get serverHeader => 'Server';

  @override
  String get applicationHeader => 'Application';

  @override
  String get tabsTitle => 'Tabs';

  @override
  String get sceneColumns => 'Scene columns (portrait)';

  @override
  String get longPressPreview => 'Video preview on long press';

  @override
  String get longPressPreviewSubtitle =>
      'Plays a scene\'s preview while you hold it';

  @override
  String get serverVersion => 'Server version';

  @override
  String get scanLibrary => 'Scan the library';

  @override
  String get scanInProgressSubtitle =>
      'Scan in progress (shown at the bottom of the screen)';

  @override
  String get scanSubtitle => 'Finds added, changed or removed files';

  @override
  String get logout => 'Log out';

  @override
  String get logoutQuestion => 'Log out?';

  @override
  String get logoutMessage =>
      'The server address and API key will be forgotten.';

  @override
  String get appVersion => 'App version';

  @override
  String get settingsSubtitle => 'Language, popup player, password, updates';

  @override
  String get language => 'Language';

  @override
  String get appLanguage => 'App language';

  @override
  String systemLanguage(Object name) {
    return 'System language ($name)';
  }

  @override
  String get playbackHeader => 'Playback';

  @override
  String get popupPlayer => 'Popup player';

  @override
  String get popupPlayerSubtitle =>
      'The playing video continues in a small window when you leave the app';

  @override
  String get privacyHeader => 'Privacy';

  @override
  String get hideInRecents => 'Hide in recent apps';

  @override
  String get hideInRecentsSubtitle =>
      'Black preview in the app switcher (also blocks screenshots)';

  @override
  String get createPassword => 'Create a password';

  @override
  String get createPasswordSubtitle => 'Asked when the app opens';

  @override
  String get changePassword => 'Change the password';

  @override
  String get removePassword => 'Remove the password';

  @override
  String get askPasswordAgain => 'Ask for the password again';

  @override
  String get passwordRemoved => 'Password removed';

  @override
  String get passwordCreated => 'Password created';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get updatesHeader => 'Updates';

  @override
  String get checkAtStartup => 'Check at startup';

  @override
  String get checkAtStartupSubtitle =>
      'Offers the new versions published on GitHub';

  @override
  String get checkForUpdate => 'Check for an update';

  @override
  String get passwordTooShort => 'At least 4 characters';

  @override
  String get passwordsDiffer => 'The passwords differ';

  @override
  String get create => 'Create';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmation => 'Confirmation';

  @override
  String get forgottenPasswordHint =>
      'If you forget it, you will have to clear the app\'s data (and set it up again).';

  @override
  String updateCheckFailed(Object error) {
    return 'Could not check: $error';
  }

  @override
  String get upToDate => 'The app is up to date';

  @override
  String installFailed(Object error) {
    return 'Could not install: $error';
  }

  @override
  String versionAvailable(Object version) {
    return 'Version $version available';
  }

  @override
  String whatsNewIn(Object version) {
    return 'What\'s new in $version';
  }

  @override
  String get later => 'Later';

  @override
  String get install => 'Install';

  @override
  String installWithSize(Object size) {
    return 'Install ($size)';
  }

  @override
  String downloadingVersion(Object version) {
    return 'Downloading $version';
  }

  @override
  String failedWith(Object error) {
    return 'Failed: $error';
  }

  @override
  String get installHint =>
      'Android will then ask you to confirm the installation (and, the first time, to allow Stash to install apps).';

  @override
  String get criterionFolder => 'folder';

  @override
  String get criterionCustomFields => 'custom fields';

  @override
  String deleteNamedQuestion(Object name) {
    return 'Delete “$name”?';
  }

  @override
  String webFilterOf(Object kind) {
    return 'Stash filter (web) · $kind';
  }

  @override
  String get noFilter => 'no filter';

  @override
  String get viewsIntro =>
      'Create a view (scenes, performers, studios…) with the “New view” button, or from the Scenes tab (bookmark icon). Filters saved in the Stash web UI show up too (cloud icon); they are edited from the web.';

  @override
  String unsupportedWebFilters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count web filters of a kind the app does not know are left out',
      one: '$count web filter of a kind the app does not know is left out',
    );
    return '$_temp0';
  }

  @override
  String skippedCriteriaWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count web filters use criteria the app cannot apply (listed under each of them). They are ignored: the view shows more items than on the web.',
      one: 'A web filter uses criteria the app cannot apply (listed under that filter). They are ignored: the view shows more items than on the web.',
    );
    return '$_temp0';
  }

  @override
  String get composeHomePages => 'Compose the home pages';

  @override
  String get homeIsDefault => 'Home: default';

  @override
  String homeItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Home: $count items',
      one: 'Home: $count item',
    );
    return '$_temp0';
  }

  @override
  String get noSavedViews => 'No saved views';

  @override
  String get homeIconHint =>
      'The house icon adds a view at the end of the home page, or removes it. The order, the sections and the default home are set in “Compose the home pages”.';

  @override
  String get removeFromHome => 'Remove from the home page';

  @override
  String get addToHome => 'Add to the home page';

  @override
  String ignored(Object criteria) {
    return 'Ignored: $criteria';
  }

  @override
  String get reloadWebFilters => 'Reload Stash\'s filters';

  @override
  String get newView => 'New view';

  @override
  String get webFiltersUnavailable => 'Stash\'s filters unavailable';

  @override
  String get nameTheView => 'Give the view a name';

  @override
  String get editView => 'Edit the view';

  @override
  String get content => 'Content';

  @override
  String get nameRequired => 'Name *';

  @override
  String get searchOptional => 'Search (optional)';

  @override
  String get sortField => 'Sort';

  @override
  String get filter => 'Filter';

  @override
  String noFilterAll(Object kind) {
    return 'No filter (all $kind)';
  }

  @override
  String get editFilter => 'Edit the filter';

  @override
  String tabsIntro(Object max) {
    return 'Check up to $max screens for the bottom bar (“More” always stays there, last). The others are in More. Drag to change the order; the first tab opens at launch.';
  }

  @override
  String tabsCount(Object count, Object max) {
    return '$count / $max tabs';
  }

  @override
  String get tab => 'Tab';

  @override
  String get inMore => 'In More';

  @override
  String get byDefault => 'Default';

  @override
  String get homeLayoutIntro =>
      'Items stacked on the home page, in this order. With nothing checked, the default home is used; with a single view, it fills the page and gives it its name.';

  @override
  String get dashboardLayoutIntro =>
      'Rows of the default home (opened by the button at the top right of a custom home), in this order.';

  @override
  String get defaultRows => 'Default rows';

  @override
  String get homeSection => 'Home section';

  @override
  String viewOf(Object kind) {
    return 'View · $kind';
  }

  @override
  String errorWith(Object error) {
    return 'Error: $error';
  }

  @override
  String get nothingYet => 'Nothing yet';

  @override
  String showMore(Object count) {
    return 'Show more ($count)';
  }

  @override
  String serverUnreachableShort(Object error) {
    return 'Server unreachable: $error';
  }

  @override
  String countHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '$count hour',
    );
    return '$_temp0';
  }

  @override
  String get seeAll => 'See all';

  @override
  String viewSaved(Object name) {
    return 'View “$name” saved';
  }

  @override
  String get showOnHome => 'Show on the home page';

  @override
  String get clear => 'Clear';

  @override
  String get filters => 'Filters';

  @override
  String get saveAsNewView => 'Save as a new view';

  @override
  String get saveView => 'Save the view';

  @override
  String get noMarkers => 'No markers';

  @override
  String get noImages => 'No images';

  @override
  String get noDownloads =>
      'No downloads.\n\nUse the download button of a scene, a group, a gallery or an image (in the viewer) to keep it on the phone.';

  @override
  String deleteFromPhoneQuestion(Object title) {
    return 'Delete “$title” from the phone?';
  }

  @override
  String get groupScenesDeletedToo =>
      'This group\'s scenes will be deleted too.';

  @override
  String get downloadFailedRetry => 'Failed: tap ⋮ to retry';

  @override
  String get downloadQueued => 'Waiting';

  @override
  String get downloadRunning => 'Downloading…';

  @override
  String downloadProgress(Object percent) {
    return 'Downloading · $percent %';
  }

  @override
  String resumeAt(Object time) {
    return 'Resume at $time';
  }

  @override
  String get play => 'Play';

  @override
  String get fromStart => 'From the start';

  @override
  String get forgetResumePosition => 'Forget the resume position';

  @override
  String get resumePositionCleared => 'Resume position cleared';

  @override
  String get code => 'Code';

  @override
  String get file => 'File';

  @override
  String get fileSize => 'Size';

  @override
  String get dimensions => 'Dimensions';

  @override
  String get format => 'Format';

  @override
  String get video => 'Video';

  @override
  String get audio => 'Audio';

  @override
  String get framesPerSecondLabel => 'Frames/s';

  @override
  String get bitRate => 'Bit rate';

  @override
  String megabitsPerSecond(Object value) {
    return '$value Mb/s';
  }

  @override
  String get offlineCopy => 'Offline copy';

  @override
  String get noStream => 'No stream available';

  @override
  String get directStream => 'Direct (original)';

  @override
  String directPlaybackFailed(Object source) {
    return 'Direct playback failed, trying “$source”';
  }

  @override
  String playbackFailed(Object error) {
    return 'Cannot play: $error';
  }

  @override
  String get playbackError => 'Playback error';

  @override
  String get coverGenerating => 'Stash is generating the cover';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String get useFrameAsCover => 'Use this frame as the cover';

  @override
  String get addMarkerHere => 'Add a marker here';

  @override
  String get streams => 'Streams';

  @override
  String get pause => 'Pause';

  @override
  String filterKind(Object kind) {
    return 'Filter: $kind';
  }

  @override
  String get allRatings => 'Any';

  @override
  String get allResolutions => 'Any';

  @override
  String get withLabel => 'With';

  @override
  String get withoutLabel => 'Without';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get anyValue => 'All';

  @override
  String confirmCount(Object count) {
    return 'Confirm ($count)';
  }

  @override
  String get clearAll => 'Clear all';

  @override
  String get includeSubTags => 'Include sub-tags';

  @override
  String get includeSubStudios => 'Include sub-studios';

  @override
  String get includeSubGroups => 'Include sub-groups';

  @override
  String get minRating => 'Minimum rating';

  @override
  String get minResolution => 'Minimum resolution';

  @override
  String get durationMinutes => 'Duration (minutes)';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get apply => 'Apply';

  @override
  String get choose => 'Choose';

  @override
  String get watchStatus => 'Watched';

  @override
  String get cover => 'Cover';

  @override
  String get organized => 'Organized';

  @override
  String get scrape => 'Scrape';

  @override
  String get editScene => 'Edit the scene';

  @override
  String get photo => 'Photo';

  @override
  String get deathDate => 'Death date';

  @override
  String get weight => 'Weight';

  @override
  String get fakeTits => 'Fake tits';

  @override
  String get tattoos => 'Tattoos';

  @override
  String get piercings => 'Piercings';

  @override
  String get editPerformer => 'Edit the performer';

  @override
  String get logo => 'Logo';

  @override
  String get editStudio => 'Edit the studio';

  @override
  String get image => 'Image';

  @override
  String get parentTags => 'Parent tags';

  @override
  String get editTag => 'Edit the tag';

  @override
  String get frontCover => 'Front cover';

  @override
  String get backCover => 'Back cover';

  @override
  String get editGroup => 'Edit the group';

  @override
  String get photographer => 'Photographer';

  @override
  String get editGallery => 'Edit the gallery';

  @override
  String get start => 'Start';

  @override
  String get endOptional => 'End (optional)';

  @override
  String get primaryTag => 'Primary tag';

  @override
  String get otherTags => 'Other tags';

  @override
  String get deleteMarker => 'Delete the marker';

  @override
  String get newMarker => 'New marker';

  @override
  String fieldRequired(Object label) {
    return '$label is required';
  }

  @override
  String get dateHint => 'YYYY-MM-DD';

  @override
  String dateFormatExpected(Object label, Object format) {
    return '$label: $format format expected';
  }

  @override
  String integerExpected(Object label) {
    return '$label: whole number expected';
  }

  @override
  String timeFormatExpected(Object label) {
    return '$label: m:ss format expected';
  }

  @override
  String get change => 'Change';

  @override
  String get add => 'Add';

  @override
  String get addHint => 'Add…';

  @override
  String questionOf(Object action) {
    return '$action?';
  }

  @override
  String get saved => 'Saved';

  @override
  String get deleted => 'Deleted';

  @override
  String get use => 'Use';

  @override
  String get fromPhone => 'From the phone';

  @override
  String get fromUrl => 'From a URL';

  @override
  String get cannotBeUndone => 'This cannot be undone.';

  @override
  String get discardChangesQuestion => 'Discard the changes?';

  @override
  String get continueEditing => 'Keep editing';

  @override
  String get discard => 'Discard';

  @override
  String get newGroup => 'New group';

  @override
  String get newGallery => 'New gallery';

  @override
  String get newPerformer => 'New performer';

  @override
  String get newStudio => 'New studio';

  @override
  String get newTag => 'New tag';

  @override
  String get deletePerformer => 'Delete the performer';

  @override
  String get deleteStudio => 'Delete the studio';

  @override
  String get deleteTag => 'Delete the tag';

  @override
  String get deleteGroup => 'Delete the group';

  @override
  String get deleteGallery => 'Delete the gallery';

  @override
  String get untitled => 'Untitled';

  @override
  String get newImage => 'New image';

  @override
  String get nothingNewInResult => 'Nothing new in this result';

  @override
  String searchOn(Object source) {
    return 'Search on $source';
  }

  @override
  String get titleCodeHint => 'Title, code…';

  @override
  String get scrapeWith => 'Scrape with…';

  @override
  String get byFingerprintThenSearch => 'By fingerprint, else by search';

  @override
  String get bySearch => 'By search';

  @override
  String get byScene => 'by scene';

  @override
  String get bySearchLower => 'by search';

  @override
  String get scrapersHeader => 'Scrapers';

  @override
  String get noScraperConfigured =>
      'No scraper or stash-box is set up for this type on the server (Settings > Metadata).';

  @override
  String countResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '$count result',
    );
    return '$_temp0';
  }

  @override
  String createdInStash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items created in Stash',
      one: '$count item created in Stash',
    );
    return '$_temp0';
  }

  @override
  String get scrapeResultIntro =>
      'Check the values to take. They fill the edit form and are only saved with “Save” (except the items to create, below).';

  @override
  String currentValue(Object value) {
    return 'Current: $value';
  }

  @override
  String get missingFromStash => 'Missing from Stash';

  @override
  String get missingFromStashHint =>
      'Checked items are created in Stash (with the scraper\'s information) on “Apply”, then linked.';

  @override
  String createAndLink(Object label) {
    return 'Create and link · $label';
  }

  @override
  String get search => 'Search';

  @override
  String get scrapeUrl => 'Scrape a URL';

  @override
  String get otherUrl => 'Other URL…';

  @override
  String get scrapeResult => 'Scrape result';
}
