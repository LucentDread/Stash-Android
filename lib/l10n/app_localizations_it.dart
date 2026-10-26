// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get cancel => 'Annulla';

  @override
  String get close => 'Chiudi';

  @override
  String get download => 'Scarica';

  @override
  String get downloads => 'Download';

  @override
  String get retry => 'Riprova';

  @override
  String get show => 'Mostra';

  @override
  String get hide => 'Nascondi';

  @override
  String get save => 'Salva';

  @override
  String get delete => 'Elimina';

  @override
  String get edit => 'Modifica';

  @override
  String get ok => 'OK';

  @override
  String get home => 'Home';

  @override
  String get more => 'Altro';

  @override
  String get settings => 'Impostazioni';

  @override
  String get scenes => 'Scene';

  @override
  String get performers => 'Attori';

  @override
  String get studios => 'Studi';

  @override
  String get groups => 'Gruppi';

  @override
  String get galleries => 'Gallerie';

  @override
  String get tags => 'Tag';

  @override
  String get markers => 'Marcatori';

  @override
  String get images => 'Immagini';

  @override
  String get studio => 'Studio';

  @override
  String get group => 'Gruppo';

  @override
  String get modeAny => 'Almeno uno';

  @override
  String get modeAll => 'Tutti';

  @override
  String get modeExclude => 'Nessuno di';

  @override
  String get modeNone => 'Vuoto';

  @override
  String get modeNotNone => 'Non vuoto';

  @override
  String criterionAny(Object label, Object names) {
    return '$label: $names';
  }

  @override
  String criterionAll(Object label, Object names) {
    return '$label (tutti): $names';
  }

  @override
  String criterionExclude(Object label, Object names) {
    return '$label tranne: $names';
  }

  @override
  String get withoutPerformer => 'Senza attori';

  @override
  String get withPerformer => 'Con attori';

  @override
  String get withoutTag => 'Senza tag';

  @override
  String get withTag => 'Con tag';

  @override
  String get withoutStudio => 'Senza studio';

  @override
  String get withStudio => 'Con studio';

  @override
  String get withoutGroup => 'Senza gruppo';

  @override
  String get withGroup => 'Con gruppo';

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
      'scenes': 'Ordinate',
      'other': 'Ordinato',
    });
    return '$_temp0';
  }

  @override
  String notOrganizedState(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scenes': 'Non ordinate',
      'other': 'Non ordinato',
    });
    return '$_temp0';
  }

  @override
  String playedState(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scenes': 'Già viste',
      'other': 'Già visto',
    });
    return '$_temp0';
  }

  @override
  String notPlayedState(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scenes': 'Mai viste',
      'other': 'Mai visto',
    });
    return '$_temp0';
  }

  @override
  String get withMarkers => 'Con marcatori';

  @override
  String get withoutMarkers => 'Senza marcatori';

  @override
  String get favoritePerformer => 'Attore preferito';

  @override
  String get noFavoritePerformer => 'Senza attori preferiti';

  @override
  String get favorites => 'Preferiti';

  @override
  String get notFavorites => 'Non preferiti';

  @override
  String get sectionStats => 'Statistiche';

  @override
  String get sectionResume => 'Continua a guardare';

  @override
  String get sectionRecent => 'Aggiunte di recente';

  @override
  String get sectionReleases => 'Uscite recenti';

  @override
  String get sectionFavoritePerformers => 'Attori preferiti';

  @override
  String get sectionRandom => 'Casuale';

  @override
  String get sectionGalleries => 'Gallerie recenti';

  @override
  String sceneNumber(Object id) {
    return 'Scena $id';
  }

  @override
  String galleryNumber(Object id) {
    return 'Galleria $id';
  }

  @override
  String get genderMale => 'Uomo';

  @override
  String get genderFemale => 'Donna';

  @override
  String get genderTransMale => 'Uomo transgender';

  @override
  String get genderTransFemale => 'Donna transgender';

  @override
  String get genderIntersex => 'Intersessualità';

  @override
  String get genderNonBinary => 'Non binario';

  @override
  String get bytesUnits => 'B,KB,MB,GB,TB';

  @override
  String get sortCreatedAt => 'Data di aggiunta';

  @override
  String get sortReleaseDate => 'Data di uscita';

  @override
  String get sortDate => 'Data';

  @override
  String get sortTitle => 'Titolo';

  @override
  String get sortName => 'Nome';

  @override
  String get sortRating => 'Valutazione';

  @override
  String get sortLastPlayed => 'Ultima visualizzazione';

  @override
  String get sortPlayCount => 'Visualizzazioni';

  @override
  String get sortOCounter => 'Contatore O';

  @override
  String get sortDuration => 'Durata';

  @override
  String get sortFileSize => 'Dimensione';

  @override
  String get sortRandom => 'Casuale';

  @override
  String get sortSceneCount => 'Numero di scene';

  @override
  String get sortImageCount => 'Numero di immagini';

  @override
  String get sortBirthdate => 'Data di nascita';

  @override
  String get sortGroupOrder => 'Ordine nel gruppo';

  @override
  String get sortPath => 'Percorso';

  @override
  String get sortPosition => 'Posizione';

  @override
  String get sceneNotFound => 'Scena non trovata';

  @override
  String get performerNotFound => 'Attore non trovato';

  @override
  String get studioNotFound => 'Studio non trovato';

  @override
  String get tagNotFound => 'Tag non trovato';

  @override
  String get groupNotFound => 'Gruppo non trovato';

  @override
  String get galleryNotFound => 'Galleria non trovata';

  @override
  String get imageNotFound => 'Immagine non trovata';

  @override
  String serverUnreachable(Object error) {
    return 'Impossibile raggiungere il server: $error';
  }

  @override
  String accessDenied(Object status) {
    return 'Accesso negato (HTTP $status). Controlla la chiave API.';
  }

  @override
  String httpError(Object status) {
    return 'Errore HTTP $status';
  }

  @override
  String get invalidResponse =>
      'Risposta non valida: il server non sembra essere Stash.';

  @override
  String get lockAtLaunchOnly => 'Solo all\'avvio';

  @override
  String get lockImmediately => 'Appena l\'app passa in background';

  @override
  String lockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Dopo $minutes minuti in background',
      one: 'Dopo 1 minuto in background',
    );
    return '$_temp0';
  }

  @override
  String get notifDownloading => 'Download in corso';

  @override
  String get notifDownloaded => 'Scaricato';

  @override
  String get notifDownloadFailed => 'Download non riuscito';

  @override
  String get notifPaused => 'In pausa';

  @override
  String githubError(Object status) {
    return 'GitHub ha risposto $status';
  }

  @override
  String downloadRefused(Object status) {
    return 'Download rifiutato ($status)';
  }

  @override
  String get downloadIncomplete => 'Download incompleto';

  @override
  String get noServerConfigured => 'Nessun server configurato';

  @override
  String get fileUnavailable => 'File non disponibile';

  @override
  String imageNumber(Object id) {
    return 'Immagine $id';
  }

  @override
  String countItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi',
      one: '$count elemento',
    );
    return '$_temp0';
  }

  @override
  String countScenes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scene',
      one: '$count scena',
    );
    return '$_temp0';
  }

  @override
  String countPerformers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attori',
      one: '$count attore',
    );
    return '$_temp0';
  }

  @override
  String countStudios(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count studi',
      one: '$count studio',
    );
    return '$_temp0';
  }

  @override
  String countGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gruppi',
      one: '$count gruppo',
    );
    return '$_temp0';
  }

  @override
  String countGalleries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gallerie',
      one: '$count galleria',
    );
    return '$_temp0';
  }

  @override
  String countTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tag',
      one: '$count tag',
    );
    return '$_temp0';
  }

  @override
  String countMarkers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count marcatori',
      one: '$count marcatore',
    );
    return '$_temp0';
  }

  @override
  String countImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count immagini',
      one: '$count immagine',
    );
    return '$_temp0';
  }

  @override
  String countPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visualizzazioni',
      one: '$count visualizzazione',
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
      other: '$age anni',
      one: '$age anno',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Cerca…';

  @override
  String get sort => 'Ordina';

  @override
  String get descending => 'Discendente';

  @override
  String get ascending => 'Ascendente';

  @override
  String get noResults => 'Nessun risultato';

  @override
  String framesPerSecond(Object fps) {
    return '$fps fps';
  }

  @override
  String addedOn(Object date) {
    return 'Aggiunta il $date';
  }

  @override
  String starsOutOfFive(Object stars) {
    return '$stars / 5';
  }

  @override
  String get openScene => 'Apri la scena';

  @override
  String get editMarker => 'Modifica il marcatore';

  @override
  String get downloadTitle => 'Scaricare?';

  @override
  String downloadSceneQuestion(Object size) {
    return 'Scaricare questa scena per guardarla offline$size?';
  }

  @override
  String downloadGroupQuestion(Object size) {
    return 'Scaricare tutte le scene di questo gruppo per guardarle offline$size?';
  }

  @override
  String downloadGalleryQuestion(Object size) {
    return 'Scaricare tutte le immagini di questa galleria per vederle offline$size?';
  }

  @override
  String downloadImageQuestion(Object size) {
    return 'Scaricare questa immagine per vederla offline$size?';
  }

  @override
  String get downloadInBackground => 'Il download continua in background.';

  @override
  String get preparingDownload => 'Preparazione del download…';

  @override
  String get downloadStarted => 'Download avviato (Altro > Download)';

  @override
  String get downloadInProgress => 'Download in corso';

  @override
  String get connectionRestored => 'Connessione al server ripristinata';

  @override
  String get offlineTitle => 'Offline';

  @override
  String offlineMessage(Object url) {
    return 'Il server Stash ($url) non è raggiungibile. Scene, gruppi, gallerie e immagini scaricati restano disponibili.';
  }

  @override
  String get scanRunning => 'Scansione della libreria…';

  @override
  String scanProgress(Object percent) {
    return 'Scansione della libreria · $percent %';
  }

  @override
  String get scanFailed => 'Scansione non riuscita';

  @override
  String get scanStopped => 'Scansione interrotta · dati aggiornati';

  @override
  String get scanFinished => 'Scansione completata · dati aggiornati';

  @override
  String get stopScan => 'Interrompi la scansione';

  @override
  String get lockedTitle => 'Stash è bloccato';

  @override
  String get password => 'Password';

  @override
  String get wrongPassword => 'Password errata';

  @override
  String get unlock => 'Sblocca';

  @override
  String get clearRating => 'Rimuovi la valutazione';

  @override
  String get notRated => 'Non valutato';

  @override
  String get select => 'Seleziona';

  @override
  String get selectAll => 'Tutti';

  @override
  String get selectNone => 'Nessuno';

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selezionati',
      one: '$count selezionato',
    );
    return '$_temp0';
  }

  @override
  String downloadSelectionQuestion(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Scaricare i $count elementi selezionati per vederli offline?',
      one: 'Scaricare l\'elemento selezionato per vederlo offline?',
    );
    return '$_temp0';
  }

  @override
  String get info => 'Info';

  @override
  String get information => 'Informazioni';

  @override
  String get parentStudio => 'Studio principale';

  @override
  String get description => 'Descrizione';

  @override
  String get links => 'Link';

  @override
  String get favorite => 'Preferito';

  @override
  String get disambiguation => 'Disambiguazione';

  @override
  String get aliases => 'Alias';

  @override
  String get gender => 'Genere';

  @override
  String get birth => 'Nascita';

  @override
  String get country => 'Paese';

  @override
  String get ethnicity => 'Etnia';

  @override
  String get height => 'Altezza';

  @override
  String get measurements => 'Misure';

  @override
  String get hairColor => 'Capelli';

  @override
  String get eyeColor => 'Occhi';

  @override
  String get date => 'Data';

  @override
  String get duration => 'Durata';

  @override
  String get director => 'Regista';

  @override
  String get synopsis => 'Sinossi';

  @override
  String get path => 'Percorso';

  @override
  String get emptyGallery => 'Galleria vuota';

  @override
  String get enterServerAddress => 'Inserisci l\'indirizzo del server.';

  @override
  String connectedTo(Object version) {
    return 'Connesso a Stash $version';
  }

  @override
  String get stashServer => 'Server Stash';

  @override
  String get connectPrompt => 'Connettiti al tuo server Stash';

  @override
  String get serverAddress => 'Indirizzo del server';

  @override
  String get apiKeyOptional => 'Chiave API (facoltativa)';

  @override
  String get apiKeyHelp =>
      'Stash > Impostazioni > Sicurezza > Chiave API. Necessaria se l\'autenticazione è attiva.';

  @override
  String get connect => 'Connetti';

  @override
  String get scanLibraryQuestion => 'Scansionare la libreria?';

  @override
  String get scanConfirmMessage =>
      'Stash esaminerà le tue cartelle con le opzioni di scansione predefinite (Impostazioni > Attività). Lo stato appare in fondo allo schermo; al termine le pagine si ricaricano.';

  @override
  String get scan => 'Scansiona';

  @override
  String get homePage => 'Pagina iniziale';

  @override
  String get defaultHome => 'Home predefinita';

  @override
  String customHomeItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Personalizzata: $count elementi',
      one: 'Personalizzata: $count elemento',
    );
    return '$_temp0';
  }

  @override
  String get savedViews => 'Viste salvate';

  @override
  String get noViews => 'Nessuna';

  @override
  String countViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viste',
      one: '$count vista',
    );
    return '$_temp0';
  }

  @override
  String get downloadsSubtitle => 'Scene, gruppi, gallerie e immagini offline';

  @override
  String get displayHeader => 'Visualizzazione';

  @override
  String get serverHeader => 'Server';

  @override
  String get applicationHeader => 'Applicazione';

  @override
  String get tabsTitle => 'Schede';

  @override
  String get sceneColumns => 'Colonne di scene (verticale)';

  @override
  String get longPressPreview => 'Anteprima video con pressione prolungata';

  @override
  String get longPressPreviewSubtitle =>
      'Riproduce l\'anteprima di una scena mentre la tieni premuta';

  @override
  String get serverVersion => 'Versione del server';

  @override
  String get scanLibrary => 'Scansiona la libreria';

  @override
  String get scanInProgressSubtitle =>
      'Scansione in corso (stato in fondo allo schermo)';

  @override
  String get scanSubtitle => 'Rileva i file aggiunti, modificati o eliminati';

  @override
  String get logout => 'Esci';

  @override
  String get logoutQuestion => 'Uscire?';

  @override
  String get logoutMessage =>
      'L\'indirizzo del server e la chiave API verranno dimenticati.';

  @override
  String get appVersion => 'Versione dell\'app';

  @override
  String get settingsSubtitle =>
      'Lingua, lettore popup, password, aggiornamenti';

  @override
  String get language => 'Lingua';

  @override
  String get appLanguage => 'Lingua dell\'app';

  @override
  String systemLanguage(Object name) {
    return 'Lingua di sistema ($name)';
  }

  @override
  String get playbackHeader => 'Riproduzione';

  @override
  String get popupPlayer => 'Lettore popup';

  @override
  String get popupPlayerSubtitle =>
      'Il video in riproduzione continua in una piccola finestra quando esci dall\'app';

  @override
  String get privacyHeader => 'Privacy';

  @override
  String get hideInRecents => 'Nascondi nelle app recenti';

  @override
  String get hideInRecentsSubtitle =>
      'Anteprima nera nel selettore delle app (blocca anche gli screenshot)';

  @override
  String get createPassword => 'Crea una password';

  @override
  String get createPasswordSubtitle => 'Richiesta all\'apertura dell\'app';

  @override
  String get changePassword => 'Modifica la password';

  @override
  String get removePassword => 'Rimuovi la password';

  @override
  String get askPasswordAgain => 'Richiedi di nuovo la password';

  @override
  String get passwordRemoved => 'Password rimossa';

  @override
  String get passwordCreated => 'Password creata';

  @override
  String get passwordChanged => 'Password modificata';

  @override
  String get updatesHeader => 'Aggiornamenti';

  @override
  String get checkAtStartup => 'Controlla all\'avvio';

  @override
  String get checkAtStartupSubtitle =>
      'Propone le nuove versioni pubblicate su GitHub';

  @override
  String get checkForUpdate => 'Cerca un aggiornamento';

  @override
  String get passwordTooShort => 'Almeno 4 caratteri';

  @override
  String get passwordsDiffer => 'Le password non coincidono';

  @override
  String get create => 'Crea';

  @override
  String get currentPassword => 'Password attuale';

  @override
  String get newPassword => 'Nuova password';

  @override
  String get confirmation => 'Conferma';

  @override
  String get forgottenPasswordHint =>
      'Se la dimentichi, dovrai cancellare i dati dell\'app (e configurarla di nuovo).';

  @override
  String updateCheckFailed(Object error) {
    return 'Impossibile controllare: $error';
  }

  @override
  String get upToDate => 'L\'app è aggiornata';

  @override
  String installFailed(Object error) {
    return 'Impossibile installare: $error';
  }

  @override
  String versionAvailable(Object version) {
    return 'Versione $version disponibile';
  }

  @override
  String whatsNewIn(Object version) {
    return 'Novità della $version';
  }

  @override
  String get later => 'Più tardi';

  @override
  String get install => 'Installa';

  @override
  String installWithSize(Object size) {
    return 'Installa ($size)';
  }

  @override
  String downloadingVersion(Object version) {
    return 'Download della $version';
  }

  @override
  String failedWith(Object error) {
    return 'Non riuscito: $error';
  }

  @override
  String get installHint =>
      'Android chiederà poi di confermare l\'installazione (e, la prima volta, di consentire a Stash di installare app).';

  @override
  String get criterionFolder => 'cartella';

  @override
  String get criterionCustomFields => 'campi personalizzati';

  @override
  String deleteNamedQuestion(Object name) {
    return 'Eliminare «$name»?';
  }

  @override
  String webFilterOf(Object kind) {
    return 'Filtro di Stash (web) · $kind';
  }

  @override
  String get noFilter => 'senza filtro';

  @override
  String get viewsIntro =>
      'Crea una vista (scene, attori, studi…) con il pulsante «Nuova vista» o dalla scheda Scene (icona segnalibro). Anche i filtri salvati nell\'interfaccia web di Stash compaiono qui (icona nuvola); si modificano dal web.';

  @override
  String unsupportedWebFilters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count filtri web di un tipo sconosciuto all\'app non vengono ripresi',
      one:
          '$count filtro web di un tipo sconosciuto all\'app non viene ripreso',
    );
    return '$_temp0';
  }

  @override
  String skippedCriteriaWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count filtri web usano criteri che l\'app non sa applicare (elencati sotto ciascun filtro). Vengono ignorati: la vista mostra più elementi che sul web.',
      one: 'Un filtro web usa criteri che l\'app non sa applicare (elencati sotto il filtro). Vengono ignorati: la vista mostra più elementi che sul web.',
    );
    return '$_temp0';
  }

  @override
  String get composeHomePages => 'Componi le pagine iniziali';

  @override
  String get homeIsDefault => 'Home: predefinita';

  @override
  String homeItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Home: $count elementi',
      one: 'Home: $count elemento',
    );
    return '$_temp0';
  }

  @override
  String get noSavedViews => 'Nessuna vista salvata';

  @override
  String get homeIconHint =>
      'L\'icona casa aggiunge una vista in fondo alla pagina iniziale, o la toglie. Ordine, sezioni e home predefinita si impostano in «Componi le pagine iniziali».';

  @override
  String get removeFromHome => 'Togli dalla pagina iniziale';

  @override
  String get addToHome => 'Aggiungi alla pagina iniziale';

  @override
  String ignored(Object criteria) {
    return 'Ignorati: $criteria';
  }

  @override
  String get reloadWebFilters => 'Ricarica i filtri di Stash';

  @override
  String get newView => 'Nuova vista';

  @override
  String get webFiltersUnavailable => 'Filtri di Stash non disponibili';

  @override
  String get nameTheView => 'Dai un nome alla vista';

  @override
  String get editView => 'Modifica la vista';

  @override
  String get content => 'Contenuto';

  @override
  String get nameRequired => 'Nome *';

  @override
  String get searchOptional => 'Ricerca (facoltativa)';

  @override
  String get sortField => 'Ordinamento';

  @override
  String get filter => 'Filtro';

  @override
  String noFilterAll(Object kind) {
    return 'Senza filtro ($kind: tutto)';
  }

  @override
  String get editFilter => 'Modifica il filtro';

  @override
  String tabsIntro(Object max) {
    return 'Seleziona fino a $max schermate per la barra in basso («Altro» resta sempre lì, per ultimo). Le altre sono in Altro. Trascina per cambiare l\'ordine; la prima scheda si apre all\'avvio.';
  }

  @override
  String tabsCount(Object count, Object max) {
    return '$count / $max schede';
  }

  @override
  String get tab => 'Scheda';

  @override
  String get inMore => 'In Altro';

  @override
  String get byDefault => 'Predefinite';

  @override
  String get homeLayoutIntro =>
      'Elementi impilati nella pagina iniziale, in quest\'ordine. Se non selezioni nulla si usa la home predefinita; con una sola vista, questa riempie la pagina e le dà il suo nome.';

  @override
  String get dashboardLayoutIntro =>
      'Righe della home predefinita (aperta dal pulsante in alto a destra di una home personalizzata), in quest\'ordine.';

  @override
  String get defaultRows => 'Righe predefinite';

  @override
  String get homeSection => 'Sezione della home';

  @override
  String viewOf(Object kind) {
    return 'Vista · $kind';
  }

  @override
  String errorWith(Object error) {
    return 'Errore: $error';
  }

  @override
  String get nothingYet => 'Ancora niente';

  @override
  String showMore(Object count) {
    return 'Mostra altro ($count)';
  }

  @override
  String serverUnreachableShort(Object error) {
    return 'Server non raggiungibile: $error';
  }

  @override
  String countHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore',
      one: '$count ora',
    );
    return '$_temp0';
  }

  @override
  String get seeAll => 'Vedi tutto';

  @override
  String viewSaved(Object name) {
    return 'Vista «$name» salvata';
  }

  @override
  String get showOnHome => 'Mostra nella pagina iniziale';

  @override
  String get clear => 'Cancella';

  @override
  String get filters => 'Filtri';

  @override
  String get saveAsNewView => 'Salva come nuova vista';

  @override
  String get saveView => 'Salva la vista';

  @override
  String get noMarkers => 'Nessun marcatore';

  @override
  String get noImages => 'Nessuna immagine';

  @override
  String get noDownloads =>
      'Nessun download.\n\nUsa il pulsante di download di una scena, un gruppo, una galleria o un\'immagine (nel visualizzatore) per tenerla sul telefono.';

  @override
  String deleteFromPhoneQuestion(Object title) {
    return 'Eliminare «$title» dal telefono?';
  }

  @override
  String get groupScenesDeletedToo =>
      'Anche le scene di questo gruppo verranno eliminate.';

  @override
  String get downloadFailedRetry => 'Non riuscito: tocca ⋮ per riprovare';

  @override
  String get downloadQueued => 'In attesa';

  @override
  String get downloadRunning => 'Download in corso…';

  @override
  String downloadProgress(Object percent) {
    return 'Download · $percent %';
  }

  @override
  String resumeAt(Object time) {
    return 'Riprendi da $time';
  }

  @override
  String get play => 'Riproduci';

  @override
  String get fromStart => 'Dall\'inizio';

  @override
  String get forgetResumePosition => 'Dimentica la posizione di ripresa';

  @override
  String get resumePositionCleared => 'Posizione di ripresa cancellata';

  @override
  String get code => 'Codice';

  @override
  String get file => 'File';

  @override
  String get fileSize => 'Dimensione';

  @override
  String get dimensions => 'Dimensioni';

  @override
  String get format => 'Formato';

  @override
  String get video => 'Video';

  @override
  String get audio => 'Audio';

  @override
  String get framesPerSecondLabel => 'Fotogrammi/s';

  @override
  String get bitRate => 'Bitrate';

  @override
  String megabitsPerSecond(Object value) {
    return '$value Mb/s';
  }

  @override
  String get offlineCopy => 'Copia offline';

  @override
  String get noStream => 'Nessun flusso disponibile';

  @override
  String get directStream => 'Diretto (originale)';

  @override
  String directPlaybackFailed(Object source) {
    return 'Riproduzione diretta non riuscita, provo «$source»';
  }

  @override
  String playbackFailed(Object error) {
    return 'Impossibile riprodurre: $error';
  }

  @override
  String get playbackError => 'Errore di riproduzione';

  @override
  String get coverGenerating => 'Stash sta generando la copertina';

  @override
  String get playbackSpeed => 'Velocità di riproduzione';

  @override
  String get useFrameAsCover => 'Usa questo fotogramma come copertina';

  @override
  String get addMarkerHere => 'Aggiungi un marcatore qui';

  @override
  String get streams => 'Flussi';

  @override
  String get pause => 'Pausa';

  @override
  String get soundOn => 'Attiva l\'audio';

  @override
  String get soundOff => 'Disattiva l\'audio';

  @override
  String filterKind(Object kind) {
    return 'Filtra: $kind';
  }

  @override
  String get allRatings => 'Tutte';

  @override
  String get allResolutions => 'Tutte';

  @override
  String get withLabel => 'Con';

  @override
  String get withoutLabel => 'Senza';

  @override
  String get yes => 'Sì';

  @override
  String get no => 'No';

  @override
  String get anyValue => 'Tutti';

  @override
  String confirmCount(Object count) {
    return 'Conferma ($count)';
  }

  @override
  String get clearAll => 'Cancella tutto';

  @override
  String get includeSubTags => 'Includi i sotto-tag';

  @override
  String get includeSubStudios => 'Includi i sotto-studi';

  @override
  String get includeSubGroups => 'Includi i sottogruppi';

  @override
  String get minRating => 'Valutazione minima';

  @override
  String get minResolution => 'Risoluzione minima';

  @override
  String get durationMinutes => 'Durata (minuti)';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get apply => 'Applica';

  @override
  String get choose => 'Scegli';

  @override
  String get watchStatus => 'Visione';

  @override
  String get cover => 'Copertina';

  @override
  String get organized => 'Ordinata';

  @override
  String get scrape => 'Scrape';

  @override
  String get editScene => 'Modifica la scena';

  @override
  String get photo => 'Foto';

  @override
  String get deathDate => 'Data di morte';

  @override
  String get weight => 'Peso';

  @override
  String get fakeTits => 'Tette finte';

  @override
  String get tattoos => 'Tatuaggi';

  @override
  String get piercings => 'Piercing';

  @override
  String get editPerformer => 'Modifica l\'attore';

  @override
  String get logo => 'Logo';

  @override
  String get editStudio => 'Modifica lo studio';

  @override
  String get image => 'Immagine';

  @override
  String get parentTags => 'Tag principali';

  @override
  String get editTag => 'Modifica il tag';

  @override
  String get frontCover => 'Copertina (fronte)';

  @override
  String get backCover => 'Copertina (retro)';

  @override
  String get editGroup => 'Modifica il gruppo';

  @override
  String get photographer => 'Fotografo';

  @override
  String get editGallery => 'Modifica la galleria';

  @override
  String get start => 'Inizio';

  @override
  String get endOptional => 'Fine (facoltativa)';

  @override
  String get primaryTag => 'Tag principale';

  @override
  String get otherTags => 'Altri tag';

  @override
  String get deleteMarker => 'Elimina il marcatore';

  @override
  String get newMarker => 'Nuovo marcatore';

  @override
  String fieldRequired(Object label) {
    return '$label è obbligatorio';
  }

  @override
  String get dateHint => 'AAAA-MM-GG';

  @override
  String dateFormatExpected(Object label, Object format) {
    return '$label: formato $format previsto';
  }

  @override
  String integerExpected(Object label) {
    return '$label: numero intero previsto';
  }

  @override
  String timeFormatExpected(Object label) {
    return '$label: formato m:ss previsto';
  }

  @override
  String get change => 'Cambia';

  @override
  String get add => 'Aggiungi';

  @override
  String get addHint => 'Aggiungi…';

  @override
  String questionOf(Object action) {
    return '$action?';
  }

  @override
  String get saved => 'Salvato';

  @override
  String get deleted => 'Eliminato';

  @override
  String get use => 'Usa';

  @override
  String get fromPhone => 'Dal telefono';

  @override
  String get fromUrl => 'Da un URL';

  @override
  String get cannotBeUndone => 'Questa azione è definitiva.';

  @override
  String get discardChangesQuestion => 'Annullare le modifiche?';

  @override
  String get continueEditing => 'Continua';

  @override
  String get discard => 'Annulla modifiche';

  @override
  String get newGroup => 'Nuovo gruppo';

  @override
  String get newGallery => 'Nuova galleria';

  @override
  String get newPerformer => 'Nuovo attore';

  @override
  String get newStudio => 'Nuovo studio';

  @override
  String get newTag => 'Nuovo tag';

  @override
  String get deletePerformer => 'Elimina l\'attore';

  @override
  String get deleteStudio => 'Elimina lo studio';

  @override
  String get deleteTag => 'Elimina il tag';

  @override
  String get deleteGroup => 'Elimina il gruppo';

  @override
  String get deleteGallery => 'Elimina la galleria';

  @override
  String createNamed(Object name) {
    return 'Crea «$name»';
  }

  @override
  String createdNamed(Object name) {
    return '«$name» creato in Stash';
  }

  @override
  String get untitled => 'Senza titolo';

  @override
  String get newImage => 'Nuova immagine';

  @override
  String get nothingNewInResult => 'Niente di nuovo in questo risultato';

  @override
  String searchOn(Object source) {
    return 'Cerca su $source';
  }

  @override
  String get titleCodeHint => 'Titolo, codice…';

  @override
  String get scrapeWith => 'Scrape con…';

  @override
  String get byFingerprintThenSearch => 'Per impronta, altrimenti per ricerca';

  @override
  String get bySearch => 'Per ricerca';

  @override
  String get byScene => 'dalla scena';

  @override
  String get bySearchLower => 'per ricerca';

  @override
  String get scrapersHeader => 'Scraper';

  @override
  String get noScraperConfigured =>
      'Nessuno scraper o stash-box è configurato per questo tipo sul server (Impostazioni > Metadati).';

  @override
  String countResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count risultati',
      one: '$count risultato',
    );
    return '$_temp0';
  }

  @override
  String createdInStash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi creati in Stash',
      one: '$count elemento creato in Stash',
    );
    return '$_temp0';
  }

  @override
  String get scrapeResultIntro =>
      'Seleziona i valori da riprendere. Compilano il modulo di modifica e vengono salvati solo con «Salva» (tranne gli elementi da creare, più sotto).';

  @override
  String currentValue(Object value) {
    return 'Attuale: $value';
  }

  @override
  String get missingFromStash => 'Assenti da Stash';

  @override
  String get missingFromStashHint =>
      'Gli elementi selezionati vengono creati in Stash (con le informazioni dello scraper) con «Applica», poi collegati.';

  @override
  String createAndLink(Object label) {
    return 'Crea e collega · $label';
  }

  @override
  String get search => 'Cerca';

  @override
  String get scrapeUrl => 'Scrape di un URL';

  @override
  String get otherUrl => 'Altro URL…';

  @override
  String get scrapeResult => 'Risultato dello scraping';
}
