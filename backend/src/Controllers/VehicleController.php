<?php
declare(strict_types=1);

namespace OiToto\Controllers;

use OiToto\Core\Database;
use OiToto\Core\Request;
use OiToto\Core\Response;
use OiToto\Core\Validator;
use PDO;

class VehicleController
{
    public function index(Request $request): void
    {
        $db = Database::getConnection();
        $type = $request->get('ownership_type');
        $status = $request->get('status');

        $sql = "
            SELECT v.*, u.full_name AS driver_name, u.phone AS driver_phone,
                   o.business_name AS owner_name, sa.name AS service_area_name
            FROM vehicles v
            LEFT JOIN driver_profiles dp ON dp.id = v.current_driver_id
            LEFT JOIN users u ON u.id = dp.user_id
            LEFT JOIN vehicle_owners o ON o.id = v.owner_id
            LEFT JOIN service_areas sa ON sa.id = v.service_area_id
            WHERE 1=1
        ";
        $params = [];

        if (!empty($type)) {
            $sql .= " AND v.ownership_type = ?";
            $params[] = $type;
        }

        if (!empty($status)) {
            $sql .= " AND v.status = ?";
            $params[] = $status;
        }

        $sql .= " ORDER BY v.created_at DESC";

        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        $vehicles = $stmt->fetchAll();

        Response::success($vehicles);
    }

    public function show(Request $request): void
    {
        $id = (int)$request->param('id');
        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT v.*, u.full_name AS driver_name, u.phone AS driver_phone,
                   o.business_name AS owner_name, sa.name AS service_area_name
            FROM vehicles v
            LEFT JOIN driver_profiles dp ON dp.id = v.current_driver_id
            LEFT JOIN users u ON u.id = dp.user_id
            LEFT JOIN vehicle_owners o ON o.id = v.owner_id
            LEFT JOIN service_areas sa ON sa.id = v.service_area_id
            WHERE v.id = ?
        ");
        $stmt->execute([$id]);
        $veh = $stmt->fetch();

        if (!$veh) {
            Response::error('Vehicle not found', 404);
            return;
        }

        Response::success($veh);
    }

    public function store(Request $request): void
    {
        $v = Validator::make($request->all(), [
            'vehicle_number' => 'required',
            'brand_make' => 'required',
            'ownership_type' => 'in:company_owned,driver_owned,fleet_owned'
        ]);

        if (!$v->validate()) {
            Response::error($v->getFirstError(), 422);
            return;
        }

        $vehNo = strtoupper(trim((string)$request->get('vehicle_number')));
        $db = Database::getConnection();

        // Check duplicate
        $chk = $db->prepare("SELECT id FROM vehicles WHERE vehicle_number = ?");
        $chk->execute([$vehNo]);
        if ($chk->fetch()) {
            Response::error("Vehicle number {$vehNo} is already registered.", 409);
            return;
        }

        $ownership = $request->get('ownership_type', 'company_owned');
        $status = ($ownership === 'company_owned') ? 'approved' : 'pending_verification';

        $stmt = $db->prepare("
            INSERT INTO vehicles (
                vehicle_number, registration_certificate_no, vehicle_type,
                brand_make, model_year, battery_type, ownership_type,
                seating_capacity, color, service_area_id, status,
                fitness_expiry, insurance_expiry, permit_expiry
            ) VALUES (?, ?, 'e_rickshaw', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $vehNo,
            $request->get('registration_certificate_no'),
            $request->get('brand_make', 'Mayuri Grand EV'),
            (int)$request->get('model_year', date('Y')),
            $request->get('battery_type', 'lithium_ion'),
            $ownership,
            (int)$request->get('seating_capacity', 4),
            $request->get('color', 'Green and Yellow'),
            $request->get('service_area_id'),
            $status,
            $request->get('fitness_expiry'),
            $request->get('insurance_expiry'),
            $request->get('permit_expiry')
        ]);

        $newId = (int)$db->lastInsertId();
        Response::success(['id' => $newId, 'vehicle_number' => $vehNo, 'status' => $status], 'Vehicle registered successfully.', 201);
    }

    public function assignDriver(Request $request): void
    {
        $id = (int)$request->param('id');
        $driverId = (int)$request->get('driver_id');

        $db = Database::getConnection();
        $db->beginTransaction();

        try {
            // Unassign driver from previous vehicle if any
            $db->prepare("UPDATE vehicles SET current_driver_id = NULL WHERE current_driver_id = ?")->execute([$driverId]);
            $db->prepare("UPDATE driver_profiles SET vehicle_id = NULL WHERE vehicle_id = ?")->execute([$id]);

            // Assign
            $db->prepare("UPDATE vehicles SET current_driver_id = ? WHERE id = ?")->execute([$driverId, $id]);
            $db->prepare("UPDATE driver_profiles SET vehicle_id = ? WHERE id = ?")->execute([$id, $driverId]);

            $db->commit();
            Response::success(null, 'Driver assigned to E-Rickshaw successfully.');
        } catch (\Exception $e) {
            $db->rollBack();
            Response::error($e->getMessage(), 500);
        }
    }
}
