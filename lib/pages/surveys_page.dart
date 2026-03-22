import 'package:flutter/material.dart';
import 'package:projet_sejour/services/feedback_service.dart';
import 'package:projet_sejour/widgets/feedback/survey_dialog.dart';
import 'package:intl/intl.dart';

class SurveysPage extends StatefulWidget {
  const SurveysPage({super.key});

  @override
  State<SurveysPage> createState() => _SurveysPageState();
}

class _SurveysPageState extends State<SurveysPage> {
  final FeedbackService _feedbackService = FeedbackService();
  List<SurveyPeriod> _periods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final periods = await _feedbackService.getSurveyPeriods();
    if (mounted) {
      setState(() {
        _periods = periods.reversed.toList(); // Newest first
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'My Surveys',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.primary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _periods.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _periods.length,
                    itemBuilder: (context, index) {
                      final period = _periods[index];
                      return _buildSurveyCard(period);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final periods = await _feedbackService.getSurveyPeriods();
          if (periods.isNotEmpty && mounted) {
            // Priority: current period not answered > first period not answered > last period
            final currentPeriod = periods.lastWhere(
              (p) => !p.isAnswered && (p.start.isBefore(DateTime.now()) || p.start.day == DateTime.now().day),
              orElse: () => periods.firstWhere((p) => !p.isAnswered, orElse: () => periods.last)
            );
            
            final result = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => SurveyDialog(period: currentPeriod),
            );
            
            if (result == true) {
              _loadData();
            }
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not find any survey periods. Start a trip first!')),
            );
          }
        },
        icon: const Icon(Icons.science_outlined),
        label: const Text('Simulate Survey'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No surveys available yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Surveys appear every 3 days during your trip.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyCard(SurveyPeriod period) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMissed = !period.isAnswered && period.end.isBefore(DateTime.now());
    final isUpcoming = period.start.isAfter(DateTime.now());
    final isCurrent = !period.isAnswered && !isUpcoming && !isMissed;

    final dateFormat = DateFormat('MMM d');
    final dateRange = '${dateFormat.format(period.start)} - ${dateFormat.format(period.end)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent ? colorScheme.primary.withValues(alpha: 0.3) : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left Status Bar
              Container(
                width: 6,
                color: period.isAnswered
                    ? Colors.greenAccent[700]
                    : isMissed
                        ? Colors.redAccent
                        : isCurrent
                            ? colorScheme.primary
                            : Colors.grey[300],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Survey #${period.surveyNo}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(period, isMissed, isUpcoming, isCurrent),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateRange,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      if (period.isAnswered)
                        Text(
                          'Thank you for your feedback! Your response helps us improve the pilgrimage experience.',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                        )
                      else if (isUpcoming)
                        Text(
                          'This survey will be available after ${dateFormat.format(period.start)}.',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic),
                        )
                      else
                        ElevatedButton(
                          onPressed: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => SurveyDialog(period: period),
                            );
                            if (result == true) {
                              _loadData();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isMissed ? Colors.redAccent : colorScheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(isMissed ? 'Complete Missed Survey' : 'Take Survey Now', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SurveyPeriod period, bool isMissed, bool isUpcoming, bool isCurrent) {
    String label;
    Color color;
    IconData icon;

    if (period.isAnswered) {
      label = 'COMPLETED';
      color = Colors.green;
      icon = Icons.check_circle_rounded;
    } else if (isMissed) {
      label = 'MISSED';
      color = Colors.redAccent;
      icon = Icons.error_outline_rounded;
    } else if (isCurrent) {
      label = 'DUE NOW';
      color = Theme.of(context).colorScheme.primary;
      icon = Icons.pending_actions_rounded;
    } else {
      label = 'UPCOMING';
      color = Colors.grey;
      icon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}
