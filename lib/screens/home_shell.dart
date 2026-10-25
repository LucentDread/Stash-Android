import 'package:flutter/material.dart';

import 'browse_screens.dart';
import 'home_screen.dart';
import 'more_screen.dart';

/// Root screen with the bottom navigation bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _visited = <int>{0};

  /// Each page with its bottom bar entry, kept together so they match.
  static const _tabs = <(Widget, NavigationDestination)>[
    (
      HomeTab(),
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Accueil',
      ),
    ),
    (
      ScenesScreen(),
      NavigationDestination(
        icon: Icon(Icons.movie_outlined),
        selectedIcon: Icon(Icons.movie),
        label: 'Scènes',
      ),
    ),
    (
      GroupsScreen(),
      NavigationDestination(
        icon: Icon(Icons.video_library_outlined),
        selectedIcon: Icon(Icons.video_library),
        label: 'Groupes',
      ),
    ),
    (
      PerformersScreen(),
      NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Performeurs',
      ),
    ),
    (
      MoreScreen(),
      NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Plus'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < _tabs.length; i++)
              _visited.contains(i) ? _tabs[i].$1 : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() {
            _index = i;
            _visited.add(i);
          }),
          destinations: [
            // Labels stay on one line (ellipsis) on narrow screens. This
            // must sit inside the bar: its Material resets the text style.
            for (final t in _tabs)
              DefaultTextStyle.merge(
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                child: t.$2,
              ),
          ],
        ),
      ),
    );
  }
}
