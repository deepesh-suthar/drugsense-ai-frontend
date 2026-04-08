// lib/message_model.dart

class Message {
  final String text;
  final bool isUser; // True if the message is from the user, false if from the AI
  final String? extractedText; // Optional text from OCR

  Message({required this.text, required this.isUser, this.extractedText});
}