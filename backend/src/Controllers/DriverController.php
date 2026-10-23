<?php
declare(strict_types=1);

namespace OiToto\Controllers;

use OiToto\Core\Database;
use OiToto\Core\Logger;
use OiToto\Core\Request;
use OiToto\Core\Response;
use OiToto\Core\Validator;
use PDO;

class DriverController
{
    public function getProfile(Request $request): void
    {
        $user = $request->getUser();
        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT dp.*, u.full_name, u.phone, u.email, u.avatar_url,
                   v.vehicle_number, v.brand_make, v.model_year, v.battery_type,
                   v.color, v.ownership_type, v.status AS vehicle_status,
                   dw.current_balance, dw.total_earned, dw.cash_collected_held,
                   sa.name AS service_area_name
            FROM driver_profiles dp
            JOIN users u ON u.id = dp.user_id
            LEFT JOIN vehicles v ON v.id = dp.vehicle_id
            LEFT JOIN driver_wallets dw ON dw.driver_id = dp.id
            LEFT JOIN service_areas sa ON sa.id = dp.service_area_id
            WHERE dp.user_id = ?
        ");
        $stmt->execute([$user['id']]);
        $profile = $stmt->fetch();

        if (!$profile) {
            Response::error('Driver profile not found', 404);
            return;
        }

        Response::success($profile);
    }

    public function updateProfile(Request $request): void
    {
        $user = $request->getUser();
        $db = Database::getConnection();

        $v = Validator::make($request->all(), [
            'ownership_model' => 'in:company_driver,owner_operator,fleet_driver'
        ]);

        if (!$v->validate()) {
            Response::error($v->getFirstError(), 422);
            return;
        }

        $stmt = $db->prepare("
            UPDATE driver_profiles 
            SET ownership_model = COALESCE(?, ownership_model),
                driving_license_no = COALESCE(?, driving_license_no),
                dl_expiry = COALESCE(?, dl_expiry),
                badge_number = COALESCE(?, badge_number),
                aadhaar_number = COALESCE(?, aadhaar_number),
                pan_number = COALESCE(?, pan_number),
                bank_account_no = COALESCE(?, bank_account_no),
                bank_ifsc = COALESCE(?, bank_ifsc),
                bank_beneficiary_name = COALESCE(?, bank_beneficiary_name),
                service_area_id = COALESCE(?, service_area_id)
            WHERE user_id = ?
        ");
        $stmt->execute([
            $request->get('ownership_model'),
            $request->get('driving_license_no'),
            $request->get('dl_expiry'),
            $request->get('badge_number'),
            $request->get('aadhaar_number'),
            $request->get('pan_number'),
            $request->get('bank_account_no'),
            $request->get('bank_ifsc'),
            $request->get('bank_beneficiary_name'),
            $request->get('service_area_id'),
            $user['id']
        ]);

        Response::success(null, 'Driver profile updated.');
    }

    public function toggleOnline(Request $request): void
    {
        $user = $request->getUser();
        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT dp.*, v.status AS vehicle_status 
            FROM driver_profiles dp 
            LEFT JOIN vehicles v ON v.id = dp.vehicle_id 
            WHERE dp.user_id = ?
        ");
        $stmt->execute([$user['id']]);
        $driver = $stmt->fetch();

        if (!$driver) {
            Response::error('Driver profile not found', 404);
            return;
        }

        $requestedState = (int)$request->get('is_online', $driver['is_online'] ? 0 : 1);

        if ($requestedState === 1) {
            // Check eligibility
            if ($driver['status'] !== 'verified_active') {
                Response::error("Cannot go online. Driver status is '{$driver['status']}'. Admin approval required.", 403);
                return;
            }

            if (empty($driver['vehicle_id']) || $driver['vehicle_status'] !== 'approved') {
                Response::error('Cannot go online. You do not have an approved E-Rickshaw assigned.', 403);
                return;
            }
        }

        $db->prepare("UPDATE driver_profiles SET is_online = ? WHERE id = ?")->execute([$requestedState, $driver['id']]);

        Response::success([
            'is_online' => (bool)$requestedState,
            'message' => $requestedState ? 'You are now ONLINE and ready to receive bookings!' : 'You are now OFFLINE.'
        ]);
    }

    public function updateLocation(Request $request): void
    {
        $user = $request->getUser();
        $v = Validator::make($request->all(), [
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric'
        ]);

        if (!$v->validate()) {
            Response::error($v->getFirstError(), 422);
            return;
        }

        $lat = (float)$request->get('latitude');
        $lng = (float)$request->get('longitude');
        $heading = (float)$request->get('heading', 0.0);
        $speed = (float)$request->get('speed_kmh', 0.0);
        $battery = $request->get('battery_percentage') !== null ? (int)$request->get('battery_percentage') : null;
        $bookingId = $request->get('booking_id');

        $db = Database::getConnection();

        // Get driver id
        $dStmt = $db->prepare("SELECT id FROM driver_profiles WHERE user_id = ?");
        $dStmt->execute([$user['id']]);
        $driver = $dStmt->fetch();

        if (!$driver) {
            Response::error('Driver profile not found', 404);
            return;
        }

        // Update driver live coords
        $upd = $db->prepare("
            UPDATE driver_profiles 
            SET current_lat = ?, current_lng = ?, heading = ?, last_location_updated_at = NOW() 
            WHERE id = ?
        ");
        $upd->execute([$lat, $lng, $heading, $driver['id']]);

        // Record breadcrumb
        $rec = $db->prepare("
            INSERT INTO driver_locations (driver_id, booking_id, latitude, longitude, heading, speed_kmh, battery_percentage)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        $rec->execute([
            $driver['id'],
            $bookingId ?: null,
            $lat,
            $lng,
            $heading,
            $speed,
            $battery
        ]);

        Response::success(['status' => 'location_updated', 'recorded_at' => date('c')]);
    }

    public function uploadDocument(Request $request): void
    {
        $user = $request->getUser();
        $docType = $request->get('document_type');
        $docNumber = $request->get('document_number');
        $expiryDate = $request->get('expiry_date');

        $allowedTypes = [
            'driving_license', 'aadhaar_card', 'pan_card', 'vehicle_rc',
            'insurance_policy', 'fitness_certificate', 'police_verification', 'profile_photo'
        ];

        if (!in_array($docType, $allowedTypes, true)) {
            Response::error("Invalid document type. Allowed: " . implode(', ', $allowedTypes), 422);
            return;
        }

        $file = $request->getFile('document_file');
        $filePath = '';

        if ($file && !empty($file['tmp_name']) && is_uploaded_file($file['tmp_name'])) {
            $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
            if (!in_array($ext, ['jpg', 'jpeg', 'png', 'pdf'], true)) {
                Response::error('Only JPG, PNG, and PDF files are permitted for documents.', 422);
                return;
            }

            $uploadDir = dirname(__DIR__, 2) . '/public/uploads/documents';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0777, true);
            }

            $fileName = 'doc_' . $user['id'] . '_' . $docType . '_' . time() . '.' . $ext;
            $target = $uploadDir . '/' . $fileName;

            if (move_uploaded_file($file['tmp_name'], $target)) {
                $filePath = '/uploads/documents/' . $fileName;
            } else {
                Response::error('Failed to save uploaded file.', 500);
                return;
            }
        } else {
            // If file_path is passed as URL or existing
            $filePath = (string)$request->get('file_path', '/uploads/documents/default_document.pdf');
        }

        $db = Database::getConnection();

        $dStmt = $db->prepare("SELECT id, vehicle_id FROM driver_profiles WHERE user_id = ?");
        $dStmt->execute([$user['id']]);
        $driver = $dStmt->fetch();

        if (!$driver) {
            Response::error('Driver profile not found', 404);
            return;
        }

        // Upsert document
        $chk = $db->prepare("SELECT id FROM driver_documents WHERE driver_id = ? AND document_type = ?");
        $chk->execute([$driver['id'], $docType]);
        $existing = $chk->fetch();

        if ($existing) {
            $upd = $db->prepare("
                UPDATE driver_documents 
                SET file_path = ?, document_number = ?, expiry_date = ?, verification_status = 'pending', rejection_notes = NULL, updated_at = NOW() 
                WHERE id = ?
            ");
            $upd->execute([$filePath, $docNumber, $expiryDate ?: null, $existing['id']]);
        } else {
            $ins = $db->prepare("
                INSERT INTO driver_documents (driver_id, vehicle_id, document_type, document_number, file_path, expiry_date, verification_status)
                VALUES (?, ?, ?, ?, ?, ?, 'pending')
            ");
            $ins->execute([
                $driver['id'],
                $driver['vehicle_id'],
                $docType,
                $docNumber,
                $filePath,
                $expiryDate ?: null
            ]);
        }

        Response::success([
            'document_type' => $docType,
            'file_path' => $filePath,
            'status' => 'pending'
        ], 'Document submitted for administrative verification.');
    }

    public function getDocuments(Request $request): void
    {
        $user = $request->getUser();
        $db = Database::getConnection();

        $dStmt = $db->prepare("SELECT id FROM driver_profiles WHERE user_id = ?");
        $dStmt->execute([$user['id']]);
        $driver = $dStmt->fetch();

        if (!$driver) {
            Response::error('Driver profile not found', 404);
            return;
        }

        $stmt = $db->prepare("SELECT * FROM driver_documents WHERE driver_id = ? ORDER BY created_at DESC");
        $stmt->execute([$driver['id']]);
        $docs = $stmt->fetchAll();

        Response::success($docs);
    }

    public function getEarnings(Request $request): void
    {
        $user = $request->getUser();
        $db = Database::getConnection();

        $dStmt = $db->prepare("SELECT id FROM driver_profiles WHERE user_id = ?");
        $dStmt->execute([$user['id']]);
        $driver = $dStmt->fetch();

        if (!$driver) {
            Response::error('Driver profile not found', 404);
            return;
        }

        $driverId = $driver['id'];

        // Today earnings
        $tStmt = $db->prepare("
            SELECT COUNT(*) AS today_trips, 
                   COALESCE(SUM(driver_earnings_amount), 0) AS today_earnings,
                   COALESCE(SUM(CASE WHEN payment_mode = 'cash' THEN final_fare ELSE 0 END), 0) AS today_cash
            FROM bookings 
            WHERE driver_id = ? AND booking_status = 'completed' AND DATE(completed_at) = CURDATE()
        ");
        $tStmt->execute([$driverId]);
        $today = $tStmt->fetch();

        // Monthly earnings
        $mStmt = $db->prepare("
            SELECT COUNT(*) AS month_trips, 
                   COALESCE(SUM(driver_earnings_amount), 0) AS month_earnings,
                   COALESCE(SUM(platform_commission_amount), 0) AS month_commission
            FROM bookings 
            WHERE driver_id = ? AND booking_status = 'completed' 
              AND MONTH(completed_at) = MONTH(CURDATE()) AND YEAR(completed_at) = YEAR(CURDATE())
        ");
        $mStmt->execute([$driverId]);
        $month = $mStmt->fetch();

        // Lifetime
        $wStmt = $db->prepare("SELECT * FROM driver_wallets WHERE driver_id = ?");
        $wStmt->execute([$driverId]);
        $wallet = $wStmt->fetch();

        Response::success([
            'today' => [
                'trips' => (int)$today['today_trips'],
                'earnings' => (float)$today['today_earnings'],
                'cash_collected' => (float)$today['today_cash']
            ],
            'month' => [
                'trips' => (int)$month['month_trips'],
                'earnings' => (float)$month['month_earnings'],
                'commission_paid' => (float)$month['month_commission']
            ],
            'wallet' => [
                'current_balance' => (float)($wallet['current_balance'] ?? 0.0),
                'total_earned' => (float)($wallet['total_earned'] ?? 0.0),
                'cash_held' => (float)($wallet['cash_collected_held'] ?? 0.0)
            ]
        ]);
    }

    public function getWallet(Request $request): void
    {
        $user = $request->getUser();
        $db = Database::getConnection();

        $dStmt = $db->prepare("SELECT id FROM driver_profiles WHERE user_id = ?");
        $dStmt->execute([$user['id']]);
        $driver = $dStmt->fetch();

        if (!$driver) {
            Response::error('Driver profile not found', 404);
            return;
        }

        $wStmt = $db->prepare("SELECT * FROM driver_wallets WHERE driver_id = ?");
        $wStmt->execute([$driver['id']]);
        $wallet = $wStmt->fetch();

        $lStmt = $db->prepare("
            SELECT * FROM ledger_entries 
            WHERE driver_id = ? 
            ORDER BY created_at DESC 
            LIMIT 50
        ");
        $lStmt->execute([$driver['id']]);
        $ledger = $lStmt->fetchAll();

        Response::success([
            'wallet' => $wallet,
            'recent_transactions' => $ledger
        ]);
    }

    public function requestPayout(Request $request): void
    {
        $user = $request->getUser();
        $amount = (float)$request->get('amount');
        $method = $request->get('payout_method', 'upi_vpa');
        $upiId = $request->get('upi_id');

        if ($amount < 100.0) {
            Response::error('Minimum withdrawal amount is ₹100.', 422);
            return;
        }

        $db = Database::getConnection();
        $db->beginTransaction();

        try {
            $dStmt = $db->prepare("SELECT id, bank_account_no, bank_ifsc FROM driver_profiles WHERE user_id = ?");
            $dStmt->execute([$user['id']]);
            $driver = $dStmt->fetch();

            if (!$driver) {
                $db->rollBack();
                Response::error('Driver profile not found', 404);
                return;
            }

            $wStmt = $db->prepare("SELECT current_balance FROM driver_wallets WHERE driver_id = ? FOR UPDATE");
            $wStmt->execute([$driver['id']]);
            $wallet = $wStmt->fetch();

            $balance = (float)($wallet['current_balance'] ?? 0.0);
            if ($balance < $amount) {
                $db->rollBack();
                Response::error("Insufficient balance. Your available wallet balance is ₹{$balance}", 422);
                return;
            }

            // Deduct from wallet balance and add to pending settlement
            $newBalance = $balance - $amount;
            $db->prepare("
                UPDATE driver_wallets 
                SET current_balance = ?, pending_settlement = pending_settlement + ? 
                WHERE driver_id = ?
            ")->execute([$newBalance, $amount, $driver['id']]);

            // Create payout record
            $ins = $db->prepare("
                INSERT INTO payouts (
                    driver_id, requested_amount, processing_fee, net_payout,
                    payout_method, upi_id, bank_account_no, bank_ifsc, status
                ) VALUES (?, ?, 0.00, ?, ?, ?, ?, ?, 'requested')
            ");
            $ins->execute([
                $driver['id'],
                $amount,
                $amount,
                $method,
                $upiId,
                $driver['bank_account_no'],
                $driver['bank_ifsc']
            ]);

            $payoutId = $db->lastInsertId();

            // Record in ledger
            $db->prepare("
                INSERT INTO ledger_entries (driver_id, entry_type, amount, balance_after, description, reference_id)
                VALUES (?, 'payout_credit', ?, ?, ?, ?)
            ")->execute([
                $driver['id'],
                -$amount,
                $newBalance,
                "Payout withdrawal request #{$payoutId}",
                (string)$payoutId
            ]);

            $db->commit();

            Response::success([
                'payout_id' => $payoutId,
                'requested_amount' => $amount,
                'new_balance' => $newBalance,
                'status' => 'requested'
            ], 'Payout request submitted successfully. It will be reviewed by admin.');
        } catch (\Exception $e) {
            if ($db->inTransaction()) {
                $db->rollBack();
            }
            Response::error($e->getMessage(), 500);
        }
    }
}
