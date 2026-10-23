<?php
declare(strict_types=1);

namespace OiToto\Controllers;

use OiToto\Core\Database;
use OiToto\Core\Logger;
use OiToto\Core\Request;
use OiToto\Core\Response;
use OiToto\Core\Validator;
use PDO;

class AdminController
{
    /**
     * Dashboard Statistics
     */
    public function dashboardStats(Request $request): void
    {
        $db = Database::getConnection();

        // Counts
        $totalCustomers = (int)$db->query("SELECT COUNT(*) FROM users WHERE role = 'customer'")->fetchColumn();
        $totalDrivers = (int)$db->query("SELECT COUNT(*) FROM driver_profiles")->fetchColumn();
        $approvedDrivers = (int)$db->query("SELECT COUNT(*) FROM driver_profiles WHERE status = 'verified_active'")->fetchColumn();
        $pendingDrivers = (int)$db->query("SELECT COUNT(*) FROM driver_profiles WHERE status = 'pending_review'")->fetchColumn();
        $onlineDrivers = (int)$db->query("SELECT COUNT(*) FROM driver_profiles WHERE is_online = 1")->fetchColumn();

        $totalVehicles = (int)$db->query("SELECT COUNT(*) FROM vehicles")->fetchColumn();
        $companyVehicles = (int)$db->query("SELECT COUNT(*) FROM vehicles WHERE ownership_type = 'company_owned'")->fetchColumn();
        $independentVehicles = (int)$db->query("SELECT COUNT(*) FROM vehicles WHERE ownership_type = 'driver_owned'")->fetchColumn();

        $activeBookings = (int)$db->query("SELECT COUNT(*) FROM bookings WHERE booking_status IN ('requested', 'dispatched', 'accepted', 'arrived', 'in_progress')")->fetchColumn();
        $completedBookings = (int)$db->query("SELECT COUNT(*) FROM bookings WHERE booking_status = 'completed'")->fetchColumn();
        $cancelledBookings = (int)$db->query("SELECT COUNT(*) FROM bookings WHERE booking_status = 'cancelled'")->fetchColumn();

        // Financials
        $fin = $db->query("
            SELECT COALESCE(SUM(final_fare), 0) AS gross_booking_value,
                   COALESCE(SUM(platform_commission_amount), 0) AS total_commission,
                   COALESCE(SUM(driver_earnings_amount), 0) AS total_driver_earnings
            FROM bookings 
            WHERE booking_status = 'completed'
        ")->fetch();

        // Pending payouts
        $pendingPayouts = (float)$db->query("SELECT COALESCE(SUM(requested_amount), 0) FROM payouts WHERE status = 'requested'")->fetchColumn();

        Response::success([
            'customers' => [
                'total' => $totalCustomers
            ],
            'drivers' => [
                'total' => $totalDrivers,
                'approved' => $approvedDrivers,
                'pending' => $pendingDrivers,
                'online' => $onlineDrivers
            ],
            'vehicles' => [
                'total' => $totalVehicles,
                'company_owned' => $companyVehicles,
                'independent' => $independentVehicles
            ],
            'bookings' => [
                'active' => $activeBookings,
                'completed' => $completedBookings,
                'cancelled' => $cancelledBookings,
                'total' => $activeBookings + $completedBookings + $cancelledBookings
            ],
            'financials' => [
                'gross_booking_value' => (float)$fin['gross_booking_value'],
                'platform_commission' => (float)$fin['total_commission'],
                'driver_earnings' => (float)$fin['total_driver_earnings'],
                'pending_payouts' => $pendingPayouts,
                'currency' => '₹'
            ]
        ]);
    }

    /**
     * List all drivers with filtering
     */
    public function drivers(Request $request): void
    {
        $db = Database::getConnection();
        $status = $request->get('status');

        $sql = "
            SELECT dp.*, u.full_name, u.phone, u.email, u.status AS user_status,
                   v.vehicle_number, v.brand_make, v.ownership_type,
                   sa.name AS service_area_name,
                   dw.current_balance, dw.cash_collected_held
            FROM driver_profiles dp
            JOIN users u ON u.id = dp.user_id
            LEFT JOIN vehicles v ON v.id = dp.vehicle_id
            LEFT JOIN service_areas sa ON sa.id = dp.service_area_id
            LEFT JOIN driver_wallets dw ON dw.driver_id = dp.id
            WHERE 1=1
        ";
        $params = [];

        if (!empty($status)) {
            $sql .= " AND dp.status = ?";
            $params[] = $status;
        }

        $sql .= " ORDER BY dp.created_at DESC";

        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        $drivers = $stmt->fetchAll();

        Response::success($drivers);
    }

    /**
     * Verify/Approve or Reject driver profile
     */
    public function verifyDriver(Request $request): void
    {
        $admin = $request->getUser();
        $id = (int)$request->param('id');
        $status = $request->get('status'); // verified_active, rejected, suspended
        $reason = $request->get('rejection_reason');

        if (!in_array($status, ['verified_active', 'rejected', 'suspended'], true)) {
            Response::error('Invalid driver status. Allowed: verified_active, rejected, suspended', 422);
            return;
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("
            UPDATE driver_profiles 
            SET status = ?, rejection_reason = ?, updated_at = NOW() 
            WHERE id = ?
        ");
        $stmt->execute([$status, $reason, $id]);

        // If approved, update user status to active
        if ($status === 'verified_active') {
            $db->prepare("UPDATE users SET status = 'active' WHERE id = (SELECT user_id FROM driver_profiles WHERE id = ?)")->execute([$id]);
        }

        Logger::audit((int)$admin['id'], 'verify_driver', 'driver_profiles', $id, null, ['status' => $status]);

        Response::success(['id' => $id, 'status' => $status], "Driver application status updated to '{$status}'.");
    }

    /**
     * Verify document
     */
    public function verifyDocument(Request $request): void
    {
        $admin = $request->getUser();
        $id = (int)$request->param('id');
        $status = $request->get('status'); // approved, rejected
        $notes = $request->get('rejection_notes');

        if (!in_array($status, ['approved', 'rejected'], true)) {
            Response::error('Invalid verification status.', 422);
            return;
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("
            UPDATE driver_documents 
            SET verification_status = ?, verified_by = ?, verified_at = NOW(), rejection_notes = ? 
            WHERE id = ?
        ");
        $stmt->execute([$status, $admin['id'], $notes, $id]);

        Response::success(['id' => $id, 'status' => $status], "Document verification updated to {$status}.");
    }

    /**
     * Verify / Update Vehicle status
     */
    public function verifyVehicle(Request $request): void
    {
        $admin = $request->getUser();
        $id = (int)$request->param('id');
        $status = $request->get('status'); // approved, rejected, maintenance

        $db = Database::getConnection();
        $db->prepare("UPDATE vehicles SET status = ?, updated_at = NOW() WHERE id = ?")->execute([$status, $id]);

        Logger::audit((int)$admin['id'], 'verify_vehicle', 'vehicles', $id, null, ['status' => $status]);

        Response::success(['id' => $id, 'status' => $status], "Vehicle status updated to {$status}.");
    }

    /**
     * Bookings list for admin
     */
    public function bookings(Request $request): void
    {
        $db = Database::getConnection();
        $status = $request->get('status');
        $limit = max(1, min(100, (int)$request->get('limit', 50)));

        $sql = "
            SELECT b.*,
                   u_c.full_name AS customer_name, u_c.phone AS customer_phone,
                   u_d.full_name AS driver_name, u_d.phone AS driver_phone,
                   v.vehicle_number, v.ownership_type
            FROM bookings b
            JOIN users u_c ON u_c.id = b.customer_id
            LEFT JOIN driver_profiles dp ON dp.id = b.driver_id
            LEFT JOIN users u_d ON u_d.id = dp.user_id
            LEFT JOIN vehicles v ON v.id = b.vehicle_id
            WHERE 1=1
        ";
        $params = [];

        if (!empty($status)) {
            $sql .= " AND b.booking_status = ?";
            $params[] = $status;
        }

        $sql .= " ORDER BY b.id DESC LIMIT ?";
        $stmt = $db->prepare($sql);

        foreach ($params as $idx => $p) {
            $stmt->bindValue($idx + 1, $p);
        }
        $stmt->bindValue(count($params) + 1, $limit, PDO::PARAM_INT);
        $stmt->execute();

        $bookings = $stmt->fetchAll();
        Response::success($bookings);
    }

    /**
     * Settlement & Payouts management
     */
    public function settlements(Request $request): void
    {
        $db = Database::getConnection();
        $stmt = $db->query("
            SELECT p.*, u.full_name AS driver_name, u.phone AS driver_phone,
                   dw.current_balance AS driver_wallet_balance
            FROM payouts p
            JOIN driver_profiles dp ON dp.id = p.driver_id
            JOIN users u ON u.id = dp.user_id
            JOIN driver_wallets dw ON dw.driver_id = p.driver_id
            ORDER BY p.id DESC
        ");
        $payouts = $stmt->fetchAll();

        Response::success($payouts);
    }

    /**
     * Process Payout (Approve / Complete / Reject)
     */
    public function processPayout(Request $request): void
    {
        $admin = $request->getUser();
        $id = (int)$request->param('id');
        $status = $request->get('status'); // approved, completed, rejected
        $txnRef = $request->get('transaction_ref');
        $remarks = $request->get('remarks');

        $db = Database::getConnection();
        $db->beginTransaction();

        try {
            $pStmt = $db->prepare("SELECT * FROM payouts WHERE id = ? FOR UPDATE");
            $pStmt->execute([$id]);
            $payout = $pStmt->fetch();

            if (!$payout) {
                $db->rollBack();
                Response::error('Payout request not found', 404);
                return;
            }

            if ($payout['status'] === 'completed') {
                $db->rollBack();
                Response::error('Payout is already completed.', 400);
                return;
            }

            if ($status === 'rejected') {
                // Refund pending settlement back to current balance
                $db->prepare("
                    UPDATE driver_wallets 
                    SET current_balance = current_balance + ?, pending_settlement = pending_settlement - ? 
                    WHERE driver_id = ?
                ")->execute([$payout['requested_amount'], $payout['requested_amount'], $payout['driver_id']]);
            } elseif ($status === 'completed') {
                // Deduct from pending settlement and add to total withdrawn
                $db->prepare("
                    UPDATE driver_wallets 
                    SET pending_settlement = pending_settlement - ?, total_withdrawn = total_withdrawn + ? 
                    WHERE driver_id = ?
                ")->execute([$payout['requested_amount'], $payout['requested_amount'], $payout['driver_id']]);
            }

            $db->prepare("
                UPDATE payouts 
                SET status = ?, transaction_ref = COALESCE(?, transaction_ref), remarks = ?, reviewed_by = ?, updated_at = NOW() 
                WHERE id = ?
            ")->execute([$status, $txnRef, $remarks, $admin['id'], $id]);

            $db->commit();

            Response::success(['id' => $id, 'status' => $status], "Payout marked as {$status}.");
        } catch (\Exception $e) {
            $db->rollBack();
            Response::error($e->getMessage(), 500);
        }
    }

    /**
     * Complaints & Dispute tickets
     */
    public function complaints(Request $request): void
    {
        $db = Database::getConnection();
        $stmt = $db->query("
            SELECT c.*, 
                   u1.full_name AS reported_by_name, u1.phone AS reported_by_phone,
                   u2.full_name AS against_name,
                   b.booking_code
            FROM complaints c
            JOIN users u1 ON u1.id = c.reported_by_user_id
            LEFT JOIN users u2 ON u2.id = c.against_user_id
            LEFT JOIN bookings b ON b.id = c.booking_id
            ORDER BY c.id DESC
        ");
        $complaints = $stmt->fetchAll();

        Response::success($complaints);
    }

    /**
     * Resolve Complaint
     */
    public function resolveComplaint(Request $request): void
    {
        $admin = $request->getUser();
        $id = (int)$request->param('id');
        $status = $request->get('status', 'resolved');
        $notes = $request->get('resolution_notes', 'Resolved by admin.');

        $db = Database::getConnection();
        $db->prepare("
            UPDATE complaints 
            SET status = ?, resolution_notes = ?, resolved_by = ?, updated_at = NOW() 
            WHERE id = ?
        ")->execute([$status, $notes, $admin['id'], $id]);

        Response::success(null, 'Complaint resolved successfully.');
    }

    /**
     * Audit Logs
     */
    public function auditLogs(Request $request): void
    {
        $db = Database::getConnection();
        $stmt = $db->query("
            SELECT al.*, u.full_name AS admin_name, u.phone AS admin_phone 
            FROM audit_logs al
            LEFT JOIN users u ON u.id = al.admin_id
            ORDER BY al.id DESC
            LIMIT 100
        ");
        $logs = $stmt->fetchAll();

        Response::success($logs);
    }

    /**
     * Customers list with ride summary and profile details
     */
    public function customers(Request $request): void
    {
        $db = Database::getConnection();
        $status = $request->get('status');
        $search = $request->get('search');

        $sql = "
            SELECT u.id, u.phone, u.full_name, u.email, u.status, u.language, u.created_at,
                   cp.emergency_contact_name, cp.emergency_contact_phone,
                   cp.home_address, cp.work_address,
                   COALESCE(cp.rating_avg, 5.0) AS rating_avg,
                   COALESCE(cp.total_rides, COUNT(b.id)) AS total_rides,
                   COALESCE(SUM(CASE WHEN b.booking_status = 'completed' THEN b.final_fare ELSE 0 END), 0) AS total_spend
            FROM users u
            LEFT JOIN customer_profiles cp ON cp.user_id = u.id
            LEFT JOIN bookings b ON b.customer_id = u.id
            WHERE u.role = 'customer'
        ";
        $params = [];

        if (!empty($status)) {
            $sql .= " AND u.status = ?";
            $params[] = $status;
        }

        if (!empty($search)) {
            $sql .= " AND (u.full_name LIKE ? OR u.phone LIKE ? OR u.email LIKE ?)";
            $params[] = "%{$search}%";
            $params[] = "%{$search}%";
            $params[] = "%{$search}%";
        }

        $sql .= " GROUP BY u.id, cp.id ORDER BY u.id DESC";

        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        $customers = $stmt->fetchAll();

        Response::success($customers);
    }

    /**
     * Customer full details with all ride history
     */
    public function customerDetails(Request $request): void
    {
        $id = (int)$request->param('id');
        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT u.id, u.phone, u.full_name, u.email, u.status, u.language, u.created_at,
                   cp.emergency_contact_name, cp.emergency_contact_phone,
                   cp.home_address, cp.home_lat, cp.home_lng,
                   cp.work_address, cp.work_lat, cp.work_lng,
                   COALESCE(cp.rating_avg, 5.0) AS rating_avg,
                   COALESCE(cp.total_rides, 0) AS total_rides
            FROM users u
            LEFT JOIN customer_profiles cp ON cp.user_id = u.id
            WHERE u.id = ? AND u.role = 'customer'
        ");
        $stmt->execute([$id]);
        $customer = $stmt->fetch();

        if (!$customer) {
            Response::error('Customer not found', 404);
            return;
        }

        // Fetch ride history
        $hStmt = $db->prepare("
            SELECT b.*,
                   u_d.full_name AS driver_name, u_d.phone AS driver_phone,
                   v.vehicle_number, v.brand_make,
                   r.rating AS customer_rating, r.comments AS customer_review
            FROM bookings b
            LEFT JOIN driver_profiles dp ON dp.id = b.driver_id
            LEFT JOIN users u_d ON u_d.id = dp.user_id
            LEFT JOIN vehicles v ON v.id = b.vehicle_id
            LEFT JOIN ratings r ON r.booking_id = b.id AND r.from_user_id = b.customer_id
            WHERE b.customer_id = ?
            ORDER BY b.id DESC
        ");
        $hStmt->execute([$id]);
        $rides = $hStmt->fetchAll();

        $customer['ride_history'] = $rides;
        $customer['total_spend'] = array_reduce($rides, function($acc, $r) {
            return $acc + ($r['booking_status'] === 'completed' ? (float)$r['final_fare'] : 0);
        }, 0);

        Response::success($customer);
    }
}
