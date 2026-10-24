<?php
declare(strict_types=1);

namespace OiToto\Controllers;

use OiToto\Core\Database;
use OiToto\Core\Request;
use OiToto\Core\Response;
use OiToto\Core\Validator;

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
            $stmt = $db->prepare("
                INSERT INTO service_areas (name, state, city, center_lat, center_lng, radius_km, max_search_radius_km, is_active)
                VALUES (?, ?, ?, ?, ?, ?, ?, 1)
            ");
            $stmt->execute([
                $request->get('name'),
                $request->get('state'),
                $request->get('city'),
                $request->get('center_lat'),
                $request->get('center_lng'),
                $request->get('radius_km'),
                $request->get('max_search_radius_km', 4.0)
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

        $stmt = $db->prepare("
            UPDATE service_areas 
            SET name = COALESCE(?, name),
                state = COALESCE(?, state),
                city = COALESCE(?, city),
                center_lat = COALESCE(?, center_lat),
                center_lng = COALESCE(?, center_lng),
                radius_km = COALESCE(?, radius_km),
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
            $request->get('is_active'),
            $id
        ]);

        Response::success(null, 'Service area updated successfully.');
    }

    public function destroy(Request $request): void
    {
        $id = (int)$request->param('id');
        $db = Database::getConnection();

        $stmt = $db->prepare("DELETE FROM service_areas WHERE id = ?");
        $stmt->execute([$id]);

        Response::success(null, 'Service area deleted successfully.');
    }
}
