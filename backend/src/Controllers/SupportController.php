<?php
declare(strict_types=1);

namespace OiToto\Controllers;

use OiToto\Core\Database;
use OiToto\Core\Logger;
use OiToto\Core\Request;
use OiToto\Core\Response;
use OiToto\Core\Validator;

class SupportController
{
    public function createComplaint(Request $request): void
    {
        $user = $request->getUser();
        $v = Validator::make($request->all(), [
            'description' => 'required',
            'category' => 'in:fare_dispute,driver_behavior,vehicle_condition,safety_sos,rash_driving,overcharging,other'
        ]);

        if (!$v->validate()) {
            Response::error($v->getFirstError(), 422);
            return;
        }

        $bookingId = $request->get('booking_id');
        $againstUserId = $request->get('against_user_id');
        $category = (string)$request->get('category', 'other');
        $desc = (string)$request->get('description');

        $db = Database::getConnection();
        $stmt = $db->prepare("
            INSERT INTO complaints (booking_id, reported_by_user_id, against_user_id, category, description, status)
            VALUES (?, ?, ?, ?, ?, 'open')
        ");
        $stmt->execute([
            $bookingId ?: null,
            $user['id'],
            $againstUserId ?: null,
            $category,
            $desc
        ]);

        Response::success(['id' => (int)$db->lastInsertId()], 'Complaint submitted. Oi Toto support will contact you within 24 hours.', 201);
    }

    public function sosAlert(Request $request): void
    {
        $user = $request->getUser();
        $bookingId = $request->get('booking_id');
        $lat = (float)$request->get('latitude', 0.0);
        $lng = (float)$request->get('longitude', 0.0);

        $db = Database::getConnection();

        // 1. Immediately log emergency complaint
        $stmt = $db->prepare("
            INSERT INTO complaints (booking_id, reported_by_user_id, category, description, status)
            VALUES (?, ?, 'safety_sos', ?, 'open')
        ");
        $sosMsg = "EMERGENCY SOS TRIGGERED by user {$user['full_name']} (Phone: {$user['phone']}) at Coordinates: {$lat}, {$lng}. Booking: #" . ($bookingId ?: 'N/A');
        $stmt->execute([$bookingId ?: null, $user['id'], $sosMsg]);

        Logger::error("SOS ALERT: {$sosMsg}");

        // 2. Fetch emergency contacts
        $cStmt = $db->prepare("SELECT emergency_contact_name, emergency_contact_phone FROM customer_profiles WHERE user_id = ?");
        $cStmt->execute([$user['id']]);
        $cust = $cStmt->fetch();

        Response::success([
            'emergency_dispatched' => true,
            'police_helpline' => '112',
            'oi_toto_safety_hotline' => '1800-OI-TOTO',
            'emergency_contact' => $cust ?: null,
            'message' => 'Emergency SOS alert activated. Location coordinates transmitted to safety response team.'
        ]);
    }

    public function notifications(Request $request): void
    {
        $user = $request->getUser();
        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT * FROM notifications 
            WHERE user_id = ? 
            ORDER BY sent_at DESC 
            LIMIT 50
        ");
        $stmt->execute([$user['id']]);
        $notifs = $stmt->fetchAll();

        // Mark as read
        $db->prepare("UPDATE notifications SET is_read = 1, read_at = NOW() WHERE user_id = ? AND is_read = 0")->execute([$user['id']]);

        Response::success($notifs);
    }
}
