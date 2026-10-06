import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';

// --- 1. Message Bubble ---
class ChatMessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;

  const ChatMessageBubble({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg["sender"] == "user";
    final text = (msg["text"] ?? "").toString();
    final imageBase64 = msg["imageBase64"];
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coach Avatar on Left for Bot
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 2, right: 8),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC8E6C9), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  "assets/images/n-logo.png",
                  height: 18,
                  width: 18,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],

          // Bubble Container
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isUser ? screenWidth * 0.78 : screenWidth * 0.75,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser ? null : Colors.white,
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 16 : 4),
                  topRight: Radius.circular(isUser ? 4 : 16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: const Color(0xFFE8F5E9), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? Color(0xFF2E7D32).withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    const Text(
                      "NutriBot",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E7D32),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  if (imageBase64 != null && imageBase64.toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          base64Decode(imageBase64),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  if (text.isNotEmpty)
                    _buildFormattedText(text, isUser),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String rawText, bool isUser) {
    // 1. Clean out annoying triple asterisks or markdown headers
    String cleaned = rawText
        .replaceAll(RegExp(r'\*{3,}'), '')
        .replaceAll(RegExp(r'#{1,6}\s*'), '')
        .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '• ');

    // 2. Base text styles
    final baseStyle = TextStyle(
      fontSize: 14.5,
      height: 1.45,
      color: isUser ? Colors.white : const Color(0xFF212121),
    );
    final boldStyle = TextStyle(
      fontSize: 14.5,
      height: 1.45,
      fontWeight: FontWeight.bold,
      color: isUser ? Colors.white : const Color(0xFF1B5E20),
    );

    // 3. Match bold spans like **bold text**
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(cleaned)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: cleaned.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: boldStyle,
      ));
      lastIndex = match.end;
    }

    if (lastIndex < cleaned.length) {
      spans.add(TextSpan(
        text: cleaned.substring(lastIndex),
        style: baseStyle,
      ));
    }

    if (spans.isEmpty) {
      return Text(cleaned, style: baseStyle);
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

// --- 2. Typing Indicator ---
class ChatTypingIndicator extends StatelessWidget {
  final AnimationController controller;
  const ChatTypingIndicator({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 6, left: 10, right: 10, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            double phase(int i) => (controller.value + i * 0.2) % 1.0;
            double opacityFor(int i) =>
                (math.sin(2 * math.pi * phase(i)) + 1) / 2;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    // FIX: Replaced withOpacity with withValues(alpha: ...)
                    color: Colors.grey.withValues(
                      alpha: opacityFor(i).clamp(0.2, 1.0),
                    ),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

// --- 3. Input Area ---
class ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isListening;
  final File? selectedImage;
  final VoidCallback onToggleListening;
  final VoidCallback onRemoveImage;
  final Function(ImageSource) onPickImage;
  final Function(String) onSendMessage;

  const ChatInputArea({
    super.key,
    required this.controller,
    required this.isListening,
    required this.selectedImage,
    required this.onToggleListening,
    required this.onRemoveImage,
    required this.onPickImage,
    required this.onSendMessage,
  });

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                onPickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                onPickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (selectedImage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    selectedImage!,
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: onRemoveImage,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Transform.rotate(
                          angle: 0.8,
                          child: Icon(
                            Icons.attach_file,
                            color: selectedImage != null
                                ? const Color(0xFF37C97D)
                                : Colors.grey,
                          ),
                        ),
                        onPressed: () => _showAttachmentOptions(context),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: "Type or speak...",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          onSubmitted: onSendMessage,
                        ),
                      ),
                      GestureDetector(
                        onTap: onToggleListening,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              // FIX: Replaced withOpacity with withValues(alpha: ...)
                              color: isListening
                                  ? Colors.redAccent.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isListening ? Icons.mic : Icons.mic_none,
                              color: isListening ? Colors.red : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onSendMessage(controller.text),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF37C97D),
                  ),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- 4. Navigation Drawer ---
class ChatDrawer extends StatelessWidget {
  const ChatDrawer({super.key});

  Future<void> _showRenameDialog(
    BuildContext context,
    String chatId,
    String currentTitle,
  ) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final controller = TextEditingController(text: currentTitle);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename chat'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await chatProvider.renameChat(chatId, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    return Drawer(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: chatProvider.chatSessionsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snapshot.data!.docs;
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Conversations',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_note,
                          size: 26,
                          color: Colors.grey,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          final id = await chatProvider.createNewChat(
                            "Chat with NutriBot",
                          );
                          if (id != null) chatProvider.setActiveChat(id);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: sessions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final chatDoc = sessions[index];
                      final data = chatDoc.data();
                      final title = (data['title'] ?? 'Untitled').toString();
                      final isSelected =
                          chatProvider.activeChatId == chatDoc.id;
                      return GestureDetector(
                        onTap: () {
                          chatProvider.setActiveChat(chatDoc.id);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.green.shade50
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: isSelected
                                ? Border.all(
                                    color: const Color(0xFF37C97D),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'rename') {
                                    _showRenameDialog(
                                      context,
                                      chatDoc.id,
                                      title,
                                    );
                                    // FIX: Added curly braces
                                  } else if (value == 'delete') {
                                    await chatProvider.deleteChat(chatDoc.id);
                                    // FIX: Added curly braces
                                  } else if (value == 'share') {
                                    await chatProvider.shareChat(chatDoc.id);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'rename',
                                    child: Text('Rename'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'share',
                                    child: Text('Share'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
