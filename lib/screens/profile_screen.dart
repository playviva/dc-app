import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ProfileScreen displays and allows editing of the current user's profile.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Not logged in
      return const Scaffold(
        body: Center(child: Text('Please log in to view your profile')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          // Initialize text controller with current name.
          final displayName = data['displayName'] ?? '';
          final tags = List<String>.from(data['tags'] ?? []);
          _nameController.text = displayName;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tags',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final tag in tags)
                      Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () async {
                          final updatedTags = [...tags]..remove(tag);
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser.uid)
                              .update({'tags': updatedTags});
                        },
                      ),
                    InputChip(
                      label: SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _tagController,
                          decoration: const InputDecoration.collapsed(
                            hintText: 'Add tag',
                          ),
                          onSubmitted: (value) async {
                            final trimmed = value.trim();
                            if (trimmed.isNotEmpty && !tags.contains(trimmed)) {
                              final updatedTags = [...tags, trimmed];
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser.uid)
                                  .set({
                                'tags': updatedTags,
                              }, SetOptions(merge: true));
                            }
                            _tagController.clear();
                          },
                        ),
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .set({
                      'displayName': name,
                    }, SetOptions(merge: true));
                    if (tags.isEmpty) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .set({'tags': tags}, SetOptions(merge: true));
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated')),
                    );
                  },
                  child: const Text('Save Profile'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
