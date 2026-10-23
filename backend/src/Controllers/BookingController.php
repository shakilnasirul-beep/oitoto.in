<?php
declare(strict_types=1);

namespace OiToto\Controllers;

use OiToto\Core\Database;
use OiToto\Core\Logger;
use OiToto\Core\Request;
use OiToto\Core\Response;
use OiToto\Core\Validator;
use OiToto\Services\FareCalculatorService;
use OiToto\Services\LocationService;
use OiToto\Services\MatchingService;
use OiToto\Services\NotificationService;
use PDO;
use Throwable;

class BookingController
{
    /**
     * Display live nearby E-Rickshaws on the map
     */
    public function nearbyTotos(Request $request): void
    {
        $lat = (float)$request->get('pickup_lat', 22.5726);
        $lng = (float)$request->get('pickup_lng', 88.3639);
        $radius = (float)$request->get('radius_km', 4.0);

        $nearby = MatchingService::findNearbyDrivers($lat, $lng, $radius);
        Response::success($nearby);
    }

    /**
     * Customer books an E-Rickshaw (Immediate or Scheduled)
     */
    public function estimateAndCreate(Request $request): void
    {
        $user = $request->getUser();
        $v = Validator::make($request->all(), [
            'pickup_address' => 'required',
            'pickup_lat' => 'required|numeric',
            'pickup_lng' => 'required|numeric',
            'drop_address' => 'required',
            'drop_lat' => 'required|numeric',
            'drop_lng' => 'required|numeric',
            'payment_mode' => 'in:cash,upi,wallet'
        ]);

        if (!$v->validate()) {
            Response::error($v->getFirstError(), 422);
            return;
        }

        $pLat = (float)$request->get('pickup_lat');
        $pLng = (float)$request->get('pickup_lng');
        $dLat = (float)$request->get('drop_lat');
        $dLng = (float)$request->get('drop_lng');
        $pAddr = (string)$request->get('pickup_address');
        $dAddr = (string)$request->get('drop_address');
        $payMode = (string)$request->get('payment_mode', 'cash');
        $promoCode = $request->get('promo_code');
        $scheduledAt = $request->get('scheduled_at');

        $db = Database::getConnection();

        // Check if customer already has an active ongoing booking
        $chkActive = $db->prepare("
            SELECT id, booking_code, booking_status 
            FROM bookings 
            WHERE customer_id = ? AND booking_status IN ('requested', 'dispatched', 'accepted', 'arrived', 'in_progress')
            LIMIT 1
        ");
        $chkActive->execute([$user['id']]);
        $existing = $chkActive->fetch();

        if ($existing) {
            Response::error("You already have an active ride ({$existing['booking_code']}).", 409, [
                'active_booking_id' => $existing['id'],
                'status' => $existing['booking_status']
            ]);
            return;
        }

        // Distance & duration
        $distanceKm = LocationService::calculateDistance($pLat, $pLng, $dLat, $dLng);
        $durationMins = LocationService::estimateDurationMinutes($distanceKm, 18.0);
        $serviceArea = LocationService::findServiceArea($pLat, $pLng);
        $areaId = $serviceArea['id'] ?? 1;

        // Fare Calculation
        $fare = FareCalculatorService::calculate($distanceKm, 0, (int)$areaId, $promoCode ? (string)$promoCode : null);

        // Generate 4-digit ride start OTP
        $rideOtp = (string)random_int(1000, 9999);
        $bookingCode = 'OT-' . date('Ymd') . '-' . strtoupper(bin2hex(random_bytes(2)));

        $db->beginTransaction();
        try {
            $stmt = $db->prepare("
                INSERT INTO bookings (
                    booking_code, customer_id, service_area_id,
                    pickup_address, pickup_lat, pickup_lng,
                    drop_address, drop_lat, drop_lng,
                    estimated_distance_km, estimated_duration_mins, estimated_fare,
                    base_fare_charged, distance_fare_charged, surge_fare_charged,
                    discount_amount, platform_commission_amount, driver_earnings_amount,
                    payment_mode, payment_status, booking_status, start_otp,
                    scheduled_at, requested_at
                ) VALUES (
                    ?, ?, ?,
                    ?, ?, ?,
                    ?, ?, ?,
                    ?, ?, ?,
                    ?, ?, ?,
                    ?, ?, ?,
                    ?, 'pending', 'requested', ?,
                    ?, NOW()
                )
            ");
            $stmt->execute([
                $bookingCode,
                $user['id'],
                $areaId,
                $pAddr,
                $pLat,
                $pLng,
                $dAddr,
                $dLat,
                $dLng,
                $distanceKm,
                $durationMins,
                $fare['final_fare'],
                $fare['base_fare_charged'],
                $fare['distance_fare_charged'],
                $fare['surge_fare_charged'],
                $fare['discount_amount'],
                $fare['platform_commission_amount'],
                $fare['driver_earnings_amount'],
                $payMode,
                $rideOtp,
                $scheduledAt ?: null
            ]);

            $bookingId = (int)$db->lastInsertId();

            // Record booking event
            $db->prepare("
                INSERT INTO booking_events (booking_id, event_name, actor_id, actor_type, payload)
                VALUES (?, 'booking_created', ?, 'customer', ?)
            ")->execute([
                $bookingId,
                $user['id'],
                json_encode(['fare' => $fare['final_fare'], 'distance_km' => $distanceKm])
            ]);

            $db->commit();

            // Broadcast to nearby drivers
            $nearbyDrivers = MatchingService::findNearbyDrivers($pLat, $pLng, 4.0, 8);
            foreach ($nearbyDrivers as $drv) {
                NotificationService::send(
                    (int)$drv['user_id'],
                    'New E-Rickshaw Ride Request!',
                    "Pickup: {$pAddr} (Est: ₹{$fare['final_fare']})",
                    'booking_alert',
                    [
                        'booking_id' => $bookingId,
                        'booking_code' => $bookingCode,
                        'pickup_lat' => $pLat,
                        'pickup_lng' => $pLng,
                        'pickup_address' => $pAddr,
                        'fare' => $fare['final_fare']
                    ]
                );
            }

            Response::success([
                'booking_id' => $bookingId,
                'booking_code' => $bookingCode,
                'start_otp' => $rideOtp,
                'estimated_fare' => $fare['final_fare'],
                'estimated_distance_km' => $distanceKm,
                'estimated_duration_mins' => $durationMins,
                'status' => 'requested',
                'nearby_drivers_notified' => count($nearbyDrivers)
            ], 'E-Rickshaw requested! Searching for nearby available drivers...');
        } catch (\Exception $e) {
            $db->rollBack();
            Response::error($e->getMessage(), 500);
        }
    }

    /**
     * Poll active trip for rider or driver
     */
    public function activeBooking(Request $request): void
    {
        $user = $request->getUser();
        $db = Database::getConnection();

        $role = $user['role'];
        $whereClause = ($role === 'driver')
            ? "b.driver_id = (SELECT id FROM driver_profiles WHERE user_id = ?) AND b.booking_status IN ('accepted', 'arrived', 'in_progress')"
            : "b.customer_id = ? AND b.booking_status IN ('requested', 'dispatched', 'accepted', 'arrived', 'in_progress')";

        $stmt = $db->prepare("
            SELECT b.*,
                   u_c.full_name AS customer_name, u_c.phone AS customer_phone,
                   u_d.full_name AS driver_name, u_d.phone AS driver_phone, u_d.avatar_url AS driver_avatar,
                   dp.rating_avg AS driver_rating, dp.current_lat AS driver_lat, dp.current_lng AS driver_lng, dp.heading AS driver_heading,
                   v.vehicle_number, v.brand_make, v.color AS vehicle_color, v.ownership_type
            FROM bookings b
            JOIN users u_c ON u_c.id = b.customer_id
            LEFT JOIN driver_profiles dp ON dp.id = b.driver_id
            LEFT JOIN users u_d ON u_d.id = dp.user_id
            LEFT JOIN vehicles v ON v.id = b.vehicle_id
            WHERE {$whereClause}
            ORDER BY b.id DESC
            LIMIT 1
        ");
        $stmt->execute([$user['id']]);
        $booking = $stmt->fetch();

        Response::success($booking ?: null);
    }

    /**
     * Detailed booking view
     */
    public function show(Request $request): void
    {
        $id = (int)$request->param('id');
        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT b.*,
                   u_c.full_name AS customer_name, u_c.phone AS customer_phone,
                   u_d.full_name AS driver_name, u_d.phone AS driver_phone,
                   dp.rating_avg AS driver_rating, dp.current_lat AS driver_lat, dp.current_lng AS driver_lng,
                   v.vehicle_number, v.brand_make, v.color AS vehicle_color, v.ownership_type,
                   p.gateway_payment_id, p.transaction_reference, p.payment_gateway
            FROM bookings b
            JOIN users u_c ON u_c.id = b.customer_id
            LEFT JOIN driver_profiles dp ON dp.id = b.driver_id
            LEFT JOIN users u_d ON u_d.id = dp.user_id
            LEFT JOIN vehicles v ON v.id = b.vehicle_id
            LEFT JOIN payments p ON p.booking_id = b.id
            WHERE b.id = ?
        ");
        $stmt->execute([$id]);
        $booking = $stmt->fetch();

        if (!$booking) {
            Response::error('Booking not found', 404);
            return;
        }

        Response::success($booking);
    }

    /**
     * Booking History
     */
    public function history(Request $request): void
    {
        $user = $request->getUser();
        $db = Database::getConnection();
        $page = max(1, (int)$request->get('page', 1));
        $limit = 20;
        $offset = ($page - 1) * $limit;

        if ($user['role'] === 'driver') {
            $stmt = $db->prepare("
                SELECT b.*, u.full_name AS customer_name, u.phone AS customer_phone
                FROM bookings b
                JOIN users u ON u.id = b.customer_id
                WHERE b.driver_id = (SELECT id FROM driver_profiles WHERE user_id = ?)
                ORDER BY b.id DESC
                LIMIT ? OFFSET ?
            ");
            $stmt->bindValue(1, $user['id'], PDO::PARAM_INT);
            $stmt->bindValue(2, $limit, PDO::PARAM_INT);
            $stmt->bindValue(3, $offset, PDO::PARAM_INT);
            $stmt->execute();
        } else {
            $stmt = $db->prepare("
                SELECT b.*, u.full_name AS driver_name, v.vehicle_number, v.brand_make
                FROM bookings b
                LEFT JOIN driver_profiles dp ON dp.id = b.driver_id
                LEFT JOIN users u ON u.id = dp.user_id
                LEFT JOIN vehicles v ON v.id = b.vehicle_id
                WHERE b.customer_id = ?
                ORDER BY b.id DESC
                LIMIT ? OFFSET ?
            ");
            $stmt->bindValue(1, $user['id'], PDO::PARAM_INT);
            $stmt->bindValue(2, $limit, PDO::PARAM_INT);
            $stmt->bindValue(3, $offset, PDO::PARAM_INT);
            $stmt->execute();
        }

        $rides = $stmt->fetchAll();
        Response::success($rides);
    }

    /**
     * Driver atomic acceptance of incoming ride
     */
    public function accept(Request $request): void
    {
        $user = $request->getUser();
        $bookingId = (int)$request->param('id');
        $db = Database::getConnection();

        $dStmt = $db->prepare("SELECT id FROM driver_profiles WHERE user_id = ?");
        $dStmt->execute([$user['id']]);
        $driver = $dStmt->fetch();

        if (!$driver) {
            Response::error('Driver profile not found.', 404);
            return;
        }

        try {
            $res = MatchingService::atomicAcceptBooking($bookingId, (int)$driver['id']);
            Response::success($res, $res['message']);
        } catch (Throwable $e) {
            Response::error($e->getMessage(), 400);
        }
    }

    /**
     * Driver marks arrived at pickup location
     */
    public function arrived(Request $request): void
    {
        $user = $request->getUser();
        $bookingId = (int)$request->param('id');
        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT b.*, dp.id AS driver_profile_id 
            FROM bookings b 
            JOIN driver_profiles dp ON dp.id = b.driver_id 
            WHERE b.id = ? AND dp.user_id = ?
        ");
        $stmt->execute([$bookingId, $user['id']]);
        $booking = $stmt->fetch();

        if (!$booking) {
            Response::error('Booking not found or not assigned to you.', 404);
            return;
        }

        if ($booking['booking_status'] !== 'accepted') {
            Response::error("Cannot mark arrival. Trip is currently in '{$booking['booking_status']}' status.", 400);
            return;
        }

        $db->prepare("UPDATE bookings SET booking_status = 'arrived', arrived_at = NOW() WHERE id = ?")->execute([$bookingId]);

        // Event
        $db->prepare("
            INSERT INTO booking_events (booking_id, event_name, actor_id, actor_type)
            VALUES (?, 'driver_arrived', ?, 'driver')
        ")->execute([$bookingId, $user['id']]);

        // Notify customer
        NotificationService::send(
            (int)$booking['customer_id'],
            'Your Oi Toto has Arrived!',
            "Your E-Rickshaw driver is waiting at the pickup point. Share OTP {$booking['start_otp']} to start.",
            'trip_status',
            ['booking_id' => $bookingId, 'status' => 'arrived', 'start_otp' => $booking['start_otp']]
        );

        Response::success(['status' => 'arrived'], 'Arrival marked! Customer has been notified.');
    }

    /**
     * Driver starts trip by verifying 4-digit Ride OTP provided by customer
     */
    public function startTrip(Request $request): void
    {
        $user = $request->getUser();
        $bookingId = (int)$request->param('id');
        $enteredOtp = trim((string)$request->get('otp'));

        $db = Database::getConnection();
        $stmt = $db->prepare("
            SELECT b.*, dp.id AS driver_profile_id 
            FROM bookings b 
            JOIN driver_profiles dp ON dp.id = b.driver_id 
            WHERE b.id = ? AND dp.user_id = ?
        ");
        $stmt->execute([$bookingId, $user['id']]);
        $booking = $stmt->fetch();

        if (!$booking) {
            Response::error('Booking not found or not assigned to you.', 404);
            return;
        }

        if ($booking['booking_status'] !== 'arrived' && $booking['booking_status'] !== 'accepted') {
            Response::error("Cannot start trip from status '{$booking['booking_status']}'.", 400);
            return;
        }

        if ($booking['start_otp'] !== $enteredOtp) {
            Response::error('Incorrect Ride OTP! Please ask the customer for the 4-digit OTP shown on their app.', 400);
            return;
        }

        // OTP Verified! Trip starts
        $db->prepare("UPDATE bookings SET booking_status = 'in_progress', started_at = NOW() WHERE id = ?")->execute([$bookingId]);

        // Event
        $db->prepare("
            INSERT INTO booking_events (booking_id, event_name, actor_id, actor_type)
            VALUES (?, 'trip_started', ?, 'driver')
        ")->execute([$bookingId, $user['id']]);

        // Notify customer
        NotificationService::send(
            (int)$booking['customer_id'],
            'Trip Started — Cholo!',
            'Your Oi Toto E-Rickshaw ride is now in progress. Safe journey!',
            'trip_status',
            ['booking_id' => $bookingId, 'status' => 'in_progress']
        );

        Response::success(['status' => 'in_progress'], 'Ride OTP verified! Trip started successfully.');
    }

    /**
     * Driver completes trip, generates final fare, commission, and digital receipt
     */
    public function completeTrip(Request $request): void
    {
        $user = $request->getUser();
        $bookingId = (int)$request->param('id');
        $actualDistance = (float)$request->get('actual_distance_km');
        $waitingMins = (int)$request->get('waiting_duration_mins', 0);

        $db = Database::getConnection();
        $stmt = $db->prepare("
            SELECT b.*, dp.id AS driver_profile_id 
            FROM bookings b 
            JOIN driver_profiles dp ON dp.id = b.driver_id 
            WHERE b.id = ? AND dp.user_id = ?
        ");
        $stmt->execute([$bookingId, $user['id']]);
        $booking = $stmt->fetch();

        if (!$booking) {
            Response::error('Booking not found or not assigned to you.', 404);
            return;
        }

        if ($booking['booking_status'] !== 'in_progress') {
            Response::error("Trip cannot be completed from status '{$booking['booking_status']}'.", 400);
            return;
        }

        $distanceToCharge = ($actualDistance > 0.1) ? $actualDistance : (float)$booking['estimated_distance_km'];
        $startTime = $booking['started_at'] ? strtotime($booking['started_at']) : time();
        $durationMins = (int)ceil((time() - $startTime) / 60);

        // Recalculate final fare
        $fare = FareCalculatorService::calculate(
            $distanceToCharge,
            $waitingMins,
            (int)$booking['service_area_id']
        );

        $db->beginTransaction();
        try {
            $upd = $db->prepare("
                UPDATE bookings 
                SET booking_status = 'completed',
                    completed_at = NOW(),
                    actual_distance_km = ?,
                    actual_duration_mins = ?,
                    waiting_duration_mins = ?,
                    final_fare = ?,
                    base_fare_charged = ?,
                    distance_fare_charged = ?,
                    waiting_fare_charged = ?,
                    surge_fare_charged = ?,
                    platform_commission_amount = ?,
                    driver_earnings_amount = ?
                WHERE id = ?
            ");
            $upd->execute([
                $distanceToCharge,
                $durationMins,
                $waitingMins,
                $fare['final_fare'],
                $fare['base_fare_charged'],
                $fare['distance_fare_charged'],
                $fare['waiting_fare_charged'],
                $fare['surge_fare_charged'],
                $fare['platform_commission_amount'],
                $fare['driver_earnings_amount'],
                $bookingId
            ]);

            // Release driver from busy state and increment trips
            $db->prepare("
                UPDATE driver_profiles 
                SET is_busy = 0, total_trips = total_trips + 1 
                WHERE id = ?
            ")->execute([$booking['driver_profile_id']]);

            // Increment customer ride count
            $db->prepare("UPDATE customer_profiles SET total_rides = total_rides + 1 WHERE user_id = ?")->execute([$booking['customer_id']]);

            // Event
            $db->prepare("
                INSERT INTO booking_events (booking_id, event_name, actor_id, actor_type, payload)
                VALUES (?, 'trip_completed', ?, 'driver', ?)
            ")->execute([
                $bookingId,
                $user['id'],
                json_encode(['final_fare' => $fare['final_fare'], 'distance_km' => $distanceToCharge])
            ]);

            $db->commit();

            // Notify customer
            NotificationService::send(
                (int)$booking['customer_id'],
                'Trip Completed — Digital Receipt Ready',
                "Your ride has ended. Total fare: ₹{$fare['final_fare']}. Please pay your driver.",
                'payment_receipt',
                ['booking_id' => $bookingId, 'final_fare' => $fare['final_fare'], 'payment_mode' => $booking['payment_mode']]
            );

            Response::success([
                'booking_id' => $bookingId,
                'status' => 'completed',
                'final_fare' => $fare['final_fare'],
                'base_fare' => $fare['base_fare_charged'],
                'distance_fare' => $fare['distance_fare_charged'],
                'waiting_fare' => $fare['waiting_fare_charged'],
                'driver_earnings' => $fare['driver_earnings_amount'],
                'platform_commission' => $fare['platform_commission_amount'],
                'payment_mode' => $booking['payment_mode'],
                'receipt_url' => "/api/v1/bookings/{$bookingId}"
            ], 'Trip completed! Itemized receipt generated.');
        } catch (\Exception $e) {
            $db->rollBack();
            Response::error($e->getMessage(), 500);
        }
    }

    /**
     * Cancel booking with cancellation policy
     */
    public function cancel(Request $request): void
    {
        $user = $request->getUser();
        $bookingId = (int)$request->param('id');
        $reason = (string)$request->get('reason', 'Cancelled by user');

        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT * FROM bookings WHERE id = ?");
        $stmt->execute([$bookingId]);
        $booking = $stmt->fetch();

        if (!$booking) {
            Response::error('Booking not found', 404);
            return;
        }

        if (in_array($booking['booking_status'], ['completed', 'cancelled'], true)) {
            Response::error("Cannot cancel booking with status '{$booking['booking_status']}'.", 400);
            return;
        }

        $cancelledBy = ($user['id'] === (int)$booking['customer_id']) ? 'customer' : (($booking['driver_id'] && $user['role'] === 'driver') ? 'driver' : 'admin');

        $db->beginTransaction();
        try {
            $db->prepare("
                UPDATE bookings 
                SET booking_status = 'cancelled', cancelled_at = NOW(), cancelled_by = ?, cancellation_reason = ? 
                WHERE id = ?
            ")->execute([$cancelledBy, $reason, $bookingId]);

            // Release driver if assigned
            if (!empty($booking['driver_id'])) {
                $db->prepare("UPDATE driver_profiles SET is_busy = 0 WHERE id = ?")->execute([$booking['driver_id']]);
            }

            // Event
            $db->prepare("
                INSERT INTO booking_events (booking_id, event_name, actor_id, actor_type, payload)
                VALUES (?, 'cancelled', ?, ?, ?)
            ")->execute([$bookingId, $user['id'], $cancelledBy, json_encode(['reason' => $reason])]);

            $db->commit();

            Response::success(['status' => 'cancelled'], 'Booking has been cancelled.');
        } catch (\Exception $e) {
            $db->rollBack();
            Response::error($e->getMessage(), 500);
        }
    }
}
