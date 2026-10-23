<?php
declare(strict_types=1);

namespace OiToto\Services;

use OiToto\Core\Database;
use PDO;

class LocationService
{
    /**
     * Calculate Great Circle distance between two coordinates in Kilometers (Haversine formula)
     */
    public static function calculateDistance(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        if (($lat1 === $lat2) && ($lon1 === $lon2)) {
            return 0.0;
        }

        $earthRadiusKm = 6371.0;

        $latFrom = deg2rad($lat1);
        $lonFrom = deg2rad($lon1);
        $latTo = deg2rad($lat2);
        $lonTo = deg2rad($lon2);

        $latDelta = $latTo - $latFrom;
        $lonDelta = $lonTo - $lonFrom;

        $angle = 2 * asin(sqrt(pow(sin($latDelta / 2), 2) +
            cos($latFrom) * cos($latTo) * pow(sin($lonDelta / 2), 2)));

        return round($angle * $earthRadiusKm, 2);
    }

    /**
     * Estimate trip duration for electric rickshaws in Indian traffic (typical speed: 18-20 km/h)
     */
    public static function estimateDurationMinutes(float $distanceKm, float $avgSpeedKmh = 18.0): int
    {
        if ($distanceKm <= 0.1) {
            return 3;
        }
        $hours = $distanceKm / $avgSpeedKmh;
        $minutes = (int)ceil($hours * 60);
        return max($minutes, 3);
    }

    /**
     * Find the best matching service area for given coordinates
     */
    public static function findServiceArea(float $lat, float $lng): ?array
    {
        $db = Database::getConnection();
        $stmt = $db->query("
            SELECT id, name, state, city, center_lat, center_lng, radius_km, max_search_radius_km, is_active 
            FROM service_areas 
            WHERE is_active = 1
        ");
        $areas = $stmt->fetchAll();

        $matchedArea = null;
        $minDist = PHP_FLOAT_MAX;

        foreach ($areas as $area) {
            $dist = self::calculateDistance($lat, $lng, (float)$area['center_lat'], (float)$area['center_lng']);
            if ($dist <= (float)$area['radius_km'] && $dist < $minDist) {
                $minDist = $dist;
                $matchedArea = $area;
                $matchedArea['distance_from_center_km'] = $dist;
            }
        }

        // If coordinates are slightly outside predefined centers, default to the closest active area
        if (!$matchedArea && !empty($areas)) {
            foreach ($areas as $area) {
                $dist = self::calculateDistance($lat, $lng, (float)$area['center_lat'], (float)$area['center_lng']);
                if ($dist < $minDist) {
                    $minDist = $dist;
                    $matchedArea = $area;
                    $matchedArea['distance_from_center_km'] = $dist;
                }
            }
        }

        return $matchedArea;
    }
}
