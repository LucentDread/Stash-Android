import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/stash_repository.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../widgets/async_view.dart';
import 'browse_screens.dart';

class TagScreen extends StatelessWidget {
  const TagScreen({super.key, required this.tagId});
  final String tagId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppState>().repo!;
    return AsyncView<Tag>(
      load: () => repo.findTag(tagId),
      builder: (context, t, _) {
        final entity = EntityFilter.tag(t.id);
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(t.name),
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'Scènes (${t.sceneCount})'),
                  Tab(text: 'Marqueurs (${t.markerCount})'),
                  Tab(text: 'Performeurs (${t.performerCount})'),
                  Tab(text: 'Galeries (${t.galleryCount})'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                sceneGrid(context, entity: entity),
                markerGrid(context, entity: entity),
                performerGrid(context, entity: entity),
                galleryGrid(context, entity: entity),
              ],
            ),
          ),
        );
      },
    );
  }
}
