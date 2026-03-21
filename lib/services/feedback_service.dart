import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projet_sejour/services/auth_service.dart';
import 'package:projet_sejour/data/local_repository.dart';
import 'package:projet_sejour/models/activity.dart';

class SurveyPeriod {
  final DateTime start;
  final DateTime end;
  final int surveyNo;
  final bool isAnswered;
  final Map<String, dynamic>? data;

  SurveyPeriod({
    required this.start,
    required this.end,
    required this.surveyNo,
    this.isAnswered = false,
    this.data,
  });

  String get bundleId => '${end.year}_sojourn_1_${end.toIso8601String().split('T')[0]}_survey_$surveyNo';
}

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalRepository _localRepository = LocalRepository();

  Future<bool> checkIfSurveyDue() async {
    final periods = await getSurveyPeriods();
    final currentPeriod = periods.lastWhere((p) => p.end.isBefore(DateTime.now()) || p.end.day == DateTime.now().day, orElse: () => periods.last);
    
    // If the latest period that has passed (or is today) is not answered, it's "due" (at least to remind them)
    // Actually, user wants it every 3 days.
    final prefs = await SharedPreferences.getInstance();
    final lastDismissedStr = prefs.getString('last_survey_dismissed_date');
    if (lastDismissedStr != null) {
      final lastDismissed = DateTime.parse(lastDismissedStr);
      if (DateTime.now().difference(lastDismissed).inDays < 3) return false;
    }

    return !currentPeriod.isAnswered;
  }

  Future<void> dismissSurvey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_survey_dismissed_date', DateTime.now().toIso8601String());
  }

  Future<List<SurveyPeriod>> getSurveyPeriods() async {
    final trip = await _localRepository.getFirstTrip();
    if (trip == null) return [];

    final List<SurveyPeriod> periods = [];
    DateTime currentStart = trip.startDate;
    int surveyNo = 1;

    // Fetch answered surveys from Firestore
    final userId = FirebaseAuth.instance.currentUser?.uid ?? (await SharedPreferences.getInstance()).getString('auth_token') ?? 'anonymous';

    final answeredSnap = await _firestore
        .collection('responses')
        .where('userId', isEqualTo: userId)
        .get();
    
    final answeredBundles = {for (var doc in answeredSnap.docs) (doc.data()['bundleId'] as String): doc.data()};

    while (currentStart.isBefore(DateTime.now()) || currentStart.isAtSameMomentAs(DateTime.now())) {
      DateTime currentEnd = currentStart.add(const Duration(days: 2)); // 3-day window (inclusive)
      
      final tempPeriod = SurveyPeriod(start: currentStart, end: currentEnd, surveyNo: surveyNo);
      final data = answeredBundles[tempPeriod.bundleId];

      periods.add(SurveyPeriod(
        start: currentStart,
        end: currentEnd,
        surveyNo: surveyNo,
        isAnswered: data != null,
        data: data,
      ));

      currentStart = currentEnd.add(const Duration(days: 1));
      surveyNo++;
      
      // Stop generating if we are too far in the future
      if (currentStart.isAfter(DateTime.now().add(const Duration(days: 7)))) break;
    }

    return periods;
  }

  Future<List<Activity>> getItineraryForPeriod(DateTime start, DateTime end) async {
    final allActivities = await _localRepository.getAllActivities();
    return allActivities.where((a) {
      return (a.scheduledArrival.isAfter(start) || a.scheduledArrival.isAtSameMomentAs(start)) &&
             (a.scheduledArrival.isBefore(end) || a.scheduledArrival.day == end.day);
    }).toList();
  }

  Future<void> submitFeedback(SurveyPeriod period, Map<String, dynamic> answers) async {
    final prefs = await SharedPreferences.getInstance();
    final authService = AuthService();
    final userData = await authService.getUserData();
    
    final userId = FirebaseAuth.instance.currentUser?.uid ?? prefs.getString('auth_token') ?? 'anonymous';
    final teamId = 'team_alpha';
    
    final docId = '${period.bundleId}_$userId';

    await _firestore
        .collection('responses')
        .doc(docId)
        .set({
      'userId': userId,
      'bundleId': period.bundleId,
      'teamId': teamId,
      'userName': userData['name'] ?? 'User',
      'timestamp': FieldValue.serverTimestamp(),
      'periodStart': period.start.toIso8601String(),
      'periodEnd': period.end.toIso8601String(),
      'answers': answers,
    });

    await prefs.setString('last_survey_completed_date', DateTime.now().toIso8601String());
  }
}
