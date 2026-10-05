import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

class ChatProvider extends ChangeNotifier {
  String? _activeChatId;
  String? get activeChatId => _activeChatId;

  // Helper to get current User ID safely
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Switch active chat
  void setActiveChat(String? chatId) {
    _activeChatId = chatId;
    notifyListeners();
  }

  /// Create a new chat session
  Future<String?> createNewChat(String title) async {
    final uid = _currentUserId;
    if (uid == null) return null;

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('ChatsCollection')
          .add({
            'userId': uid,
            'title': title,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      _activeChatId = docRef.id;
      notifyListeners();
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Rename a chat
  Future<void> renameChat(String chatId, String newTitle) async {
    if (chatId.isEmpty) return;

    final docRef = FirebaseFirestore.instance
        .collection('ChatsCollection')
        .doc(chatId);

    await docRef.update({
      'title': newTitle,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  /// Add a message
  Future<void> addMessage(
    String sender,
    String text, {
    String? imageBase64,
  }) async {
    final chatId = _activeChatId;
    if (chatId == null) return;

    final messagesRef = FirebaseFirestore.instance
        .collection('ChatsCollection')
        .doc(chatId)
        .collection('messages');

    await messagesRef.add({
      'sender': sender,
      'text': text,
      'imageBase64': imageBase64,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('ChatsCollection')
        .doc(chatId)
        .update({'updatedAt': FieldValue.serverTimestamp()});
  }

  /// Check if chat is empty, fetch Profile, and send Greeting
  Future<void> checkAndSendGreeting() async {
    final chatId = _activeChatId;
    final uid = _currentUserId;

    if (chatId == null || uid == null) return;

    try {
      final messagesRef = FirebaseFirestore.instance
          .collection('ChatsCollection')
          .doc(chatId)
          .collection('messages');

      final messageSnap = await messagesRef.limit(1).get();
      if (messageSnap.docs.isNotEmpty) return;

      final profileDoc = await FirebaseFirestore.instance
          .collection('UserProfiles')
          .doc(uid)
          .get();

      String name = "User";
      String goal = "Healthy Living";
      String dietType = "Balanced";
      String calories = "2000";
      String restrictions = "";

      if (profileDoc.exists) {
        final data = profileDoc.data();
        if (data != null) {
          name = data['name'] ?? "User";
          goal = data['dietaryGoal'] ?? "Healthy Living";
          dietType = data['dietType'] ?? "Balanced";
          final dynamic rawTarget = data['dailyCalorieTarget'];
          final int targetNum = (rawTarget is num)
              ? rawTarget.round()
              : (num.tryParse(rawTarget?.toString() ?? '')?.round() ?? 2000);
          calories = targetNum.toString();

          String rawRestr = data['restrictions'] ?? "";
          if (rawRestr.isNotEmpty && rawRestr.toLowerCase() != "none") {
            restrictions = " ($rawRestr)";
          }
        }
      }

      final String greeting =
          "Hello $name! 👋\n\n"
          "I have retrieved your profile data. 📊\n"
          "• **Goal:** $goal\n"
          "• **Diet:** $dietType$restrictions\n"
          "• **Target:** $calories kcal/day\n\n"
          "I'm ready to help you stay on track! What shall we do first?";

      await messagesRef.add({
        'sender': 'bot',
        'text': greeting,
        'imageBase64': null,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('ChatsCollection')
          .doc(chatId)
          .update({'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint("Error sending greeting: $e");
    }
  }

  /// Delete a chat
  Future<void> deleteChat(String chatId) async {
    final chatDocRef = FirebaseFirestore.instance
        .collection('ChatsCollection')
        .doc(chatId);

    final messagesSnap = await chatDocRef.collection('messages').get();
    if (messagesSnap.docs.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in messagesSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await chatDocRef.delete();

    // After deleting, check for other chats or create a new one
    await setActiveToLatestOrNull();
  }

  /// ✅ UPDATED: Set active to latest OR create new if none exist
  Future<void> setActiveToLatestOrNull() async {
    final uid = _currentUserId;
    if (uid == null) {
      _activeChatId = null;
      notifyListeners();
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection('ChatsCollection')
        .where('userId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      // Chat exists, use it
      _activeChatId = snap.docs.first.id;
    } else {
      // ✅ FIX: No chats found? Create one automatically!
      final newId = await createNewChat("Chat with NutriBot");
      _activeChatId = newId;
    }
    notifyListeners();
  }

  /// Stream messages
  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream() {
    final chatId = _activeChatId;
    if (chatId == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('ChatsCollection')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Stream sessions
  Stream<QuerySnapshot<Map<String, dynamic>>> chatSessionsStream() {
    final uid = _currentUserId;
    if (uid == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('ChatsCollection')
        .where('userId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  /// Share chat
  Future<void> shareChat(String chatId) async {
    if (chatId.isEmpty) return;

    final chatDoc = await FirebaseFirestore.instance
        .collection('ChatsCollection')
        .doc(chatId)
        .get();

    if (!chatDoc.exists) throw Exception('Chat not found');

    final title = (chatDoc.data()?['title'] ?? 'Chat').toString();

    final messagesSnap = await FirebaseFirestore.instance
        .collection('ChatsCollection')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .get();

    final buffer = StringBuffer();
    buffer.writeln('Conversation: $title\n');

    for (final m in messagesSnap.docs) {
      final data = m.data();
      final sender = (data['sender'] ?? '').toString();
      final text = (data['text'] ?? '').toString();
      buffer.writeln('$sender: $text');
    }

    final shareText = buffer.toString().trim();
    if (shareText.isEmpty) throw Exception('Nothing to share');

    final params = ShareParams(text: shareText, subject: title);
    await SharePlus.instance.share(params);
  }

  /// Get recent messages for AI conversation memory
  Future<List<Map<String, dynamic>>> getRecentMessages({int limit = 6}) async {
    final chatId = _activeChatId;
    if (chatId == null) return [];

    try {
      final snap = await FirebaseFirestore.instance
          .collection('ChatsCollection')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final docs = snap.docs.reversed.toList();
      List<Map<String, dynamic>> history = [];

      for (var doc in docs) {
        final d = doc.data();
        final sender = d['sender'] == 'user' ? 'user' : 'assistant';
        final text = (d['text'] as String?)?.trim() ?? '';
        if (text.isNotEmpty) {
          history.add({"role": sender, "content": text});
        }
      }
      return history;
    } catch (e) {
      debugPrint("Error fetching recent messages: $e");
      return [];
    }
  }
}
