import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme/driver_theme.dart';
import '../core/constants/driver_constants.dart';
import '../core/localization/driver_localizations.dart';
import '../core/services/driver_api_service.dart';
import 'driver_earnings_screen.dart';
import 'kyc_documents_screen.dart';
import 'driver_profile_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _otpInputController = TextEditingController();

  bool _isOnline = false;
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _activeTrip;
  Map<String, dynamic>? _earningsToday;

  Timer? _gpsTimer;
  Timer? _pollTripTimer;
  LatLng _currentLocation = LatLng(DriverConstants.defaultLat, DriverConstants.defaultLng);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prof = await DriverApiService().getProfile();
    final earnings = await DriverApiService().getEarnings();
    final trip = await DriverApiService().getActiveTrip();

    if (mounted) {
      setState(() {
        _profile = prof;
        _isOnline = (prof?['is_online'] == 1 || prof?['is_online'] == true);
        _earningsToday = earnings;
        _activeTrip = trip;
        _isLoading = false;

        if (prof?['current_lat'] != null && prof?['current_lng'] != null) {
          final lat = double.tryParse(prof!['current_lat']?.toString() ?? '');
          final lng = double.tryParse(prof!['current_lng']?.toString() ?? '');
          if (lat != null && lng != null) {
            _currentLocation = LatLng(lat, lng);
          }
        }
      });

      if (_isOnline) {
        _startTelemetry();
      }
    }
  }

  void _startTelemetry() {
    _gpsTimer?.cancel();
    _pollTripTimer?.cancel();

    // Fetch initial device GPS position
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((pos) {
      if (mounted) {
        setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
        _mapController.move(_currentLocation, 15.0);
      }
    }).catchError((_) {});

    // 1. Broadcast GPS every 6 seconds
    _gpsTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
        if (mounted) {
          setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
        }
      } catch (_) {}

      DriverApiService().updateLocation(
        _currentLocation.latitude,
        _currentLocation.longitude,
        heading: 45.0,
        speed: 16.0,
        bookingId: _activeTrip?['id'],
      );
    });

    // 2. Poll for incoming ride requests or active ride updates
    _pollTripTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final trip = await DriverApiService().getActiveTrip();
      if (mounted) {
        setState(() => _activeTrip = trip);
      }
    });
  }

  void _stopTelemetry() {
    _gpsTimer?.cancel();
    _pollTripTimer?.cancel();
  }

  Future<void> _handleToggleOnline() async {
    final targetState = !_isOnline;
    setState(() => _isLoading = true);

    final res = await DriverApiService().toggleOnline(targetState);
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() => _isOnline = targetState);
      if (_isOnline) {
        _startTelemetry();
      } else {
        _stopTelemetry();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['data']?['message'] ?? 'Status updated.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: DriverColors.errorRed, content: Text(res['message'] ?? 'Could not toggle online.')),
      );
    }
  }

  // --- TRIP STAGES ACTIONS ---
  Future<void> _handleArrived() async {
    if (_activeTrip == null) return;
    final bId = int.tryParse(_activeTrip!['id']?.toString() ?? '') ?? 0;

    final res = await DriverApiService().markArrived(bId);
    if (res['success'] == true) {
      final updated = await DriverApiService().getActiveTrip();
      setState(() => _activeTrip = updated);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed.')));
    }
  }

  Future<void> _handleStartTrip() async {
    if (_activeTrip == null) return;
    final bId = int.tryParse(_activeTrip!['id']?.toString() ?? '') ?? 0;
    final otp = _otpInputController.text.trim();

    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 4-digit Ride OTP provided by the passenger.')),
      );
      return;
    }

    final res = await DriverApiService().startTrip(bId, otp);
    if (res['success'] == true) {
      _otpInputController.clear();
      final updated = await DriverApiService().getActiveTrip();
      setState(() => _activeTrip = updated);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: DriverColors.errorRed, content: Text(res['message'] ?? 'Incorrect OTP.')),
      );
    }
  }

  Future<void> _handleCompleteTrip() async {
    if (_activeTrip == null) return;
    final bId = int.tryParse(_activeTrip!['id']?.toString() ?? '') ?? 0;
    final dist = double.tryParse(_activeTrip!['estimated_distance_km']?.toString() ?? '') ?? 1.8;

    final res = await DriverApiService().completeTrip(bId, dist);
    if (res['success'] == true) {
      _showPaymentCollectionDialog(res['data']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed.')));
    }
  }

  void _showPaymentCollectionDialog(Map<String, dynamic> data) {
    final fare = data['final_fare'] ?? '20.00';
    final earnings = data['driver_earnings'] ?? '18.00';
    final comm = data['platform_commission'] ?? '2.00';
    final mode = (data['payment_mode'] ?? 'cash').toString().toUpperCase();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Trip Finished — Collect Fare', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DriverColors.primaryGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Total Fare To Collect', style: TextStyle(fontSize: 12, color: DriverColors.primaryGreenDark)),
                  Text('₹$fare', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: DriverColors.deepNavy)),
                  Text('Payment Method: $mode', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Your Net Share (90%):', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('₹$earnings', style: const TextStyle(fontWeight: FontWeight.bold, color: DriverColors.primaryGreen)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Oi Toto Platform Fee (10%):', style: TextStyle(color: DriverColors.textMuted, fontSize: 13)),
                Text('₹$comm', style: const TextStyle(color: DriverColors.textMuted, fontSize: 13)),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DriverColors.primaryGreen),
            onPressed: () async {
              if (data['payment_mode'] == 'cash') {
                await DriverApiService().confirmCash(data['booking_id'], double.parse(fare.toString()));
              }
              Navigator.pop(ctx);
              _loadInitialData();
            },
            child: const Text('Confirm Received & Free E-Rickshaw'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _pollTripTimer?.cancel();
    _otpInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = DriverLocalizations(DriverApiService().language);
    final tripStatus = _activeTrip?['booking_status'];

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Map with Current Location
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'in.oitoto.driver',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isOnline ? DriverColors.onlineGreen : DriverColors.offlineGray,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8),
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

          // 2. Top Driver Header & Online Toggle Switch
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Online/Offline Pill Switch
                  InkWell(
                    onTap: _handleToggleOnline,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isOnline ? DriverColors.onlineGreen : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                        ],
                        border: Border.all(
                          color: _isOnline ? DriverColors.onlineGreen : DriverColors.offlineGray,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.power_settings_new,
                            size: 18,
                            color: _isOnline ? Colors.white : DriverColors.offlineGray,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isOnline ? loc.tr('go_offline') : loc.tr('go_online'),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: _isOnline ? Colors.white : DriverColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Earnings Button
                  IconButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverEarningsScreen()));
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.account_balance_wallet, color: DriverColors.primaryGreen),
                    ),
                  ),
                  // Profile Button
                  IconButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverProfileScreen()));
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.person, color: DriverColors.deepNavy),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Active Trip Execution Panel (Bottom Sheet)
          if (_activeTrip != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stage 1: Accepted -> Arrived at pickup
                    if (tripStatus == 'accepted') ...[
                      Row(
                        children: [
                          const Icon(Icons.navigation, color: DriverColors.primaryGreen, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pickup Passenger At:', style: TextStyle(fontSize: 11, color: DriverColors.textMuted, fontWeight: FontWeight.bold)),
                                Text(_activeTrip!['pickup_address'] ?? 'Pickup', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              ],
                            ),
                          ),
                          Text('₹${_activeTrip!['estimated_fare']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: DriverColors.primaryGreen)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleArrived,
                          child: Text(loc.tr('mark_arrived')),
                        ),
                      ),
                    ],

                    // Stage 2: Arrived -> Enter 4-digit Ride OTP
                    if (tripStatus == 'arrived') ...[
                      Text(
                        loc.tr('enter_otp_hint'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: DriverColors.deepNavy),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _otpInputController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 10),
                        decoration: const InputDecoration(
                          hintText: '0000',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleStartTrip,
                          child: Text(loc.tr('start_trip')),
                        ),
                      ),
                    ],

                    // Stage 3: In Progress -> Complete Trip
                    if (tripStatus == 'in_progress') ...[
                      Row(
                        children: [
                          const Icon(Icons.flag, color: DriverColors.primaryGreen, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Dropping Passenger At:', style: TextStyle(fontSize: 11, color: DriverColors.textMuted, fontWeight: FontWeight.bold)),
                                Text(_activeTrip!['drop_address'] ?? 'Destination', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: DriverColors.warmYellow, foregroundColor: Colors.black),
                          onPressed: _handleCompleteTrip,
                          child: Text(loc.tr('complete_trip')),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
