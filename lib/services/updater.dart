import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/l10n.dart';

/// A published version of the app (GitHub release).
class Release {
  const Release({
    required this.version,
    required this.notes,
    this.apkUrl,
    this.apkSize = 0,
  });

  final String version;

  /// The version's CHANGELOG.md section.
  final String notes;
  final String? apkUrl;
  final int apkSize;
}

/// Versions newer than the installed one, newest first. [newer.first] is
/// the one installed by an update.
class UpdateInfo {
  const UpdateInfo(this.newer);
  final List<Release> newer;
  Release get latest => newer.first;
}

/// Looks for new versions in the GitHub releases of the project and
/// downloads them. The system installer does the rest.
class Updater {
  Updater({http.Client? client, Future<String> Function()? currentVersion})
    : _client = client ?? http.Client(),
      _currentVersion = currentVersion ?? _installedVersion;

  static const repository = 'LucentDread/Stash-Android';

  final http.Client _client;
  final Future<String> Function() _currentVersion;

  static Future<String> _installedVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  /// Returns the versions newer than the installed one, or null when it is
  /// up to date. Only versions with an APK can be installed.
  Future<UpdateInfo?> check() async {
    final res = await _client.get(
      Uri.parse(
        'https://api.github.com/repos/$repository/releases?per_page=30',
      ),
      headers: {'Accept': 'application/vnd.github+json'},
    );
    if (res.statusCode != 200) {
      throw HttpException(tr.githubError(res.statusCode));
    }
    final current = parseVersion(await _currentVersion());
    final newer = <Release>[];
    for (final r in jsonDecode(utf8.decode(res.bodyBytes)) as List) {
      final m = (r as Map).cast<String, dynamic>();
      if (m['draft'] == true || m['prerelease'] == true) continue;
      final tag = (m['tag_name'] as String? ?? '').replaceFirst('v', '');
      final version = parseVersion(tag);
      if (version == null ||
          (current != null && compareVersions(version, current) <= 0)) {
        continue;
      }
      final assets = [
        for (final a in m['assets'] as List? ?? const [])
          (a as Map).cast<String, dynamic>(),
      ].where((a) => (a['name'] as String? ?? '').endsWith('.apk')).toList();
      // Builds are 64-bit ARM; prefer that one if others are added.
      final apk =
          assets
              .where((a) => (a['name'] as String).contains('arm64-v8a'))
              .firstOrNull ??
          assets.firstOrNull;
      newer.add(
        Release(
          version: tag,
          notes: m['body'] as String? ?? '',
          apkUrl: apk?['browser_download_url'] as String?,
          apkSize: (apk?['size'] as num?)?.toInt() ?? 0,
        ),
      );
    }
    newer.sort(
      (a, b) =>
          compareVersions(parseVersion(b.version)!, parseVersion(a.version)!),
    );
    // A release still waiting for its APK is announced with the next one.
    while (newer.isNotEmpty && newer.first.apkUrl == null) {
      newer.removeAt(0);
    }
    return newer.isEmpty ? null : UpdateInfo(newer);
  }

  /// Downloads the APK of [release] into the cache folder shared with the
  /// installer (see res/xml/update_paths.xml). [onProgress] gets 0 to 1,
  /// or null when the size is unknown.
  Future<File> download(
    Release release, {
    void Function(double? progress)? onProgress,
    Directory? into,
  }) async {
    final dir = Directory(
      '${(into ?? await getTemporaryDirectory()).path}/updates',
    );
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final file = File('${dir.path}/Stash-${release.version}.apk');

    final res = await _client.send(
      http.Request('GET', Uri.parse(release.apkUrl!)),
    );
    if (res.statusCode != 200) {
      throw HttpException(tr.downloadRefused(res.statusCode));
    }
    final total = res.contentLength ?? release.apkSize;
    final sink = file.openWrite();
    var received = 0;
    try {
      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(total > 0 ? received / total : null);
      }
    } finally {
      await sink.close();
    }
    if (total > 0 && received != total) {
      throw HttpException(tr.downloadIncomplete);
    }
    return file;
  }

  /// "1.10.2" → [1, 10, 2]; null when not a version number.
  static List<int>? parseVersion(String v) {
    final m = RegExp(r'^(\d+)\.(\d+)\.(\d+)').firstMatch(v.trim());
    if (m == null) return null;
    return [for (var i = 1; i <= 3; i++) int.parse(m.group(i)!)];
  }

  static int compareVersions(List<int> a, List<int> b) {
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i].compareTo(b[i]);
    }
    return 0;
  }

  /// The items of release notes written as a Markdown list, with wrapped
  /// lines joined.
  static List<String> noteItems(String notes) {
    final items = <String>[];
    for (final line in const LineSplitter().convert(notes)) {
      final t = line.trim();
      if (t.isEmpty) continue;
      if (t.startsWith('- ') || t.startsWith('* ')) {
        items.add(t.substring(2).trim());
      } else if (items.isNotEmpty && line.startsWith(' ')) {
        items[items.length - 1] = '${items.last} $t';
      } else {
        items.add(t);
      }
    }
    return items;
  }
}
