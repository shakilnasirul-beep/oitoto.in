import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/api_service.dart';
import 'home_screen.dart';

class TripReceiptScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const TripReceiptScreen({super.key, required this.booking});

  @override
  State<TripReceiptScreen> createState() => _TripReceiptScreenState();
}

class _TripReceiptScreenState extends State<TripReceiptScreen> {
  int _selectedRating = 5;
  final List<String> _selectedTags = [];
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _availableTags = [
    'Clean E-Rickshaw',
    'Polite Driver',
    'Smooth Driving',
    'Quick Arrival',
    'Fair Fare',
  ];

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _handleSubmitFeedback() async {
    setState(() => _isSubmitting = true);
    final bookingId = widget.booking['id'] as int? ?? 1;

    await ApiService().submitRating(
      bookingId,
      _selectedRating,
      _selectedTags.join(','),
      _commentController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(ApiService().language);
    final b = widget.booking;

    final finalFare = (b['final_fare'] ?? b['estimated_fare'] ?? '20.00').toString();
    final baseFare = (b['base_fare_charged'] ?? '20.00').toString();
    final distFare = (b['distance_fare_charged'] ?? '0.00').toString();
    final waitFare = (b['waiting_fare_charged'] ?? '0.00').toString();
    final distance = (b['actual_distance_km'] ?? b['estimated_distance_km'] ?? '1.5').toString();
    final paymentMode = (b['payment_mode'] ?? 'cash').toString().toUpperCase();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(loc.tr('trip_receipt')),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Success Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreenLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 44),
              ),
              const SizedBox(height: 14),
              const Text(
                'Ride Completed! Cholo!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deepNavy),
              ),
              const SizedBox(height: 4),
              Text(
                'Booking #${b['booking_code'] ?? 'OT-2026'}',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              // Itemized Receipt Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Base Fare', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                        Text('₹$baseFare', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Distance Charge ($distance km)', style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
                        Text('₹$distFare', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Waiting Charges', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                        Text('₹$waitFare', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.tr('total_fare'),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.deepNavy),
                        ),
                        Text(
                          '₹$finalFare',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.primaryGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Mode', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warmYellowLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            paymentMode,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF854D0E)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Rating Header
              Text(
                loc.tr('rate_driver'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.deepNavy),
              ),
              const SizedBox(height: 12),

              // 5 Star Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return IconButton(
                    iconSize: 38,
                    onPressed: () => setState(() => _selectedRating = starNum),
                    icon: Icon(
                      starNum <= _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.warmYellow,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Tag Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textMain)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryGreen,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? AppColors.primaryGreen : AppColors.border),
                    onSelected: (_) => _toggleTag(tag),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Comments input
              TextField(
                controller: _commentController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Share more feedback (Optional)...',
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmitFeedback,
                  child: _isSubmitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(loc.tr('submit_feedback')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
