import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PodsScreen extends StatelessWidget {
  const PodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pods')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('pods').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pods available.'));
          }
          final pods = snapshot.data!.docs;
          return ListView.builder(
            itemCount: pods.length,
            itemBuilder: (context, index) {
              final podData = pods[index].data() as Map<String, dynamic>;
              final podName = podData['name'] ?? 'Unnamed Pod';
              return ListTile(
                title: Text(podName),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PodChatScreen(
                        podId: pods[index].id,
                        podName: podName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class PodChatScreen extends StatelessWidget {
  final String podId;
  final String podName;

  const PodChatScreen({super.key, required this.podId, required this.podName});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _messageController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text(podName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pods')
                  .doc(podId)
                  .collection('messages')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final text = messageData['text'] ?? '';
                    return ListTile(
                      title: Text(text),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter message',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final text = _messageController.text.trim();
                    if (text.isEmpty) return;
                    await FirebaseFirestore.instance
                        .collection('pods')
                        .doc(podId)
                        .collection('messages')
                        .add({
                      'text': text,
                      'authorId': FirebaseAuth.instance.currentUser?.uid,
                      'created_at': FieldValue.serverTimestamp(),
                    });
                    _messageController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
