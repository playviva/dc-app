import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Messages screen shows a list of direct message conversations for the current user.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      // If not authenticated, show a placeholder.
      return const Scaffold(
        body: Center(child: Text('Please log in to view messages')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('direct_chats')
            .where('participants', arrayContains: userId)
            .orderBy('lastUpdated', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No conversations'));
          }
          final chats = snapshot.data!.docs;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              final participants = List<String>.from(chatDoc['participants'] ?? []);
              // Determine the other user's UID.
              final otherUserId = participants.firstWhere((id) => id != userId, orElse: () => '');
              return FutureBuilder<DocumentSnapshot>(
                future: otherUserId.isNotEmpty
                    ? FirebaseFirestore.instance.collection('users').doc(otherUserId).get()
                    : Future.value(null),
                builder: (context, userSnapshot) {
                  final otherName = (userSnapshot.hasData && userSnapshot.data != null)
                      ? (userSnapshot.data!.data() as Map<String, dynamic>)['displayName'] ?? 'Unknown'
                      : 'Unknown';
                  final lastMessage = chatDoc['lastMessage'] ?? '';
                  return ListTile(
                    title: Text(otherName),
                    subtitle: Text(lastMessage),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DMChatScreen(
                            chatId: chatDoc.id,
                            otherUserId: otherUserId,
                            otherName: otherName,
                          ),
                        ),
                      );
                    },
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

/// DMChatScreen displays a direct message conversation.
class DMChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherName;
  const DMChatScreen({Key? key, required this.chatId, required this.otherUserId, required this.otherName}) : super(key: key);

  @override
  State<DMChatScreen> createState() => _DMChatScreenState();
}

class _DMChatScreenState extends State<DMChatScreen> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _sendMessage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    // Add the message to the subcollection.
    await FirebaseFirestore.instance
        .collection('direct_chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'senderId': currentUser.uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    // Update chat metadata for ordering and preview.
    await FirebaseFirestore.instance.collection('direct_chats').doc(widget.chatId).update({
      'lastMessage': text,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('direct_chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data?.docs ?? [];
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUser?.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(msg['text'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
