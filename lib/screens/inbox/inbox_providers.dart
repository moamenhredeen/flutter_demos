
// final tasksProvider =
import 'dart:async';

import 'package:flutter_demos/data/gtd.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final simpleInboxProvider = FutureProvider.autoDispose.family<GtdOffsetPage<GtdTask>, int>((ref, page) async {

  return ref.watch(gtdRepositoryProvider).getTasks(page: page);
});

final inboxNotifierProvider = AsyncNotifierProvider(InboxNotifier.new);

class InboxNotifier extends AsyncNotifier<GtdOffsetPage<GtdTask>> {
  @override
  FutureOr<GtdOffsetPage<GtdTask>> build() {
    var repo = ref.watch(gtdRepositoryProvider);
    return repo.getTasks(page: 1, perPage: 20);
  }

}