import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Feed'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const _CreatePostSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No posts yet.'));
          }
          final posts = snapshot.data!.docs;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data() as Map<String, dynamic>;
              final content = post['content'] ?? '';
              final tags = List<String>.from(post['tags'] ?? []);
              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: tags
                            .map((tag) => Chip(
                                  label: Text(tag),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(content),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final TextEditingController _contentController = TextEditingController();
  final List<String> _selectedTags = [];

  final List<String> allTags = ['Housing', 'Travel', 'Hiring'];

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    await FirebaseFirestore.instance.collection('posts').add({
      'content': content,
      'tags': _selectedTags,
      'authorId': FirebaseAuth.instance.currentUser?.uid,
      'created_at': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'What do you want to share?',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: allTags.map((tag) {
                final selected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text('#$tag'),
                  selected: selected,
                  onSelected: (bool value) {
                    setState(() {
                      if (value) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _submitPost,
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
