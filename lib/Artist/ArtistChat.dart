import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ArtistChatPage extends StatefulWidget {
  final String userId;

  const ArtistChatPage({super.key, required this.userId, required String userRole});

  @override
  State<ArtistChatPage> createState() => _ArtistChatPageState();
}

class _ArtistChatPageState extends State<ArtistChatPage> {
  final _dbRef = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  String currentUserId = '';
  final String currentUserRole = 'artist';

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser?.uid ?? '';
    _listenToMessages();
  }

  void _listenToMessages() {
    final messagesRef = _dbRef.child('chats/${widget.userId}/messages');

    messagesRef.onValue.listen((event) {
      final List<Map<String, dynamic>> loadedMessages = [];

      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        data.entries.forEach((entry) {
          final value = Map<String, dynamic>.from(entry.value);
          int timestamp = 0;
          final rawTimestamp = value['timestamp'];
          if (rawTimestamp is int) {
            timestamp = rawTimestamp;
          } else if (rawTimestamp is double) {
            timestamp = rawTimestamp.toInt();
          } else if (rawTimestamp is String) {
            timestamp = int.tryParse(rawTimestamp) ?? 0;
          }

          loadedMessages.add({
            'id': entry.key,
            'sender': value['sender'] ?? '',
            'message': value['message'] ?? '',
            'timestamp': timestamp,
          });
        });

        loadedMessages.sort((a, b) {
          if (a['timestamp'] == b['timestamp']) {
            return a['id'].compareTo(b['id']);
          }
          return a['timestamp'].compareTo(b['timestamp']);
        });
      }

      setState(() => messages = loadedMessages);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final msgRef = _dbRef.child('chats/${widget.userId}/messages').push();
    final newMsg = {
      'sender': currentUserRole,
      'message': text,
      'timestamp': ServerValue.timestamp,
    };

    msgRef.set(newMsg);
    _msgController.clear();

    Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with Admin')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['sender'] == currentUserRole;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.green[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      msg['message'],
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
