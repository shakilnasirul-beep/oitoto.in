import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/api_service.dart';
import 'trip_receipt_screen.dart';

class ActiveRideScreen extends StatefulWidget {
  final int? bookingId;
  final Map<String, dynamic>? initialData;
  final Map<String, dynamic>? booking;

  const ActiveRideScreen({
    super.key,
    this.bookingId,
    this.initialData,
    this.booking,
  });

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  final MapController _mapController = MapController();
  Timer? _pollingTimer;

  Map<String, dynamic>? _currentBooking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.booking != null) {
      _currentBooking = widget.booking;
      _isLoading = false;
    } else if (widget.initialData != null) {
      _currentBooking = widget.initialData;
    }

    _pollActiveTrip();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => _pollActiveTrip());
  }

  Future<void> _pollActiveTrip() async {
    final active = await ApiService().getActiveBooking();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (active != null) {
          _currentBooking = active;
        }
      });

      // Check if trip completed
      if (active == null && _currentBooking != null && _currentBooking!['booking_status'] == 'completed') {
        _navigateToReceipt();
      } else if (active != null && active['booking_status'] == 'completed') {
        _navigateToReceipt();
      }
    }
  }

  void _navigateToReceipt() {
    _pollingTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TripReceiptScreen(booking: _currentBooking!),
      ),
    );
  }

  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Ride?'),
        content: const Text('Are you sure you want to cancel this E-Rickshaw ride?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && _currentBooking != null) {
      final id = _currentBooking!['id'] ?? widget.bookingId;
      final res = await ApiService().cancelBooking(id, 'Cancelled by rider');
      if (mounted) {
        if (res['success'] == true) {
          _pollingTimer?.cancel();
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Cancellation failed.')),
          );
        }
      }
    }
  }

  Future<void> _handleSos() async {
    final lat = (_currentBooking?['pickup_lat'] as num?)?.toDouble() ?? 22.5726;
    final lng = (_currentBooking?['pickup_lng'] as num?)?.toDouble() ?? 88.3639;
    final bId = _currentBooking?['id'] as int?;

    final res = await ApiService().triggerSos(lat, lng, bookingId: bId);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('SOS Emergency Alert', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          res['message'] ?? 'Emergency responders and your trusted contacts have been alerted with your live location coordinates.',
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => launchUrl(Uri.parse('tel:112')),
            icon: const Icon(Icons.call),
            label: const Text('Call 112 Police Helpline'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(ApiService().language);
    final status = _currentBooking?['booking_status'] ?? 'requested';
    final otp = _currentBooking?['start_otp'] ?? '----';

    final pLat = (_currentBooking?['pickup_lat'] as num?)?.toDouble() ?? 22.5726;
    final pLng = (_currentBooking?['pickup_lng'] as num?)?.toDouble() ?? 88.3639;
    final dLat = (_currentBooking?['driver_lat'] as num?)?.toDouble();
    final dLng = (_currentBooking?['driver_lng'] as num?)?.toDouble();

    final centerPoint = LatLng(pLat, pLng);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Live Tracking Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerPoint,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'in.oitoto.customer',
              ),
              MarkerLayer(
                markers: [
                  // Pickup Pin
                  Marker(
                    point: centerPoint,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 22),
                    ),
                  ),
                  // Live Driver Toto Marker
                  if (dLat != null && dLng != null)
                    Marker(
                      point: LatLng(dLat, dLng),
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.warmYellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.deepNavy, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🛺', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // 2. Top Status Bar & Emergency SOS
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: status == 'requested' ? AppColors.warmYellow : AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status == 'requested'
                              ? loc.tr('searching_driver')
                              : (status == 'arrived'
                                  ? loc.tr('driver_arrived')
                                  : (status == 'in_progress' ? loc.tr('trip_in_progress') : loc.tr('driver_assigned'))),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.deepNavy),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // SOS Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _handleSos,
                    icon: const Icon(Icons.shield, size: 16),
                    label: const Text('SOS', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Information & Driver Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 18,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // RIDE START OTP BANNER (Most critical security step)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.warmYellowLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.warmYellow.withOpacity(0.6)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          loc.tr('share_otp_hint'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF854D0E)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          otp,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: AppColors.deepNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Driver & Vehicle Card (when assigned)
                  if (_currentBooking?['driver_name'] != null) ...[
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreenLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryGreen, width: 2),
                          ),
                          child: const Center(
                            child: Icon(Icons.person, color: AppColors.primaryGreenDark, size: 28),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentBooking!['driver_name'],
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textMain),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: AppColors.warmYellow, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_currentBooking!['driver_rating'] ?? '4.9'}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• ${_currentBooking!['brand_make'] ?? 'Mayuri EV'}',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Vehicle Plate Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            _currentBooking!['vehicle_number'] ?? 'WB-01-E-XXXX',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.deepNavy),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Call Driver Button
                    if (_currentBooking!['driver_phone'] != null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(Uri.parse('tel:${_currentBooking!['driver_phone']}')),
                          icon: const Icon(Icons.call, size: 18),
                          label: Text('Call Driver (${_currentBooking!['driver_phone']})'),
                        ),
                      ),
                  ] else ...[
                    // Searching state with radar animation
                    Row(
                      children: const [
                        SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 2.5)),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Connecting with nearby eligible E-Rickshaw drivers...',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Cancel Ride
                  if (status != 'in_progress')
                    TextButton(
                      onPressed: _handleCancel,
                      child: Text(loc.tr('cancel_ride'), style: const TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
