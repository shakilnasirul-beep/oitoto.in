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
  String _mapMode = 'road'; // 'road', 'satellite', 'traffic'
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

  String _getCategoryIcon(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'bike':
        return '🏍️';
      case 'cab':
        return '🚗';
      case 'cargo':
        return '🚛';
      case 'parcel':
        return '📦';
      case 'toto':
      default:
        return '🛺';
    }
  }

  String _getCategoryLabel(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'bike':
        return 'Bike';
      case 'cab':
        return 'Cab';
      case 'cargo':
        return 'Cargo';
      case 'parcel':
        return 'Parcel';
      case 'toto':
      default:
        return 'Toto';
    }
  }

  void _showKycPendingDialog() {
    final loc = DriverLocalizations(DriverApiService().language);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.verified_user_outlined, color: Color(0xFFD97706), size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                loc.tr('kyc_pending_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          loc.tr('kyc_pending_msg'),
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DriverColors.primaryGreen),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KycDocumentsScreen(isOnboarding: false)),
              );
            },
            child: Text(loc.tr('upload_kyc_docs')),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggleOnline() async {
    final status = _profile?['status']?.toString();
    if (status != 'verified_active') {
      _showKycPendingDialog();
      return;
    }

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
  Future<void> _handleAcceptTrip() async {
    if (_activeTrip == null) return;
    final bId = int.tryParse(_activeTrip!['id']?.toString() ?? '') ?? 0;
    setState(() => _isLoading = true);

    final res = await DriverApiService().acceptTrip(bId);
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final updated = await DriverApiService().getActiveTrip();
      setState(() => _activeTrip = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride Accepted! Head to passenger pickup.')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: DriverColors.errorRed, content: Text(res['message'] ?? 'Could not accept ride.')),
        );
      }
    }
  }

  void _handleDeclineTrip() {
    setState(() {
      _activeTrip = null;
    });
  }

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

  Widget _buildMapModePill(String mode, String label) {
    final isSelected = _mapMode == mode;
    return InkWell(
      onTap: () => setState(() => _mapMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? DriverColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : DriverColors.deepNavy,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = DriverLocalizations(DriverApiService().language);
    final tripStatus = _activeTrip?['booking_status'];
    final categoryCode = _profile?['vehicle_category'] ?? 'toto';

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Map with Current Location & 3 Modes (Road / Satellite / Traffic)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
              maxZoom: 19.0,
              minZoom: 4.0,
            ),
            children: [
              if (_mapMode == 'satellite')
                TileLayer(
                  urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'in.oitoto.driver',
                  maxZoom: 19,
                  maxNativeZoom: 19,
                )
              else if (_mapMode == 'traffic')
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'in.oitoto.driver',
                  maxZoom: 19,
                  maxNativeZoom: 19,
                )
              else
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'in.oitoto.driver',
                  maxZoom: 19,
                  maxNativeZoom: 19,
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 52,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isOnline ? DriverColors.onlineGreen : DriverColors.offlineGray,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8),
                        ],
                      ),
                      child: Center(
                        child: Text(_getCategoryIcon(categoryCode), style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Top Driver Header & Online Toggle Switch + Vehicle Category Badge
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Online/Offline Pill Switch
                  InkWell(
                    onTap: _handleToggleOnline,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
                          const SizedBox(width: 6),
                          Text(
                            _isOnline ? loc.tr('go_offline') : loc.tr('go_online'),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: _isOnline ? Colors.white : DriverColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Vehicle Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_getCategoryIcon(categoryCode), style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 4),
                        Text(
                          _getCategoryLabel(categoryCode),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: DriverColors.deepNavy),
                        ),
                      ],
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
                      child: const Icon(Icons.account_balance_wallet, color: DriverColors.primaryGreen, size: 20),
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
                      child: const Icon(Icons.person, color: DriverColors.deepNavy, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2.1 3-Mode Location Map Selector Pill (Road / Satellite / Traffic)
          Positioned(
            top: 68,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMapModePill('road', '🛣️ ${loc.tr('map_road')}'),
                  _buildMapModePill('satellite', '🛰️ ${loc.tr('map_satellite')}'),
                  _buildMapModePill('traffic', '🚦 ${loc.tr('map_traffic')}'),
                ],
              ),
            ),
          ),

          // 2.2 KYC Verification Notice Banner if not active
          if (_profile != null && _profile!['status'] != 'verified_active')
            Positioned(
              top: 112,
              left: 16,
              right: 16,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KycDocumentsScreen(isOnboarding: false)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.tr('kyc_pending_title'),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF92400E)),
                            ),
                            Text(
                              loc.tr('kyc_pending_msg'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, color: Color(0xFFB45309), size: 18),
                    ],
                  ),
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
                    // Stage 0: Requested -> Accept or Decline
                    if (tripStatus == 'requested') ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: DriverColors.primaryGreenLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(_getCategoryIcon(_activeTrip!['vehicle_category'] ?? categoryCode), style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 5),
                                Text(
                                  loc.tr('new_booking'),
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: DriverColors.primaryGreenDark, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₹${_activeTrip!['estimated_fare'] ?? '20'}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: DriverColors.primaryGreen),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.trip_origin, color: DriverColors.primaryGreen, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pickup Location:', style: TextStyle(fontSize: 11, color: DriverColors.textMuted, fontWeight: FontWeight.bold)),
                                Text(_activeTrip!['pickup_address'] ?? 'Pickup point', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: DriverColors.errorRed, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Destination:', style: TextStyle(fontSize: 11, color: DriverColors.textMuted, fontWeight: FontWeight.bold)),
                                Text(_activeTrip!['drop_address'] ?? 'Destination point', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              onPressed: _handleDeclineTrip,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: DriverColors.textMuted,
                                side: BorderSide(color: Colors.grey.shade400),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(loc.tr('reject_ride')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAcceptTrip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DriverColors.primaryGreen,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                loc.tr('accept_ride'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

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
