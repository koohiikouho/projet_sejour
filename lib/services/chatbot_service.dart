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
      ),
    );
    
    // Initial system message
    _history.add(ChatMessage.system('You are Lumen AI Assistant, a helpful and friendly AI assistant for the Projet Sejour application.'));
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
