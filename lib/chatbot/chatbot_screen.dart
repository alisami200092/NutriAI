import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nutriapp/chatbot/chatbot_functions.dart';
import 'package:nutriapp/chatbot/chatbot_widgets.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage>
    with SingleTickerProviderStateMixin, ChatbotLogic {
  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      drawer: const ChatDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 64,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 45),
          child: Image.asset(
            "assets/images/nutri-bot.png",
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: chatProvider.messagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !(snapshot.hasData && snapshot.data!.docs.isNotEmpty)) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  controller: messagesController, // From ChatbotLogic
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return ChatMessageBubble(msg: docs[index].data());
                  },
                );
              },
            ),
          ),
          if (showTyping)
            ChatTypingIndicator(
              controller: dotsController,
            ), // From ChatbotLogic
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),

          // Suggestions Grid
          if (showSuggestions) // From ChatbotLogic
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: suggestionLabels.length, // From ChatbotLogic
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.8,
                ),
                itemBuilder: (context, i) {
                  final visible =
                      suggestionVisible[i] &&
                      showSuggestions; // From ChatbotLogic
                  return AnimatedSlide(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    offset: visible ? Offset.zero : const Offset(0, 0.15),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      opacity: visible ? 1.0 : 0.0,
                      child: ElevatedButton(
                        onPressed: () => sendMessage(
                          suggestionLabels[i],
                        ), // From ChatbotLogic
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF37C97D),
                          side: const BorderSide(color: Color(0xFF37C97D)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          suggestionLabels[i],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Input Area
          ChatInputArea(
            controller: textController,
            isListening: isListening,
            selectedImage: selectedImage,
            onToggleListening: toggleListening, // From ChatbotLogic
            onRemoveImage: removeSelectedImage, // From ChatbotLogic
            onPickImage: pickImage, // From ChatbotLogic
            onSendMessage: sendMessage, // From ChatbotLogic
          ),
        ],
      ),
    );
  }
}
