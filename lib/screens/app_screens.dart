import 'package:flutter/material.dart';

import '../services/app_state.dart';

import 'browse_screens.dart';
import 'home_screen.dart';

/// Screens that can sit in the bottom bar, or else in the Plus tab.
enum AppScreen {
  home('Accueil', Icons.home_outlined, Icons.home),
  scenes('Scènes', Icons.movie_outlined, Icons.movie),
  groups('Groupes', Icons.video_library_outlined, Icons.video_library),
  performers('Performeurs', Icons.people_outline, Icons.people),
  galleries('Galeries', Icons.photo_library_outlined, Icons.photo_library),
  images('Images', Icons.image_outlined, Icons.image),
  studios('Studios', Icons.business_outlined, Icons.business),
  tags('Tags', Icons.label_outline, Icons.label),
  markers('Marqueurs', Icons.bookmarks_outlined, Icons.bookmarks);

  const AppScreen(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// The bar before tabs could be chosen.
  static const defaultTabs = [home, scenes, groups, performers];

  /// Tabs besides Plus, which is always last.
  static const maxTabs = 4;

  /// The tabs chosen in Plus > Onglets, in order.
  static List<AppScreen> tabsOf(AppState app) {
    final names = app.tabNames;
    if (names == null) return defaultTabs;
    final tabs = [
      for (final n in names) ?values.where((s) => s.name == n).firstOrNull,
    ];
    return tabs.isEmpty ? defaultTabs : tabs.take(maxTabs).toList();
  }

  Widget build() => switch (this) {
    home => const HomeTab(),
    scenes => const ScenesScreen(),
    groups => const GroupsScreen(),
    performers => const PerformersScreen(),
    galleries => const GalleriesScreen(),
    images => const ImagesScreen(),
    studios => const StudiosScreen(),
    tags => const TagsScreen(),
    markers => const MarkersScreen(),
  };
}
