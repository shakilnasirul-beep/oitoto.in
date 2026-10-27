const fs = require('fs');

let content = fs.readFileSync('G:/oitoto/backend/src/Controllers/AdminController.php', 'utf8');

const targetMarker = 'public function verifyDocument(Request $request): void';

const deleteDriverMethod = `/**
     * Delete driver partner permanently and unassign vehicles
     */
    public function deleteDriver(Request $request): void
    {
        $admin = $request->getUser();
        $id = (int)$request->param('id');
        $db = Database::getConnection();

        // 1. Fetch driver profile & user
        $stmt = $db->prepare("
            SELECT dp.*, u.full_name, u.phone, v.vehicle_number 
            FROM driver_profiles dp
            JOIN users u ON u.id = dp.user_id
            LEFT JOIN vehicles v ON v.id = dp.vehicle_id
            WHERE dp.id = ?
        ");
        $stmt->execute([$id]);
        $driver = $stmt->fetch();

        if (!$driver) {
            $uStmt = $db->prepare("
                SELECT dp.*, u.full_name, u.phone, v.vehicle_number 
                FROM driver_profiles dp
                JOIN users u ON u.id = dp.user_id
                LEFT JOIN vehicles v ON v.id = dp.vehicle_id
                WHERE dp.user_id = ?
            ");
            $uStmt->execute([$id]);
            $driver = $uStmt->fetch();
        }

        if (!$driver) {
            Response::error('Driver partner not found', 404);
            return;
        }

        $driverId = (int)$driver['id'];
        $userId = (int)$driver['user_id'];
        $driverName = $driver['full_name'] ?? 'Driver Partner';
        $vehicleNumber = $driver['vehicle_number'] ?? null;

        // 2. Unassign vehicle
        $db->prepare("UPDATE vehicles SET current_driver_id = NULL WHERE current_driver_id = ?")->execute([$driverId]);

        // 3. Delete from driver_profiles
        $db->prepare("DELETE FROM driver_profiles WHERE id = ?")->execute([$driverId]);

        // 4. Update user status to deleted
        $db->prepare("UPDATE users SET status = 'deleted' WHERE id = ?")->execute([$userId]);

        // 5. Audit log
        if (class_exists('\\\\OiToto\\\\Core\\\\Logger')) {
            Logger::audit(
                (int)($admin['id'] ?? 1),
                'delete_driver',
                'driver_profiles',
                $driverId,
                null,
                ['driver_name' => $driverName, 'vehicle_number' => $vehicleNumber]
            );
        }

        Response::success([
            'id' => $driverId,
            'user_id' => $userId,
            'driver_name' => $driverName,
            'vehicle_number' => $vehicleNumber
        ], "Driver partner '{$driverName}' successfully deleted.");
    }

    `;

if (!content.includes('function deleteDriver(')) {
    content = content.replace(targetMarker, deleteDriverMethod + targetMarker);
    fs.writeFileSync('G:/oitoto/backend/src/Controllers/AdminController.php', content, 'utf8');
    console.log('deleteDriver method added to AdminController.php');
} else {
    console.log('deleteDriver already exists in AdminController.php');
}
