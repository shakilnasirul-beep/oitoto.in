import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/api_service.dart';
import 'home_screen.dart';
import 'trip_receipt_screen.dart';

class ActiveRideScreen extends StatefulWidget {
  final int? bookingId;
  final Map<String, dynamic>? initialData;
  final Map<String, dynamic>? booking;
  final List<LatLng>? routePoints;

  const ActiveRideScreen({
    super.key,
    this.bookingId,
    this.initialData,
    this.booking,
    this.routePoints,
  });

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  final MapController _mapController = MapController();
  Timer? _pollingTimer;
  Timer? _liveMovementTimer;

  Map<String, dynamic>? _currentBooking;
  bool _isLoading = true;

  List<LatLng> _activeRoutePoints = [];
  int _driverProgressIndex = 0;
  LatLng? _driverCurrentPos;
  String _liveStatusNote = 'Driver is starting the ride...';

  @override
  void initState() {
    super.initState();
    if (widget.booking != null) {
      _currentBooking = widget.booking;
      _isLoading = false;
    } else if (widget.initialData != null) {
      _currentBooking = widget.initialData;
    }

    // Initialize full unbroken route
    if (widget.routePoints != null && widget.routePoints!.isNotEmpty) {
      _activeRoutePoints = List.from(widget.routePoints!);
    } else {
      final pLat = double.tryParse(_currentBooking?['pickup_lat']?.toString() ?? '') ?? 25.2748;
      final pLng = double.tryParse(_currentBooking?['pickup_lng']?.toString() ?? '') ?? 88.0076;
      final dLat = double.tryParse(_currentBooking?['drop_lat']?.toString() ?? '') ?? 25.2745;
      final dLng = double.tryParse(_currentBooking?['drop_lng']?.toString() ?? '') ?? 88.0062;
      _activeRoutePoints = [
        LatLng(pLat, pLng),
        LatLng((pLat + dLat) / 2, (pLng + dLng) / 2),
        LatLng(dLat, dLng),
      ];
    }

    if (_activeRoutePoints.isNotEmpty) {
      _driverCurrentPos = _activeRoutePoints.first;
    }

    _pollActiveTrip();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => _pollActiveTrip());

    // Live continuous vehicle movement simulation along the green route
    _startLiveRideSimulation();
  }

  void _startLiveRideSimulation() {
    _liveMovementTimer?.cancel();
    if (_activeRoutePoints.isEmpty) return;

    // Advance Toto along the route points step by step
    _liveMovementTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (!mounted) return;
      if (_driverProgressIndex < _activeRoutePoints.length - 1) {
        setState(() {
          _driverProgressIndex++;
          _driverCurrentPos = _activeRoutePoints[_driverProgressIndex];

          final progressRatio = _driverProgressIndex / (_activeRoutePoints.length - 1);
          if (progressRatio < 0.25) {
            _liveStatusNote = 'Departing from pickup via pocket/feeder road...';
          } else if (progressRatio < 0.8) {
            _liveStatusNote = 'Cruising via PMG & Highway corridor...';
          } else {
            _liveStatusNote = 'Approaching destination drop point...';
          }
        });

        // Map camera automatically tracks and centers on the vehicle
        if (_driverCurrentPos != null) {
          _mapController.move(_driverCurrentPos!, 16.0);
        }
      } else {
        // Reached destination! Stop movement and transition smoothly to receipt
        timer.cancel();
        _navigateToReceipt();
      }
    });
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

      // Check if trip completed externally
      if (active == null && _currentBooking != null && _currentBooking!['booking_status'] == 'completed') {
        _navigateToReceipt();
      } else if (active != null && active['booking_status'] == 'completed') {
        _navigateToReceipt();
      }
    }
  }

  void _navigateToReceipt() {
    _liveMovementTimer?.cancel();
    _pollingTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TripReceiptScreen(booking: _currentBooking ?? widget.initialData ?? {}),
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
          _liveMovementTimer?.cancel();
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
    final lat = double.tryParse(_currentBooking?['pickup_lat']?.toString() ?? '') ?? 25.2748;
    final lng = double.tryParse(_currentBooking?['pickup_lng']?.toString() ?? '') ?? 88.0076;
    final bId = int.tryParse(_currentBooking?['id']?.toString() ?? '');

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
    _liveMovementTimer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(ApiService().language);
    final status = _currentBooking?['booking_status'] ?? 'accepted';
    final otp = _currentBooking?['start_otp'] ?? '4826';

    final pLat = double.tryParse(_currentBooking?['pickup_lat']?.toString() ?? '') ?? 25.2748;
    final pLng = double.tryParse(_currentBooking?['pickup_lng']?.toString() ?? '') ?? 88.0076;
    final centerPoint = LatLng(pLat, pLng);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Live Tracking Map with Google Maps Tiles & Full Continuous Route
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _driverCurrentPos ?? centerPoint,
              initialZoom: 15.5,
              maxZoom: 20.0,
              minZoom: 4.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                subdomains: const ['0', '1', '2', '3'],
                userAgentPackageName: 'in.oitoto.customer',
                maxZoom: 20,
                maxNativeZoom: 20,
              ),

              // Full Unbroken Green Route Line (White Casing + Vivid Emerald Green)
              if (_activeRoutePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _activeRoutePoints,
                      strokeWidth: 8.5,
                      color: Colors.white,
                    ),
                    Polyline(
                      points: _activeRoutePoints,
                      strokeWidth: 5.5,
                      color: const Color(0xFF00C853),
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  // 1. Pickup Pin with Needle Tip Touching Exact Pickup Ground Spot
                  if (_activeRoutePoints.isNotEmpty)
                    Marker(
                      point: _activeRoutePoints.first,
                      width: 28,
                      height: 52,
                      alignment: Alignment.bottomCenter,
                      child: const SlenderPickupPin(),
                    ),

                  // 2. Destination Pin with Needle Tip Touching Exact Drop Spot
                  if (_activeRoutePoints.length > 1)
                    Marker(
                      point: _activeRoutePoints.last,
                      width: 28,
                      height: 54,
                      alignment: Alignment.bottomCenter,
                      child: const SlenderDestinationPin(),
                    ),

                  // 3. Live Driver Toto Marker Moving Real-Time along the Route
                  if (_driverCurrentPos != null)
                    Marker(
                      point: _driverCurrentPos!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.warmYellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.deepNavy, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🛺', style: TextStyle(fontSize: 24)),
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
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _liveStatusNote,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.deepNavy),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  // RIDE START OTP BANNER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.warmYellowLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.warmYellow.withOpacity(0.6)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.tr('share_otp_hint'),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF854D0E)),
                            ),
                            const Text(
                              'Verify with Driver',
                              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        Text(
                          otp,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: AppColors.deepNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Driver & Vehicle Card
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
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
                              _currentBooking?['driver_name'] ?? 'Subrata Roy',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textMain),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: AppColors.warmYellow, size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  '${_currentBooking?['driver_rating'] ?? '4.9'}',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '• ${_currentBooking?['brand_make'] ?? 'Mayuri Deluxe EV'}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                          _currentBooking?['vehicle_number'] ?? 'WB-66-E-1082',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.deepNavy),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Call Driver Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse('tel:${_currentBooking?['driver_phone'] ?? '9832109876'}')),
                      icon: const Icon(Icons.call, size: 18),
                      label: Text('Call Driver (${_currentBooking?['driver_phone'] ?? '9832109876'})'),
                    ),
                  ),

                  const SizedBox(height: 8),

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
