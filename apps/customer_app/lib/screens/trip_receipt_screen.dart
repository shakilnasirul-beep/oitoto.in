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

  String _selectedPaymentMode = 'cash';
  bool _isUpiPaid = false;

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
    final bookingId = int.tryParse(widget.booking['id']?.toString() ?? '') ?? 1;

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
                decoration: const BoxDecoration(
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
              const SizedBox(height: 20),

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
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Payment Method Selection Card (Shown on Ride Completion)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Payment Method',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Cash to Driver Button
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedPaymentMode = 'cash'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _selectedPaymentMode == 'cash'
                                    ? AppColors.warmYellowLight
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedPaymentMode == 'cash'
                                      ? AppColors.warmYellowDark
                                      : AppColors.border,
                                  width: _selectedPaymentMode == 'cash' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.payments_rounded,
                                    color: _selectedPaymentMode == 'cash'
                                        ? const Color(0xFF854D0E)
                                        : AppColors.textMuted,
                                    size: 26,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Cash to Driver',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.deepNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pay ₹$finalFare in Cash',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // UPI / Online Button
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedPaymentMode = 'upi'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _selectedPaymentMode == 'upi'
                                    ? AppColors.primaryGreenLight
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedPaymentMode == 'upi'
                                      ? AppColors.primaryGreen
                                      : AppColors.border,
                                  width: _selectedPaymentMode == 'upi' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner_rounded,
                                    color: _selectedPaymentMode == 'upi'
                                        ? AppColors.primaryGreen
                                        : AppColors.textMuted,
                                    size: 26,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'UPI / Online',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.deepNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'GPay / PhonePe / QR',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // If Cash Selected: Guidance
                    if (_selectedPaymentMode == 'cash') ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warmYellowLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFF854D0E), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Hand ₹$finalFare cash directly to driver ${b['driver_name'] ?? 'Subrata Roy'}.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF854D0E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // If UPI Selected: QR Code & UPI Apps
                    if (_selectedPaymentMode == 'upi') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreenLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6),
                                    ],
                                  ),
                                  child: const Icon(Icons.qr_code_2_rounded, size: 72, color: AppColors.deepNavy),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Scan & Pay Driver',
                                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.deepNavy),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'UPI: oitoto.${b['driver_phone'] ?? '9832109876'}@upi',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryGreenDark),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Amount: ₹$finalFare',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryGreen),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                minimumSize: const Size(double.infinity, 42),
                              ),
                              onPressed: () {
                                setState(() => _isUpiPaid = true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('UPI Payment Confirmed! Thank you.')),
                                );
                              },
                              icon: Icon(_isUpiPaid ? Icons.check_circle : Icons.payment, color: Colors.white, size: 18),
                              label: Text(
                                _isUpiPaid ? 'UPI Paid Successfully ✅' : 'I Have Paid via UPI',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
              const SizedBox(height: 24),

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
