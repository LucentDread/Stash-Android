import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:path_provider/path_provider.dart';

import 'downloads.dart';

/// [FileFetcher] backed by background_downloader: transfers continue when
/// the app is in the background, videos run as a foreground service with a
/// progress notification (no 10-minute limit on Android).
class BackgroundFetcher implements FileFetcher {
  static const _videos = 'stash-videos';
  static const _files = 'stash-files';
  static const _dir = 'offline';

  final _downloader = FileDownloader();
  final _updates = StreamController<FileUpdate>.broadcast();
  bool _askedNotifications = false;

  @override
  Future<String> rootPath() async =>
      '${(await getApplicationSupportDirectory()).path}/$_dir';

  @override
  Stream<FileUpdate> get updates => _updates.stream;

  static FileState _state(TaskStatus s) => switch (s) {
    TaskStatus.enqueued || TaskStatus.waitingToRetry => FileState.queued,
    TaskStatus.running => FileState.running,
    TaskStatus.paused => FileState.paused,
    TaskStatus.complete => FileState.done,
    _ => FileState.failed,
  };

  @override
  Future<Map<String, FileState>> start() async {
    await _downloader.configure(
      androidConfig: [(Config.runInForegroundIfFileLargerThan, 20)],
    );
    _downloader.configureNotificationForGroup(
      _videos,
      running: const TaskNotification('Téléchargement', '{displayName}'),
      complete: const TaskNotification('Téléchargé', '{displayName}'),
      error: const TaskNotification('Échec du téléchargement', '{displayName}'),
      paused: const TaskNotification('En pause', '{displayName}'),
      progressBar: true,
    );
    // Listens for the app's lifetime, like the downloader itself.
    _downloader.updates.listen((u) {
      switch (u) {
        case TaskStatusUpdate():
          _updates.add((
            taskId: u.task.taskId,
            state: _state(u.status),
            progress: u.status == TaskStatus.complete ? 1.0 : null,
          ));
        case TaskProgressUpdate():
          // Negative values flag failures/cancellations, sent as statuses.
          if (u.progress >= 0) {
            _updates.add((
              taskId: u.task.taskId,
              state: FileState.running,
              progress: u.progress,
            ));
          }
      }
    });
    await _downloader.start();
    final records = await _downloader.database.allRecords();
    return {for (final r in records) r.taskId: _state(r.status)};
  }

  @override
  Future<void> enqueue({
    required String taskId,
    required String url,
    required Map<String, String> headers,
    required String path,
    required String displayName,
    required bool notify,
  }) async {
    if (notify && !_askedNotifications) {
      // Android 13+: progress notifications need the user's permission.
      _askedNotifications = true;
      final status = await _downloader.permissions.status(
        PermissionType.notifications,
      );
      if (status != PermissionStatus.granted) {
        await _downloader.permissions.request(PermissionType.notifications);
      }
    }
    final slash = path.lastIndexOf('/');
    final ok = await _downloader.enqueue(
      DownloadTask(
        taskId: taskId,
        url: url,
        headers: headers,
        directory: '$_dir/${path.substring(0, slash)}',
        filename: path.substring(slash + 1),
        baseDirectory: BaseDirectory.applicationSupport,
        group: notify ? _videos : _files,
        updates: notify ? Updates.statusAndProgress : Updates.status,
        displayName: displayName,
        allowPause: true,
        retries: 3,
      ),
    );
    if (!ok) {
      _updates.add((taskId: taskId, state: FileState.failed, progress: null));
    }
  }

  @override
  Future<void> cancel(Iterable<String> taskIds) async {
    await _downloader.cancelTasksWithIds(taskIds);
    await _downloader.database.deleteRecordsWithIds(taskIds);
  }
}
