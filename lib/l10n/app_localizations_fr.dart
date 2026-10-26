// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get download => 'Télécharger';

  @override
  String get downloads => 'Téléchargements';

  @override
  String get retry => 'Réessayer';

  @override
  String get show => 'Afficher';

  @override
  String get hide => 'Masquer';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get ok => 'OK';

  @override
  String get home => 'Accueil';

  @override
  String get more => 'Plus';

  @override
  String get settings => 'Paramètres';

  @override
  String get scenes => 'Scènes';

  @override
  String get performers => 'Performeurs';

  @override
  String get studios => 'Studios';

  @override
  String get groups => 'Groupes';

  @override
  String get galleries => 'Galeries';

  @override
  String get tags => 'Tags';

  @override
  String get markers => 'Marqueurs';

  @override
  String get images => 'Images';

  @override
  String get studio => 'Studio';

  @override
  String get group => 'Groupe';

  @override
  String get modeAny => 'Au moins un';

  @override
  String get modeAll => 'Tous';

  @override
  String get modeExclude => 'Aucun de';

  @override
  String get modeNone => 'Vide';

  @override
  String get modeNotNone => 'Non vide';

  @override
  String criterionAny(Object label, Object names) {
    return '$label : $names';
  }

  @override
  String criterionAll(Object label, Object names) {
    return '$label (tous) : $names';
  }

  @override
  String criterionExclude(Object label, Object names) {
    return '$label sauf : $names';
  }

  @override
  String get withoutPerformer => 'Sans performeur';

  @override
  String get withPerformer => 'Avec performeur';

  @override
  String get withoutTag => 'Sans tag';

  @override
  String get withTag => 'Avec tag';

  @override
  String get withoutStudio => 'Sans studio';

  @override
  String get withStudio => 'Avec studio';

  @override
  String get withoutGroup => 'Sans groupe';

  @override
  String get withGroup => 'Avec groupe';

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
      'scenes': 'Organisées',
      'other': 'Organisé',
    });
    return '$_temp0';
  }

  @override
  String notOrganizedState(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scenes': 'Non organisées',
      'other': 'Non organisé',
    });
    return '$_temp0';
  }

  @override
  String playedState(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scenes': 'Déjà vues',
      'other': 'Déjà vu',
    });
    return '$_temp0';
  }

  @override
  String notPlayedState(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scenes': 'Jamais vues',
      'other': 'Jamais vu',
    });
    return '$_temp0';
  }

  @override
  String get withMarkers => 'Avec marqueurs';

  @override
  String get withoutMarkers => 'Sans marqueurs';

  @override
  String get favoritePerformer => 'Performeur favori';

  @override
  String get noFavoritePerformer => 'Sans performeur favori';

  @override
  String get favorites => 'Favoris';

  @override
  String get notFavorites => 'Hors favoris';

  @override
  String get sectionStats => 'Statistiques';

  @override
  String get sectionResume => 'Reprendre la lecture';

  @override
  String get sectionRecent => 'Ajoutées récemment';

  @override
  String get sectionReleases => 'Sorties récentes';

  @override
  String get sectionFavoritePerformers => 'Performeurs favoris';

  @override
  String get sectionRandom => 'Au hasard';

  @override
  String get sectionGalleries => 'Galeries récentes';

  @override
  String sceneNumber(Object id) {
    return 'Scène $id';
  }

  @override
  String galleryNumber(Object id) {
    return 'Galerie $id';
  }

  @override
  String get genderMale => 'Homme';

  @override
  String get genderFemale => 'Femme';

  @override
  String get genderTransMale => 'Homme trans';

  @override
  String get genderTransFemale => 'Femme trans';

  @override
  String get genderIntersex => 'Intersexe';

  @override
  String get genderNonBinary => 'Non-binaire';

  @override
  String get bytesUnits => 'o,Ko,Mo,Go,To';

  @override
  String get sortCreatedAt => 'Date d\'ajout';

  @override
  String get sortReleaseDate => 'Date de sortie';

  @override
  String get sortDate => 'Date';

  @override
  String get sortTitle => 'Titre';

  @override
  String get sortName => 'Nom';

  @override
  String get sortRating => 'Note';

  @override
  String get sortLastPlayed => 'Dernière lecture';

  @override
  String get sortPlayCount => 'Nombre de lectures';

  @override
  String get sortOCounter => 'Compteur O';

  @override
  String get sortDuration => 'Durée';

  @override
  String get sortFileSize => 'Taille';

  @override
  String get sortRandom => 'Aléatoire';

  @override
  String get sortSceneCount => 'Nombre de scènes';

  @override
  String get sortImageCount => 'Nombre d\'images';

  @override
  String get sortBirthdate => 'Date de naissance';

  @override
  String get sortGroupOrder => 'Ordre dans le groupe';

  @override
  String get sortPath => 'Chemin';

  @override
  String get sortPosition => 'Position';

  @override
  String get sceneNotFound => 'Scène introuvable';

  @override
  String get performerNotFound => 'Performeur introuvable';

  @override
  String get studioNotFound => 'Studio introuvable';

  @override
  String get tagNotFound => 'Tag introuvable';

  @override
  String get groupNotFound => 'Groupe introuvable';

  @override
  String get galleryNotFound => 'Galerie introuvable';

  @override
  String get imageNotFound => 'Image introuvable';

  @override
  String serverUnreachable(Object error) {
    return 'Impossible de joindre le serveur : $error';
  }

  @override
  String accessDenied(Object status) {
    return 'Accès refusé (HTTP $status). Vérifiez la clé API.';
  }

  @override
  String httpError(Object status) {
    return 'Erreur HTTP $status';
  }

  @override
  String get invalidResponse =>
      'Réponse invalide : le serveur ne semble pas être Stash.';

  @override
  String get lockAtLaunchOnly => 'Au lancement uniquement';

  @override
  String get lockImmediately => 'Dès que l\'app passe en arrière-plan';

  @override
  String lockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Après $minutes minutes en arrière-plan',
      one: 'Après 1 minute en arrière-plan',
    );
    return '$_temp0';
  }

  @override
  String get notifDownloading => 'Téléchargement';

  @override
  String get notifDownloaded => 'Téléchargé';

  @override
  String get notifDownloadFailed => 'Échec du téléchargement';

  @override
  String get notifPaused => 'En pause';

  @override
  String githubError(Object status) {
    return 'GitHub a répondu $status';
  }

  @override
  String downloadRefused(Object status) {
    return 'Téléchargement refusé ($status)';
  }

  @override
  String get downloadIncomplete => 'Téléchargement incomplet';

  @override
  String get noServerConfigured => 'Aucun serveur configuré';

  @override
  String get fileUnavailable => 'Fichier indisponible';

  @override
  String imageNumber(Object id) {
    return 'Image $id';
  }

  @override
  String countItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '$count élément',
    );
    return '$_temp0';
  }

  @override
  String countScenes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scènes',
      one: '$count scène',
    );
    return '$_temp0';
  }

  @override
  String countPerformers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count performeurs',
      one: '$count performeur',
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
      other: '$count groupes',
      one: '$count groupe',
    );
    return '$_temp0';
  }

  @override
  String countGalleries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count galeries',
      one: '$count galerie',
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
      other: '$count marqueurs',
      one: '$count marqueur',
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
      other: '$count lectures',
      one: '$count lecture',
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
      other: '$age ans',
      one: '$age an',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Rechercher…';

  @override
  String get sort => 'Trier';

  @override
  String get descending => 'Décroissant';

  @override
  String get ascending => 'Croissant';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String framesPerSecond(Object fps) {
    return '$fps i/s';
  }

  @override
  String addedOn(Object date) {
    return 'Ajoutée le $date';
  }

  @override
  String get noRating => 'Pas de note';

  @override
  String starsOutOfFive(Object stars) {
    return '$stars / 5';
  }

  @override
  String get openScene => 'Ouvrir la scène';

  @override
  String get editMarker => 'Modifier le marqueur';

  @override
  String get downloadTitle => 'Télécharger ?';

  @override
  String downloadSceneQuestion(Object size) {
    return 'Télécharger cette scène pour la regarder hors ligne$size ?';
  }

  @override
  String downloadGroupQuestion(Object size) {
    return 'Télécharger toutes les scènes de ce groupe pour les regarder hors ligne$size ?';
  }

  @override
  String downloadGalleryQuestion(Object size) {
    return 'Télécharger toutes les images de cette galerie pour les regarder hors ligne$size ?';
  }

  @override
  String downloadImageQuestion(Object size) {
    return 'Télécharger cette image pour la regarder hors ligne$size ?';
  }

  @override
  String get downloadInBackground =>
      'Le téléchargement continue en arrière-plan.';

  @override
  String get preparingDownload => 'Préparation du téléchargement…';

  @override
  String get downloadStarted => 'Téléchargement lancé (Plus > Téléchargements)';

  @override
  String get downloadInProgress => 'Téléchargement en cours';

  @override
  String get connectionRestored => 'Connexion au serveur rétablie';

  @override
  String get offlineTitle => 'Hors ligne';

  @override
  String offlineMessage(Object url) {
    return 'Le serveur Stash ($url) est injoignable. Les scènes, groupes, galeries et images téléchargés restent disponibles.';
  }

  @override
  String get scanRunning => 'Scan de la bibliothèque…';

  @override
  String scanProgress(Object percent) {
    return 'Scan de la bibliothèque · $percent %';
  }

  @override
  String get scanFailed => 'Échec du scan';

  @override
  String get scanStopped => 'Scan arrêté · données actualisées';

  @override
  String get scanFinished => 'Scan terminé · données actualisées';

  @override
  String get stopScan => 'Arrêter le scan';

  @override
  String get lockedTitle => 'Stash est verrouillé';

  @override
  String get password => 'Mot de passe';

  @override
  String get wrongPassword => 'Mot de passe incorrect';

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get info => 'Infos';

  @override
  String get information => 'Informations';

  @override
  String get parentStudio => 'Studio parent';

  @override
  String get description => 'Description';

  @override
  String get links => 'Liens';

  @override
  String get favorite => 'Favori';

  @override
  String get disambiguation => 'Désambiguïsation';

  @override
  String get aliases => 'Alias';

  @override
  String get gender => 'Genre';

  @override
  String get birth => 'Naissance';

  @override
  String get country => 'Pays';

  @override
  String get ethnicity => 'Origine';

  @override
  String get height => 'Taille';

  @override
  String get measurements => 'Mensurations';

  @override
  String get hairColor => 'Cheveux';

  @override
  String get eyeColor => 'Yeux';

  @override
  String get date => 'Date';

  @override
  String get duration => 'Durée';

  @override
  String get director => 'Réalisateur';

  @override
  String get synopsis => 'Synopsis';

  @override
  String get path => 'Chemin';

  @override
  String get emptyGallery => 'Galerie vide';

  @override
  String get enterServerAddress => 'Saisissez l\'adresse du serveur.';

  @override
  String connectedTo(Object version) {
    return 'Connecté à Stash $version';
  }

  @override
  String get stashServer => 'Serveur Stash';

  @override
  String get connectPrompt => 'Connectez-vous à votre serveur Stash';

  @override
  String get serverAddress => 'Adresse du serveur';

  @override
  String get apiKeyOptional => 'Clé API (optionnelle)';

  @override
  String get apiKeyHelp =>
      'Stash > Paramètres > Sécurité > Clé API. Requise si l\'authentification est activée.';

  @override
  String get connect => 'Se connecter';

  @override
  String get scanLibraryQuestion => 'Scanner la bibliothèque ?';

  @override
  String get scanConfirmMessage =>
      'Stash va parcourir vos dossiers avec ses options de scan par défaut (Paramètres > Tâches). Le suivi s\'affiche en bas de l\'écran ; les pages se rechargeront à la fin.';

  @override
  String get scan => 'Scanner';

  @override
  String get homePage => 'Page d\'accueil';

  @override
  String get defaultHome => 'Accueil par défaut';

  @override
  String customHomeItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Personnalisé : $count éléments',
      one: 'Personnalisé : $count élément',
    );
    return '$_temp0';
  }

  @override
  String get savedViews => 'Vues enregistrées';

  @override
  String get noViews => 'Aucune';

  @override
  String countViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vues',
      one: '$count vue',
    );
    return '$_temp0';
  }

  @override
  String get downloadsSubtitle =>
      'Scènes, groupes, galeries et images hors ligne';

  @override
  String get displayHeader => 'Affichage';

  @override
  String get serverHeader => 'Serveur';

  @override
  String get applicationHeader => 'Application';

  @override
  String get tabsTitle => 'Onglets';

  @override
  String get sceneColumns => 'Colonnes de scènes (portrait)';

  @override
  String get longPressPreview => 'Aperçu vidéo par appui long';

  @override
  String get longPressPreviewSubtitle =>
      'Lit l\'aperçu d\'une scène en la maintenant';

  @override
  String get serverVersion => 'Version du serveur';

  @override
  String get scanLibrary => 'Scanner la bibliothèque';

  @override
  String get scanInProgressSubtitle =>
      'Scan en cours (suivi en bas de l\'écran)';

  @override
  String get scanSubtitle =>
      'Détecte les fichiers ajoutés, modifiés ou supprimés';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get logoutQuestion => 'Se déconnecter ?';

  @override
  String get logoutMessage =>
      'L\'adresse du serveur et la clé API seront oubliées.';

  @override
  String get appVersion => 'Version de l\'application';

  @override
  String get settingsSubtitle =>
      'Langue, lecteur popup, mot de passe, mises à jour';

  @override
  String get language => 'Langue';

  @override
  String get appLanguage => 'Langue de l\'application';

  @override
  String systemLanguage(Object name) {
    return 'Langue du système ($name)';
  }

  @override
  String get playbackHeader => 'Lecture';

  @override
  String get popupPlayer => 'Lecteur popup';

  @override
  String get popupPlayerSubtitle =>
      'La vidéo en cours continue dans une petite fenêtre quand vous quittez l\'application';

  @override
  String get privacyHeader => 'Confidentialité';

  @override
  String get hideInRecents => 'Masquer dans les applications récentes';

  @override
  String get hideInRecentsSubtitle =>
      'Aperçu noir dans le sélecteur d\'applications (bloque aussi les captures d\'écran)';

  @override
  String get createPassword => 'Créer un mot de passe';

  @override
  String get createPasswordSubtitle =>
      'Demandé à l\'ouverture de l\'application';

  @override
  String get changePassword => 'Modifier le mot de passe';

  @override
  String get removePassword => 'Supprimer le mot de passe';

  @override
  String get askPasswordAgain => 'Redemander le mot de passe';

  @override
  String get passwordRemoved => 'Mot de passe supprimé';

  @override
  String get passwordCreated => 'Mot de passe créé';

  @override
  String get passwordChanged => 'Mot de passe modifié';

  @override
  String get updatesHeader => 'Mises à jour';

  @override
  String get checkAtStartup => 'Rechercher au démarrage';

  @override
  String get checkAtStartupSubtitle =>
      'Propose les nouvelles versions publiées sur GitHub';

  @override
  String get checkForUpdate => 'Rechercher une mise à jour';

  @override
  String get passwordTooShort => 'Au moins 4 caractères';

  @override
  String get passwordsDiffer => 'Les mots de passe sont différents';

  @override
  String get create => 'Créer';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmation => 'Confirmation';

  @override
  String get forgottenPasswordHint =>
      'En cas d\'oubli, il faudra effacer les données de l\'application (et la reconfigurer).';

  @override
  String updateCheckFailed(Object error) {
    return 'Recherche impossible : $error';
  }

  @override
  String get upToDate => 'L\'application est à jour';

  @override
  String installFailed(Object error) {
    return 'Installation impossible : $error';
  }

  @override
  String versionAvailable(Object version) {
    return 'Version $version disponible';
  }

  @override
  String whatsNewIn(Object version) {
    return 'Nouveautés de la $version';
  }

  @override
  String get later => 'Plus tard';

  @override
  String get install => 'Installer';

  @override
  String installWithSize(Object size) {
    return 'Installer ($size)';
  }

  @override
  String downloadingVersion(Object version) {
    return 'Téléchargement de la $version';
  }

  @override
  String failedWith(Object error) {
    return 'Échec : $error';
  }

  @override
  String get installHint =>
      'Android demandera ensuite de confirmer l\'installation (et, la première fois, d\'autoriser Stash à installer des applications).';

  @override
  String get criterionFolder => 'dossier';

  @override
  String get criterionCustomFields => 'champs personnalisés';

  @override
  String deleteNamedQuestion(Object name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String webFilterOf(Object kind) {
    return 'Filtre de Stash (web) · $kind';
  }

  @override
  String get noFilter => 'sans filtre';

  @override
  String get viewsIntro =>
      'Créez une vue (scènes, performeurs, studios…) avec le bouton « Nouvelle vue », ou depuis l\'onglet Scènes (icône signet). Les filtres enregistrés dans l\'interface web de Stash apparaissent aussi (icône nuage) ; ils se modifient depuis le web.';

  @override
  String unsupportedWebFilters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count filtres web d\'un type inconnu de l\'app ne sont pas repris',
      one: '$count filtre web d\'un type inconnu de l\'app n\'est pas repris',
    );
    return '$_temp0';
  }

  @override
  String skippedCriteriaWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count filtres web utilisent des critères que l\'app ne sait pas reprendre (détail sous chaque filtre concerné). Ces critères sont ignorés : la vue affiche plus d\'éléments que sur le web.',
      one: 'Un filtre web utilise des critères que l\'app ne sait pas reprendre (détail sous le filtre concerné). Ces critères sont ignorés : la vue affiche plus d\'éléments que sur le web.',
    );
    return '$_temp0';
  }

  @override
  String get composeHomePages => 'Composer les pages d\'accueil';

  @override
  String get homeIsDefault => 'Accueil : par défaut';

  @override
  String homeItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Accueil : $count éléments',
      one: 'Accueil : $count élément',
    );
    return '$_temp0';
  }

  @override
  String get noSavedViews => 'Aucune vue enregistrée';

  @override
  String get homeIconHint =>
      'L\'icône maison ajoute une vue à la fin de la page d\'accueil, ou l\'en retire. L\'ordre, les sections et l\'accueil par défaut se règlent dans « Composer les pages d\'accueil ».';

  @override
  String get removeFromHome => 'Retirer de la page d\'accueil';

  @override
  String get addToHome => 'Ajouter à la page d\'accueil';

  @override
  String ignored(Object criteria) {
    return 'Ignoré : $criteria';
  }

  @override
  String get reloadWebFilters => 'Relire les filtres de Stash';

  @override
  String get newView => 'Nouvelle vue';

  @override
  String get webFiltersUnavailable => 'Filtres de Stash indisponibles';

  @override
  String get nameTheView => 'Donnez un nom à la vue';

  @override
  String get editView => 'Modifier la vue';

  @override
  String get content => 'Contenu';

  @override
  String get nameRequired => 'Nom *';

  @override
  String get searchOptional => 'Recherche (optionnelle)';

  @override
  String get sortField => 'Tri';

  @override
  String get filter => 'Filtre';

  @override
  String noFilterAll(Object kind) {
    return 'Sans filtre ($kind : tout)';
  }

  @override
  String get editFilter => 'Modifier le filtre';

  @override
  String tabsIntro(Object max) {
    return 'Cochez jusqu\'à $max écrans pour la barre du bas (« Plus » y reste toujours, en dernier). Les autres sont dans Plus. Faites glisser pour changer l\'ordre ; le premier onglet s\'ouvre au lancement.';
  }

  @override
  String tabsCount(Object count, Object max) {
    return '$count / $max onglets';
  }

  @override
  String get tab => 'Onglet';

  @override
  String get inMore => 'Dans Plus';

  @override
  String get byDefault => 'Par défaut';

  @override
  String get homeLayoutIntro =>
      'Éléments empilés sur la page d\'accueil, dans cet ordre. Sans rien de coché, l\'accueil par défaut est utilisé ; avec une seule vue, elle remplit la page et lui donne son nom.';

  @override
  String get dashboardLayoutIntro =>
      'Lignes de l\'accueil par défaut (ouvert par le bouton en haut à droite d\'un accueil personnalisé), dans cet ordre.';

  @override
  String get defaultRows => 'Lignes par défaut';

  @override
  String get homeSection => 'Section de l\'accueil';

  @override
  String viewOf(Object kind) {
    return 'Vue · $kind';
  }

  @override
  String errorWith(Object error) {
    return 'Erreur : $error';
  }

  @override
  String get nothingYet => 'Rien pour le moment';

  @override
  String showMore(Object count) {
    return 'Afficher plus ($count)';
  }

  @override
  String serverUnreachableShort(Object error) {
    return 'Serveur injoignable : $error';
  }

  @override
  String countHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures',
      one: '$count heure',
    );
    return '$_temp0';
  }

  @override
  String get seeAll => 'Voir tout';

  @override
  String viewSaved(Object name) {
    return 'Vue « $name » enregistrée';
  }

  @override
  String get showOnHome => 'Afficher sur la page d\'accueil';

  @override
  String get clear => 'Effacer';

  @override
  String get filters => 'Filtres';

  @override
  String get saveAsNewView => 'Enregistrer comme nouvelle vue';

  @override
  String get saveView => 'Enregistrer la vue';

  @override
  String get noMarkers => 'Aucun marqueur';

  @override
  String get noImages => 'Aucune image';

  @override
  String get noDownloads =>
      'Aucun téléchargement.\n\nUtilisez le bouton de téléchargement d\'une scène, d\'un groupe, d\'une galerie ou d\'une image (dans la visionneuse) pour la garder sur le téléphone.';

  @override
  String deleteFromPhoneQuestion(Object title) {
    return 'Supprimer « $title » du téléphone ?';
  }

  @override
  String get groupScenesDeletedToo =>
      'Les scènes de ce groupe seront aussi supprimées.';

  @override
  String get downloadFailedRetry => 'Échec : touchez ⋮ pour réessayer';

  @override
  String get downloadQueued => 'En attente';

  @override
  String get downloadRunning => 'Téléchargement…';

  @override
  String downloadProgress(Object percent) {
    return 'Téléchargement · $percent %';
  }

  @override
  String resumeAt(Object time) {
    return 'Reprendre à $time';
  }

  @override
  String get play => 'Lire';

  @override
  String get fromStart => 'Depuis le début';

  @override
  String get forgetResumePosition => 'Oublier la position de reprise';

  @override
  String get resumePositionCleared => 'Position de reprise effacée';

  @override
  String get code => 'Code';

  @override
  String get file => 'Fichier';

  @override
  String get fileSize => 'Taille';

  @override
  String get dimensions => 'Dimensions';

  @override
  String get format => 'Format';

  @override
  String get video => 'Vidéo';

  @override
  String get audio => 'Audio';

  @override
  String get framesPerSecondLabel => 'Images/s';

  @override
  String get bitRate => 'Débit';

  @override
  String megabitsPerSecond(Object value) {
    return '$value Mb/s';
  }

  @override
  String get offlineCopy => 'Copie hors ligne';

  @override
  String get noStream => 'Aucun flux disponible';

  @override
  String get directStream => 'Direct (original)';

  @override
  String directPlaybackFailed(Object source) {
    return 'Lecture directe impossible, essai de « $source »';
  }

  @override
  String playbackFailed(Object error) {
    return 'Lecture impossible : $error';
  }

  @override
  String get playbackError => 'Erreur de lecture';

  @override
  String get coverGenerating => 'Couverture en cours de génération par Stash';

  @override
  String get playbackSpeed => 'Vitesse de lecture';

  @override
  String get useFrameAsCover => 'Utiliser cette image comme couverture';

  @override
  String get addMarkerHere => 'Ajouter un marqueur ici';

  @override
  String get streams => 'Flux';

  @override
  String get pause => 'Pause';

  @override
  String filterKind(Object kind) {
    return 'Filtrer : $kind';
  }

  @override
  String get allRatings => 'Toutes';

  @override
  String get allResolutions => 'Toutes';

  @override
  String get withLabel => 'Avec';

  @override
  String get withoutLabel => 'Sans';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get anyValue => 'Tous';

  @override
  String confirmCount(Object count) {
    return 'Valider ($count)';
  }

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get includeSubTags => 'Inclure les sous-tags';

  @override
  String get includeSubStudios => 'Inclure les sous-studios';

  @override
  String get includeSubGroups => 'Inclure les sous-groupes';

  @override
  String get minRating => 'Note minimale';

  @override
  String get minResolution => 'Résolution minimale';

  @override
  String get durationMinutes => 'Durée (minutes)';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get apply => 'Appliquer';

  @override
  String get choose => 'Choisir';

  @override
  String get watchStatus => 'Lecture';

  @override
  String get cover => 'Couverture';

  @override
  String get organized => 'Organisée';

  @override
  String get scrape => 'Scraper';

  @override
  String get editScene => 'Modifier la scène';

  @override
  String get photo => 'Photo';

  @override
  String get deathDate => 'Date de décès';

  @override
  String get weight => 'Poids';

  @override
  String get fakeTits => 'Implants';

  @override
  String get tattoos => 'Tatouages';

  @override
  String get piercings => 'Piercings';

  @override
  String get editPerformer => 'Modifier le performeur';

  @override
  String get logo => 'Logo';

  @override
  String get editStudio => 'Modifier le studio';

  @override
  String get image => 'Image';

  @override
  String get parentTags => 'Tags parents';

  @override
  String get editTag => 'Modifier le tag';

  @override
  String get frontCover => 'Jaquette (recto)';

  @override
  String get backCover => 'Jaquette (verso)';

  @override
  String get editGroup => 'Modifier le groupe';

  @override
  String get photographer => 'Photographe';

  @override
  String get editGallery => 'Modifier la galerie';

  @override
  String get start => 'Début';

  @override
  String get endOptional => 'Fin (optionnelle)';

  @override
  String get primaryTag => 'Tag principal';

  @override
  String get otherTags => 'Autres tags';

  @override
  String get deleteMarker => 'Supprimer le marqueur';

  @override
  String get newMarker => 'Nouveau marqueur';

  @override
  String fieldRequired(Object label) {
    return '$label est obligatoire';
  }

  @override
  String get dateHint => 'AAAA-MM-JJ';

  @override
  String dateFormatExpected(Object label, Object format) {
    return '$label : format $format attendu';
  }

  @override
  String integerExpected(Object label) {
    return '$label : nombre entier attendu';
  }

  @override
  String timeFormatExpected(Object label) {
    return '$label : format m:ss attendu';
  }

  @override
  String get change => 'Changer';

  @override
  String get add => 'Ajouter';

  @override
  String get addHint => 'Ajouter…';

  @override
  String questionOf(Object action) {
    return '$action ?';
  }

  @override
  String get saved => 'Enregistré';

  @override
  String get deleted => 'Supprimé';

  @override
  String get use => 'Utiliser';

  @override
  String get fromPhone => 'Depuis le téléphone';

  @override
  String get fromUrl => 'Depuis une URL';

  @override
  String get cannotBeUndone => 'Cette action est définitive.';

  @override
  String get discardChangesQuestion => 'Abandonner les modifications ?';

  @override
  String get continueEditing => 'Continuer';

  @override
  String get discard => 'Abandonner';

  @override
  String get newGroup => 'Nouveau groupe';

  @override
  String get newGallery => 'Nouvelle galerie';

  @override
  String get untitled => 'Sans titre';

  @override
  String get newImage => 'Nouvelle image';

  @override
  String get nothingNewInResult => 'Rien de nouveau dans ce résultat';

  @override
  String searchOn(Object source) {
    return 'Rechercher sur $source';
  }

  @override
  String get titleCodeHint => 'Titre, code…';

  @override
  String get scrapeWith => 'Scraper avec…';

  @override
  String get byFingerprintThenSearch => 'Par empreinte, sinon par recherche';

  @override
  String get bySearch => 'Par recherche';

  @override
  String get byScene => 'par la scène';

  @override
  String get bySearchLower => 'par recherche';

  @override
  String get scrapersHeader => 'Scrapers';

  @override
  String get noScraperConfigured =>
      'Aucun scraper ni stash-box n\'est configuré pour ce type sur le serveur (Paramètres > Métadonnées).';

  @override
  String countResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '$count résultat',
    );
    return '$_temp0';
  }

  @override
  String createdInStash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments créés dans Stash',
      one: '$count élément créé dans Stash',
    );
    return '$_temp0';
  }

  @override
  String get scrapeResultIntro =>
      'Cochez les valeurs à reprendre. Elles remplissent le formulaire de modification et ne sont enregistrées qu\'avec « Enregistrer » (sauf les éléments à créer, plus bas).';

  @override
  String currentValue(Object value) {
    return 'Actuel : $value';
  }

  @override
  String get missingFromStash => 'Absents de Stash';

  @override
  String get missingFromStashHint =>
      'Les éléments cochés sont créés dans Stash (avec les informations du scraper) dès « Appliquer », puis liés.';

  @override
  String createAndLink(Object label) {
    return 'Créer et lier · $label';
  }

  @override
  String get search => 'Rechercher';

  @override
  String get scrapeUrl => 'Scraper une URL';

  @override
  String get otherUrl => 'Autre URL…';

  @override
  String get scrapeResult => 'Résultat du scraping';
}
