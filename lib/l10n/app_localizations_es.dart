// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Cerrar';

  @override
  String get download => 'Descargar';

  @override
  String get downloads => 'Descargas';

  @override
  String get retry => 'Reintentar';

  @override
  String get show => 'Mostrar';

  @override
  String get hide => 'Ocultar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get ok => 'Aceptar';

  @override
  String get home => 'Inicio';

  @override
  String get more => 'Más';

  @override
  String get settings => 'Ajustes';

  @override
  String get scenes => 'Escenas';

  @override
  String get performers => 'Actores';

  @override
  String get studios => 'Estudios';

  @override
  String get groups => 'Grupos';

  @override
  String get galleries => 'Galerías';

  @override
  String get tags => 'Etiquetas';

  @override
  String get markers => 'Marcadores';

  @override
  String get images => 'Imágenes';

  @override
  String get studio => 'Estudio';

  @override
  String get group => 'Grupo';

  @override
  String get modeAny => 'Al menos uno';

  @override
  String get modeAll => 'Todos';

  @override
  String get modeExclude => 'Ninguno de';

  @override
  String get modeNone => 'Vacío';

  @override
  String get modeNotNone => 'No vacío';

  @override
  String criterionAny(Object label, Object names) {
    return '$label: $names';
  }

  @override
  String criterionAll(Object label, Object names) {
    return '$label (todos): $names';
  }

  @override
  String criterionExclude(Object label, Object names) {
    return '$label excepto: $names';
  }

  @override
  String get withoutPerformer => 'Sin actores';

  @override
  String get withPerformer => 'Con actores';

  @override
  String get withoutTag => 'Sin etiquetas';

  @override
  String get withTag => 'Con etiquetas';

  @override
  String get withoutStudio => 'Sin estudio';

  @override
  String get withStudio => 'Con estudio';

  @override
  String get withoutGroup => 'Sin grupo';

  @override
  String get withGroup => 'Con grupo';

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
      'scenes': 'Clasificadas',
      'other': 'Clasificado',
    });
    return '$_temp0';
  }

  @override
  String notOrganizedState(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scenes': 'Sin clasificar',
      'other': 'Sin clasificar',
    });
    return '$_temp0';
  }

  @override
  String playedState(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scenes': 'Vistas',
      'other': 'Visto',
    });
    return '$_temp0';
  }

  @override
  String notPlayedState(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scenes': 'Nunca vistas',
      'other': 'Nunca visto',
    });
    return '$_temp0';
  }

  @override
  String get withMarkers => 'Con marcadores';

  @override
  String get withoutMarkers => 'Sin marcadores';

  @override
  String get favoritePerformer => 'Actor favorito';

  @override
  String get noFavoritePerformer => 'Sin actores favoritos';

  @override
  String get favorites => 'Favoritos';

  @override
  String get notFavorites => 'No favoritos';

  @override
  String get sectionStats => 'Estadísticas';

  @override
  String get sectionResume => 'Seguir viendo';

  @override
  String get sectionRecent => 'Añadidas recientemente';

  @override
  String get sectionReleases => 'Publicadas recientemente';

  @override
  String get sectionFavoritePerformers => 'Actores favoritos';

  @override
  String get sectionRandom => 'Aleatorio';

  @override
  String get sectionGalleries => 'Galerías recientes';

  @override
  String sceneNumber(Object id) {
    return 'Escena $id';
  }

  @override
  String galleryNumber(Object id) {
    return 'Galería $id';
  }

  @override
  String get genderMale => 'Varón';

  @override
  String get genderFemale => 'Mujer';

  @override
  String get genderTransMale => 'Varón transgénero';

  @override
  String get genderTransFemale => 'Mujer transgénero';

  @override
  String get genderIntersex => 'Intersexual';

  @override
  String get genderNonBinary => 'No binario';

  @override
  String get bytesUnits => 'B,KB,MB,GB,TB';

  @override
  String get sortCreatedAt => 'Fecha de creación';

  @override
  String get sortReleaseDate => 'Fecha de publicación';

  @override
  String get sortDate => 'Fecha';

  @override
  String get sortTitle => 'Título';

  @override
  String get sortName => 'Nombre';

  @override
  String get sortRating => 'Puntuación';

  @override
  String get sortLastPlayed => 'Última reproducción';

  @override
  String get sortPlayCount => 'Reproducciones';

  @override
  String get sortOCounter => 'Contador O';

  @override
  String get sortDuration => 'Duración';

  @override
  String get sortFileSize => 'Tamaño';

  @override
  String get sortRandom => 'Aleatorio';

  @override
  String get sortSceneCount => 'Número de escenas';

  @override
  String get sortImageCount => 'Número de imágenes';

  @override
  String get sortBirthdate => 'Fecha de nacimiento';

  @override
  String get sortGroupOrder => 'Orden en el grupo';

  @override
  String get sortPath => 'Ruta';

  @override
  String get sortPosition => 'Posición';

  @override
  String get sceneNotFound => 'Escena no encontrada';

  @override
  String get performerNotFound => 'Actor no encontrado';

  @override
  String get studioNotFound => 'Estudio no encontrado';

  @override
  String get tagNotFound => 'Etiqueta no encontrada';

  @override
  String get groupNotFound => 'Grupo no encontrado';

  @override
  String get galleryNotFound => 'Galería no encontrada';

  @override
  String get imageNotFound => 'Imagen no encontrada';

  @override
  String serverUnreachable(Object error) {
    return 'No se puede contactar con el servidor: $error';
  }

  @override
  String accessDenied(Object status) {
    return 'Acceso denegado (HTTP $status). Comprueba la clave API.';
  }

  @override
  String httpError(Object status) {
    return 'Error HTTP $status';
  }

  @override
  String get invalidResponse =>
      'Respuesta no válida: el servidor no parece ser Stash.';

  @override
  String get lockAtLaunchOnly => 'Solo al iniciar';

  @override
  String get lockImmediately => 'En cuanto la app pasa a segundo plano';

  @override
  String lockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Tras $minutes minutos en segundo plano',
      one: 'Tras 1 minuto en segundo plano',
    );
    return '$_temp0';
  }

  @override
  String get notifDownloading => 'Descargando';

  @override
  String get notifDownloaded => 'Descargado';

  @override
  String get notifDownloadFailed => 'Error en la descarga';

  @override
  String get notifPaused => 'En pausa';

  @override
  String githubError(Object status) {
    return 'GitHub respondió $status';
  }

  @override
  String downloadRefused(Object status) {
    return 'Descarga rechazada ($status)';
  }

  @override
  String get downloadIncomplete => 'Descarga incompleta';

  @override
  String get noServerConfigured => 'Ningún servidor configurado';

  @override
  String get fileUnavailable => 'Archivo no disponible';

  @override
  String imageNumber(Object id) {
    return 'Imagen $id';
  }

  @override
  String countItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos',
      one: '$count elemento',
    );
    return '$_temp0';
  }

  @override
  String countScenes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count escenas',
      one: '$count escena',
    );
    return '$_temp0';
  }

  @override
  String countPerformers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actores',
      one: '$count actor',
    );
    return '$_temp0';
  }

  @override
  String countStudios(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estudios',
      one: '$count estudio',
    );
    return '$_temp0';
  }

  @override
  String countGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grupos',
      one: '$count grupo',
    );
    return '$_temp0';
  }

  @override
  String countGalleries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count galerías',
      one: '$count galería',
    );
    return '$_temp0';
  }

  @override
  String countTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count etiquetas',
      one: '$count etiqueta',
    );
    return '$_temp0';
  }

  @override
  String countMarkers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count marcadores',
      one: '$count marcador',
    );
    return '$_temp0';
  }

  @override
  String countImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count imágenes',
      one: '$count imagen',
    );
    return '$_temp0';
  }

  @override
  String countPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reproducciones',
      one: '$count reproducción',
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
      other: '$age años',
      one: '$age año',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Buscar…';

  @override
  String get sort => 'Ordenar';

  @override
  String get descending => 'Descendente';

  @override
  String get ascending => 'Ascendente';

  @override
  String get noResults => 'Sin resultados';

  @override
  String framesPerSecond(Object fps) {
    return '$fps fps';
  }

  @override
  String addedOn(Object date) {
    return 'Añadida el $date';
  }

  @override
  String starsOutOfFive(Object stars) {
    return '$stars / 5';
  }

  @override
  String get openScene => 'Abrir la escena';

  @override
  String get editMarker => 'Editar el marcador';

  @override
  String get downloadTitle => '¿Descargar?';

  @override
  String downloadSceneQuestion(Object size) {
    return '¿Descargar esta escena para verla sin conexión$size?';
  }

  @override
  String downloadGroupQuestion(Object size) {
    return '¿Descargar todas las escenas de este grupo para verlas sin conexión$size?';
  }

  @override
  String downloadGalleryQuestion(Object size) {
    return '¿Descargar todas las imágenes de esta galería para verlas sin conexión$size?';
  }

  @override
  String downloadImageQuestion(Object size) {
    return '¿Descargar esta imagen para verla sin conexión$size?';
  }

  @override
  String get downloadInBackground => 'La descarga continúa en segundo plano.';

  @override
  String get preparingDownload => 'Preparando la descarga…';

  @override
  String get downloadStarted => 'Descarga iniciada (Más > Descargas)';

  @override
  String get downloadInProgress => 'Descargando';

  @override
  String get connectionRestored => 'Conexión con el servidor restablecida';

  @override
  String get offlineTitle => 'Sin conexión';

  @override
  String offlineMessage(Object url) {
    return 'No se puede contactar con el servidor Stash ($url). Las escenas, grupos, galerías e imágenes descargados siguen disponibles.';
  }

  @override
  String get scanRunning => 'Escaneando la biblioteca…';

  @override
  String scanProgress(Object percent) {
    return 'Escaneando la biblioteca · $percent %';
  }

  @override
  String get scanFailed => 'Error en el escaneo';

  @override
  String get scanStopped => 'Escaneo detenido · datos actualizados';

  @override
  String get scanFinished => 'Escaneo terminado · datos actualizados';

  @override
  String get stopScan => 'Detener el escaneo';

  @override
  String get lockedTitle => 'Stash está bloqueado';

  @override
  String get password => 'Contraseña';

  @override
  String get wrongPassword => 'Contraseña incorrecta';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get clearRating => 'Quitar la puntuación';

  @override
  String get notRated => 'Sin puntuar';

  @override
  String get info => 'Info';

  @override
  String get information => 'Información';

  @override
  String get parentStudio => 'Estudio principal';

  @override
  String get description => 'Descripción';

  @override
  String get links => 'Enlaces';

  @override
  String get favorite => 'Favorito';

  @override
  String get disambiguation => 'Desambiguación';

  @override
  String get aliases => 'Alias';

  @override
  String get gender => 'Género';

  @override
  String get birth => 'Nacimiento';

  @override
  String get country => 'País';

  @override
  String get ethnicity => 'Origen étnico';

  @override
  String get height => 'Estatura';

  @override
  String get measurements => 'Medidas';

  @override
  String get hairColor => 'Pelo';

  @override
  String get eyeColor => 'Ojos';

  @override
  String get date => 'Fecha';

  @override
  String get duration => 'Duración';

  @override
  String get director => 'Director';

  @override
  String get synopsis => 'Sinopsis';

  @override
  String get path => 'Ruta';

  @override
  String get emptyGallery => 'Galería vacía';

  @override
  String get enterServerAddress => 'Introduce la dirección del servidor.';

  @override
  String connectedTo(Object version) {
    return 'Conectado a Stash $version';
  }

  @override
  String get stashServer => 'Servidor Stash';

  @override
  String get connectPrompt => 'Conéctate a tu servidor Stash';

  @override
  String get serverAddress => 'Dirección del servidor';

  @override
  String get apiKeyOptional => 'Clave API (opcional)';

  @override
  String get apiKeyHelp =>
      'Stash > Preferencias > Seguridad > Clave API. Necesaria si la autenticación está activada.';

  @override
  String get connect => 'Conectar';

  @override
  String get scanLibraryQuestion => '¿Escanear la biblioteca?';

  @override
  String get scanConfirmMessage =>
      'Stash recorrerá tus carpetas con sus opciones de escaneo predeterminadas (Preferencias > Tareas). El progreso aparece en la parte inferior; al terminar, las páginas se recargan.';

  @override
  String get scan => 'Escanear';

  @override
  String get homePage => 'Página de inicio';

  @override
  String get defaultHome => 'Inicio predeterminado';

  @override
  String customHomeItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Personalizado: $count elementos',
      one: 'Personalizado: $count elemento',
    );
    return '$_temp0';
  }

  @override
  String get savedViews => 'Vistas guardadas';

  @override
  String get noViews => 'Ninguna';

  @override
  String countViews(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vistas',
      one: '$count vista',
    );
    return '$_temp0';
  }

  @override
  String get downloadsSubtitle =>
      'Escenas, grupos, galerías e imágenes sin conexión';

  @override
  String get displayHeader => 'Visualización';

  @override
  String get serverHeader => 'Servidor';

  @override
  String get applicationHeader => 'Aplicación';

  @override
  String get tabsTitle => 'Pestañas';

  @override
  String get sceneColumns => 'Columnas de escenas (vertical)';

  @override
  String get longPressPreview => 'Vista previa al mantener pulsado';

  @override
  String get longPressPreviewSubtitle =>
      'Reproduce la vista previa de una escena mientras la mantienes pulsada';

  @override
  String get serverVersion => 'Versión del servidor';

  @override
  String get scanLibrary => 'Escanear la biblioteca';

  @override
  String get scanInProgressSubtitle =>
      'Escaneo en curso (progreso en la parte inferior)';

  @override
  String get scanSubtitle =>
      'Detecta archivos añadidos, modificados o eliminados';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get logoutQuestion => '¿Cerrar sesión?';

  @override
  String get logoutMessage =>
      'Se olvidarán la dirección del servidor y la clave API.';

  @override
  String get appVersion => 'Versión de la app';

  @override
  String get settingsSubtitle =>
      'Idioma, reproductor emergente, contraseña, actualizaciones';

  @override
  String get language => 'Idioma';

  @override
  String get appLanguage => 'Idioma de la app';

  @override
  String systemLanguage(Object name) {
    return 'Idioma del sistema ($name)';
  }

  @override
  String get playbackHeader => 'Reproducción';

  @override
  String get popupPlayer => 'Reproductor emergente';

  @override
  String get popupPlayerSubtitle =>
      'El vídeo en curso sigue en una ventana pequeña cuando sales de la app';

  @override
  String get privacyHeader => 'Privacidad';

  @override
  String get hideInRecents => 'Ocultar en aplicaciones recientes';

  @override
  String get hideInRecentsSubtitle =>
      'Vista previa negra en el selector de apps (también bloquea las capturas de pantalla)';

  @override
  String get createPassword => 'Crear una contraseña';

  @override
  String get createPasswordSubtitle => 'Se pide al abrir la app';

  @override
  String get changePassword => 'Cambiar la contraseña';

  @override
  String get removePassword => 'Quitar la contraseña';

  @override
  String get askPasswordAgain => 'Volver a pedir la contraseña';

  @override
  String get passwordRemoved => 'Contraseña quitada';

  @override
  String get passwordCreated => 'Contraseña creada';

  @override
  String get passwordChanged => 'Contraseña cambiada';

  @override
  String get updatesHeader => 'Actualizaciones';

  @override
  String get checkAtStartup => 'Buscar al iniciar';

  @override
  String get checkAtStartupSubtitle =>
      'Ofrece las nuevas versiones publicadas en GitHub';

  @override
  String get checkForUpdate => 'Buscar una actualización';

  @override
  String get passwordTooShort => 'Al menos 4 caracteres';

  @override
  String get passwordsDiffer => 'Las contraseñas no coinciden';

  @override
  String get create => 'Crear';

  @override
  String get currentPassword => 'Contraseña actual';

  @override
  String get newPassword => 'Nueva contraseña';

  @override
  String get confirmation => 'Confirmación';

  @override
  String get forgottenPasswordHint =>
      'Si la olvidas, tendrás que borrar los datos de la app (y volver a configurarla).';

  @override
  String updateCheckFailed(Object error) {
    return 'No se pudo buscar: $error';
  }

  @override
  String get upToDate => 'La app está actualizada';

  @override
  String installFailed(Object error) {
    return 'No se pudo instalar: $error';
  }

  @override
  String versionAvailable(Object version) {
    return 'Versión $version disponible';
  }

  @override
  String whatsNewIn(Object version) {
    return 'Novedades de la $version';
  }

  @override
  String get later => 'Más tarde';

  @override
  String get install => 'Instalar';

  @override
  String installWithSize(Object size) {
    return 'Instalar ($size)';
  }

  @override
  String downloadingVersion(Object version) {
    return 'Descargando la $version';
  }

  @override
  String failedWith(Object error) {
    return 'Error: $error';
  }

  @override
  String get installHint =>
      'Android pedirá después confirmar la instalación (y, la primera vez, permitir que Stash instale aplicaciones).';

  @override
  String get criterionFolder => 'carpeta';

  @override
  String get criterionCustomFields => 'campos personalizados';

  @override
  String deleteNamedQuestion(Object name) {
    return '¿Eliminar «$name»?';
  }

  @override
  String webFilterOf(Object kind) {
    return 'Filtro de Stash (web) · $kind';
  }

  @override
  String get noFilter => 'sin filtro';

  @override
  String get viewsIntro =>
      'Crea una vista (escenas, actores, estudios…) con el botón «Nueva vista» o desde la pestaña Escenas (icono de marcador). Los filtros guardados en la interfaz web de Stash también aparecen (icono de nube); se editan desde la web.';

  @override
  String unsupportedWebFilters(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count filtros web de un tipo desconocido para la app no se incluyen',
      one: '$count filtro web de un tipo desconocido para la app no se incluye',
    );
    return '$_temp0';
  }

  @override
  String skippedCriteriaWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count filtros web usan criterios que la app no puede aplicar (indicados bajo cada filtro). Se ignoran: la vista muestra más elementos que en la web.',
      one: 'Un filtro web usa criterios que la app no puede aplicar (indicados bajo el filtro). Se ignoran: la vista muestra más elementos que en la web.',
    );
    return '$_temp0';
  }

  @override
  String get composeHomePages => 'Componer las páginas de inicio';

  @override
  String get homeIsDefault => 'Inicio: predeterminado';

  @override
  String homeItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Inicio: $count elementos',
      one: 'Inicio: $count elemento',
    );
    return '$_temp0';
  }

  @override
  String get noSavedViews => 'No hay vistas guardadas';

  @override
  String get homeIconHint =>
      'El icono de la casa añade una vista al final de la página de inicio, o la quita. El orden, las secciones y el inicio predeterminado se ajustan en «Componer las páginas de inicio».';

  @override
  String get removeFromHome => 'Quitar de la página de inicio';

  @override
  String get addToHome => 'Añadir a la página de inicio';

  @override
  String ignored(Object criteria) {
    return 'Ignorados: $criteria';
  }

  @override
  String get reloadWebFilters => 'Recargar los filtros de Stash';

  @override
  String get newView => 'Nueva vista';

  @override
  String get webFiltersUnavailable => 'Filtros de Stash no disponibles';

  @override
  String get nameTheView => 'Ponle un nombre a la vista';

  @override
  String get editView => 'Editar la vista';

  @override
  String get content => 'Contenido';

  @override
  String get nameRequired => 'Nombre *';

  @override
  String get searchOptional => 'Búsqueda (opcional)';

  @override
  String get sortField => 'Orden';

  @override
  String get filter => 'Filtro';

  @override
  String noFilterAll(Object kind) {
    return 'Sin filtro ($kind: todo)';
  }

  @override
  String get editFilter => 'Editar el filtro';

  @override
  String tabsIntro(Object max) {
    return 'Marca hasta $max pantallas para la barra inferior («Más» siempre se queda, al final). Las demás están en Más. Arrastra para cambiar el orden; la primera pestaña se abre al iniciar.';
  }

  @override
  String tabsCount(Object count, Object max) {
    return '$count / $max pestañas';
  }

  @override
  String get tab => 'Pestaña';

  @override
  String get inMore => 'En Más';

  @override
  String get byDefault => 'Predeterminado';

  @override
  String get homeLayoutIntro =>
      'Elementos apilados en la página de inicio, en este orden. Sin nada marcado se usa el inicio predeterminado; con una sola vista, esta ocupa la página y le da su nombre.';

  @override
  String get dashboardLayoutIntro =>
      'Filas del inicio predeterminado (se abre con el botón de arriba a la derecha de un inicio personalizado), en este orden.';

  @override
  String get defaultRows => 'Filas predeterminadas';

  @override
  String get homeSection => 'Sección del inicio';

  @override
  String viewOf(Object kind) {
    return 'Vista · $kind';
  }

  @override
  String errorWith(Object error) {
    return 'Error: $error';
  }

  @override
  String get nothingYet => 'Nada por ahora';

  @override
  String showMore(Object count) {
    return 'Mostrar más ($count)';
  }

  @override
  String serverUnreachableShort(Object error) {
    return 'Servidor inaccesible: $error';
  }

  @override
  String countHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '$count hora',
    );
    return '$_temp0';
  }

  @override
  String get seeAll => 'Ver todo';

  @override
  String viewSaved(Object name) {
    return 'Vista «$name» guardada';
  }

  @override
  String get showOnHome => 'Mostrar en la página de inicio';

  @override
  String get clear => 'Borrar';

  @override
  String get filters => 'Filtros';

  @override
  String get saveAsNewView => 'Guardar como nueva vista';

  @override
  String get saveView => 'Guardar la vista';

  @override
  String get noMarkers => 'Sin marcadores';

  @override
  String get noImages => 'Sin imágenes';

  @override
  String get noDownloads =>
      'Ninguna descarga.\n\nUsa el botón de descarga de una escena, un grupo, una galería o una imagen (en el visor) para guardarla en el teléfono.';

  @override
  String deleteFromPhoneQuestion(Object title) {
    return '¿Eliminar «$title» del teléfono?';
  }

  @override
  String get groupScenesDeletedToo =>
      'También se eliminarán las escenas de este grupo.';

  @override
  String get downloadFailedRetry => 'Error: toca ⋮ para reintentar';

  @override
  String get downloadQueued => 'En espera';

  @override
  String get downloadRunning => 'Descargando…';

  @override
  String downloadProgress(Object percent) {
    return 'Descargando · $percent %';
  }

  @override
  String resumeAt(Object time) {
    return 'Reanudar en $time';
  }

  @override
  String get play => 'Reproducir';

  @override
  String get fromStart => 'Desde el principio';

  @override
  String get forgetResumePosition => 'Olvidar la posición de reanudación';

  @override
  String get resumePositionCleared => 'Posición de reanudación borrada';

  @override
  String get code => 'Código';

  @override
  String get file => 'Archivo';

  @override
  String get fileSize => 'Tamaño';

  @override
  String get dimensions => 'Dimensiones';

  @override
  String get format => 'Formato';

  @override
  String get video => 'Vídeo';

  @override
  String get audio => 'Audio';

  @override
  String get framesPerSecondLabel => 'Fotogramas/s';

  @override
  String get bitRate => 'Tasa de bits';

  @override
  String megabitsPerSecond(Object value) {
    return '$value Mb/s';
  }

  @override
  String get offlineCopy => 'Copia sin conexión';

  @override
  String get noStream => 'Ninguna transmisión disponible';

  @override
  String get directStream => 'Directo (original)';

  @override
  String directPlaybackFailed(Object source) {
    return 'No se pudo reproducir directamente, probando «$source»';
  }

  @override
  String playbackFailed(Object error) {
    return 'No se puede reproducir: $error';
  }

  @override
  String get playbackError => 'Error de reproducción';

  @override
  String get coverGenerating => 'Stash está generando la portada';

  @override
  String get playbackSpeed => 'Velocidad de reproducción';

  @override
  String get useFrameAsCover => 'Usar este fotograma como portada';

  @override
  String get addMarkerHere => 'Añadir un marcador aquí';

  @override
  String get streams => 'Transmisiones';

  @override
  String get pause => 'Pausa';

  @override
  String get soundOn => 'Activar el sonido';

  @override
  String get soundOff => 'Silenciar';

  @override
  String filterKind(Object kind) {
    return 'Filtrar: $kind';
  }

  @override
  String get allRatings => 'Todas';

  @override
  String get allResolutions => 'Todas';

  @override
  String get withLabel => 'Con';

  @override
  String get withoutLabel => 'Sin';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get anyValue => 'Todos';

  @override
  String confirmCount(Object count) {
    return 'Confirmar ($count)';
  }

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get includeSubTags => 'Incluir subetiquetas';

  @override
  String get includeSubStudios => 'Incluir subestudios';

  @override
  String get includeSubGroups => 'Incluir subgrupos';

  @override
  String get minRating => 'Puntuación mínima';

  @override
  String get minResolution => 'Resolución mínima';

  @override
  String get durationMinutes => 'Duración (minutos)';

  @override
  String get min => 'Mín.';

  @override
  String get max => 'Máx.';

  @override
  String get apply => 'Aplicar';

  @override
  String get choose => 'Elegir';

  @override
  String get watchStatus => 'Visualización';

  @override
  String get cover => 'Portada';

  @override
  String get organized => 'Clasificada';

  @override
  String get scrape => 'Extraer';

  @override
  String get editScene => 'Editar la escena';

  @override
  String get photo => 'Foto';

  @override
  String get deathDate => 'Fecha de fallecimiento';

  @override
  String get weight => 'Peso';

  @override
  String get fakeTits => 'Pecho operado';

  @override
  String get tattoos => 'Tatuajes';

  @override
  String get piercings => 'Piercings';

  @override
  String get editPerformer => 'Editar el actor';

  @override
  String get logo => 'Logo';

  @override
  String get editStudio => 'Editar el estudio';

  @override
  String get image => 'Imagen';

  @override
  String get parentTags => 'Etiquetas principales';

  @override
  String get editTag => 'Editar la etiqueta';

  @override
  String get frontCover => 'Carátula (frontal)';

  @override
  String get backCover => 'Carátula (trasera)';

  @override
  String get editGroup => 'Editar el grupo';

  @override
  String get photographer => 'Fotógrafo';

  @override
  String get editGallery => 'Editar la galería';

  @override
  String get start => 'Inicio';

  @override
  String get endOptional => 'Fin (opcional)';

  @override
  String get primaryTag => 'Etiqueta principal';

  @override
  String get otherTags => 'Otras etiquetas';

  @override
  String get deleteMarker => 'Eliminar el marcador';

  @override
  String get newMarker => 'Nuevo marcador';

  @override
  String fieldRequired(Object label) {
    return '$label es obligatorio';
  }

  @override
  String get dateHint => 'AAAA-MM-DD';

  @override
  String dateFormatExpected(Object label, Object format) {
    return '$label: se espera el formato $format';
  }

  @override
  String integerExpected(Object label) {
    return '$label: se espera un número entero';
  }

  @override
  String timeFormatExpected(Object label) {
    return '$label: se espera el formato m:ss';
  }

  @override
  String get change => 'Cambiar';

  @override
  String get add => 'Añadir';

  @override
  String get addHint => 'Añadir…';

  @override
  String questionOf(Object action) {
    return '¿$action?';
  }

  @override
  String get saved => 'Guardado';

  @override
  String get deleted => 'Eliminado';

  @override
  String get use => 'Usar';

  @override
  String get fromPhone => 'Desde el teléfono';

  @override
  String get fromUrl => 'Desde una URL';

  @override
  String get cannotBeUndone => 'Esta acción no se puede deshacer.';

  @override
  String get discardChangesQuestion => '¿Descartar los cambios?';

  @override
  String get continueEditing => 'Seguir editando';

  @override
  String get discard => 'Descartar';

  @override
  String get newGroup => 'Nuevo grupo';

  @override
  String get newGallery => 'Nueva galería';

  @override
  String get newPerformer => 'Nuevo actor';

  @override
  String get newStudio => 'Nuevo estudio';

  @override
  String get newTag => 'Nueva etiqueta';

  @override
  String get deletePerformer => 'Eliminar el actor';

  @override
  String get deleteStudio => 'Eliminar el estudio';

  @override
  String get deleteTag => 'Eliminar la etiqueta';

  @override
  String get deleteGroup => 'Eliminar el grupo';

  @override
  String get deleteGallery => 'Eliminar la galería';

  @override
  String createNamed(Object name) {
    return 'Crear «$name»';
  }

  @override
  String createdNamed(Object name) {
    return '«$name» creado en Stash';
  }

  @override
  String get untitled => 'Sin título';

  @override
  String get newImage => 'Nueva imagen';

  @override
  String get nothingNewInResult => 'Nada nuevo en este resultado';

  @override
  String searchOn(Object source) {
    return 'Buscar en $source';
  }

  @override
  String get titleCodeHint => 'Título, código…';

  @override
  String get scrapeWith => 'Extraer con…';

  @override
  String get byFingerprintThenSearch => 'Por huella, si no por búsqueda';

  @override
  String get bySearch => 'Por búsqueda';

  @override
  String get byScene => 'por la escena';

  @override
  String get bySearchLower => 'por búsqueda';

  @override
  String get scrapersHeader => 'Scrapers';

  @override
  String get noScraperConfigured =>
      'No hay ningún scraper ni stash-box configurado para este tipo en el servidor (Preferencias > Metadatos).';

  @override
  String countResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '$count resultado',
    );
    return '$_temp0';
  }

  @override
  String createdInStash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos creados en Stash',
      one: '$count elemento creado en Stash',
    );
    return '$_temp0';
  }

  @override
  String get scrapeResultIntro =>
      'Marca los valores que quieres usar. Rellenan el formulario de edición y solo se guardan con «Guardar» (salvo los elementos que hay que crear, más abajo).';

  @override
  String currentValue(Object value) {
    return 'Actual: $value';
  }

  @override
  String get missingFromStash => 'No están en Stash';

  @override
  String get missingFromStashHint =>
      'Los elementos marcados se crean en Stash (con la información del scraper) al pulsar «Aplicar» y luego se vinculan.';

  @override
  String createAndLink(Object label) {
    return 'Crear y vincular · $label';
  }

  @override
  String get search => 'Buscar';

  @override
  String get scrapeUrl => 'Extraer de una URL';

  @override
  String get otherUrl => 'Otra URL…';

  @override
  String get scrapeResult => 'Resultado de la extracción';
}
