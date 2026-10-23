import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/api_service.dart';
import 'active_ride_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String selectedCategory;
  final String categoryName;
  final String categoryIcon;

  const HomeScreen({
    super.key,
    this.selectedCategory = 'toto',
    this.categoryName = 'Oi Toto',
    this.categoryIcon = '🛺',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();

  LatLng _currentLocation = LatLng(ApiConstants.defaultLat, ApiConstants.defaultLng);
  LatLng? _dropLocation;

  List<dynamic> _nearbyDrivers = [];
  Map<String, dynamic>? _fareEstimate;
  bool _isEstimatingFare = false;
  bool _isBooking = false;
  String _selectedPaymentMode = 'cash'; // 'cash' or 'upi'
  String? _promoCode;

  Timer? _activeCheckTimer;

  // Preset popular landmarks for quick selection (Kolkata / Pan-India)
  final List<Map<String, dynamic>> _quickSpots = [
    {
      'name': 'Metro Station (Gate 1)',
      'addr': 'Shyambazar Metro Gate 1, Kolkata',
      'lat': 22.6038,
      'lng': 88.3713,
      'icon': Icons.train,
    },
    {
      'name': 'Railway Station North',
      'addr': 'Sealdah Railway Station, Kolkata',
      'lat': 22.5681,
      'lng': 88.3704,
      'icon': Icons.directions_railway,
    },
    {
      'name': 'Local Market Bazaar',
      'addr': 'Hatibagan Market Crossing, Kolkata',
      'lat': 22.5942,
      'lng': 88.3710,
      'icon': Icons.storefront,
    },
    {
      'name': 'College Street Junction',
      'addr': 'College Street Coffee House, Kolkata',
      'lat': 22.5754,
      'lng': 88.3639,
      'icon': Icons.menu_book,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pickupController.text = 'Current Location (Shyambazar)';
    _fetchNearbyDrivers();
    _checkActiveBooking();

    // Periodic check for nearby E-Rickshaws
    _activeCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchNearbyDrivers();
      _checkActiveBooking();
    });
  }

  Future<void> _checkActiveBooking() async {
    final active = await ApiService().getActiveBooking();
    if (active != null && mounted) {
      _activeCheckTimer?.cancel();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ActiveRideScreen(booking: active)),
      ).then((_) {
        _activeCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
          _fetchNearbyDrivers();
          _checkActiveBooking();
        });
      });
    }
  }

  Future<void> _fetchNearbyDrivers() async {
    final drivers = await ApiService().getNearbyTotos(
      _currentLocation.latitude,
      _currentLocation.longitude,
    );
    if (mounted) {
      setState(() => _nearbyDrivers = drivers);
    }
  }

  Future<void> _calculateFare() async {
    if (_dropLocation == null) return;

    setState(() => _isEstimatingFare = true);
    final res = await ApiService().estimateFare(
      _currentLocation.latitude,
      _currentLocation.longitude,
      _dropLocation!.latitude,
      _dropLocation!.longitude,
      promo: _promoCode,
    );

    if (mounted) {
      setState(() {
        _isEstimatingFare = false;
        if (res['success'] == true) {
          _fareEstimate = res['data'];
        }
      });
    }
  }

  void _selectQuickSpot(Map<String, dynamic> spot) {
    setState(() {
      _dropController.text = spot['name'];
      _dropLocation = LatLng(spot['lat'], spot['lng']);
    });
    _calculateFare();
  }

  Future<void> _handleBookNow() async {
    if (_dropLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination to book an E-Rickshaw.')),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      final res = await ApiService().createBooking(
        pickupAddress: _pickupController.text,
        pickupLat: _currentLocation.latitude,
        pickupLng: _currentLocation.longitude,
        dropAddress: _dropController.text,
        dropLat: _dropLocation!.latitude,
        dropLng: _dropLocation!.longitude,
        paymentMode: _selectedPaymentMode,
        promoCode: _promoCode,
      );

      setState(() => _isBooking = false);

      if (res['success'] == true && res['data'] != null) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveRideScreen(
              bookingId: res['data']['booking_id'],
              initialData: res['data'],
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Booking request failed.')),
        );
      }
    } catch (e) {
      setState(() => _isBooking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect to server.')),
      );
    }
  }

  @override
  void dispose() {
    _activeCheckTimer?.cancel();
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(ApiService().language);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Interactive Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 14.5,
              onTap: (tapPosition, point) {
                setState(() {
                  _dropLocation = point;
                  _dropController.text = 'Custom Pinned Destination';
                });
                _calculateFare();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'in.oitoto.customer',
              ),
              // Markers Layer
              MarkerLayer(
                markers: [
                  // Current Pickup Marker
                  Marker(
                    point: _currentLocation,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 22),
                    ),
                  ),
                  // Drop Marker (if selected)
                  if (_dropLocation != null)
                    Marker(
                      point: _dropLocation!,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.errorRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 22),
                      ),
                    ),
                  // Nearby Online E-Rickshaws
                  ..._nearbyDrivers.map((d) {
                    final dLat = double.tryParse(d['current_lat']?.toString() ?? '') ?? _currentLocation.latitude;
                    final dLng = double.tryParse(d['current_lng']?.toString() ?? '') ?? _currentLocation.longitude;
                    return Marker(
                      point: LatLng(dLat, dLng),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.warmYellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.deepNavy, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(widget.categoryIcon, style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),

          // 2. Floating Top Header with Branding & Profile Button
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
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/logo.png', width: 26, height: 26),
                        const SizedBox(width: 8),
                        const Text(
                          'Oi Toto!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepNavy,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF93C5FD)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(widget.categoryIcon, style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 3),
                                Text(
                                  widget.categoryName.split(' ')[0],
                                  style: const TextStyle(
                                    color: Color(0xFF1E40AF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.edit, size: 9, color: Color(0xFF1E40AF)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreenLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_nearbyDrivers.length} Available',
                            style: const TextStyle(
                              color: AppColors.primaryGreenDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // History button
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryScreen()),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history, color: AppColors.textMain),
                    ),
                  ),
                  // Profile button
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: AppColors.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Booking Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.70),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                  // Pickup & Drop Fields
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.my_location, color: AppColors.primaryGreen, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _pickupController.text,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.errorRed, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _dropController.text.isNotEmpty ? _dropController.text : loc.tr('drop_location'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: _dropController.text.isNotEmpty ? AppColors.textMain : AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quick Destination Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickSpots.map((spot) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: Icon(spot['icon'] as IconData, size: 16, color: AppColors.primaryGreen),
                            label: Text(spot['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.border),
                            onPressed: () => _selectQuickSpot(spot),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Estimated Fare Card
                  if (_fareEstimate != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreenLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.tr('estimated_fare'),
                                style: const TextStyle(fontSize: 12, color: AppColors.primaryGreenDark, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '₹${_fareEstimate!['final_fare']}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.deepNavy),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '${_fareEstimate!['distance_km']} km • ~${_fareEstimate!['estimated_duration_mins']} mins',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.deepNavy),
                              ),
                              const SizedBox(width: 8),
                              const Text('⚡', style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Payment Method Selector
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedPaymentMode = 'cash'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedPaymentMode == 'cash' ? AppColors.warmYellowLight : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedPaymentMode == 'cash' ? AppColors.warmYellowDark : AppColors.border,
                                  width: _selectedPaymentMode == 'cash' ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.payments_outlined, size: 18, color: AppColors.textMain),
                                  SizedBox(width: 6),
                                  Text('Cash to Driver', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedPaymentMode = 'upi'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedPaymentMode == 'upi' ? AppColors.primaryGreenLight : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedPaymentMode == 'upi' ? AppColors.primaryGreen : AppColors.border,
                                  width: _selectedPaymentMode == 'upi' ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.qr_code, size: 18, color: AppColors.primaryGreenDark),
                                  SizedBox(width: 6),
                                  Text('UPI / Online', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Prominent Book Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: (_isBooking || _isEstimatingFare) ? null : _handleBookNow,
                      child: _isBooking
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _fareEstimate != null ? 'Confirm & Book Oi Toto!' : 'Select Destination on Map',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);
  }
}
