import 'package:flutter_test/flutter_test.dart';
import 'package:stash_android/models/models.dart';
import 'package:stash_android/utils/format.dart';

void main() {
  test('Scene.fromJson parses a findScene payload', () {
    final s = Scene.fromJson({
      'id': '12',
      'title': '',
      'rating100': 80,
      'o_counter': 2,
      'resume_time': 61.5,
      'files': [
        {
          'path': '/data/videos/My Clip.mp4',
          'duration': 754.2,
          'width': 1920,
          'height': 1080,
          'size': 1048576,
        }
      ],
      'paths': {'screenshot': '/scene/12/screenshot', 'stream': '/s'},
      'studio': {'id': '3', 'name': 'Studio'},
      'performers': [
        {'id': '1', 'name': 'A'}
      ],
      'tags': [],
      'galleries': [
        {'id': '9', 'title': null}
      ],
      'scene_markers': [
        {
          'id': '5',
          'title': '',
          'seconds': 30,
          'primary_tag': {'id': '7', 'name': 'Intro'},
        }
      ],
    });
    expect(s.displayTitle, 'My Clip.mp4');
    expect(s.duration, 754.2);
    expect(s.studio!.name, 'Studio');
    expect(s.markers.single.displayTitle, 'Intro');
    expect(s.galleries.single.name, 'Galerie 9');
    expect(starsFromRating(s.rating100), 4);
  });

  test('formatting helpers', () {
    expect(formatDuration(754.2), '12:34');
    expect(formatDuration(3725), '1:02:05');
    expect(formatBytes(1536), '1.5 Ko');
    expect(resolutionLabel(3840, 2160), '4K');
    expect(resolutionLabel(1080, 1920), '1080p');
  });
}
