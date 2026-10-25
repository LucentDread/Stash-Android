import 'package:flutter/material.dart';

import 'models/models.dart';
import 'screens/gallery_screen.dart';
import 'screens/group_screen.dart';
import 'screens/image_viewer_screen.dart';
import 'screens/performer_screen.dart';
import 'screens/player_screen.dart';
import 'screens/scene_screen.dart';
import 'screens/studio_screen.dart';
import 'screens/tag_screen.dart';

Future<T?> _push<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

void openScene(BuildContext context, String id) =>
    _push(context, SceneScreen(sceneId: id));

void openPerformer(BuildContext context, String id) =>
    _push(context, PerformerScreen(performerId: id));

void openStudio(BuildContext context, String id) =>
    _push(context, StudioScreen(studioId: id));

void openTag(BuildContext context, String id) =>
    _push(context, TagScreen(tagId: id));

void openGroup(BuildContext context, String id) =>
    _push(context, GroupScreen(groupId: id));

void openGallery(BuildContext context, String id) =>
    _push(context, GalleryScreen(galleryId: id));

void openImages(BuildContext context, List<StashImage> images, int index) =>
    _push(context, ImageViewerScreen(images: images, initialIndex: index));

/// Opens the player; [start] in seconds, otherwise resumes where left off.
Future<void> playScene(BuildContext context, String id, {double? start}) =>
    _push(context, PlayerScreen(sceneId: id, startAt: start));
