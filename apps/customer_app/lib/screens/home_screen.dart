import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
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
  String _mapMode = 'road'; // 'road', 'satellite'
  bool _isLocatingGps = false;
  bool _isLoadingRoute = false;
  List<LatLng> _routePoints = [];
  double? _routeDistanceKm;
  int? _routeDurationMins;
  String _routeRoadType = 'Hybrid Route';

  Timer? _activeCheckTimer;

  // Dynamic Zone & Authentic Local Corridors State
  String _currentZoneName = 'Samsi & Chanchal';
  List<Map<String, dynamic>> _activeZoneCorridors = [];

  // Pan-India & West Bengal Regional Hub & Corridor Registry
  static final List<Map<String, dynamic>> _zoneRegistry = [
    {
      'id': 'samsi_chanchal',
      'name': 'Samsi & Chanchal',
      'city': 'Malda',
      'center': const LatLng(25.276269, 88.010118),
      'radius_km': 45.0,
      'corridors': [
        {
          'name': 'Samsi Railway Station',
          'addr': 'Station Road, Samsi, Malda',
          'lat': 25.2745,
          'lng': 88.0062,
          'icon': Icons.train,
          'tag': 'Station',
        },
        {
          'name': 'Samsi College Morh',
          'addr': 'College Road, Samsi',
          'lat': 25.2818,
          'lng': 88.0065,
          'icon': Icons.school,
          'tag': 'College',
        },
        {
          'name': 'Ghasiram Morh',
          'addr': 'Ghasiram Morh Crossing, Samsi',
          'lat': 25.2731,
          'lng': 88.0088,
          'icon': Icons.storefront,
          'tag': 'Hub',
        },
        {
          'name': 'Kandaran Colony',
          'addr': 'Kandaran Durga Mandir Road, Chanchal-II',
          'lat': 25.2773,
          'lng': 87.9892,
          'icon': Icons.temple_hindu,
          'tag': 'Colony',
        },
        {
          'name': 'Chanchal Bus Stand',
          'addr': 'Chanchal Sub-Division Hub',
          'lat': 25.3895,
          'lng': 87.9940,
          'icon': Icons.directions_bus,
          'tag': 'Bus Stand',
        },
        {
          'name': 'Binodpur Balia Market',
          'addr': 'Balia Hat, Ratua-I',
          'lat': 25.2690,
          'lng': 88.0150,
          'icon': Icons.shopping_basket,
          'tag': 'Market',
        },
        {
          'name': 'Makaram Morh',
          'addr': 'Makaram Road, Samsi',
          'lat': 25.2715,
          'lng': 87.9840,
          'icon': Icons.alt_route,
          'tag': 'Link',
        },
        {
          'name': 'Vidyasagar College Rd',
          'addr': 'Vidyasagar Road Crossing, Samsi',
          'lat': 25.2748,
          'lng': 88.0035,
          'icon': Icons.alt_route,
          'tag': 'Feeder',
        },
        {
          'name': 'Damanbhiti Morh',
          'addr': 'Damanbhiti Crossing, Samsi',
          'lat': 25.2855,
          'lng': 88.0120,
          'icon': Icons.turn_sharp_right,
          'tag': 'Link',
        },
      ],
    },
    {
      'id': 'malda_town',
      'name': 'Malda Town',
      'city': 'Malda',
      'center': const LatLng(25.0065, 88.1420),
      'radius_km': 18.0,
      'corridors': [
        {
          'name': 'Malda Town Station',
          'addr': 'Station Road, English Bazar',
          'lat': 25.0116,
          'lng': 88.1405,
          'icon': Icons.train,
        },
        {
          'name': 'Rathbari Morh',
          'addr': 'NH34, Rathbari, Malda',
          'lat': 25.0065,
          'lng': 88.1420,
          'icon': Icons.alt_route,
        },
        {
          'name': 'Post Office Morh',
          'addr': 'Main Road, English Bazar',
          'lat': 25.0010,
          'lng': 88.1380,
          'icon': Icons.local_post_office,
        },
        {
          'name': 'Gour Banga University',
          'addr': 'Mokdumpur, Malda',
          'lat': 25.0290,
          'lng': 88.1250,
          'icon': Icons.school,
        },
        {
          'name': 'Mangalbari Chowrasta',
          'addr': 'Old Malda Crossing',
          'lat': 25.0210,
          'lng': 88.1560,
          'icon': Icons.storefront,
        },
      ],
    },
    {
      'id': 'siliguri',
      'name': 'Siliguri',
      'city': 'Siliguri',
      'center': const LatLng(26.727101, 88.395287),
      'radius_km': 20.0,
      'corridors': [
        {
          'name': 'Siliguri Junction',
          'addr': 'Pradhan Nagar, Siliguri',
          'lat': 26.7302,
          'lng': 88.4215,
          'icon': Icons.train,
        },
        {
          'name': 'Bidhan Market',
          'addr': 'Hill Cart Road, Siliguri',
          'lat': 26.7161,
          'lng': 88.4285,
          'icon': Icons.shopping_cart,
        },
        {
          'name': 'Venus Morh',
          'addr': 'Sevoke Road, Siliguri',
          'lat': 26.7235,
          'lng': 88.4320,
          'icon': Icons.alt_route,
        },
        {
          'name': 'Court Morh',
          'addr': 'Kachari Road, Siliguri',
          'lat': 26.7110,
          'lng': 88.4240,
          'icon': Icons.account_balance,
        },
      ],
    },
    {
      'id': 'kolkata_north',
      'name': 'Kolkata North',
      'city': 'Kolkata',
      'center': const LatLng(22.572646, 88.363895),
      'radius_km': 20.0,
      'corridors': [
        {
          'name': 'Shyambazar Metro (Gate 1)',
          'addr': 'Five Point Crossing, Kolkata',
          'lat': 22.6038,
          'lng': 88.3713,
          'icon': Icons.subway,
        },
        {
          'name': 'Sealdah Railway Station',
          'addr': 'Bipin Behari Ganguly St',
          'lat': 22.5681,
          'lng': 88.3704,
          'icon': Icons.train,
        },
        {
          'name': 'Hatibagan Market',
          'addr': 'Bidhan Sarani, Kolkata',
          'lat': 22.5942,
          'lng': 88.3710,
          'icon': Icons.storefront,
        },
        {
          'name': 'College Street',
          'addr': 'Coffee House Crossing',
          'lat': 22.5754,
          'lng': 88.3639,
          'icon': Icons.menu_book,
        },
      ],
    },
    {
      'id': 'howrah',
      'name': 'Howrah Urban',
      'city': 'Howrah',
      'center': const LatLng(22.595770, 88.263640),
      'radius_km': 15.0,
      'corridors': [
        {
          'name': 'Howrah Railway Station',
          'addr': 'Station Road, Howrah',
          'lat': 22.5855,
          'lng': 88.3426,
          'icon': Icons.train,
        },
        {
          'name': 'Nabanna (Secretariat)',
          'addr': 'Mandirtala, Shibpur',
          'lat': 22.5564,
          'lng': 88.3075,
          'icon': Icons.location_city,
        },
        {
          'name': 'Kadamtala Market',
          'addr': 'Bantra, Howrah',
          'lat': 22.5880,
          'lng': 88.3120,
          'icon': Icons.storefront,
        },
      ],
    },
  ];

  void _updateZoneCorridors(LatLng point) {
    Map<String, dynamic>? closestZone;
    double minDistance = double.infinity;

    for (final zone in _zoneRegistry) {
      final center = zone['center'] as LatLng;
      final dist = Geolocator.distanceBetween(
        point.latitude, point.longitude, center.latitude, center.longitude,
      ) / 1000.0;
      final radius = (zone['radius_km'] as num).toDouble();
      if (dist <= radius && dist < minDistance) {
        minDistance = dist;
        closestZone = zone;
      }
    }

    // Fallback: If outside defined radius, pick the nearest registered zone if within 70 km
    if (closestZone == null) {
      for (final zone in _zoneRegistry) {
        final center = zone['center'] as LatLng;
        final dist = Geolocator.distanceBetween(
          point.latitude, point.longitude, center.latitude, center.longitude,
        ) / 1000.0;
        if (dist <= 70.0 && dist < minDistance) {
          minDistance = dist;
          closestZone = zone;
        }
      }
    }

    if (closestZone != null) {
      setState(() {
        _currentZoneName = closestZone!['name'] as String;
        _activeZoneCorridors = List<Map<String, dynamic>>.from(closestZone['corridors'] as List);
      });
    } else {
      setState(() {
        _currentZoneName = 'Local Zone';
        _activeZoneCorridors = [
          {
            'name': 'Nearby Railway Station',
            'addr': 'Local Station Feeder',
            'lat': point.latitude + 0.005,
            'lng': point.longitude + 0.003,
            'icon': Icons.train,
          },
          {
            'name': 'Main Market / Bazaar',
            'addr': 'Local Central Market',
            'lat': point.latitude - 0.004,
            'lng': point.longitude + 0.002,
            'icon': Icons.storefront,
          },
          {
            'name': 'College / High School',
            'addr': 'Local Educational Hub',
            'lat': point.latitude + 0.006,
            'lng': point.longitude - 0.004,
            'icon': Icons.school,
          },
          {
            'name': 'Bus Stand / Morh',
            'addr': 'Local Junction Morh',
            'lat': point.latitude - 0.005,
            'lng': point.longitude - 0.003,
            'icon': Icons.directions_bus,
          },
        ];
      });
    }

    // Also fetch dynamically from localhost backend if connected
    _fetchCorridorsFromBackend(point);
  }

  Future<void> _fetchCorridorsFromBackend(LatLng point) async {
    try {
      final data = await ApiService().getZoneCorridors(point.latitude, point.longitude);
      if (data != null && mounted) {
        final list = data['corridors'] as List?;
        if (list != null && list.isNotEmpty) {
          setState(() {
            if (data['zone_name'] != null) {
              _currentZoneName = data['zone_name'];
            }
            _activeZoneCorridors = list.map((c) => {
              'name': c['name'] ?? 'Hub',
              'addr': c['address'] ?? '',
              'lat': (c['lat'] as num).toDouble(),
              'lng': (c['lng'] as num).toDouble(),
              'icon': Icons.location_on,
            }).toList();
          });
        }
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _pickupController.text = 'Locating GPS...';
    _updateZoneCorridors(_currentLocation);
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
        _updateZoneCorridors(newGps);

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

  // --- DIRECT PMG, CONCRETE DHALAI & POCKET ROAD GEOMETRIC SYNTHESIS ---
  List<LatLng> _synthesizePmgPocketRoute(LatLng p1, LatLng p2) {
    // Hub points around Samsi & Malda rural/suburban network
    const pttiCollege = LatLng(25.2748, 88.0076);
    const pttiHwyJunction = LatLng(25.2748, 88.0090);
    const stationRoadCrossing = LatLng(25.2750, 88.0055);
    const stationPocketLink = LatLng(25.2756, 88.0008);
    const pmgConcreteCenter = LatLng(25.2763, 87.9962);
    const kandaranVillage = LatLng(25.2769, 87.9922);
    const kandaranColony = LatLng(25.2773, 87.9892);
    const ghasiramMorh = LatLng(25.2731, 88.0088);
    const samsiCollegeMorh = LatLng(25.2818, 88.0065);
    const samsiCollegeHwy = LatLng(25.2825, 88.0095);

    final isSamsiCorridor = (p1.latitude >= 25.23 && p1.latitude <= 25.32 && p1.longitude >= 87.95 && p1.longitude <= 88.05) &&
                            (p2.latitude >= 25.23 && p2.latitude <= 25.32 && p2.longitude >= 87.95 && p2.longitude <= 88.05);

    if (isSamsiCorridor) {
      final pts = <LatLng>[p1];

      // If start is west of NH31 (e.g. Nagar PTTI College or Kandaran)
      final p1IsPtti = Geolocator.distanceBetween(p1.latitude, p1.longitude, pttiCollege.latitude, pttiCollege.longitude) < 350;
      final p2IsPtti = Geolocator.distanceBetween(p2.latitude, p2.longitude, pttiCollege.latitude, pttiCollege.longitude) < 350;

      if (p1IsPtti && !p2IsPtti) {
        // From Nagar PTTI College through pocket feeder road eastward to NH31
        pts.add(const LatLng(25.2748, 88.0083));
        pts.add(pttiHwyJunction);
        // Then along NH31 towards p2
        if (p2.latitude < p1.latitude) {
          pts.add(ghasiramMorh);
        } else {
          pts.add(const LatLng(25.2780, 88.0092));
        }
      } else if (!p1IsPtti && p2IsPtti) {
        // Towards Nagar PTTI College
        if (p1.latitude < p2.latitude) {
          pts.add(ghasiramMorh);
        }
        pts.add(pttiHwyJunction);
        pts.add(const LatLng(25.2748, 88.0083));
      } else if (p1.longitude > p2.longitude) {
        // East (NH31 / Station) to West (Kandaran / Ratua)
        pts.add(stationRoadCrossing);
        pts.add(stationPocketLink);
        pts.add(pmgConcreteCenter);
        pts.add(kandaranVillage);
        pts.add(kandaranColony);
      } else {
        // West (Kandaran / Ratua) to East (NH31 / Station)
        pts.add(kandaranColony);
        pts.add(kandaranVillage);
        pts.add(pmgConcreteCenter);
        pts.add(stationPocketLink);
        pts.add(stationRoadCrossing);
      }
      pts.add(p2);
      return pts;
    }

    // General suburban/rural pocket road synthesis with natural road terrain curves
    final pts = <LatLng>[p1];
    const steps = 8;
    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      final lat = p1.latitude + (p2.latitude - p1.latitude) * t;
      final lng = p1.longitude + (p2.longitude - p1.longitude) * t;
      final curvature = math.sin(t * math.pi) * 0.00035;
      pts.add(LatLng(lat + curvature, lng));
    }
    pts.add(p2);
    return pts;
  }

  // --- HYBRID ROAD NAVIGATION ROUTING (HIGHWAY + PMG / POCKET ROADS) ---
  Future<void> _fetchRoadRoute(LatLng start, LatLng end) async {
    setState(() => _isLoadingRoute = true);

    final straightDistKm = Geolocator.distanceBetween(
      start.latitude, start.longitude, end.latitude, end.longitude,
    ) / 1000.0;

    // 1. PMG, Gram Sadak, and Local Pocket Road Routers (OSRM Bike profile traversing rural tracks, living streets & alleys)
    final pmgUris = [
      Uri.parse(
        'https://routing.openstreetmap.de/routed-bike/route/v1/bicycle/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      ),
      Uri.parse(
        'http://routing.openstreetmap.de/routed-bike/route/v1/bicycle/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      ),
    ];

    // 2. Highway and Major Arterial Routers (OSRM Car Driving profile)
    final highwayUris = [
      Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      ),
      Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      ),
    ];

    Future<Map<String, dynamic>?> queryCandidates(List<Uri> uris) async {
      for (final uri in uris) {
        try {
          final res = await http.get(uri, headers: {
            'User-Agent': 'in.oitoto.customer/1.0',
          }).timeout(const Duration(milliseconds: 2500));
          if (res.statusCode == 200) {
            final json = jsonDecode(res.body);
            if (json['code'] == 'Ok' && json['routes'] != null && (json['routes'] as List).isNotEmpty) {
              return json['routes'][0];
            }
          }
        } catch (_) {}
      }
      return null;
    }

    try {
      // Query both Highway and PMG/Pocket road networks concurrently
      final results = await Future.wait([
        queryCandidates(pmgUris),
        queryCandidates(highwayUris),
      ]);

      final pmgCandidate = results[0];
      final highwayCandidate = results[1];

      Map<String, dynamic>? bestRoute;
      String roadCategory = 'Direct Shortest Road';

      if (pmgCandidate != null && highwayCandidate != null) {
        final pmgDistM = (pmgCandidate['distance'] as num).toDouble();
        final hwyDistM = (highwayCandidate['distance'] as num).toDouble();

        if (pmgDistM <= hwyDistM) {
          bestRoute = pmgCandidate;
          roadCategory = 'PMG / Pocket Road';
        } else {
          bestRoute = highwayCandidate;
          roadCategory = 'Highway Corridor';
        }
      } else if (pmgCandidate != null) {
        bestRoute = pmgCandidate;
        roadCategory = 'PMG / Pocket Road';
      } else if (highwayCandidate != null) {
        bestRoute = highwayCandidate;
        roadCategory = 'Highway Corridor';
      }

      if (bestRoute != null) {
        final distM = (bestRoute['distance'] as num).toDouble();
        final distKm = distM / 1000.0;

        // CRITICAL SHORTCUT CHECK:
        // If trip is local (straight line <= 4.2 km), but OSRM took a massive highway detour (> straightDistKm * 1.6),
        // it means the OSM database is missing the local village PMG / concrete dhalai road!
        // We override with the authentic direct PMG / pocket road:
        if (straightDistKm <= 4.2 && distKm > straightDistKm * 1.6) {
          final pmgPoints = _synthesizePmgPocketRoute(start, end);
          final directKm = double.parse((straightDistKm * 1.15).toStringAsFixed(1));
          final directMins = ((directKm / 20.0) * 60.0).round().clamp(2, 60);

          if (mounted) {
            setState(() {
              _routePoints = pmgPoints;
              _routeDistanceKm = directKm;
              _routeDurationMins = directMins;
              _routeRoadType = 'PMG / Pocket Dhalai Road';
              _isLoadingRoute = false;
            });
            _centerOnRoute(start, end);
            return;
          }
        }

        final coords = bestRoute['geometry']['coordinates'] as List;
        final roadPoints = coords.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();

        // Ensure unbroken continuous route directly from start pin to end pin:
        final fullRoute = <LatLng>[start];

        final startGapM = Geolocator.distanceBetween(
          start.latitude, start.longitude,
          roadPoints.first.latitude, roadPoints.first.longitude,
        );

        if (startGapM > 5.0) {
          final steps = (startGapM / 25.0).ceil().clamp(1, 10);
          for (int i = 1; i < steps; i++) {
            final t = i / steps;
            fullRoute.add(LatLng(
              start.latitude + (roadPoints.first.latitude - start.latitude) * t,
              start.longitude + (roadPoints.first.longitude - start.longitude) * t,
            ));
          }
        }

        fullRoute.addAll(roadPoints);

        final endGapM = Geolocator.distanceBetween(
          roadPoints.last.latitude, roadPoints.last.longitude,
          end.latitude, end.longitude,
        );

        if (endGapM > 5.0) {
          final lastPt = roadPoints.last;
          final steps = (endGapM / 25.0).ceil().clamp(1, 10);
          for (int i = 1; i < steps; i++) {
            final t = i / steps;
            fullRoute.add(LatLng(
              lastPt.latitude + (end.latitude - lastPt.latitude) * t,
              lastPt.longitude + (end.longitude - lastPt.longitude) * t,
            ));
          }
          fullRoute.add(end);
        } else {
          fullRoute.add(end);
        }

        final durMins = ((distKm / 20.0) * 60.0).round().clamp(2, 240);
        final finalCategory = (startGapM > 25.0 || endGapM > 25.0)
            ? 'PMG Road + Highway Hybrid'
            : roadCategory;

        if (mounted) {
          setState(() {
            _routePoints = fullRoute;
            _routeDistanceKm = distKm;
            _routeDurationMins = durMins;
            _routeRoadType = finalCategory;
            _isLoadingRoute = false;
          });
          _centerOnRoute(start, end);
          return;
        }
      }
    } catch (_) {}

    // Fallback if network routing unavailable or times out
    if (mounted) {
      final pmgPoints = _synthesizePmgPocketRoute(start, end);
      final estRoadKm = double.parse((straightDistKm * 1.18).toStringAsFixed(1));
      final estMins = ((estRoadKm / 20.0) * 60.0).round().clamp(2, 60);

      setState(() {
        _routePoints = pmgPoints;
        _routeDistanceKm = estRoadKm;
        _routeDurationMins = estMins;
        _routeRoadType = 'PMG Road + Highway Hybrid';
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
        MaterialPageRoute(builder: (_) => ActiveRideScreen(booking: active, routePoints: _routePoints)),
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
        if (res['success'] == true && res['data'] != null) {
          _fareEstimate = res['data'];
        } else {
          // Localhost offline/fallback fare calculation (Base ₹20 for 1.5 km + ₹10/km)
          final roadKm = _routeDistanceKm ?? (Geolocator.distanceBetween(
            _currentLocation.latitude, _currentLocation.longitude,
            _dropLocation!.latitude, _dropLocation!.longitude,
          ) / 1000.0 * 1.2);
          final finalFare = roadKm <= 1.5 ? 20 : (20 + (roadKm - 1.5) * 10).round();
          final durMins = ((roadKm / 20.0) * 60.0).round().clamp(2, 180);

          _fareEstimate = {
            'final_fare': finalFare,
            'base_fare': 20,
            'distance_km': roadKm.toStringAsFixed(1),
            'estimated_duration_mins': durMins,
            'service_area': {'name': _currentZoneName},
          };
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
              routePoints: _routePoints,
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
              maxZoom: 20.0,
              minZoom: 4.0,
              onTap: (tapPosition, point) => _setDestination(point),
            ),
            children: [
              if (_mapMode == 'satellite')
                TileLayer(
                  urlTemplate: 'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
                  subdomains: const ['0', '1', '2', '3'],
                  userAgentPackageName: 'in.oitoto.customer',
                  maxZoom: 20,
                  maxNativeZoom: 20,
                )
              else
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'in.oitoto.customer',
                  maxZoom: 19,
                ),

              // Road Route Layer following traffic/street network (Bold Emerald Green on All PMG & Pocket Roads)
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Outer crisp white casing for high street contrast on all map tiles
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 8.5,
                      color: Colors.white,
                    ),
                    // Inner vivid electric emerald green navigation route line
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.5,
                      color: const Color(0xFF00C853),
                    ),
                  ],
                ),

              // Markers Layer
              MarkerLayer(
                markers: [
                  // Current Pickup Marker (Slender Pointer Pin)
                  Marker(
                    point: _currentLocation,
                    width: 28,
                    height: 52,
                    alignment: Alignment.bottomCenter,
                    child: const SlenderPickupPin(),
                  ),

                  // Destination Drop Marker (Slender Pointer Pin with Needle Tip)
                  if (_dropLocation != null)
                    Marker(
                      point: _dropLocation!,
                      width: 28,
                      height: 54,
                      alignment: Alignment.bottomCenter,
                      child: const SlenderDestinationPin(),
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
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF3B82F6), width: 0.8),
                          ),
                          child: const Text(
                            'v1.0.9',
                            style: TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
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

          // 2.1 2-Mode Location Map Selector (Road & Satellite - Vertical Layout)
          Positioned(
            top: 105,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.16), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMapModePill('road', '🛣️ Road'),
                  const SizedBox(height: 4),
                  _buildMapModePill('satellite', '🛰️ Sat'),
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

                      // Dynamic Zone Corridor Header
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.explore_outlined, size: 14, color: AppColors.primaryGreen),
                            const SizedBox(width: 4),
                            Text(
                              '$_currentZoneName Corridors:',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.deepNavy),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreenLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${_activeZoneCorridors.length} Hubs',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryGreenDark),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quick Destination Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _activeZoneCorridors.map((spot) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                avatar: Icon(spot['icon'] as IconData? ?? Icons.location_on, size: 15, color: AppColors.primaryGreen),
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
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _routeRoadType.contains('PMG') ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: _routeRoadType.contains('PMG') ? const Color(0xFF4CAF50) : const Color(0xFFFFB300),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          _routeRoadType.contains('PMG') ? '🛤️ PMG / Pocket' : '🛣️ Highway',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _routeRoadType.contains('PMG') ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _routeDistanceKm != null
                                            ? '${_routeDistanceKm!.toStringAsFixed(1)} km'
                                            : '${_fareEstimate!['distance_km']} km',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.deepNavy),
                                      ),
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
  }

  Widget _buildMapModePill(String mode, String label) {
    final isSelected = _mapMode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _mapMode = mode),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.deepNavy,
            ),
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// 📍 SLENDER NEEDLE NAVIGATION MARKER PINS ("Soru Needle Pin")
// ==============================================================================

/// Slender Destination Pin with Razor-Sharp Needle Tip and 3D Ground Contact Shadow ("Soru Needle Pin")
class SlenderDestinationPin extends StatelessWidget {
  const SlenderDestinationPin({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(28, 54),
      painter: _SlenderDestinationPinPainter(),
    );
  }
}

class _SlenderDestinationPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; // 14.0
    const headCenterY = 12.0;
    const headRadius = 10.5;
    final needleTipY = size.height - 4.5; // 49.5

    // 1. Ground 3D Contact Shadow on Road Surface
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height - 2.0),
        width: 13,
        height: 4.0,
      ),
      shadowPaint,
    );

    // 2. Ultra-Slender Needle Teardrop Body ("Soru Needle")
    final pinPath = Path();
    pinPath.moveTo(cx, needleTipY);
    // Sleek needle contour tapering smoothly into compact bead head
    pinPath.lineTo(cx - 7.5, headCenterY + 5.0);
    pinPath.arcToPoint(
      Offset(cx + 7.5, headCenterY + 5.0),
      radius: const Radius.circular(headRadius),
      largeArc: true,
    );
    pinPath.lineTo(cx, needleTipY);
    pinPath.close();

    // 3. Ambient Drop Shadow
    final pinShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.save();
    canvas.translate(0, 1.5);
    canvas.drawPath(pinPath, pinShadowPaint);
    canvas.restore();

    // 4. Vibrant Crimson Gradient Fill
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF2A2A), Color(0xFFB71C1C)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(pinPath, fillPaint);

    // 5. Crisp White Outer Contour
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(pinPath, strokePaint);

    // 6. Inner Core White Disc
    final coreWhitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, headCenterY), 5.0, coreWhitePaint);

    // 7. Razor Focal Dot (Deep Crimson)
    final coreDotPaint = Paint()..color = const Color(0xFF7F0000);
    canvas.drawCircle(Offset(cx, headCenterY), 2.4, coreDotPaint);

    // 8. Ground Contact Pinpoint Dot
    final groundPinPoint = Paint()..color = const Color(0xFFFF2A2A);
    canvas.drawCircle(Offset(cx, needleTipY), 1.2, groundPinPoint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Slender Pickup Pin with Razor-Sharp Needle Tip (Eco-Green Signature)
class SlenderPickupPin extends StatelessWidget {
  const SlenderPickupPin({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(28, 52),
      painter: _SlenderPickupPinPainter(),
    );
  }
}

class _SlenderPickupPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; // 14.0
    const headCenterY = 12.0;
    const headRadius = 10.0;
    final needleTipY = size.height - 4.0; // 48.0

    // 1. Ground 3D Contact Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height - 2.0),
        width: 12,
        height: 3.8,
      ),
      shadowPaint,
    );

    // 2. Slender Needle Teardrop Body Path
    final pinPath = Path();
    pinPath.moveTo(cx, needleTipY);
    pinPath.lineTo(cx - 7.0, headCenterY + 4.5);
    pinPath.arcToPoint(
      Offset(cx + 7.0, headCenterY + 4.5),
      radius: const Radius.circular(headRadius),
      largeArc: true,
    );
    pinPath.lineTo(cx, needleTipY);
    pinPath.close();

    // 3. Ambient Shadow
    final pinShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.save();
    canvas.translate(0, 1.5);
    canvas.drawPath(pinPath, pinShadowPaint);
    canvas.restore();

    // 4. Eco-Green Gradient Fill
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF047857)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(pinPath, fillPaint);

    // 5. White Outer Contour
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(pinPath, strokePaint);

    // 6. Inner Core White Disc
    final coreWhitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, headCenterY), 4.8, coreWhitePaint);

    // 7. Center Focal Dot (Deep Green)
    final coreDotPaint = Paint()..color = const Color(0xFF065F2C);
    canvas.drawCircle(Offset(cx, headCenterY), 2.2, coreDotPaint);

    // 8. Ground Contact Pinpoint Dot
    final groundPinPoint = Paint()..color = const Color(0xFF10B981);
    canvas.drawCircle(Offset(cx, needleTipY), 1.2, groundPinPoint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
