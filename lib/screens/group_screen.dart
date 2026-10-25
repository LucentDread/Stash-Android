import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/stash_repository.dart';
import '../models/models.dart';
import '../navigation.dart';
import '../services/app_state.dart';
import '../utils/format.dart';
import '../widgets/async_view.dart';
import '../widgets/detail_widgets.dart';
import '../widgets/net_image.dart';
import 'browse_screens.dart';

class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo!;
    return AsyncView<Group>(
      load: () => repo.findGroup(groupId),
      builder: (context, g, _) => DefaultTabController(
        length: 2,
        initialIndex: 1,
        child: Scaffold(
          appBar: AppBar(
            title: Text(g.name),
            bottom: TabBar(
              tabs: [
                const Tab(text: 'Infos'),
                Tab(text: 'Scènes (${g.sceneCount})'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _GroupInfo(group: g),
              sceneGrid(context, entity: EntityFilter.group(g.id)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupInfo extends StatelessWidget {
  const _GroupInfo({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final g = group;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 300,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final img in [
                g.frontImage,
                if (g.backImage != null) g.backImage,
              ])
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: NetImage(
                          img,
                          placeholderIcon: Icons.video_library,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (g.rating100 != null) ...[
          const SizedBox(height: 8),
          Center(child: StarRating(rating100: g.rating100)),
        ],
        Section(
          title: 'Informations',
          child: InfoTable([
            ('Alias', g.aliases),
            ('Date', g.date),
            (
              'Durée',
              g.duration == null
                  ? null
                  : formatDuration(g.duration!.toDouble()),
            ),
            ('Réalisateur', g.director),
          ]),
        ),
        if (g.studio != null)
          Section(
            title: 'Studio',
            child: RefChips(
              refs: [g.studio!],
              icon: Icons.business,
              onTap: (r) => openStudio(context, r.id),
            ),
          ),
        if (g.synopsis != null && g.synopsis!.isNotEmpty)
          Section(title: 'Synopsis', child: SelectableText(g.synopsis!)),
        if (g.tags.isNotEmpty)
          Section(
            title: 'Tags',
            child: RefChips(refs: g.tags, onTap: (r) => openTag(context, r.id)),
          ),
        if (g.urls.isNotEmpty) Section(title: 'Liens', child: UrlList(g.urls)),
      ],
    );
  }
}
