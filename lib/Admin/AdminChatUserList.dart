import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'AdminChatSelection.dart';

class AdminChatUserListPage extends StatefulWidget {
  const AdminChatUserListPage({super.key});

  @override
  State<AdminChatUserListPage> createState() => _AdminChatUserListPageState();
}

class _AdminChatUserListPageState extends State<AdminChatUserListPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  late DatabaseReference chatsRef;
  late DatabaseReference usersRef;
  late DatabaseReference readStatusRef;

  List<Map<String, dynamic>> chattingUsers = [];

  @override
  void initState() {
    super.initState();
    chatsRef = _dbRef.child('chats');
    usersRef = _dbRef.child('users');
    readStatusRef = _dbRef.child('adminReadStatus');

    _setupListeners();
  }

  void _setupListeners() {
    // Listen for changes in chats, users, and readStatus simultaneously
    // For simplicity, just listen on chats changes and fetch users and readStatus once
    chatsRef.onValue.listen((event) async {
      final chatsSnapshot = event.snapshot;
      if (!chatsSnapshot.exists) {
        setState(() {
          chattingUsers = [];
        });
        return;
      }

      final usersSnapshot = await usersRef.get();
      final readStatusSnapshot = await readStatusRef.get();

      if (!usersSnapshot.exists) {
        setState(() {
          chattingUsers = [];
        });
        return;
      }

      final Map<String, dynamic> chatMap = Map<String, dynamic>.from(chatsSnapshot.value as Map);
      final Map<String, dynamic> usersMap = Map<String, dynamic>.from(usersSnapshot.value as Map);
      final Map<String, dynamic> readStatusMap = readStatusSnapshot.exists
          ? Map<String, dynamic>.from(readStatusSnapshot.value as Map)
          : {};

      List<Map<String, dynamic>> usersList = [];

      for (var entry in chatMap.entries) {
        final userId = entry.key;
        final messagesNode = entry.value;

        if (messagesNode is Map && messagesNode['messages'] is Map) {
          final messagesMap = Map<String, dynamic>.from(messagesNode['messages']);

          // Check if user has sent at least one message (not from admin)
          bool userMessagedAdmin = messagesMap.values.any((msg) {
            final m = Map<String, dynamic>.from(msg);
            return m['sender'] != 'admin';
          });

          if (userMessagedAdmin) {
            String email = 'Unknown Email';
            String role = 'Unknown';

            if (usersMap.containsKey(userId)) {
              final userData = Map<String, dynamic>.from(usersMap[userId]);
              email = userData['email']?.toString() ?? email;
              role = userData['role']?.toString() ?? role;
            }

            // Find last message timestamp from user (artist/visitor)
            int lastUserMessageTs = 0;
            messagesMap.values.forEach((msg) {
              final m = Map<String, dynamic>.from(msg);
              if (m['sender'] != 'admin' && m['timestamp'] is int) {
                if (m['timestamp'] > lastUserMessageTs) lastUserMessageTs = m['timestamp'];
              }
            });

            // Get last read timestamp by admin for this user
            int lastReadTs = 0;
            if (readStatusMap.containsKey(userId)) {
              final val = readStatusMap[userId];
              if (val is int) lastReadTs = val;
              else if (val is String) lastReadTs = int.tryParse(val) ?? 0;
            }

            bool hasNewMessages = lastUserMessageTs > lastReadTs;

            usersList.add({
              'userId': userId,
              'email': email,
              'role': role,
              'hasNewMessages': hasNewMessages,
            });
          }
        }
      }

      setState(() {
        chattingUsers = usersList;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users Who Messaged Admin")),
      body: chattingUsers.isEmpty
          ? const Center(child: Text("No chats found"))
          : ListView.builder(
        itemCount: chattingUsers.length,
        itemBuilder: (context, index) {
          final user = chattingUsers[index];
          return ListTile(
            title: Text(user['email'] ?? 'Unknown Email'),
            subtitle: Text("Role: ${user['role']}"),
            trailing: user['hasNewMessages'] == true
                ? Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            )
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminChatPage(
                    userId: user['userId']!,
                    userRole: user['role']!,
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