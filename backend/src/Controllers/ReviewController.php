<?php
declare(strict_types=1);

namespace OiToto\Controllers;

use OiToto\Core\Database;
use OiToto\Core\Request;
use OiToto\Core\Response;
use OiToto\Core\Validator;

class ReviewController
{
    public function store(Request $request): void
    {
        $user = $request->getUser();
        $v = Validator::make($request->all(), [
            'booking_id' => 'required|numeric',
            'rating' => 'required|numeric|min:1|max:5'
        ]);

        if (!$v->validate()) {
            Response::error($v->getFirstError(), 422);
            return;
        }

        $bookingId = (int)$request->get('booking_id');
        $rating = (int)$request->get('rating');
        $tags = (string)$request->get('tags', '');
        $comments = (string)$request->get('comments', '');

        $db = Database::getConnection();

        // Fetch booking
        $bStmt = $db->prepare("SELECT * FROM bookings WHERE id = ?");
        $bStmt->execute([$bookingId]);
        $booking = $bStmt->fetch();

        if (!$booking) {
            Response::error('Booking not found', 404);
            return;
        }

        // Determine recipient
        $toUserId = 0;
        if ((int)$booking['customer_id'] === (int)$user['id']) {
            // Customer rating driver
            $dStmt = $db->prepare("SELECT user_id FROM driver_profiles WHERE id = ?");
            $dStmt->execute([$booking['driver_id']]);
            $toUserId = (int)$dStmt->fetchColumn();
        } else {
            // Driver rating customer
            $toUserId = (int)$booking['customer_id'];
        }

        $ins = $db->prepare("
            INSERT INTO ratings (booking_id, from_user_id, to_user_id, rating, tags, comments)
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        $ins->execute([$bookingId, $user['id'], $toUserId, $rating, $tags, $comments]);

        // Recalculate average rating for recipient
        $avgStmt = $db->prepare("SELECT AVG(rating) FROM ratings WHERE to_user_id = ?");
        $avgStmt->execute([$toUserId]);
        $newAvg = round((float)$avgStmt->fetchColumn(), 2);

        // Update profile
        $db->prepare("UPDATE customer_profiles SET rating_avg = ? WHERE user_id = ?")->execute([$newAvg, $toUserId]);
        $db->prepare("UPDATE driver_profiles SET rating_avg = ? WHERE user_id = ?")->execute([$newAvg, $toUserId]);

        Response::success(['rating' => $rating, 'average' => $newAvg], 'Thank you for your feedback!');
    }

    public function driverReviews(Request $request): void
    {
        $driverId = (int)$request->param('id');
        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT r.*, u.full_name AS reviewer_name 
            FROM ratings r
            JOIN users u ON u.id = r.from_user_id
            WHERE r.to_user_id = (SELECT user_id FROM driver_profiles WHERE id = ?)
            ORDER BY r.created_at DESC
            LIMIT 30
        ");
        $stmt->execute([$driverId]);
        $reviews = $stmt->fetchAll();

        Response::success($reviews);
    }
}
