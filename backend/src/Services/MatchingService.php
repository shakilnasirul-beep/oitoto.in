<?php
declare(strict_types=1);

namespace OiToto\Services;

use OiToto\Core\Database;
use OiToto\Core\Logger;
use PDO;
use RuntimeException;

class MatchingService
{
    /**
     * Find nearby online, verified, available E-Rickshaw drivers within radius
     */
    public static function findNearbyDrivers(float $pickupLat, float $pickupLng, float $radiusKm = 4.0, int $limit = 10): array
    {
        $db = Database::getConnection();

        $stmt = $db->prepare("
            SELECT 
                dp.id AS driver_id,
                dp.user_id,
                dp.vehicle_id,
                dp.ownership_model,
                dp.rating_avg,
                dp.total_trips,
                dp.current_lat,
                dp.current_lng,
                dp.heading,
                u.full_name AS driver_name,
                u.phone AS driver_phone,
                u.avatar_url,
                v.vehicle_number,
                v.brand_make,
                v.model_year,
                v.battery_type,
                v.ownership_type,
                v.color
            FROM driver_profiles dp
            JOIN users u ON u.id = dp.user_id
            JOIN vehicles v ON v.id = dp.vehicle_id
            WHERE dp.status = 'verified_active'
              AND dp.is_online = 1
              AND dp.is_busy = 0
              AND u.status = 'active'
              AND v.status = 'approved'
              AND dp.current_lat IS NOT NULL 
              AND dp.current_lng IS NOT NULL
        ");
        $stmt->execute();
        $candidates = $stmt->fetchAll();

        $nearby = [];
        foreach ($candidates as $cand) {
            $dist = LocationService::calculateDistance(
                $pickupLat,
                $pickupLng,
                (float)$cand['current_lat'],
                (float)$cand['current_lng']
            );

            if ($dist <= $radiusKm) {
                $cand['distance_to_pickup_km'] = $dist;
                $cand['estimated_pickup_mins'] = LocationService::estimateDurationMinutes($dist, 16.0);
                $nearby[] = $cand;
            }
        }

        usort($nearby, fn($a, $b) => $a['distance_to_pickup_km'] <=> $b['distance_to_pickup_km']);

        return array_slice($nearby, 0, $limit);
    }

    /**
     * Process Atomic Driver Acceptance with concurrency lock
     * Guaranteed to allow ONLY ONE driver to accept a booking.
     */
    public static function atomicAcceptBooking(int $bookingId, int $driverId): array
    {
        $db = Database::getConnection();
        $db->beginTransaction();

        try {
            // Lock the booking row for update
            $stmt = $db->prepare("SELECT * FROM bookings WHERE id = ? FOR UPDATE");
            $stmt->execute([$bookingId]);
            $booking = $stmt->fetch();

            if (!$booking) {
                $db->rollBack();
                throw new RuntimeException("Booking not found.");
            }

            if ($booking['booking_status'] !== 'requested' && $booking['booking_status'] !== 'dispatched') {
                $db->rollBack();
                if ($booking['booking_status'] === 'accepted') {
                    throw new RuntimeException("Booking was already accepted by another driver.");
                }
                throw new RuntimeException("Booking is no longer available (Status: {$booking['booking_status']}).");
            }

            if ($booking['driver_id'] !== null) {
                $db->rollBack();
                throw new RuntimeException("Booking already taken by another driver.");
            }

            // Fetch driver details
            $dStmt = $db->prepare("
                SELECT dp.*, v.id AS assigned_vehicle_id, u.full_name AS driver_name, u.phone AS driver_phone 
                FROM driver_profiles dp 
                JOIN users u ON u.id = dp.user_id
                LEFT JOIN vehicles v ON v.id = dp.vehicle_id 
                WHERE dp.id = ? FOR UPDATE
            ");
            $dStmt->execute([$driverId]);
            $driver = $dStmt->fetch();

            if (!$driver || $driver['status'] !== 'verified_active') {
                $db->rollBack();
                throw new RuntimeException("Driver is not approved or active.");
            }

            if ((int)$driver['is_busy'] === 1) {
                $db->rollBack();
                throw new RuntimeException("Driver is currently on another active trip.");
            }

            $vehicleId = $driver['assigned_vehicle_id'] ?? $driver['vehicle_id'];

            // Atomic update on booking
            $upd = $db->prepare("
                UPDATE bookings 
                SET driver_id = ?, 
                    vehicle_id = ?, 
                    booking_status = 'accepted', 
                    accepted_at = NOW() 
                WHERE id = ? AND driver_id IS NULL AND booking_status IN ('requested', 'dispatched')
            ");
            $upd->execute([$driverId, $vehicleId, $bookingId]);

            if ($upd->rowCount() === 0) {
                $db->rollBack();
                throw new RuntimeException("Race condition: another driver accepted this booking just a moment ago.");
            }

            // Mark driver as busy
            $db->prepare("UPDATE driver_profiles SET is_busy = 1 WHERE id = ?")->execute([$driverId]);

            // Record event
            $eventStmt = $db->prepare("
                INSERT INTO booking_events (booking_id, event_name, actor_id, actor_type, payload)
                VALUES (?, 'driver_accepted', ?, 'driver', ?)
            ");
            $eventStmt->execute([
                $bookingId,
                $driver['user_id'],
                json_encode([
                    'driver_id' => $driverId,
                    'vehicle_id' => $vehicleId,
                    'accepted_at' => date('c')
                ])
            ]);

            // Notify customer
            NotificationService::send(
                (int)$booking['customer_id'],
                'E-Rickshaw Confirmed!',
                "Driver {$driver['driver_name']} has accepted your booking and is on the way.",
                'trip_status',
                ['booking_id' => $bookingId, 'status' => 'accepted']
            );

            $db->commit();

            return [
                'success' => true,
                'message' => 'Booking accepted successfully! Head to the pickup location.',
                'booking_id' => $bookingId,
                'status' => 'accepted'
            ];
        } catch (\Exception $e) {
            if ($db->inTransaction()) {
                $db->rollBack();
            }
            throw $e;
        }
    }
}
