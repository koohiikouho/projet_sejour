import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_google/langchain_google.dart';

class ChatbotService {
  late final ChatGoogleGenerativeAI _model;
  final List<ChatMessage> _history = [];

  ChatbotService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found or empty in .env file');
    }

    _model = ChatGoogleGenerativeAI(
      apiKey: apiKey,
      defaultOptions: const ChatGoogleGenerativeAIOptions(
        model: 'gemini-2.5-flash',
        temperature: 0.1,
      ),
    );
    
    // Initial system message with strict scope
    _history.add(ChatMessage.system(
      'You are Lumen AI Assistant, the official support assistant for the Projet Sejour application. '
      'Your scope is strictly limited to helping users with information about Projet Sejour, travel, and their stay. '
      'RULES: '
      '1. ONLY answer questions related to Projet Sejour or travel/stay assistance. '
      '2. NEVER provide programming code, technical development advice, or answers to general software engineering questions. '
      '3. If a user asks something outside this scope, politely say: "I apologize, but I am only trained to assist with questions regarding Projet Sejour and your travel experience."'
    ));

    // Initial welcome message
    _history.add(ChatMessage.ai(
      'Hello! I am Lumen AI Assistant. How can I help you with your Projet Sejour experience today?'
    ));
  }

  Future<String> getResponse(String message) async {
    final humanMsg = ChatMessage.humanText(message);
    _history.add(humanMsg);
    
    try {
      final response = await _model.invoke(PromptValue.chat(_history));
      final aiMessage = response.output;
      _history.add(aiMessage);
      
      // In LangChain 0.8.x, content can be ChatMessageContent, so we use contentAsString
      return aiMessage.contentAsString;
    } catch (e) {
      final errorMsg = 'Error: ${e.toString()}';
      final errorAiMsg = ChatMessage.ai(errorMsg);
      _history.add(errorAiMsg);
      return errorMsg;
    }
  }

  List<ChatMessage> get history => _history;
}
