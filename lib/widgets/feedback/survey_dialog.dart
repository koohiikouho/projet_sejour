import 'package:flutter/material.dart';
import 'package:projet_sejour/services/feedback_service.dart';
import 'package:projet_sejour/models/activity.dart';
import 'package:intl/intl.dart';

class SurveyDialog extends StatefulWidget {
  final SurveyPeriod period;
  const SurveyDialog({super.key, required this.period});

  @override
  State<SurveyDialog> createState() => _SurveyDialogState();
}

class _SurveyDialogState extends State<SurveyDialog> {
  final FeedbackService _feedbackService = FeedbackService();
  bool _isSubmitting = false;
  List<Activity> _periodItinerary = [];
  bool _isLoadingItinerary = true;

  int _pacingRating = 0;
  int _clarityRating = 0;
  int _experienceRating = 0;
  final TextEditingController _commentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItinerary();
  }

  Future<void> _loadItinerary() async {
    final activities = await _feedbackService.getItineraryForPeriod(widget.period.start, widget.period.end);
    if (mounted) {
      setState(() {
        _periodItinerary = activities;
        _isLoadingItinerary = false;
      });
    }
  }

  Widget _buildStarRating(String title, int currentRating, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 32,
              ),
              onPressed: () => onChanged(index + 1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _submit() async {
    if (_pacingRating == 0 || _clarityRating == 0 || _experienceRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating for all questions before submitting.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _feedbackService.submitFeedback(widget.period, {
        'pacingRating': _pacingRating,
        'clarityRating': _clarityRating,
        'experienceRating': _experienceRating,
        'comments': _commentsController.text.trim(),
      });
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your valuable feedback!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    final dateRange = '${dateFormat.format(widget.period.start)} - ${dateFormat.format(widget.period.end)}';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.rate_review_rounded, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sojourn Feedback',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          dateRange,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // Itinerary Context
                    if (!_isLoadingItinerary && _periodItinerary.isNotEmpty) ...[
                      const Text(
                        "JOG YOUR MEMORY",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: _periodItinerary.take(3).map((a) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.place_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(a.siteName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                      if (_periodItinerary.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text("...and ${_periodItinerary.length - 3} more activities", style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                        ),
                      const SizedBox(height: 24),
                    ],

                    _buildStarRating(
                      'How would you rate the pacing?',
                      _pacingRating,
                      (v) => setState(() => _pacingRating = v),
                    ),
                    _buildStarRating(
                      'How clear were instructions and locations?',
                      _clarityRating,
                      (v) => setState(() => _clarityRating = v),
                    ),
                    _buildStarRating(
                      'How enriching was the experience?',
                      _experienceRating,
                      (v) => setState(() => _experienceRating = v),
                    ),
                    const Text('Any specific highlights or concerns?', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _commentsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Optional comments...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
