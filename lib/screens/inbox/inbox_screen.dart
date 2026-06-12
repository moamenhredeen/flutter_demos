import 'package:flutter/material.dart';
import 'package:flutter_demos/screens/inbox/inbox_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Demos')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(simpleInboxProvider);
          return ref.read(simpleInboxProvider(1));
        },
        child: ListView.custom(
          childrenDelegate: SliverChildBuilderDelegate((context, index) {
            final page = index ~/ 20 + 1;
            final indexInPage = index % 20;
            final taskList = ref.watch(simpleInboxProvider(page));
            return taskList.when(
              data: (data) {
                if (indexInPage >= data.items.length) return null;
                return ListTile(
                  leading: Icon(Icons.pending_actions),
                  title: Text(data.items[indexInPage].title),
                );
              },
              error: (err, stack) => Text(err.toString()),
              loading: () => const CardListItem(),
            );
          }),
        ),
      ),
    );
  }
}

class CardListItem extends StatelessWidget {
  const CardListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 250,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}
