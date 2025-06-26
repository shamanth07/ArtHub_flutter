// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
//
// class UserChatPage extends StatefulWidget {
//   final String userId;
//   final String userRole; // "visitor", "artist", or "admin"
//
//   const UserChatPage({super.key, required this.userId, required this.userRole});
//
//   @override
//   State<UserChatPage> createState() => _UserChatPageState();
// }
//
// class _UserChatPageState extends State<UserChatPage> {
//   final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
//   final TextEditingController _msgController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//
//   List<Map<String, dynamic>> messages = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _listenToMessages();
//   }
//   void _listenToMessages() {
//     final messagesRef = _dbRef.child('chats/${widget.userId}/messages').orderByChild('timestamp');
//
//     messages.clear();
//
//     messagesRef.onChildAdded.listen((event) {
//       if (event.snapshot.exists) {
//         final value = Map<String, dynamic>.from(event.snapshot.value as Map);
//
//         int timestamp = 0;
//         final rawTimestamp = value['timestamp'];
//         if (rawTimestamp is int) {
//           timestamp = rawTimestamp;
//         } else if (rawTimestamp is double) {
//           timestamp = rawTimestamp.toInt();
//         } else if (rawTimestamp is String) {
//           timestamp = int.tryParse(rawTimestamp) ?? 0;
//         }
//
//         final newMessage = {
//           'sender': value['sender'] ?? '',
//           'message': value['message'] ?? '',
//           'timestamp': timestamp,
//         };
//
//         setState(() {
//           messages.add(newMessage);
//         });
//
//         WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
//       }
//     });
//   }
//
//
//   void _sendMessage() {
//     final text = _msgController.text.trim();
//     if (text.isEmpty) return;
//
//     final newMsg = {
//       'sender': widget.userRole.toLowerCase(),
//       'message': text,
//       'timestamp': DateTime.now().millisecondsSinceEpoch,
//     };
//
//     final msgId = _dbRef.child('chats/${widget.userId}/messages').push().key;
//     if (msgId != null) {
//       _dbRef.child('chats/${widget.userId}/messages/$msgId').set(newMsg);
//     }
//
//     _msgController.clear();
//
//     // Scroll slightly after sending new message
//     Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
//   }
//
//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chat with Admin'),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               controller: _scrollController,
//               padding: const EdgeInsets.all(12),
//               itemCount: messages.length,
//               itemBuilder: (context, index) {
//                 final msg = messages[index];
//                 final isUser = msg['sender'] == widget.userRole.toLowerCase();
//                 return Align(
//                   alignment:
//                   isUser ? Alignment.centerRight : Alignment.centerLeft,
//                   child: Container(
//                     margin: const EdgeInsets.symmetric(vertical: 4),
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: isUser ? Colors.green[100] : Colors.grey[300],
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       msg['message'],
//                       style: const TextStyle(color: Colors.black),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _msgController,
//                     decoration: InputDecoration(
//                       hintText: 'Type a message',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     onSubmitted: (_) => _sendMessage(),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: _sendMessage,
//                 )
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserChatPage extends StatefulWidget {
  final String userId;
  final String userRole; // "visitor", "artist", or "admin"

  const UserChatPage({super.key, required this.userId, required this.userRole});

  @override
  State<UserChatPage> createState() => _UserChatPageState();
}

class _UserChatPageState extends State<UserChatPage> {
  final _dbRef = FirebaseDatabase.instance.ref();
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> messages = [];
  String currentUserId = '';
  String currentUserRole = '';

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      await _fetchUserRole();
      _fetchMessages();
    }
  }

  Future<void> _fetchUserRole() async {
    final userSnap = await _dbRef.child("users/$currentUserId").get();
    if (userSnap.exists && userSnap.child("role").value != null) {
      currentUserRole = userSnap.child("role").value.toString().toLowerCase();
    } else {
      final adminSnap = await _dbRef.child("admin/$currentUserId").get();
      if (adminSnap.exists && adminSnap.child("role").value != null) {
        currentUserRole = adminSnap.child("role").value.toString().toLowerCase();
      }
    }
  }

  void _fetchMessages() {
    final messagesRef = _dbRef.child('chats/${widget.userId}/messages');

    messagesRef.onValue.listen((event) {
      final msgList = <Map<String, dynamic>>[];

      if (event.snapshot.exists) {
        final raw = Map<String, dynamic>.from(event.snapshot.value as Map);

        raw.entries.forEach((entry) {
          final data = Map<String, dynamic>.from(entry.value as Map);
          int timestamp = 0;
          final ts = data['timestamp'];
          if (ts is int) timestamp = ts;
          else if (ts is double) timestamp = ts.toInt();
          else if (ts is String) timestamp = int.tryParse(ts) ?? 0;

          msgList.add({
            'id': entry.key,
            'sender': data['sender'] ?? '',
            'message': data['message'] ?? '',
            'timestamp': timestamp,
          });
        });

        msgList.sort((a, b) {
          if (a['timestamp'] == b['timestamp']) {
            return a['id'].compareTo(b['id']);
          }
          return a['timestamp'].compareTo(b['timestamp']);
        });
      }

      setState(() {
        messages = msgList;
      });

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

  Color _bubbleColor(bool isSender) {
    if (currentUserRole == "admin") {
      return isSender ? Colors.blue[100]! : Colors.grey[300]!;
    } else {
      return isSender ? Colors.green[100]! : Colors.grey[300]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatWith = widget.userRole[0].toUpperCase() + widget.userRole.substring(1);
    return Scaffold(
      appBar: AppBar(title: Text('Chat with $chatWith')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['sender'] == currentUserRole;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _bubbleColor(isUser),
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
