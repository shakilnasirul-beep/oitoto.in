<?php
declare(strict_types=1);

namespace OiToto\Controllers;

use OiToto\Core\Database;
use OiToto\Core\Request;
use OiToto\Core\Response;
use OiToto\Core\Validator;
use OiToto\Services\LocationService;

class ServiceAreaController
{
    public function index(Request $request): void
    {
        $db = Database::getConnection();
        $stmt = $db->query("
            SELECT sa.*, fr.base_fare, fr.per_km_rate, fr.platform_commission_percentage,
                   (SELECT COUNT(*) FROM vehicles WHERE service_area_id = sa.id) AS total_vehicles,
                   (SELECT COUNT(*) FROM driver_profiles WHERE service_area_id = sa.id AND is_online = 1) AS online_drivers
            FROM service_areas sa
            LEFT JOIN fare_rules fr ON fr.service_area_id = sa.id AND fr.is_active = 1
            ORDER BY sa.name ASC
        ");
        $areas = $stmt->fetchAll();

        foreach ($areas as &$area) {
            $routes = [];
            if (!empty($area['boundary_geojson'])) {
                $decoded = json_decode($area['boundary_geojson'], true);
                if (isset($decoded['routes']) && is_array($decoded['routes'])) {
                    $routes = $decoded['routes'];
                }
            }
            $area['routes'] = $routes;
        }
        unset($area);

        Response::success($areas);
    }

    public function show(Request $request): void
    {
        $id = (int)$request->param('id');
        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT sa.*, fr.id AS fare_rule_id, fr.base_fare, fr.base_distance_km,
                   fr.per_km_rate, fr.minimum_fare, fr.per_minute_waiting_charge,
                   fr.night_surge_multiplier, fr.platform_commission_percentage
            FROM service_areas sa
            LEFT JOIN fare_rules fr ON fr.service_area_id = sa.id AND fr.is_active = 1
            WHERE sa.id = ?
        ");
        $stmt->execute([$id]);
        $area = $stmt->fetch();

        if (!$area) {
            Response::error('Service area not found', 404);
            return;
        }

        $routes = [];
        if (!empty($area['boundary_geojson'])) {
            $decoded = json_decode($area['boundary_geojson'], true);
            if (isset($decoded['routes']) && is_array($decoded['routes'])) {
                $routes = $decoded['routes'];
            }
        }
        $area['routes'] = $routes;

        Response::success($area);
    }

    public function store(Request $request): void
    {
        $v = Validator::make($request->all(), [
            'name' => 'required',
            'state' => 'required',
            'city' => 'required',
            'center_lat' => 'required|numeric',
            'center_lng' => 'required|numeric',
            'radius_km' => 'required|numeric'
        ]);

        if (!$v->validate()) {
            Response::error($v->getFirstError(), 422);
            return;
        }

        $db = Database::getConnection();
        $db->beginTransaction();

        try {
            $routes = $request->get('routes');
            $boundaryGeojson = !empty($routes) ? json_encode(['routes' => $routes], JSON_UNESCAPED_UNICODE) : null;

            $stmt = $db->prepare("
                INSERT INTO service_areas (name, state, city, center_lat, center_lng, radius_km, max_search_radius_km, boundary_geojson, is_active)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $request->get('name'),
                $request->get('state'),
                $request->get('city'),
                $request->get('center_lat'),
                $request->get('center_lng'),
                $request->get('radius_km'),
                $request->get('max_search_radius_km', 4.0),
                $boundaryGeojson,
                (int)$request->get('is_active', 1)
            ]);
            $areaId = (int)$db->lastInsertId();

            // Insert initial default fare rule for this area
            $fStmt = $db->prepare("
                INSERT INTO fare_rules (service_area_id, vehicle_type, base_fare, base_distance_km, per_km_rate, minimum_fare, platform_commission_percentage)
                VALUES (?, 'e_rickshaw', 20.00, 1.50, 10.00, 20.00, 10.00)
            ");
            $fStmt->execute([$areaId]);

            $db->commit();
            Response::success(['id' => $areaId], 'Service area created successfully.', 201);
        } catch (\Exception $e) {
            $db->rollBack();
            Response::error($e->getMessage(), 500);
        }
    }

    public function update(Request $request): void
    {
        $id = (int)$request->param('id');
        $db = Database::getConnection();

        $routes = $request->get('routes');
        $boundaryGeojson = $routes !== null ? json_encode(['routes' => $routes], JSON_UNESCAPED_UNICODE) : null;

        $stmt = $db->prepare("
            UPDATE service_areas 
            SET name = COALESCE(?, name),
                state = COALESCE(?, state),
                city = COALESCE(?, city),
                center_lat = COALESCE(?, center_lat),
                center_lng = COALESCE(?, center_lng),
                radius_km = COALESCE(?, radius_km),
                boundary_geojson = CASE WHEN ? IS NOT NULL THEN ? ELSE boundary_geojson END,
                is_active = COALESCE(?, is_active)
            WHERE id = ?
        ");
        $stmt->execute([
            $request->get('name'),
            $request->get('state'),
            $request->get('city'),
            $request->get('center_lat'),
            $request->get('center_lng'),
            $request->get('radius_km'),
            $boundaryGeojson,
            $boundaryGeojson,
            $request->get('is_active'),
            $id
        ]);

        Response::success(null, 'Service area updated successfully.');
    }

    public function destroy(Request $request): void
    {
        $id = (int)$request->param('id');
        if ($id <= 0) {
            Response::error('Invalid service area ID.', 400);
            return;
        }

        $db = Database::getConnection();
        try {
            $db->beginTransaction();

            // 1. Delete associated fare rules
            $stmt = $db->prepare("DELETE FROM fare_rules WHERE service_area_id = ?");
            $stmt->execute([$id]);

            // 2. Unassign vehicles from this area
            $stmt = $db->prepare("UPDATE vehicles SET service_area_id = NULL WHERE service_area_id = ?");
            $stmt->execute([$id]);

            // 3. Unassign drivers from this area
            $stmt = $db->prepare("UPDATE driver_profiles SET service_area_id = NULL WHERE service_area_id = ?");
            $stmt->execute([$id]);

            // 4. Unassign bookings
            $stmt = $db->prepare("UPDATE bookings SET service_area_id = NULL WHERE service_area_id = ?");
            $stmt->execute([$id]);

            // 5. Delete the service area
            $stmt = $db->prepare("DELETE FROM service_areas WHERE id = ?");
            $stmt->execute([$id]);

            $db->commit();
            Response::success(null, 'Service area deleted successfully.');
        } catch (\Exception $e) {
            if ($db->inTransaction()) {
                $db->rollBack();
            }
            Response::error('Failed to delete service area: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get active corridors for a specific zone based on passenger GPS coordinates
     */
    public function corridors(Request $request): void
    {
        $lat = (float)$request->get('lat', 0.0);
        $lng = (float)$request->get('lng', 0.0);

        if ($lat == 0.0 && $lng == 0.0) {
            Response::error('Latitude and Longitude required', 400);
            return;
        }

        $area = LocationService::findServiceArea($lat, $lng);
        $corridors = [];
        $zoneName = $area['name'] ?? 'Local Zone';
        $city = $area['city'] ?? 'Local Hub';

        if (!empty($area['id'])) {
            $db = Database::getConnection();
            $stmt = $db->prepare("SELECT * FROM service_areas WHERE id = ?");
            $stmt->execute([(int)$area['id']]);
            $row = $stmt->fetch();
            if ($row && !empty($row['boundary_geojson'])) {
                $decoded = json_decode($row['boundary_geojson'], true);
                if (isset($decoded['corridors']) && is_array($decoded['corridors'])) {
                    $corridors = $decoded['corridors'];
                } elseif (isset($decoded['routes']) && is_array($decoded['routes'])) {
                    $corridors = $decoded['routes'];
                }
            }
        }

        if (empty($corridors)) {
            $corridors = self::getPredefinedCorridorsForArea($lat, $lng, $zoneName);
        }

        Response::success([
            'zone_id' => $area['id'] ?? null,
            'zone_name' => $zoneName,
            'city' => $city,
            'corridors' => $corridors,
        ]);
    }

    private static function getPredefinedCorridorsForArea(float $lat, float $lng, string $zoneName): array
    {
        // Malda / Samsi / Chanchal Corridor (approx lat 25.15 - 25.45, lng 87.85 - 88.20)
        if ($lat >= 25.15 && $lat <= 25.45 && $lng >= 87.85 && $lng <= 88.20) {
            return [
                ['name' => 'Samsi Railway Station', 'address' => 'Station Road, Samsi, Malda', 'lat' => 25.2745, 'lng' => 88.0062],
                ['name' => 'Samsi College Morh', 'address' => 'College Road, Samsi', 'lat' => 25.2818, 'lng' => 88.0065],
                ['name' => 'Ghasiram Morh', 'address' => 'Ghasiram Morh Crossing, Samsi', 'lat' => 25.2731, 'lng' => 88.0088],
                ['name' => 'Kandaran Colony', 'address' => 'Kandaran Durga Mandir Road, Chanchal-II', 'lat' => 25.2773, 'lng' => 87.9892],
                ['name' => 'Chanchal Bus Stand', 'address' => 'Chanchal Sub-Division Bus Stand', 'lat' => 25.3895, 'lng' => 87.9940],
                ['name' => 'Binodpur Balia Market', 'address' => 'Balia Hat, Ratua-I', 'lat' => 25.2690, 'lng' => 88.0150],
                ['name' => 'Vidyasagar College Rd', 'address' => 'Vidyasagar Road Crossing, Samsi', 'lat' => 25.2748, 'lng' => 88.0035],
                ['name' => 'Damanbhiti Morh', 'address' => 'Damanbhiti Crossing, Samsi', 'lat' => 25.2855, 'lng' => 88.0120],
            ];
        }

        // Malda Town / English Bazar
        if ($lat >= 24.90 && $lat <= 25.10 && $lng >= 88.05 && $lng <= 88.25) {
            return [
                ['name' => 'Malda Town Station', 'address' => 'Station Road, English Bazar', 'lat' => 25.0116, 'lng' => 88.1405],
                ['name' => 'Rathbari Morh', 'address' => 'NH34, Rathbari, Malda', 'lat' => 25.0065, 'lng' => 88.1420],
                ['name' => 'Post Office Morh', 'address' => 'Main Road, English Bazar', 'lat' => 25.0010, 'lng' => 88.1380],
                ['name' => 'Gour Banga University', 'address' => 'Mokdumpur, Malda', 'lat' => 25.0290, 'lng' => 88.1250],
                ['name' => 'Mangalbari Chowrasta', 'address' => 'Old Malda Crossing', 'lat' => 25.0210, 'lng' => 88.1560],
            ];
        }

        // Siliguri (approx lat 26.60 - 26.85, lng 88.30 - 88.50)
        if ($lat >= 26.60 && $lat <= 26.85 && $lng >= 88.30 && $lng <= 88.50) {
            return [
                ['name' => 'Siliguri Junction', 'address' => 'Pradhan Nagar, Siliguri', 'lat' => 26.7302, 'lng' => 88.4215],
                ['name' => 'Bidhan Market', 'address' => 'Hill Cart Road, Siliguri', 'lat' => 26.7161, 'lng' => 88.4285],
                ['name' => 'Venus Morh', 'address' => 'Sevoke Road, Siliguri', 'lat' => 26.7235, 'lng' => 88.4320],
                ['name' => 'Court Morh', 'address' => 'Kachari Road, Siliguri', 'lat' => 26.7110, 'lng' => 88.4240],
            ];
        }

        // Default local fallback
        return [
            ['name' => 'Nearby Railway Station', 'address' => 'Station Feeder', 'lat' => $lat + 0.005, 'lng' => $lng + 0.003],
            ['name' => 'Main Market / Bazaar', 'address' => 'Local Central Market', 'lat' => $lat - 0.004, 'lng' => $lng + 0.002],
            ['name' => 'College / High School', 'address' => 'Educational Hub', 'lat' => $lat + 0.006, 'lng' => $lng - 0.004],
            ['name' => 'Main Chowrasta Morh', 'address' => 'Town Center', 'lat' => $lat + 0.003, 'lng' => $lng - 0.003],
        ];
    }
}
