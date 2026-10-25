/// Plain data classes mapped from the Stash GraphQL schema.
library;

int? _int(dynamic v) => v is num ? v.toInt() : null;
double? _double(dynamic v) => v is num ? v.toDouble() : null;
List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
    v is List ? v.map((e) => f(e as Map<String, dynamic>)).toList() : <T>[];

class ResultPage<T> {
  const ResultPage(this.items, this.count);
  final List<T> items;
  final int count;
}

class TagRef {
  TagRef({required this.id, required this.name});
  final String id;
  final String name;

  factory TagRef.fromJson(Map<String, dynamic> j) =>
      TagRef(id: j['id'] as String, name: j['name'] as String? ?? '');
}

class VideoFile {
  VideoFile({
    required this.path,
    required this.size,
    required this.width,
    required this.height,
    required this.duration,
    required this.videoCodec,
    required this.audioCodec,
    required this.frameRate,
    required this.bitRate,
    required this.format,
  });

  final String path;
  final int size;
  final int width;
  final int height;
  final double duration;
  final String videoCodec;
  final String audioCodec;
  final double frameRate;
  final int bitRate;
  final String format;

  factory VideoFile.fromJson(Map<String, dynamic> j) => VideoFile(
    path: j['path'] as String? ?? '',
    size: _int(j['size']) ?? 0,
    width: _int(j['width']) ?? 0,
    height: _int(j['height']) ?? 0,
    duration: _double(j['duration']) ?? 0,
    videoCodec: j['video_codec'] as String? ?? '',
    audioCodec: j['audio_codec'] as String? ?? '',
    frameRate: _double(j['frame_rate']) ?? 0,
    bitRate: _int(j['bit_rate']) ?? 0,
    format: j['format'] as String? ?? '',
  );
}

class StreamEndpoint {
  StreamEndpoint({required this.url, this.mimeType, this.label});
  final String url;
  final String? mimeType;
  final String? label;

  factory StreamEndpoint.fromJson(Map<String, dynamic> j) => StreamEndpoint(
    url: j['url'] as String,
    mimeType: j['mime_type'] as String?,
    label: j['label'] as String?,
  );
}

class SceneMarker {
  SceneMarker({
    required this.id,
    required this.title,
    required this.seconds,
    this.endSeconds,
    required this.primaryTag,
    this.screenshot,
    this.sceneId,
    this.sceneTitle,
  });

  final String id;
  final String title;
  final double seconds;
  final double? endSeconds;
  final TagRef primaryTag;
  final String? screenshot;
  final String? sceneId;
  final String? sceneTitle;

  String get displayTitle => title.isNotEmpty ? title : primaryTag.name;

  factory SceneMarker.fromJson(Map<String, dynamic> j) {
    final scene = j['scene'] as Map<String, dynamic>?;
    return SceneMarker(
      id: j['id'] as String,
      title: j['title'] as String? ?? '',
      seconds: _double(j['seconds']) ?? 0,
      endSeconds: _double(j['end_seconds']),
      primaryTag: TagRef.fromJson(j['primary_tag'] as Map<String, dynamic>),
      screenshot: j['screenshot'] as String?,
      sceneId: scene?['id'] as String?,
      sceneTitle: scene?['title'] as String?,
    );
  }
}

class Scene {
  Scene({
    required this.id,
    this.title,
    this.code,
    this.details,
    this.director,
    this.date,
    this.rating100,
    this.organized = false,
    this.oCounter = 0,
    this.playCount = 0,
    this.resumeTime,
    this.lastPlayedAt,
    this.urls = const [],
    this.files = const [],
    this.screenshot,
    this.preview,
    this.stream,
    this.studio,
    this.performers = const [],
    this.tags = const [],
    this.markers = const [],
    this.galleries = const [],
    this.groups = const [],
  });

  final String id;
  final String? title;
  final String? code;
  final String? details;
  final String? director;
  final String? date;
  final int? rating100;
  final bool organized;
  final int oCounter;
  final int playCount;
  final double? resumeTime;
  final String? lastPlayedAt;
  final List<String> urls;
  final List<VideoFile> files;
  final String? screenshot;
  final String? preview;
  final String? stream;
  final TagRef? studio;
  final List<TagRef> performers;
  final List<TagRef> tags;
  final List<SceneMarker> markers;
  final List<TagRef> galleries;
  final List<TagRef> groups;

  VideoFile? get file => files.isEmpty ? null : files.first;
  double get duration => file?.duration ?? 0;

  /// Stash shows the file name when a scene has no title.
  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    final p = file?.path;
    if (p == null || p.isEmpty) return 'Scène $id';
    return p.split(RegExp(r'[\\/]')).last;
  }

  factory Scene.fromJson(Map<String, dynamic> j) {
    final paths = (j['paths'] as Map<String, dynamic>?) ?? const {};
    final studio = j['studio'] as Map<String, dynamic>?;
    return Scene(
      id: j['id'] as String,
      title: j['title'] as String?,
      code: j['code'] as String?,
      details: j['details'] as String?,
      director: j['director'] as String?,
      date: j['date'] as String?,
      rating100: _int(j['rating100']),
      organized: j['organized'] as bool? ?? false,
      oCounter: _int(j['o_counter']) ?? 0,
      playCount: _int(j['play_count']) ?? 0,
      resumeTime: _double(j['resume_time']),
      lastPlayedAt: j['last_played_at'] as String?,
      urls: (j['urls'] as List?)?.cast<String>() ?? const [],
      files: _list(j['files'], VideoFile.fromJson),
      screenshot: paths['screenshot'] as String?,
      preview: paths['preview'] as String?,
      stream: paths['stream'] as String?,
      studio: studio == null ? null : TagRef.fromJson(studio),
      performers: _list(j['performers'], TagRef.fromJson),
      tags: _list(j['tags'], TagRef.fromJson),
      markers: _list(j['scene_markers'], SceneMarker.fromJson),
      galleries: _list(
        j['galleries'],
        (g) => TagRef(
          id: g['id'] as String,
          name: (g['title'] as String?)?.isNotEmpty == true
              ? g['title'] as String
              : 'Galerie ${g['id']}',
        ),
      ),
    );
  }
}

class Performer {
  Performer({
    required this.id,
    required this.name,
    this.disambiguation,
    this.gender,
    this.birthdate,
    this.country,
    this.ethnicity,
    this.heightCm,
    this.measurements,
    this.hairColor,
    this.eyeColor,
    this.details,
    this.imagePath,
    this.favorite = false,
    this.rating100,
    this.sceneCount = 0,
    this.imageCount = 0,
    this.galleryCount = 0,
    this.aliases = const [],
    this.tags = const [],
    this.urls = const [],
  });

  final String id;
  final String name;
  final String? disambiguation;
  final String? gender;
  final String? birthdate;
  final String? country;
  final String? ethnicity;
  final int? heightCm;
  final String? measurements;
  final String? hairColor;
  final String? eyeColor;
  final String? details;
  final String? imagePath;
  final bool favorite;
  final int? rating100;
  final int sceneCount;
  final int imageCount;
  final int galleryCount;
  final List<String> aliases;
  final List<TagRef> tags;
  final List<String> urls;

  factory Performer.fromJson(Map<String, dynamic> j) => Performer(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    disambiguation: j['disambiguation'] as String?,
    gender: j['gender'] as String?,
    birthdate: j['birthdate'] as String?,
    country: j['country'] as String?,
    ethnicity: j['ethnicity'] as String?,
    heightCm: _int(j['height_cm']),
    measurements: j['measurements'] as String?,
    hairColor: j['hair_color'] as String?,
    eyeColor: j['eye_color'] as String?,
    details: j['details'] as String?,
    imagePath: j['image_path'] as String?,
    favorite: j['favorite'] as bool? ?? false,
    rating100: _int(j['rating100']),
    sceneCount: _int(j['scene_count']) ?? 0,
    imageCount: _int(j['image_count']) ?? 0,
    galleryCount: _int(j['gallery_count']) ?? 0,
    aliases: (j['alias_list'] as List?)?.cast<String>() ?? const [],
    tags: _list(j['tags'], TagRef.fromJson),
    urls: (j['urls'] as List?)?.cast<String>() ?? const [],
  );
}

class Studio {
  Studio({
    required this.id,
    required this.name,
    this.imagePath,
    this.details,
    this.parent,
    this.favorite = false,
    this.sceneCount = 0,
    this.imageCount = 0,
    this.galleryCount = 0,
    this.urls = const [],
  });

  final String id;
  final String name;
  final String? imagePath;
  final String? details;
  final TagRef? parent;
  final bool favorite;
  final int sceneCount;
  final int imageCount;
  final int galleryCount;
  final List<String> urls;

  factory Studio.fromJson(Map<String, dynamic> j) {
    final parent = j['parent_studio'] as Map<String, dynamic>?;
    return Studio(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      imagePath: j['image_path'] as String?,
      details: j['details'] as String?,
      parent: parent == null ? null : TagRef.fromJson(parent),
      favorite: j['favorite'] as bool? ?? false,
      sceneCount: _int(j['scene_count']) ?? 0,
      imageCount: _int(j['image_count']) ?? 0,
      galleryCount: _int(j['gallery_count']) ?? 0,
      urls: (j['urls'] as List?)?.cast<String>() ?? const [],
    );
  }
}

class Tag {
  Tag({
    required this.id,
    required this.name,
    this.description,
    this.imagePath,
    this.favorite = false,
    this.sceneCount = 0,
    this.markerCount = 0,
    this.performerCount = 0,
    this.imageCount = 0,
    this.galleryCount = 0,
    this.aliases = const [],
  });

  final String id;
  final String name;
  final String? description;
  final String? imagePath;
  final bool favorite;
  final int sceneCount;
  final int markerCount;
  final int performerCount;
  final int imageCount;
  final int galleryCount;
  final List<String> aliases;

  factory Tag.fromJson(Map<String, dynamic> j) => Tag(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    description: j['description'] as String?,
    imagePath: j['image_path'] as String?,
    favorite: j['favorite'] as bool? ?? false,
    sceneCount: _int(j['scene_count']) ?? 0,
    markerCount: _int(j['scene_marker_count']) ?? 0,
    performerCount: _int(j['performer_count']) ?? 0,
    imageCount: _int(j['image_count']) ?? 0,
    galleryCount: _int(j['gallery_count']) ?? 0,
    aliases: (j['aliases'] as List?)?.cast<String>() ?? const [],
  );
}

class Gallery {
  Gallery({
    required this.id,
    this.title,
    this.date,
    this.details,
    this.imageCount = 0,
    this.cover,
    this.folderPath,
    this.studio,
    this.performers = const [],
    this.tags = const [],
  });

  final String id;
  final String? title;
  final String? date;
  final String? details;
  final int imageCount;
  final String? cover;
  final String? folderPath;
  final TagRef? studio;
  final List<TagRef> performers;
  final List<TagRef> tags;

  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    if (folderPath != null && folderPath!.isNotEmpty) {
      return folderPath!.split(RegExp(r'[\\/]')).last;
    }
    return 'Galerie $id';
  }

  factory Gallery.fromJson(Map<String, dynamic> j) {
    final paths = (j['paths'] as Map<String, dynamic>?) ?? const {};
    final studio = j['studio'] as Map<String, dynamic>?;
    final folder = j['folder'] as Map<String, dynamic>?;
    final files = j['files'] as List?;
    return Gallery(
      id: j['id'] as String,
      title: j['title'] as String?,
      date: j['date'] as String?,
      details: j['details'] as String?,
      imageCount: _int(j['image_count']) ?? 0,
      cover: paths['cover'] as String?,
      folderPath:
          folder?['path'] as String? ??
          (files != null && files.isNotEmpty
              ? (files.first as Map)['path'] as String?
              : null),
      studio: studio == null ? null : TagRef.fromJson(studio),
      performers: _list(j['performers'], TagRef.fromJson),
      tags: _list(j['tags'], TagRef.fromJson),
    );
  }
}

class StashImage {
  StashImage({
    required this.id,
    this.title,
    this.thumbnail,
    this.preview,
    this.image,
    this.width,
    this.height,
  });

  final String id;
  final String? title;
  final String? thumbnail;
  final String? preview;
  final String? image;
  final int? width;
  final int? height;

  factory StashImage.fromJson(Map<String, dynamic> j) {
    final paths = (j['paths'] as Map<String, dynamic>?) ?? const {};
    final files = j['visual_files'] as List?;
    final f = (files != null && files.isNotEmpty)
        ? files.first as Map<String, dynamic>
        : const <String, dynamic>{};
    return StashImage(
      id: j['id'] as String,
      title: j['title'] as String?,
      thumbnail: paths['thumbnail'] as String?,
      preview: paths['preview'] as String?,
      image: paths['image'] as String?,
      width: _int(f['width']),
      height: _int(f['height']),
    );
  }
}

class Stats {
  Stats({
    required this.sceneCount,
    required this.scenesSize,
    required this.scenesDuration,
    required this.imageCount,
    required this.galleryCount,
    required this.performerCount,
    required this.studioCount,
    required this.tagCount,
  });

  final int sceneCount;
  final double scenesSize;
  final double scenesDuration;
  final int imageCount;
  final int galleryCount;
  final int performerCount;
  final int studioCount;
  final int tagCount;

  factory Stats.fromJson(Map<String, dynamic> j) => Stats(
    sceneCount: _int(j['scene_count']) ?? 0,
    scenesSize: _double(j['scenes_size']) ?? 0,
    scenesDuration: _double(j['scenes_duration']) ?? 0,
    imageCount: _int(j['image_count']) ?? 0,
    galleryCount: _int(j['gallery_count']) ?? 0,
    performerCount: _int(j['performer_count']) ?? 0,
    studioCount: _int(j['studio_count']) ?? 0,
    tagCount: _int(j['tag_count']) ?? 0,
  );
}

class Group {
  Group({
    required this.id,
    required this.name,
    this.aliases,
    this.date,
    this.duration,
    this.director,
    this.synopsis,
    this.frontImage,
    this.backImage,
    this.rating100,
    this.sceneCount = 0,
    this.studio,
    this.tags = const [],
    this.urls = const [],
  });

  final String id;
  final String name;
  final String? aliases;
  final String? date;

  /// Duration in seconds.
  final int? duration;
  final String? director;
  final String? synopsis;
  final String? frontImage;
  final String? backImage;
  final int? rating100;
  final int sceneCount;
  final TagRef? studio;
  final List<TagRef> tags;
  final List<String> urls;

  factory Group.fromJson(Map<String, dynamic> j) {
    final studio = j['studio'] as Map<String, dynamic>?;
    return Group(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      aliases: j['aliases'] as String?,
      date: j['date'] as String?,
      duration: _int(j['duration']),
      director: j['director'] as String?,
      synopsis: j['synopsis'] as String?,
      frontImage: j['front_image_path'] as String?,
      backImage: j['back_image_path'] as String?,
      rating100: _int(j['rating100']),
      sceneCount: _int(j['scene_count']) ?? 0,
      studio: studio == null ? null : TagRef.fromJson(studio),
      tags: _list(j['tags'], TagRef.fromJson),
      urls: (j['urls'] as List?)?.cast<String>() ?? const [],
    );
  }
}
