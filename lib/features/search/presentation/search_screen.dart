import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    final query = _queryController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() { _results = []; _error = null; });
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      final end = '$query\uf8ff';
      final snapshots = await Future.wait([
        FirebaseFirestore.instance.collection('users').orderBy('username')
            .startAt([query]).endAt([end]).limit(20).get(),
        FirebaseFirestore.instance.collection('users').orderBy('displayName')
            .startAt([query]).endAt([end]).limit(20).get(),
      ]);
      final byId = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final snapshot in snapshots) {
        for (final document in snapshot.docs) {
          byId[document.id] = document;
        }
      }
      if (mounted) setState(() => _results = byId.values.toList());
    } catch (error) {
      if (mounted) setState(() { _results = []; _error = 'تعذر تنفيذ البحث: $error'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _queryController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: const InputDecoration(hintText: 'ابحث عن مستخدم', border: InputBorder.none),
        ),
        actions: [IconButton(onPressed: _loading ? null : _search, icon: const Icon(Icons.search))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _results.isEmpty
                  ? const Center(child: Text('لا توجد نتائج'))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final document = _results[index];
                        final data = document.data();
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text((data['displayName'] ?? '').toString()),
                          subtitle: Text('@${data['username'] ?? ''}'),
                          onTap: () => context.push('/profile/${document.id}'),
                        );
                      },
                    ),
    );
  }
}
