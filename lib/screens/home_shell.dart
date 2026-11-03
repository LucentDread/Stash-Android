import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/app_state.dart';
import '../services/system_bridge.dart';
import 'app_screens.dart';
import 'more_screen.dart';

/// Root screen with the bottom navigation bar: the tabs chosen in
/// Plus > Onglets, then Plus. Rebuilt (from the first tab) when they
/// change.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _visited = <int>{0};

  @override
  Widget build(BuildContext context) {
    final tabs = AppScreen.tabsOf(context.read<AppState>());
    // Each page with its bottom bar entry, kept together so they match.
    final pages = <(Widget, NavigationDestination)>[
      for (final t in tabs)
        (
          t.build(),
          NavigationDestination(
            icon: Icon(t.icon),
            selectedIcon: Icon(t.selectedIcon),
            label: t.label,
          ),
        ),
      (
        const MoreScreen(),
        NavigationDestination(
          icon: const Icon(Icons.more_horiz),
          label: tr.more,
        ),
      ),
    ];
    final body = IndexedStack(
      index: _index,
      children: [
        for (var i = 0; i < pages.length; i++)
          _visited.contains(i) ? pages[i].$1 : const SizedBox.shrink(),
      ],
    );
    void select(int i) => setState(() {
      _index = i;
      _visited.add(i);
    });
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: SystemBridge.instance.isTv
          ? _tvLayout(pages, body, select)
          : Scaffold(
              body: body,
              bottomNavigationBar: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: select,
                destinations: [
                  // Labels stay on one line (ellipsis) on narrow screens. This
                  // must sit inside the bar: its Material resets the text style.
                  for (final p in pages)
                    DefaultTextStyle.merge(
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      child: p.$2,
                    ),
                ],
              ),
            ),
    );
  }

  /// On a TV: the tabs in a rail on the left, which the remote reaches
  /// with Left from any page, and a wide screen keeps all its height.
  Widget _tvLayout(
    List<(Widget, NavigationDestination)> pages,
    Widget body,
    ValueChanged<int> select,
  ) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: select,
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final (_, d) in pages)
                NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
