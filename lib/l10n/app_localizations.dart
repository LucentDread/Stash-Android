import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @scenes.
  ///
  /// In en, this message translates to:
  /// **'Scenes'**
  String get scenes;

  /// No description provided for @performers.
  ///
  /// In en, this message translates to:
  /// **'Performers'**
  String get performers;

  /// No description provided for @studios.
  ///
  /// In en, this message translates to:
  /// **'Studios'**
  String get studios;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @galleries.
  ///
  /// In en, this message translates to:
  /// **'Galleries'**
  String get galleries;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @markers.
  ///
  /// In en, this message translates to:
  /// **'Markers'**
  String get markers;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @studio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get studio;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @modeAny.
  ///
  /// In en, this message translates to:
  /// **'At least one'**
  String get modeAny;

  /// No description provided for @modeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get modeAll;

  /// No description provided for @modeExclude.
  ///
  /// In en, this message translates to:
  /// **'None of'**
  String get modeExclude;

  /// No description provided for @modeNone.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get modeNone;

  /// No description provided for @modeNotNone.
  ///
  /// In en, this message translates to:
  /// **'Not empty'**
  String get modeNotNone;

  /// No description provided for @criterionAny.
  ///
  /// In en, this message translates to:
  /// **'{label}: {names}'**
  String criterionAny(Object label, Object names);

  /// No description provided for @criterionAll.
  ///
  /// In en, this message translates to:
  /// **'{label} (all): {names}'**
  String criterionAll(Object label, Object names);

  /// No description provided for @criterionExclude.
  ///
  /// In en, this message translates to:
  /// **'{label} except: {names}'**
  String criterionExclude(Object label, Object names);

  /// No description provided for @withoutPerformer.
  ///
  /// In en, this message translates to:
  /// **'No performer'**
  String get withoutPerformer;

  /// No description provided for @withPerformer.
  ///
  /// In en, this message translates to:
  /// **'With performers'**
  String get withPerformer;

  /// No description provided for @withoutTag.
  ///
  /// In en, this message translates to:
  /// **'No tag'**
  String get withoutTag;

  /// No description provided for @withTag.
  ///
  /// In en, this message translates to:
  /// **'With tags'**
  String get withTag;

  /// No description provided for @withoutStudio.
  ///
  /// In en, this message translates to:
  /// **'No studio'**
  String get withoutStudio;

  /// No description provided for @withStudio.
  ///
  /// In en, this message translates to:
  /// **'With a studio'**
  String get withStudio;

  /// No description provided for @withoutGroup.
  ///
  /// In en, this message translates to:
  /// **'No group'**
  String get withoutGroup;

  /// No description provided for @withGroup.
  ///
  /// In en, this message translates to:
  /// **'In a group'**
  String get withGroup;

  /// No description provided for @minutesRange.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} min'**
  String minutesRange(Object min, Object max);

  /// No description provided for @atLeastMinutes.
  ///
  /// In en, this message translates to:
  /// **'≥ {min} min'**
  String atLeastMinutes(Object min);

  /// No description provided for @atMostMinutes.
  ///
  /// In en, this message translates to:
  /// **'≤ {max} min'**
  String atMostMinutes(Object max);

  /// No description provided for @organizedState.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, scenes{Organized} other{Organized}}'**
  String organizedState(String kind);

  /// No description provided for @notOrganizedState.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, scenes{Not organized} other{Not organized}}'**
  String notOrganizedState(String kind);

  /// No description provided for @playedState.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, scenes{Watched} other{Watched}}'**
  String playedState(String kind);

  /// No description provided for @notPlayedState.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, scenes{Never watched} other{Never watched}}'**
  String notPlayedState(String kind);

  /// No description provided for @withMarkers.
  ///
  /// In en, this message translates to:
  /// **'With markers'**
  String get withMarkers;

  /// No description provided for @withoutMarkers.
  ///
  /// In en, this message translates to:
  /// **'No markers'**
  String get withoutMarkers;

  /// No description provided for @favoritePerformer.
  ///
  /// In en, this message translates to:
  /// **'Favorite performer'**
  String get favoritePerformer;

  /// No description provided for @noFavoritePerformer.
  ///
  /// In en, this message translates to:
  /// **'No favorite performer'**
  String get noFavoritePerformer;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @notFavorites.
  ///
  /// In en, this message translates to:
  /// **'Not favorites'**
  String get notFavorites;

  /// No description provided for @sectionStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get sectionStats;

  /// No description provided for @sectionResume.
  ///
  /// In en, this message translates to:
  /// **'Continue watching'**
  String get sectionResume;

  /// No description provided for @sectionRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get sectionRecent;

  /// No description provided for @sectionReleases.
  ///
  /// In en, this message translates to:
  /// **'Recently released'**
  String get sectionReleases;

  /// No description provided for @sectionFavoritePerformers.
  ///
  /// In en, this message translates to:
  /// **'Favorite performers'**
  String get sectionFavoritePerformers;

  /// No description provided for @sectionRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get sectionRandom;

  /// No description provided for @sectionGalleries.
  ///
  /// In en, this message translates to:
  /// **'Recent galleries'**
  String get sectionGalleries;

  /// No description provided for @sceneNumber.
  ///
  /// In en, this message translates to:
  /// **'Scene {id}'**
  String sceneNumber(Object id);

  /// No description provided for @galleryNumber.
  ///
  /// In en, this message translates to:
  /// **'Gallery {id}'**
  String galleryNumber(Object id);

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderTransMale.
  ///
  /// In en, this message translates to:
  /// **'Transgender male'**
  String get genderTransMale;

  /// No description provided for @genderTransFemale.
  ///
  /// In en, this message translates to:
  /// **'Transgender female'**
  String get genderTransFemale;

  /// No description provided for @genderIntersex.
  ///
  /// In en, this message translates to:
  /// **'Intersex'**
  String get genderIntersex;

  /// No description provided for @genderNonBinary.
  ///
  /// In en, this message translates to:
  /// **'Non-binary'**
  String get genderNonBinary;

  /// No description provided for @bytesUnits.
  ///
  /// In en, this message translates to:
  /// **'B,KB,MB,GB,TB'**
  String get bytesUnits;

  /// No description provided for @sortCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Date added'**
  String get sortCreatedAt;

  /// No description provided for @sortReleaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release date'**
  String get sortReleaseDate;

  /// No description provided for @sortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sortDate;

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortTitle;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @sortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get sortRating;

  /// No description provided for @sortLastPlayed.
  ///
  /// In en, this message translates to:
  /// **'Last played'**
  String get sortLastPlayed;

  /// No description provided for @sortPlayCount.
  ///
  /// In en, this message translates to:
  /// **'Play count'**
  String get sortPlayCount;

  /// No description provided for @sortOCounter.
  ///
  /// In en, this message translates to:
  /// **'O counter'**
  String get sortOCounter;

  /// No description provided for @sortDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sortDuration;

  /// No description provided for @sortFileSize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get sortFileSize;

  /// No description provided for @sortRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get sortRandom;

  /// No description provided for @sortSceneCount.
  ///
  /// In en, this message translates to:
  /// **'Scene count'**
  String get sortSceneCount;

  /// No description provided for @sortImageCount.
  ///
  /// In en, this message translates to:
  /// **'Image count'**
  String get sortImageCount;

  /// No description provided for @sortBirthdate.
  ///
  /// In en, this message translates to:
  /// **'Birthdate'**
  String get sortBirthdate;

  /// No description provided for @sortGroupOrder.
  ///
  /// In en, this message translates to:
  /// **'Group order'**
  String get sortGroupOrder;

  /// No description provided for @sortPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get sortPath;

  /// No description provided for @sortPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get sortPosition;

  /// No description provided for @sceneNotFound.
  ///
  /// In en, this message translates to:
  /// **'Scene not found'**
  String get sceneNotFound;

  /// No description provided for @performerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Performer not found'**
  String get performerNotFound;

  /// No description provided for @studioNotFound.
  ///
  /// In en, this message translates to:
  /// **'Studio not found'**
  String get studioNotFound;

  /// No description provided for @tagNotFound.
  ///
  /// In en, this message translates to:
  /// **'Tag not found'**
  String get tagNotFound;

  /// No description provided for @groupNotFound.
  ///
  /// In en, this message translates to:
  /// **'Group not found'**
  String get groupNotFound;

  /// No description provided for @galleryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Gallery not found'**
  String get galleryNotFound;

  /// No description provided for @imageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Image not found'**
  String get imageNotFound;

  /// No description provided for @serverUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server: {error}'**
  String serverUnreachable(Object error);

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied (HTTP {status}). Check the API key.'**
  String accessDenied(Object status);

  /// No description provided for @httpError.
  ///
  /// In en, this message translates to:
  /// **'HTTP error {status}'**
  String httpError(Object status);

  /// No description provided for @invalidResponse.
  ///
  /// In en, this message translates to:
  /// **'Invalid response: the server does not seem to be Stash.'**
  String get invalidResponse;

  /// No description provided for @lockAtLaunchOnly.
  ///
  /// In en, this message translates to:
  /// **'Only at launch'**
  String get lockAtLaunchOnly;

  /// No description provided for @lockImmediately.
  ///
  /// In en, this message translates to:
  /// **'As soon as the app goes to the background'**
  String get lockImmediately;

  /// No description provided for @lockAfterMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{After 1 minute in the background} other{After {minutes} minutes in the background}}'**
  String lockAfterMinutes(int minutes);

  /// No description provided for @notifDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get notifDownloading;

  /// No description provided for @notifDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get notifDownloaded;

  /// No description provided for @notifDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get notifDownloadFailed;

  /// No description provided for @notifPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get notifPaused;

  /// No description provided for @githubError.
  ///
  /// In en, this message translates to:
  /// **'GitHub answered {status}'**
  String githubError(Object status);

  /// No description provided for @downloadRefused.
  ///
  /// In en, this message translates to:
  /// **'Download refused ({status})'**
  String downloadRefused(Object status);

  /// No description provided for @downloadIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete download'**
  String get downloadIncomplete;

  /// No description provided for @noServerConfigured.
  ///
  /// In en, this message translates to:
  /// **'No server configured'**
  String get noServerConfigured;

  /// No description provided for @fileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'File unavailable'**
  String get fileUnavailable;

  /// No description provided for @imageNumber.
  ///
  /// In en, this message translates to:
  /// **'Image {id}'**
  String imageNumber(Object id);

  /// No description provided for @countItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} item} other{{count} items}}'**
  String countItems(int count);

  /// No description provided for @countScenes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} scene} other{{count} scenes}}'**
  String countScenes(int count);

  /// No description provided for @countPerformers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} performer} other{{count} performers}}'**
  String countPerformers(int count);

  /// No description provided for @countStudios.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} studio} other{{count} studios}}'**
  String countStudios(int count);

  /// No description provided for @countGroups.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} group} other{{count} groups}}'**
  String countGroups(int count);

  /// No description provided for @countGalleries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} gallery} other{{count} galleries}}'**
  String countGalleries(int count);

  /// No description provided for @countTags.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} tag} other{{count} tags}}'**
  String countTags(int count);

  /// No description provided for @countMarkers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} marker} other{{count} markers}}'**
  String countMarkers(int count);

  /// No description provided for @countImages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} image} other{{count} images}}'**
  String countImages(int count);

  /// No description provided for @countPlays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} play} other{{count} plays}}'**
  String countPlays(int count);

  /// No description provided for @countO.
  ///
  /// In en, this message translates to:
  /// **'{count} O'**
  String countO(Object count);

  /// No description provided for @yearsOld.
  ///
  /// In en, this message translates to:
  /// **'{age, plural, one{{age} year old} other{{age} years old}}'**
  String yearsOld(int age);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get searchHint;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @framesPerSecond.
  ///
  /// In en, this message translates to:
  /// **'{fps} fps'**
  String framesPerSecond(Object fps);

  /// No description provided for @addedOn.
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String addedOn(Object date);

  /// No description provided for @noRating.
  ///
  /// In en, this message translates to:
  /// **'No rating'**
  String get noRating;

  /// No description provided for @starsOutOfFive.
  ///
  /// In en, this message translates to:
  /// **'{stars} / 5'**
  String starsOutOfFive(Object stars);

  /// No description provided for @openScene.
  ///
  /// In en, this message translates to:
  /// **'Open the scene'**
  String get openScene;

  /// No description provided for @editMarker.
  ///
  /// In en, this message translates to:
  /// **'Edit the marker'**
  String get editMarker;

  /// No description provided for @downloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Download?'**
  String get downloadTitle;

  /// No description provided for @downloadSceneQuestion.
  ///
  /// In en, this message translates to:
  /// **'Download this scene to watch it offline{size}?'**
  String downloadSceneQuestion(Object size);

  /// No description provided for @downloadGroupQuestion.
  ///
  /// In en, this message translates to:
  /// **'Download every scene of this group to watch them offline{size}?'**
  String downloadGroupQuestion(Object size);

  /// No description provided for @downloadGalleryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Download every image of this gallery to view them offline{size}?'**
  String downloadGalleryQuestion(Object size);

  /// No description provided for @downloadImageQuestion.
  ///
  /// In en, this message translates to:
  /// **'Download this image to view it offline{size}?'**
  String downloadImageQuestion(Object size);

  /// No description provided for @downloadInBackground.
  ///
  /// In en, this message translates to:
  /// **'The download continues in the background.'**
  String get downloadInBackground;

  /// No description provided for @preparingDownload.
  ///
  /// In en, this message translates to:
  /// **'Preparing the download…'**
  String get preparingDownload;

  /// No description provided for @downloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started (More > Downloads)'**
  String get downloadStarted;

  /// No description provided for @downloadInProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloadInProgress;

  /// No description provided for @connectionRestored.
  ///
  /// In en, this message translates to:
  /// **'Connection to the server restored'**
  String get connectionRestored;

  /// No description provided for @offlineTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineTitle;

  /// No description provided for @offlineMessage.
  ///
  /// In en, this message translates to:
  /// **'The Stash server ({url}) cannot be reached. Downloaded scenes, groups, galleries and images are still available.'**
  String offlineMessage(Object url);

  /// No description provided for @scanRunning.
  ///
  /// In en, this message translates to:
  /// **'Scanning the library…'**
  String get scanRunning;

  /// No description provided for @scanProgress.
  ///
  /// In en, this message translates to:
  /// **'Scanning the library · {percent} %'**
  String scanProgress(Object percent);

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed'**
  String get scanFailed;

  /// No description provided for @scanStopped.
  ///
  /// In en, this message translates to:
  /// **'Scan stopped · data refreshed'**
  String get scanStopped;

  /// No description provided for @scanFinished.
  ///
  /// In en, this message translates to:
  /// **'Scan finished · data refreshed'**
  String get scanFinished;

  /// No description provided for @stopScan.
  ///
  /// In en, this message translates to:
  /// **'Stop the scan'**
  String get stopScan;

  /// No description provided for @lockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Stash is locked'**
  String get lockedTitle;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get wrongPassword;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @parentStudio.
  ///
  /// In en, this message translates to:
  /// **'Parent studio'**
  String get parentStudio;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @disambiguation.
  ///
  /// In en, this message translates to:
  /// **'Disambiguation'**
  String get disambiguation;

  /// No description provided for @aliases.
  ///
  /// In en, this message translates to:
  /// **'Aliases'**
  String get aliases;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @birth.
  ///
  /// In en, this message translates to:
  /// **'Birth'**
  String get birth;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @ethnicity.
  ///
  /// In en, this message translates to:
  /// **'Ethnicity'**
  String get ethnicity;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @measurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get measurements;

  /// No description provided for @hairColor.
  ///
  /// In en, this message translates to:
  /// **'Hair'**
  String get hairColor;

  /// No description provided for @eyeColor.
  ///
  /// In en, this message translates to:
  /// **'Eyes'**
  String get eyeColor;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @director.
  ///
  /// In en, this message translates to:
  /// **'Director'**
  String get director;

  /// No description provided for @synopsis.
  ///
  /// In en, this message translates to:
  /// **'Synopsis'**
  String get synopsis;

  /// No description provided for @path.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get path;

  /// No description provided for @emptyGallery.
  ///
  /// In en, this message translates to:
  /// **'Empty gallery'**
  String get emptyGallery;

  /// No description provided for @enterServerAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter the server\'s address.'**
  String get enterServerAddress;

  /// No description provided for @connectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to Stash {version}'**
  String connectedTo(Object version);

  /// No description provided for @stashServer.
  ///
  /// In en, this message translates to:
  /// **'Stash server'**
  String get stashServer;

  /// No description provided for @connectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Connect to your Stash server'**
  String get connectPrompt;

  /// No description provided for @serverAddress.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get serverAddress;

  /// No description provided for @apiKeyOptional.
  ///
  /// In en, this message translates to:
  /// **'API key (optional)'**
  String get apiKeyOptional;

  /// No description provided for @apiKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Stash > Settings > Security > API key. Required when authentication is on.'**
  String get apiKeyHelp;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @scanLibraryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Scan the library?'**
  String get scanLibraryQuestion;

  /// No description provided for @scanConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Stash will go through your folders with its default scan options (Settings > Tasks). Progress shows at the bottom of the screen; pages reload when it is done.'**
  String get scanConfirmMessage;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @homePage.
  ///
  /// In en, this message translates to:
  /// **'Home page'**
  String get homePage;

  /// No description provided for @defaultHome.
  ///
  /// In en, this message translates to:
  /// **'Default home'**
  String get defaultHome;

  /// No description provided for @customHomeItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Custom: {count} item} other{Custom: {count} items}}'**
  String customHomeItems(int count);

  /// No description provided for @savedViews.
  ///
  /// In en, this message translates to:
  /// **'Saved views'**
  String get savedViews;

  /// No description provided for @noViews.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noViews;

  /// No description provided for @countViews.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} view} other{{count} views}}'**
  String countViews(int count);

  /// No description provided for @downloadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline scenes, groups, galleries and images'**
  String get downloadsSubtitle;

  /// No description provided for @displayHeader.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displayHeader;

  /// No description provided for @serverHeader.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get serverHeader;

  /// No description provided for @applicationHeader.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get applicationHeader;

  /// No description provided for @tabsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tabs'**
  String get tabsTitle;

  /// No description provided for @sceneColumns.
  ///
  /// In en, this message translates to:
  /// **'Scene columns (portrait)'**
  String get sceneColumns;

  /// No description provided for @longPressPreview.
  ///
  /// In en, this message translates to:
  /// **'Video preview on long press'**
  String get longPressPreview;

  /// No description provided for @longPressPreviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plays a scene\'s preview while you hold it'**
  String get longPressPreviewSubtitle;

  /// No description provided for @serverVersion.
  ///
  /// In en, this message translates to:
  /// **'Server version'**
  String get serverVersion;

  /// No description provided for @scanLibrary.
  ///
  /// In en, this message translates to:
  /// **'Scan the library'**
  String get scanLibrary;

  /// No description provided for @scanInProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan in progress (shown at the bottom of the screen)'**
  String get scanInProgressSubtitle;

  /// No description provided for @scanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Finds added, changed or removed files'**
  String get scanSubtitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutQuestion;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'The server address and API key will be forgotten.'**
  String get logoutMessage;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Language, popup player, password, updates'**
  String get settingsSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System language ({name})'**
  String systemLanguage(Object name);

  /// No description provided for @playbackHeader.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playbackHeader;

  /// No description provided for @popupPlayer.
  ///
  /// In en, this message translates to:
  /// **'Popup player'**
  String get popupPlayer;

  /// No description provided for @popupPlayerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The playing video continues in a small window when you leave the app'**
  String get popupPlayerSubtitle;

  /// No description provided for @privacyHeader.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyHeader;

  /// No description provided for @hideInRecents.
  ///
  /// In en, this message translates to:
  /// **'Hide in recent apps'**
  String get hideInRecents;

  /// No description provided for @hideInRecentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Black preview in the app switcher (also blocks screenshots)'**
  String get hideInRecentsSubtitle;

  /// No description provided for @createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get createPassword;

  /// No description provided for @createPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Asked when the app opens'**
  String get createPasswordSubtitle;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change the password'**
  String get changePassword;

  /// No description provided for @removePassword.
  ///
  /// In en, this message translates to:
  /// **'Remove the password'**
  String get removePassword;

  /// No description provided for @askPasswordAgain.
  ///
  /// In en, this message translates to:
  /// **'Ask for the password again'**
  String get askPasswordAgain;

  /// No description provided for @passwordRemoved.
  ///
  /// In en, this message translates to:
  /// **'Password removed'**
  String get passwordRemoved;

  /// No description provided for @passwordCreated.
  ///
  /// In en, this message translates to:
  /// **'Password created'**
  String get passwordCreated;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// No description provided for @updatesHeader.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updatesHeader;

  /// No description provided for @checkAtStartup.
  ///
  /// In en, this message translates to:
  /// **'Check at startup'**
  String get checkAtStartup;

  /// No description provided for @checkAtStartupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offers the new versions published on GitHub'**
  String get checkAtStartupSubtitle;

  /// No description provided for @checkForUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check for an update'**
  String get checkForUpdate;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 4 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDiffer.
  ///
  /// In en, this message translates to:
  /// **'The passwords differ'**
  String get passwordsDiffer;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get confirmation;

  /// No description provided for @forgottenPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'If you forget it, you will have to clear the app\'s data (and set it up again).'**
  String get forgottenPasswordHint;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check: {error}'**
  String updateCheckFailed(Object error);

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'The app is up to date'**
  String get upToDate;

  /// No description provided for @installFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not install: {error}'**
  String installFailed(Object error);

  /// No description provided for @versionAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} available'**
  String versionAvailable(Object version);

  /// No description provided for @whatsNewIn.
  ///
  /// In en, this message translates to:
  /// **'What\'s new in {version}'**
  String whatsNewIn(Object version);

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @installWithSize.
  ///
  /// In en, this message translates to:
  /// **'Install ({size})'**
  String installWithSize(Object size);

  /// No description provided for @downloadingVersion.
  ///
  /// In en, this message translates to:
  /// **'Downloading {version}'**
  String downloadingVersion(Object version);

  /// No description provided for @failedWith.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failedWith(Object error);

  /// No description provided for @installHint.
  ///
  /// In en, this message translates to:
  /// **'Android will then ask you to confirm the installation (and, the first time, to allow Stash to install apps).'**
  String get installHint;

  /// No description provided for @criterionFolder.
  ///
  /// In en, this message translates to:
  /// **'folder'**
  String get criterionFolder;

  /// No description provided for @criterionCustomFields.
  ///
  /// In en, this message translates to:
  /// **'custom fields'**
  String get criterionCustomFields;

  /// No description provided for @deleteNamedQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String deleteNamedQuestion(Object name);

  /// No description provided for @webFilterOf.
  ///
  /// In en, this message translates to:
  /// **'Stash filter (web) · {kind}'**
  String webFilterOf(Object kind);

  /// No description provided for @noFilter.
  ///
  /// In en, this message translates to:
  /// **'no filter'**
  String get noFilter;

  /// No description provided for @viewsIntro.
  ///
  /// In en, this message translates to:
  /// **'Create a view (scenes, performers, studios…) with the “New view” button, or from the Scenes tab (bookmark icon). Filters saved in the Stash web UI show up too (cloud icon); they are edited from the web.'**
  String get viewsIntro;

  /// No description provided for @unsupportedWebFilters.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} web filter of a kind the app does not know is left out} other{{count} web filters of a kind the app does not know are left out}}'**
  String unsupportedWebFilters(int count);

  /// No description provided for @skippedCriteriaWarning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{A web filter uses criteria the app cannot apply (listed under that filter). They are ignored: the view shows more items than on the web.} other{{count} web filters use criteria the app cannot apply (listed under each of them). They are ignored: the view shows more items than on the web.}}'**
  String skippedCriteriaWarning(int count);

  /// No description provided for @composeHomePages.
  ///
  /// In en, this message translates to:
  /// **'Compose the home pages'**
  String get composeHomePages;

  /// No description provided for @homeIsDefault.
  ///
  /// In en, this message translates to:
  /// **'Home: default'**
  String get homeIsDefault;

  /// No description provided for @homeItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Home: {count} item} other{Home: {count} items}}'**
  String homeItems(int count);

  /// No description provided for @noSavedViews.
  ///
  /// In en, this message translates to:
  /// **'No saved views'**
  String get noSavedViews;

  /// No description provided for @homeIconHint.
  ///
  /// In en, this message translates to:
  /// **'The house icon adds a view at the end of the home page, or removes it. The order, the sections and the default home are set in “Compose the home pages”.'**
  String get homeIconHint;

  /// No description provided for @removeFromHome.
  ///
  /// In en, this message translates to:
  /// **'Remove from the home page'**
  String get removeFromHome;

  /// No description provided for @addToHome.
  ///
  /// In en, this message translates to:
  /// **'Add to the home page'**
  String get addToHome;

  /// No description provided for @ignored.
  ///
  /// In en, this message translates to:
  /// **'Ignored: {criteria}'**
  String ignored(Object criteria);

  /// No description provided for @reloadWebFilters.
  ///
  /// In en, this message translates to:
  /// **'Reload Stash\'s filters'**
  String get reloadWebFilters;

  /// No description provided for @newView.
  ///
  /// In en, this message translates to:
  /// **'New view'**
  String get newView;

  /// No description provided for @webFiltersUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Stash\'s filters unavailable'**
  String get webFiltersUnavailable;

  /// No description provided for @nameTheView.
  ///
  /// In en, this message translates to:
  /// **'Give the view a name'**
  String get nameTheView;

  /// No description provided for @editView.
  ///
  /// In en, this message translates to:
  /// **'Edit the view'**
  String get editView;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get nameRequired;

  /// No description provided for @searchOptional.
  ///
  /// In en, this message translates to:
  /// **'Search (optional)'**
  String get searchOptional;

  /// No description provided for @sortField.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortField;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @noFilterAll.
  ///
  /// In en, this message translates to:
  /// **'No filter (all {kind})'**
  String noFilterAll(Object kind);

  /// No description provided for @editFilter.
  ///
  /// In en, this message translates to:
  /// **'Edit the filter'**
  String get editFilter;

  /// No description provided for @tabsIntro.
  ///
  /// In en, this message translates to:
  /// **'Check up to {max} screens for the bottom bar (“More” always stays there, last). The others are in More. Drag to change the order; the first tab opens at launch.'**
  String tabsIntro(Object max);

  /// No description provided for @tabsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max} tabs'**
  String tabsCount(Object count, Object max);

  /// No description provided for @tab.
  ///
  /// In en, this message translates to:
  /// **'Tab'**
  String get tab;

  /// No description provided for @inMore.
  ///
  /// In en, this message translates to:
  /// **'In More'**
  String get inMore;

  /// No description provided for @byDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get byDefault;

  /// No description provided for @homeLayoutIntro.
  ///
  /// In en, this message translates to:
  /// **'Items stacked on the home page, in this order. With nothing checked, the default home is used; with a single view, it fills the page and gives it its name.'**
  String get homeLayoutIntro;

  /// No description provided for @dashboardLayoutIntro.
  ///
  /// In en, this message translates to:
  /// **'Rows of the default home (opened by the button at the top right of a custom home), in this order.'**
  String get dashboardLayoutIntro;

  /// No description provided for @defaultRows.
  ///
  /// In en, this message translates to:
  /// **'Default rows'**
  String get defaultRows;

  /// No description provided for @homeSection.
  ///
  /// In en, this message translates to:
  /// **'Home section'**
  String get homeSection;

  /// No description provided for @viewOf.
  ///
  /// In en, this message translates to:
  /// **'View · {kind}'**
  String viewOf(Object kind);

  /// No description provided for @errorWith.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWith(Object error);

  /// No description provided for @nothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet'**
  String get nothingYet;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more ({count})'**
  String showMore(Object count);

  /// No description provided for @serverUnreachableShort.
  ///
  /// In en, this message translates to:
  /// **'Server unreachable: {error}'**
  String serverUnreachableShort(Object error);

  /// No description provided for @countHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} hour} other{{count} hours}}'**
  String countHours(int count);

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @viewSaved.
  ///
  /// In en, this message translates to:
  /// **'View “{name}” saved'**
  String viewSaved(Object name);

  /// No description provided for @showOnHome.
  ///
  /// In en, this message translates to:
  /// **'Show on the home page'**
  String get showOnHome;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @saveAsNewView.
  ///
  /// In en, this message translates to:
  /// **'Save as a new view'**
  String get saveAsNewView;

  /// No description provided for @saveView.
  ///
  /// In en, this message translates to:
  /// **'Save the view'**
  String get saveView;

  /// No description provided for @noMarkers.
  ///
  /// In en, this message translates to:
  /// **'No markers'**
  String get noMarkers;

  /// No description provided for @noImages.
  ///
  /// In en, this message translates to:
  /// **'No images'**
  String get noImages;

  /// No description provided for @noDownloads.
  ///
  /// In en, this message translates to:
  /// **'No downloads.\n\nUse the download button of a scene, a group, a gallery or an image (in the viewer) to keep it on the phone.'**
  String get noDownloads;

  /// No description provided for @deleteFromPhoneQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete “{title}” from the phone?'**
  String deleteFromPhoneQuestion(Object title);

  /// No description provided for @groupScenesDeletedToo.
  ///
  /// In en, this message translates to:
  /// **'This group\'s scenes will be deleted too.'**
  String get groupScenesDeletedToo;

  /// No description provided for @downloadFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Failed: tap ⋮ to retry'**
  String get downloadFailedRetry;

  /// No description provided for @downloadQueued.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get downloadQueued;

  /// No description provided for @downloadRunning.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get downloadRunning;

  /// No description provided for @downloadProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading · {percent} %'**
  String downloadProgress(Object percent);

  /// No description provided for @resumeAt.
  ///
  /// In en, this message translates to:
  /// **'Resume at {time}'**
  String resumeAt(Object time);

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @fromStart.
  ///
  /// In en, this message translates to:
  /// **'From the start'**
  String get fromStart;

  /// No description provided for @forgetResumePosition.
  ///
  /// In en, this message translates to:
  /// **'Forget the resume position'**
  String get forgetResumePosition;

  /// No description provided for @resumePositionCleared.
  ///
  /// In en, this message translates to:
  /// **'Resume position cleared'**
  String get resumePositionCleared;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get fileSize;

  /// No description provided for @dimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get dimensions;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @framesPerSecondLabel.
  ///
  /// In en, this message translates to:
  /// **'Frames/s'**
  String get framesPerSecondLabel;

  /// No description provided for @bitRate.
  ///
  /// In en, this message translates to:
  /// **'Bit rate'**
  String get bitRate;

  /// No description provided for @megabitsPerSecond.
  ///
  /// In en, this message translates to:
  /// **'{value} Mb/s'**
  String megabitsPerSecond(Object value);

  /// No description provided for @offlineCopy.
  ///
  /// In en, this message translates to:
  /// **'Offline copy'**
  String get offlineCopy;

  /// No description provided for @noStream.
  ///
  /// In en, this message translates to:
  /// **'No stream available'**
  String get noStream;

  /// No description provided for @directStream.
  ///
  /// In en, this message translates to:
  /// **'Direct (original)'**
  String get directStream;

  /// No description provided for @directPlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'Direct playback failed, trying “{source}”'**
  String directPlaybackFailed(Object source);

  /// No description provided for @playbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Cannot play: {error}'**
  String playbackFailed(Object error);

  /// No description provided for @playbackError.
  ///
  /// In en, this message translates to:
  /// **'Playback error'**
  String get playbackError;

  /// No description provided for @coverGenerating.
  ///
  /// In en, this message translates to:
  /// **'Stash is generating the cover'**
  String get coverGenerating;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get playbackSpeed;

  /// No description provided for @useFrameAsCover.
  ///
  /// In en, this message translates to:
  /// **'Use this frame as the cover'**
  String get useFrameAsCover;

  /// No description provided for @addMarkerHere.
  ///
  /// In en, this message translates to:
  /// **'Add a marker here'**
  String get addMarkerHere;

  /// No description provided for @streams.
  ///
  /// In en, this message translates to:
  /// **'Streams'**
  String get streams;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @filterKind.
  ///
  /// In en, this message translates to:
  /// **'Filter: {kind}'**
  String filterKind(Object kind);

  /// No description provided for @allRatings.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get allRatings;

  /// No description provided for @allResolutions.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get allResolutions;

  /// No description provided for @withLabel.
  ///
  /// In en, this message translates to:
  /// **'With'**
  String get withLabel;

  /// No description provided for @withoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Without'**
  String get withoutLabel;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @anyValue.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get anyValue;

  /// No description provided for @confirmCount.
  ///
  /// In en, this message translates to:
  /// **'Confirm ({count})'**
  String confirmCount(Object count);

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @includeSubTags.
  ///
  /// In en, this message translates to:
  /// **'Include sub-tags'**
  String get includeSubTags;

  /// No description provided for @includeSubStudios.
  ///
  /// In en, this message translates to:
  /// **'Include sub-studios'**
  String get includeSubStudios;

  /// No description provided for @includeSubGroups.
  ///
  /// In en, this message translates to:
  /// **'Include sub-groups'**
  String get includeSubGroups;

  /// No description provided for @minRating.
  ///
  /// In en, this message translates to:
  /// **'Minimum rating'**
  String get minRating;

  /// No description provided for @minResolution.
  ///
  /// In en, this message translates to:
  /// **'Minimum resolution'**
  String get minResolution;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes)'**
  String get durationMinutes;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @watchStatus.
  ///
  /// In en, this message translates to:
  /// **'Watched'**
  String get watchStatus;

  /// No description provided for @cover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get cover;

  /// No description provided for @organized.
  ///
  /// In en, this message translates to:
  /// **'Organized'**
  String get organized;

  /// No description provided for @scrape.
  ///
  /// In en, this message translates to:
  /// **'Scrape'**
  String get scrape;

  /// No description provided for @editScene.
  ///
  /// In en, this message translates to:
  /// **'Edit the scene'**
  String get editScene;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @deathDate.
  ///
  /// In en, this message translates to:
  /// **'Death date'**
  String get deathDate;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @fakeTits.
  ///
  /// In en, this message translates to:
  /// **'Fake tits'**
  String get fakeTits;

  /// No description provided for @tattoos.
  ///
  /// In en, this message translates to:
  /// **'Tattoos'**
  String get tattoos;

  /// No description provided for @piercings.
  ///
  /// In en, this message translates to:
  /// **'Piercings'**
  String get piercings;

  /// No description provided for @editPerformer.
  ///
  /// In en, this message translates to:
  /// **'Edit the performer'**
  String get editPerformer;

  /// No description provided for @logo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logo;

  /// No description provided for @editStudio.
  ///
  /// In en, this message translates to:
  /// **'Edit the studio'**
  String get editStudio;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @parentTags.
  ///
  /// In en, this message translates to:
  /// **'Parent tags'**
  String get parentTags;

  /// No description provided for @editTag.
  ///
  /// In en, this message translates to:
  /// **'Edit the tag'**
  String get editTag;

  /// No description provided for @frontCover.
  ///
  /// In en, this message translates to:
  /// **'Front cover'**
  String get frontCover;

  /// No description provided for @backCover.
  ///
  /// In en, this message translates to:
  /// **'Back cover'**
  String get backCover;

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit the group'**
  String get editGroup;

  /// No description provided for @photographer.
  ///
  /// In en, this message translates to:
  /// **'Photographer'**
  String get photographer;

  /// No description provided for @editGallery.
  ///
  /// In en, this message translates to:
  /// **'Edit the gallery'**
  String get editGallery;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @endOptional.
  ///
  /// In en, this message translates to:
  /// **'End (optional)'**
  String get endOptional;

  /// No description provided for @primaryTag.
  ///
  /// In en, this message translates to:
  /// **'Primary tag'**
  String get primaryTag;

  /// No description provided for @otherTags.
  ///
  /// In en, this message translates to:
  /// **'Other tags'**
  String get otherTags;

  /// No description provided for @deleteMarker.
  ///
  /// In en, this message translates to:
  /// **'Delete the marker'**
  String get deleteMarker;

  /// No description provided for @newMarker.
  ///
  /// In en, this message translates to:
  /// **'New marker'**
  String get newMarker;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{label} is required'**
  String fieldRequired(Object label);

  /// No description provided for @dateHint.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get dateHint;

  /// No description provided for @dateFormatExpected.
  ///
  /// In en, this message translates to:
  /// **'{label}: {format} format expected'**
  String dateFormatExpected(Object label, Object format);

  /// No description provided for @integerExpected.
  ///
  /// In en, this message translates to:
  /// **'{label}: whole number expected'**
  String integerExpected(Object label);

  /// No description provided for @timeFormatExpected.
  ///
  /// In en, this message translates to:
  /// **'{label}: m:ss format expected'**
  String timeFormatExpected(Object label);

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addHint.
  ///
  /// In en, this message translates to:
  /// **'Add…'**
  String get addHint;

  /// No description provided for @questionOf.
  ///
  /// In en, this message translates to:
  /// **'{action}?'**
  String questionOf(Object action);

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// No description provided for @fromPhone.
  ///
  /// In en, this message translates to:
  /// **'From the phone'**
  String get fromPhone;

  /// No description provided for @fromUrl.
  ///
  /// In en, this message translates to:
  /// **'From a URL'**
  String get fromUrl;

  /// No description provided for @cannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get cannotBeUndone;

  /// No description provided for @discardChangesQuestion.
  ///
  /// In en, this message translates to:
  /// **'Discard the changes?'**
  String get discardChangesQuestion;

  /// No description provided for @continueEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get continueEditing;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get newGroup;

  /// No description provided for @newGallery.
  ///
  /// In en, this message translates to:
  /// **'New gallery'**
  String get newGallery;

  /// No description provided for @newPerformer.
  ///
  /// In en, this message translates to:
  /// **'New performer'**
  String get newPerformer;

  /// No description provided for @newStudio.
  ///
  /// In en, this message translates to:
  /// **'New studio'**
  String get newStudio;

  /// No description provided for @newTag.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get newTag;

  /// No description provided for @deletePerformer.
  ///
  /// In en, this message translates to:
  /// **'Delete the performer'**
  String get deletePerformer;

  /// No description provided for @deleteStudio.
  ///
  /// In en, this message translates to:
  /// **'Delete the studio'**
  String get deleteStudio;

  /// No description provided for @deleteTag.
  ///
  /// In en, this message translates to:
  /// **'Delete the tag'**
  String get deleteTag;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete the group'**
  String get deleteGroup;

  /// No description provided for @deleteGallery.
  ///
  /// In en, this message translates to:
  /// **'Delete the gallery'**
  String get deleteGallery;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @newImage.
  ///
  /// In en, this message translates to:
  /// **'New image'**
  String get newImage;

  /// No description provided for @nothingNewInResult.
  ///
  /// In en, this message translates to:
  /// **'Nothing new in this result'**
  String get nothingNewInResult;

  /// No description provided for @searchOn.
  ///
  /// In en, this message translates to:
  /// **'Search on {source}'**
  String searchOn(Object source);

  /// No description provided for @titleCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Title, code…'**
  String get titleCodeHint;

  /// No description provided for @scrapeWith.
  ///
  /// In en, this message translates to:
  /// **'Scrape with…'**
  String get scrapeWith;

  /// No description provided for @byFingerprintThenSearch.
  ///
  /// In en, this message translates to:
  /// **'By fingerprint, else by search'**
  String get byFingerprintThenSearch;

  /// No description provided for @bySearch.
  ///
  /// In en, this message translates to:
  /// **'By search'**
  String get bySearch;

  /// No description provided for @byScene.
  ///
  /// In en, this message translates to:
  /// **'by scene'**
  String get byScene;

  /// No description provided for @bySearchLower.
  ///
  /// In en, this message translates to:
  /// **'by search'**
  String get bySearchLower;

  /// No description provided for @scrapersHeader.
  ///
  /// In en, this message translates to:
  /// **'Scrapers'**
  String get scrapersHeader;

  /// No description provided for @noScraperConfigured.
  ///
  /// In en, this message translates to:
  /// **'No scraper or stash-box is set up for this type on the server (Settings > Metadata).'**
  String get noScraperConfigured;

  /// No description provided for @countResults.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} result} other{{count} results}}'**
  String countResults(int count);

  /// No description provided for @createdInStash.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} item created in Stash} other{{count} items created in Stash}}'**
  String createdInStash(int count);

  /// No description provided for @scrapeResultIntro.
  ///
  /// In en, this message translates to:
  /// **'Check the values to take. They fill the edit form and are only saved with “Save” (except the items to create, below).'**
  String get scrapeResultIntro;

  /// No description provided for @currentValue.
  ///
  /// In en, this message translates to:
  /// **'Current: {value}'**
  String currentValue(Object value);

  /// No description provided for @missingFromStash.
  ///
  /// In en, this message translates to:
  /// **'Missing from Stash'**
  String get missingFromStash;

  /// No description provided for @missingFromStashHint.
  ///
  /// In en, this message translates to:
  /// **'Checked items are created in Stash (with the scraper\'s information) on “Apply”, then linked.'**
  String get missingFromStashHint;

  /// No description provided for @createAndLink.
  ///
  /// In en, this message translates to:
  /// **'Create and link · {label}'**
  String createAndLink(Object label);

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @scrapeUrl.
  ///
  /// In en, this message translates to:
  /// **'Scrape a URL'**
  String get scrapeUrl;

  /// No description provided for @otherUrl.
  ///
  /// In en, this message translates to:
  /// **'Other URL…'**
  String get otherUrl;

  /// No description provided for @scrapeResult.
  ///
  /// In en, this message translates to:
  /// **'Scrape result'**
  String get scrapeResult;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
