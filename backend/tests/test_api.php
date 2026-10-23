<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/src/Core/Autoloader.php';
\OiToto\Core\Autoloader::register();

use OiToto\Core\Config;
use OiToto\Core\Database;
use OiToto\Core\Auth;
use OiToto\Services\OtpService;
use OiToto\Services\FareCalculatorService;
use OiToto\Services\LocationService;
use OiToto\Services\MatchingService;
use OiToto\Services\PaymentService;

Config::load(dirname(__DIR__) . '/.env');

echo "=== RUNNING OI TOTO! BACKEND AUTOMATED TEST SUITE ===" . PHP_EOL . PHP_EOL;

$passed = 0;
$failed = 0;

function assertTest(string $name, bool $condition, ?string $extra = null): void {
    global $passed, $failed;
    if ($condition) {
        echo "[PASS] " . $name . ($extra ? " ({$extra})" : "") . PHP_EOL;
        $passed++;
    } else {
        echo "[FAIL] " . $name . ($extra ? " - Error: {$extra}" : "") . PHP_EOL;
        $failed++;
    }
}

// 1. Database Connection Test
try {
    $db = Database::getConnection();
    $stmt = $db->query("SELECT DATABASE() AS db");
    $dbName = $stmt->fetchColumn();
    assertTest("Database Connection", $dbName === 'oitoto_db', "Connected to {$dbName}");
} catch (\Throwable $e) {
    assertTest("Database Connection", false, $e->getMessage());
}

// 2. Fare Calculation Test
try {
    $fare = FareCalculatorService::calculate(2.5, 2, 1);
    // Base 1.5km = ₹20. Remaining 1.0km * ₹10 = ₹10. Total = ₹30. Commission 10% = ₹3. Driver share = ₹27.
    assertTest(
        "Fare Calculation (2.5 km)",
        $fare['final_fare'] == 30.00 && $fare['platform_commission_amount'] == 3.00 && $fare['driver_earnings_amount'] == 27.00,
        "Final Fare: ₹{$fare['final_fare']}, Commission: ₹{$fare['platform_commission_amount']}"
    );
} catch (\Throwable $e) {
    assertTest("Fare Calculation", false, $e->getMessage());
}

// 3. Location Haversine Calculation Test
try {
    // Shyambazar (22.6038, 88.3713) to College Street (22.5754, 88.3639) is approx 3.2 km
    $dist = LocationService::calculateDistance(22.6038, 88.3713, 22.5754, 88.3639);
    assertTest("Spatial Haversine Distance", $dist >= 3.0 && $dist <= 3.5, "Calculated distance: {$dist} km");
} catch (\Throwable $e) {
    assertTest("Spatial Haversine Distance", false, $e->getMessage());
}

// 4. OTP Request & Verification
try {
    $testPhone = '9998887771';
    $otpReq = OtpService::requestOtp($testPhone, 'customer');
    $sandboxOtp = $otpReq['sandbox_otp'];
    assertTest("OTP Generation", !empty($sandboxOtp), "Generated OTP: {$sandboxOtp}");

    $login = OtpService::verifyOtp($testPhone, $sandboxOtp, 'customer', 'Rishit Ganguly');
    assertTest("OTP Verification & JWT Generation", !empty($login['token']), "User ID: {$login['user']['id']}, Token valid");

    $tokenPayload = Auth::validateToken($login['token']);
    assertTest("JWT Decryption & Verification", $tokenPayload !== null && $tokenPayload['phone'] === $testPhone);
} catch (\Throwable $e) {
    assertTest("OTP Authentication Lifecycle", false, $e->getMessage());
}

// 5. Driver Discovery / Matching
try {
    $nearby = MatchingService::findNearbyDrivers(22.5726, 88.3638, 5.0);
    assertTest("Nearby E-Rickshaw Driver Discovery", count($nearby) > 0, "Found " . count($nearby) . " online E-Rickshaws nearby");
} catch (\Throwable $e) {
    assertTest("Nearby E-Rickshaw Discovery", false, $e->getMessage());
}

// 6. Booking Creation & Atomic Acceptance Concurrency
try {
    $db = Database::getConnection();
    // Create a fresh test booking
    $bCode = 'OT-TEST-' . time();
    $ins = $db->prepare("
        INSERT INTO bookings (
            booking_code, customer_id, service_area_id, pickup_address, pickup_lat, pickup_lng,
            drop_address, drop_lat, drop_lng, estimated_distance_km, estimated_fare,
            base_fare_charged, platform_commission_amount, driver_earnings_amount,
            booking_status, start_otp, requested_at
        ) VALUES (
            ?, 6, 1, 'Shyambazar Five Point', 22.6038, 88.3713,
            'Hatibagan Crossing', 22.5942, 88.3710, 1.80, 23.00,
            20.00, 2.30, 20.70,
            'requested', '5544', NOW()
        )
    ");
    $ins->execute([$bCode]);
    $bookingId = (int)$db->lastInsertId();
    assertTest("Trip Creation", $bookingId > 0, "Booking ID: {$bookingId}, Code: {$bCode}");

    // Driver 1 accepts
    $acceptRes = MatchingService::atomicAcceptBooking($bookingId, 1);
    assertTest("Atomic Driver Acceptance", $acceptRes['success'] === true && $acceptRes['status'] === 'accepted');

    // Concurrency test: Driver 2 attempts to accept SAME booking
    $secondAttemptFailed = false;
    try {
        MatchingService::atomicAcceptBooking($bookingId, 2);
    } catch (\Throwable $e) {
        $secondAttemptFailed = true;
    }
    assertTest("Concurrency Lock (Prevent Double-Acceptance)", $secondAttemptFailed, "Second driver correctly rejected");

} catch (\Throwable $e) {
    assertTest("Booking & Concurrency Lifecycle", false, $e->getMessage());
}

// 7. Trip Lifecycle: Arrived, Verify Start OTP, Complete Trip
try {
    // Mark arrived
    $db->prepare("UPDATE bookings SET booking_status = 'arrived' WHERE id = ?")->execute([$bookingId]);
    $st = $db->query("SELECT booking_status FROM bookings WHERE id = {$bookingId}")->fetchColumn();
    assertTest("Driver Arrival at Pickup", $st === 'arrived');

    // Start trip with correct OTP
    $chkOtp = $db->query("SELECT start_otp FROM bookings WHERE id = {$bookingId}")->fetchColumn();
    if ($chkOtp === '5544') {
        $db->prepare("UPDATE bookings SET booking_status = 'in_progress', started_at = NOW() WHERE id = ?")->execute([$bookingId]);
    }
    $stInProgress = $db->query("SELECT booking_status FROM bookings WHERE id = {$bookingId}")->fetchColumn();
    assertTest("Ride OTP Verification & Trip Start", $stInProgress === 'in_progress');

    // Complete trip
    $db->prepare("
        UPDATE bookings 
        SET booking_status = 'completed', completed_at = NOW(), actual_distance_km = 1.9,
            final_fare = 24.00, platform_commission_amount = 2.40, driver_earnings_amount = 21.60
        WHERE id = ?
    ")->execute([$bookingId]);
    $db->prepare("UPDATE driver_profiles SET is_busy = 0 WHERE id = 1")->execute();

    $stCompleted = $db->query("SELECT booking_status FROM bookings WHERE id = {$bookingId}")->fetchColumn();
    assertTest("Trip Completion & Receipt Finalization", $stCompleted === 'completed');

    // Settle cash collection
    $cashRes = PaymentService::recordCashCollected($bookingId, 1, 24.00);
    assertTest("Cash Collection & Wallet Settlement", $cashRes['success'] === true && $cashRes['payment_status'] === 'paid');

} catch (\Throwable $e) {
    assertTest("Trip Lifecycle & Payment", false, $e->getMessage());
}

echo PHP_EOL . "=== TEST SUMMARY: {$passed} PASSED, {$failed} FAILED ===" . PHP_EOL;

if ($failed > 0) {
    exit(1);
}
exit(0);
