import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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

  // Real GPS & Navigation State
  String _mapMode = 'road'; // 'road', 'satellite', 'traffic'
  bool _isLocatingGps = false;
  bool _isLoadingRoute = false;
  List<LatLng> _routePoints = [];
  double? _routeDistanceKm;
  int? _routeDurationMins;

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
    _pickupController.text = 'Locating GPS...';
    _getCurrentGpsLocation();
    _fetchNearbyDrivers();
    _checkActiveBooking();

    // Periodic check for nearby E-Rickshaws
    _activeCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchNearbyDrivers();
      _checkActiveBooking();
    });
  }

  // --- REAL PHYSICAL GPS LOCATION DETECTION ---
  Future<void> _getCurrentGpsLocation() async {
    if (!mounted) return;
    setState(() => _isLocatingGps = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLocatingGps = false;
            if (_pickupController.text == 'Locating GPS...') {
              _pickupController.text = 'Current Location (Default)';
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable GPS / Location on your device.'),
              backgroundColor: AppColors.errorRed,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLocatingGps = false;
              if (_pickupController.text == 'Locating GPS...') {
                _pickupController.text = 'Current Location (Default)';
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is needed to find nearby Totos.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLocatingGps = false;
            if (_pickupController.text == 'Locating GPS...') {
              _pickupController.text = 'Current Location (Default)';
            }
          });
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );

      final newGps = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _currentLocation = newGps;
          _isLocatingGps = false;
          _pickupController.text = 'Current Location';
        });

        _mapController.move(newGps, 15.5);
        _fetchNearbyDrivers();
        _reverseGeocode(newGps, isPickup: true);

        // Recalculate road route if destination was already selected
        if (_dropLocation != null) {
          _fetchRoadRoute(_currentLocation, _dropLocation!);
          _calculateFare();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocatingGps = false;
          if (_pickupController.text == 'Locating GPS...') {
            _pickupController.text = 'Current Location (Bengal)';
          }
        });
      }
    }
  }

  // --- REVERSE GEOCODING (Place / Street Name) ---
  Future<void> _reverseGeocode(LatLng point, {required bool isPickup}) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=17&addressdetails=1',
      );
      final res = await http.get(url, headers: {'User-Agent': 'in.oitoto.customer/1.0'});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final addr = json['address'] as Map<String, dynamic>?;
        String title = '';
        if (addr != null) {
          title = addr['road'] ?? addr['suburb'] ?? addr['neighbourhood'] ?? addr['town'] ?? addr['city'] ?? '';
        }
        if (title.isEmpty) {
          final disp = json['display_name'] as String?;
          if (disp != null) {
            title = disp.split(',').take(2).join(', ').trim();
          }
        }
        if (title.isNotEmpty && mounted) {
          setState(() {
            if (isPickup) {
              _pickupController.text = title;
            } else {
              _dropController.text = title;
            }
          });
        }
      }
    } catch (_) {}
  }

  // --- REAL ROAD NAVIGATION ROUTING (OSRM) ---
  Future<void> _fetchRoadRoute(LatLng start, LatLng end) async {
    setState(() => _isLoadingRoute = true);

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      );
      final res = await http.get(url, headers: {'User-Agent': 'in.oitoto.customer/1.0'});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['code'] == 'Ok' && json['routes'] != null && (json['routes'] as List).isNotEmpty) {
          final route = json['routes'][0];
          final coords = route['geometry']['coordinates'] as List;
          final distM = (route['distance'] as num).toDouble();
          final durS = (route['duration'] as num).toDouble();

          if (mounted) {
            setState(() {
              _routePoints = coords.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
              _routeDistanceKm = distM / 1000.0;
              _routeDurationMins = (durS / 60.0).ceil();
              _isLoadingRoute = false;
            });
            _centerOnRoute(start, end);
            return;
          }
        }
      }
    } catch (_) {}

    // Fallback if network routing unavailable
    if (mounted) {
      setState(() {
        _routePoints = [start, end];
        _isLoadingRoute = false;
      });
      _centerOnRoute(start, end);
    }
  }

  void _centerOnRoute(LatLng p1, LatLng p2) {
    final centerLat = (p1.latitude + p2.latitude) / 2;
    final centerLng = (p1.longitude + p2.longitude) / 2;
    _mapController.move(LatLng(centerLat, centerLng), 14.0);
  }

  void _setDestination(LatLng point, [String? name]) {
    setState(() {
      _dropLocation = point;
      _dropController.text = name ?? 'Custom Pinned Destination';
    });
    if (name == null) {
      _reverseGeocode(point, isPickup: false);
    }
    _fetchRoadRoute(_currentLocation, point);
    _calculateFare();
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
    final pt = LatLng(spot['lat'] as double, spot['lng'] as double);
    _setDestination(pt, spot['name'] as String);
  }

  Future<void> _handleBookNow() async {
    if (_dropLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tap the map to drop a destination pin.')),
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
        category: widget.selectedCategory,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to server.')),
        );
      }
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
          // 1. Full Screen Interactive Road Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
              maxZoom: 19.0,
              minZoom: 4.0,
              onTap: (tapPosition, point) => _setDestination(point),
            ),
            children: [
              if (_mapMode == 'satellite')
                TileLayer(
                  urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'in.oitoto.customer',
                  maxZoom: 19,
                  maxNativeZoom: 19,
                )
              else if (_mapMode == 'traffic')
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'in.oitoto.customer',
                  maxZoom: 19,
                  maxNativeZoom: 19,
                )
              else
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'in.oitoto.customer',
                  maxZoom: 19,
                  maxNativeZoom: 19,
                ),

              // Road Route Layer following traffic/street network
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Outer white glow/casing for high street visibility
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 8.0,
                      color: Colors.white.withOpacity(0.95),
                    ),
                    // Inner emerald green navigation route line
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: const Color(0xFF059669),
                    ),
                  ],
                ),

              // Markers Layer
              MarkerLayer(
                markers: [
                  // Current Pickup Marker
                  Marker(
                    point: _currentLocation,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_pin_circle, color: Colors.white, size: 26),
                    ),
                  ),

                  // Destination Drop Marker (if selected)
                  if (_dropLocation != null)
                    Marker(
                      point: _dropLocation!,
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.errorRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.flag_rounded, color: Colors.white, size: 24),
                      ),
                    ),

                  // Nearby Online E-Rickshaws
                  ..._nearbyDrivers.map((d) {
                    final dLat = double.tryParse(d['current_lat']?.toString() ?? '') ?? _currentLocation.latitude;
                    final dLng = double.tryParse(d['current_lng']?.toString() ?? '') ?? _currentLocation.longitude;
                    return Marker(
                      point: LatLng(dLat, dLng),
                      width: 42,
                      height: 42,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.warmYellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.deepNavy, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(widget.categoryIcon, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),

          // 2. Floating Top Header with Branding, Category Pill & Actions
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset('assets/images/logo.png', width: 26, height: 26, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Oi Toto!',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepNavy,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Category Pill with edit icon
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
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                      ),
                      child: const Icon(Icons.history, color: AppColors.textMain, size: 20),
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
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                      ),
                      child: const Icon(Icons.person, color: AppColors.primaryGreen, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2.1 3-Mode Location Map Selector Pill (Road / Satellite / Traffic)
          Positioned(
            top: 72,
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
                  _buildMapModePill('road', '🛣️ Road'),
                  _buildMapModePill('satellite', '🛰️ Sat'),
                  _buildMapModePill('traffic', '🚦 Traffic'),
                ],
              ),
            ),
          ),

          // 3. Floating GPS Current Location Button (Above Bottom Sheet)
          Positioned(
            right: 18,
            bottom: 330,
            child: FloatingActionButton.small(
              heroTag: 'btnLiveGps',
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _isLocatingGps ? null : _getCurrentGpsLocation,
              child: _isLocatingGps
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primaryGreen),
                    )
                  : const Icon(Icons.my_location, color: AppColors.primaryGreen, size: 24),
            ),
          ),

          // 4. Bottom Booking Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.72),
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
                          margin: const EdgeInsets.only(bottom: 12),
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
                            // Tap to Refresh GPS Pickup
                            InkWell(
                              onTap: _getCurrentGpsLocation,
                              child: Row(
                                children: [
                                  _isLocatingGps
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
                                        )
                                      : const Icon(Icons.my_location, color: AppColors.primaryGreen, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _pickupController.text,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textMain),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Text(
                                          'Tap to detect live GPS location',
                                          style: TextStyle(fontSize: 10, color: AppColors.primaryGreenDark, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.gps_fixed, size: 16, color: AppColors.primaryGreen),
                                ],
                              ),
                            ),
                            const Divider(height: 16),
                            // Destination Drop Field
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: AppColors.errorRed, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _dropController.text.isNotEmpty ? _dropController.text : 'Tap map to drop destination pin',
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
                      const SizedBox(height: 12),

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
                      const SizedBox(height: 12),

                      // Estimated Fare & Road Navigation Card
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _routeDistanceKm != null
                                            ? '${_routeDistanceKm!.toStringAsFixed(1)} km road route'
                                            : '${_fareEstimate!['distance_km']} km',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepNavy),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('🛣️', style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _routeDurationMins != null
                                        ? '~$_routeDurationMins mins commute'
                                        : '~${_fareEstimate!['estimated_duration_mins']} mins',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryGreenDark),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

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
                        const SizedBox(height: 14),
                      ],

                      // Prominent Book Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: (_isBooking || _isEstimatingFare || _isLoadingRoute) ? null : _handleBookNow,
                          child: _isBooking
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  _fareEstimate != null
                                      ? 'Confirm & Book ${widget.categoryName}!'
                                      : 'Tap Map to Drop Destination Pin',
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
  Widget _buildMapModePill(String mode, String label) {
    final isSelected = _mapMode == mode;
    return InkWell(
      onTap: () => setState(() => _mapMode = mode),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.deepNavy,
          ),
        ),
      ),
    );
  }
}
