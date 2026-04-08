// lib/chat_screen.dart

import 'dart:typed_data'; // ✅ FIXED (no dart:io)
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import 'message_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  final List<Message> _messages = [];
  bool _isLoading = false;

  Uint8List? _selectedImage; // ✅ FIXED

  // 🔥 SEND MESSAGE
  void _sendMessage() async {
    final messageText = _controller.text.trim();
    if (messageText.isEmpty && _selectedImage == null) return;

    setState(() {
      _messages.add(Message(text: messageText, isUser: true));
      _isLoading = true;
    });

    _scrollToBottom();

    _controller.clear();

    final imageBytes = _selectedImage;

    setState(() {
      _selectedImage = null;
    });

    final response = await _apiService.sendChatMessage(
      messageText,
      imageBytes: imageBytes, // ✅ CORRECT
    );

    if (response != null) {
      setState(() {
        _messages.add(Message(
          text: response['aiResponse'] ?? "Something went wrong.",
          isUser: false,
          extractedText: response['extractedText'],
        ));
      });
    } else {
      setState(() {
        _messages.add(Message(
          text: "Failed to connect to server.",
          isUser: false,
        ));
      });
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  // 🔥 PICK IMAGE (WEB + MOBILE)
  void _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      final bytes = await image.readAsBytes(); // ✅ IMPORTANT
      setState(() {
        _selectedImage = bytes;
      });
    }
  }

  // 🔥 SCROLL
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DrugSense AI')),
      body: Column(
        children: [
          // 🔥 CHAT LIST
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // 🔥 LOADING
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text("DrugSense is thinking...",
                      style: TextStyle(color: Colors.grey.shade400))
                ],
              ),
            ),

          // 🔥 INPUT AREA
          _buildMessageComposer(),
        ],
      ),
    );
  }

  // 🔥 MESSAGE INPUT UI
  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔥 IMAGE PREVIEW (FIXED)
            if (_selectedImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _selectedImage!, // ✅ FIXED
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: const Icon(Icons.close, color: Colors.white),
                    )
                  ],
                ),
              ),

            Row(
              children: [
                // 📷 PICK IMAGE
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                ),

                // ✏️ TEXT FIELD
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask about a medicine...',
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),

                // 📤 SEND BUTTON
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 CHAT BUBBLE
  Widget _buildMessageBubble(Message message) {
    final isUser = message.isUser;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.green : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text, style: const TextStyle(color: Colors.white)),

            if (!isUser && (message.extractedText?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Extracted: ${message.extractedText}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}