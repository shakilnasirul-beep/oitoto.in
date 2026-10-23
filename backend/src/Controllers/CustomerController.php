<?php
declare(strict_types=1);

namespace OiToto\Controllers;

use OiToto\Core\Database;
use OiToto\Core\Request;
use OiToto\Core\Response;
use OiToto\Core\Validator;

class CustomerController
{
    public function getProfile(Request $request): void
    {
        $user = $request->getUser();
        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT u.id, u.phone, u.full_name, u.email, u.language, u.avatar_url,
                   cp.emergency_contact_name, cp.emergency_contact_phone,
                   cp.home_address, cp.home_lat, cp.home_lng,
                   cp.work_address, cp.work_lat, cp.work_lng,
                   cp.rating_avg, cp.total_rides
            FROM users u
            JOIN customer_profiles cp ON cp.user_id = u.id
            WHERE u.id = ?
        ");
        $stmt->execute([$user['id']]);
        $profile = $stmt->fetch();

        if (!$profile) {
            Response::error('Customer profile not found', 404);
            return;
        }

        Response::success($profile);
    }

    public function updateProfile(Request $request): void
    {
        $user = $request->getUser();
        $fullName = $request->get('full_name');
        $email = $request->get('email');
        $language = $request->get('language');

        $db = Database::getConnection();
        $updates = [];
        $params = [];

        if (!empty($fullName)) {
            $updates[] = "full_name = ?";
            $params[] = trim((string)$fullName);
        }
        if (!empty($email)) {
            $updates[] = "email = ?";
            $params[] = trim((string)$email);
        }
        if (!empty($language) && in_array($language, ['en', 'hi', 'bn'], true)) {
            $updates[] = "language = ?";
            $params[] = $language;
        }

        if (!empty($updates)) {
            $params[] = $user['id'];
            $sql = "UPDATE users SET " . implode(', ', $updates) . " WHERE id = ?";
            $db->prepare($sql)->execute($params);
        }

        Response::success(null, 'Profile updated successfully.');
    }

    public function updateEmergencyContact(Request $request): void
    {
        $user = $request->getUser();
        $v = Validator::make($request->all(), [
            'emergency_contact_name' => 'required',
            'emergency_contact_phone' => 'required|phone'
        ]);

        if (!$v->validate()) {
            Response::error($v->getFirstError(), 422);
            return;
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("
            UPDATE customer_profiles 
            SET emergency_contact_name = ?, emergency_contact_phone = ? 
            WHERE user_id = ?
        ");
        $stmt->execute([
            $request->get('emergency_contact_name'),
            $request->get('emergency_contact_phone'),
            $user['id']
        ]);

        Response::success(null, 'Emergency contact updated successfully.');
    }

    public function updateSavedPlaces(Request $request): void
    {
        $user = $request->getUser();
        $db = Database::getConnection();

        $stmt = $db->prepare("
            UPDATE customer_profiles 
            SET home_address = COALESCE(?, home_address),
                home_lat = COALESCE(?, home_lat),
                home_lng = COALESCE(?, home_lng),
                work_address = COALESCE(?, work_address),
                work_lat = COALESCE(?, work_lat),
                work_lng = COALESCE(?, work_lng)
            WHERE user_id = ?
        ");
        $stmt->execute([
            $request->get('home_address'),
            $request->get('home_lat'),
            $request->get('home_lng'),
            $request->get('work_address'),
            $request->get('work_lat'),
            $request->get('work_lng'),
            $user['id']
        ]);

        Response::success(null, 'Saved locations updated successfully.');
    }
}
