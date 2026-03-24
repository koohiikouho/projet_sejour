import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_google/langchain_google.dart';
import 'package:projet_sejour/data/mock_data.dart';

class ChatbotService {
  late final ChatGoogleGenerativeAI _model;
  // Store only the human and AI dialogue history, not system messages
  final List<ChatMessage> _dialogueHistory = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    // Initial welcome message
    _dialogueHistory.add(ChatMessage.ai(
      'Hello! I am Lumen AI Assistant. How can I help you with your Projet Sejour experience today?'
    ));
  }

  Future<String> _fetchContext() async {
    final user = _auth.currentUser;
    if (user == null) {
      return "ERROR: No user is currently logged into Firebase. I cannot access private data.";
    }

    String context = "USER CONTEXT (UID: ${user.uid}):\n";

    try {
      // 1. User Info
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      String? teamId;
      if (userDoc.exists) {
        final data = userDoc.data()!;
        teamId = data['team'];
        context += "- Username: ${data['username']}\n";
        context += "- Role: ${data['role']}\n";
        context += "- Team ID: ${teamId ?? 'None'}\n";
      }

      // 2. ANNOUNCEMENTS (Mock Data)
      context += "\nLATEST ANNOUNCEMENTS:\n";
      for (var a in mockAnnouncements) {
        context += "- [${a.time}] ${a.title}: ${a.description}\n";
      }

      // 3. JOURNAL DATA
      context += "\nJOURNAL MESSAGES:\n";
      final journalSnapshot = await _firestore
          .collection('journals')
          .doc(user.uid)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      
      if (journalSnapshot.docs.isNotEmpty) {
        for (var doc in journalSnapshot.docs) {
          final data = doc.data();
          context += "* [${data['dateStr'] ?? 'No Date'}] ${data['content']}\n";
        }
      } else {
        context += "(No journal entries found.)\n";
      }

      // 4. TRIPS & HIERARCHICAL ITINERARY
      context += "\nTRIP ITINERARIES:\n";
      final tripsSnapshot = await _firestore.collection('trips').limit(2).get();
      
      if (tripsSnapshot.docs.isNotEmpty) {
        for (var tripDoc in tripsSnapshot.docs) {
          final tripData = tripDoc.data();
          context += "--- Trip: ${tripData['tripName']} (Status: ${tripData['status']}) ---\n";
          
          final daysSnapshot = await tripDoc.reference.collection('itineraryDays').orderBy('dayNumber').get();
          for (var dayDoc in daysSnapshot.docs) {
            final dayData = dayDoc.data();
            final dynamic dateValue = dayData['date'];
            final String datePart = (dateValue is Timestamp) 
                ? dateValue.toDate().toString().split(' ')[0] 
                : 'N/A';
            context += "  Day ${dayData['dayNumber']} ($datePart):\n";
            
            final activitiesSnapshot = await dayDoc.reference.collection('activities').get();
            for (var actDoc in activitiesSnapshot.docs) {
              final actData = actDoc.data();
              context += "    - [${actData['scheduledArrival']} to ${actData['scheduledDeparture']}] ${actData['siteName']}\n";
              context += "      Location: ${actData['location']}\n";
              context += "      Description: ${actData['description']}\n";
              if (actData['whatToBring'] != null) {
                context += "      Bring: ${actData['whatToBring']}\n";
              }
            }
          }
          context += "\n";
        }
      } else {
        context += "(No trips found.)\n";
      }

    } catch (e) {
      context += "\nDATABASE ERROR: $e\n";
    }

    return context;
  }

  Future<String> getResponse(String message) async {
    final context = await _fetchContext();
    
    final systemPrompt = ChatMessage.system(
      'You are Lumen AI Assistant for Projet Sejour.\n'
      'STRICT RULES:\n'
      '1. ONLY answer questions related to Projet Sejour, travel, or the user\'s stay.\n'
      '2. Use the provided context (Announcements, Itinerary, Journal) to answer accurately.\n'
      '3. DO NOT provide code, programming help, or technical advice.\n'
      '4. If a user asks something outside this scope, politely decline.\n'
      '\n'
      'CRITICAL FORMATTING RULES:\n'
      '1. When presenting an itinerary or list of activities, ALWAYS use a clean, bulleted list or a table-like format.\n'
      '2. Use bold text for site names and times to make them stand out.\n'
      '3. Order everything chronologically by time.\n'
      '4. If multiple days are requested, use clear headers for each Day (e.g., "### Day 1").\n'
      '5. Keep your responses concise and easy to read on a mobile screen.\n'
      '\n'
      'REAL-TIME CONTEXT:\n'
      '$context'
    );

    final fullPrompt = [
      systemPrompt,
      ..._dialogueHistory,
      ChatMessage.humanText(message)
    ];
    
    _dialogueHistory.add(ChatMessage.humanText(message));
    
    try {
      final response = await _model.invoke(PromptValue.chat(fullPrompt));
      final aiMessage = response.output;
      _dialogueHistory.add(aiMessage);
      return aiMessage.contentAsString;
    } catch (e) {
      return "Error: $e";
    }
  }

  List<ChatMessage> get history => _dialogueHistory;
}
