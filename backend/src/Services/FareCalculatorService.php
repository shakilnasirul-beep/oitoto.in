<?php
declare(strict_types=1);

namespace OiToto\Services;

use OiToto\Core\Database;
use PDO;

class FareCalculatorService
{
    /**
     * Calculate fare estimate or final fare
     */
    public static function calculate(
        float $distanceKm,
        int $waitingMinutes = 0,
        ?int $serviceAreaId = null,
        ?string $promoCode = null,
        ?string $bookingTime = null
    ): array {
        $db = Database::getConnection();

        // 1. Fetch fare rule for the service area (or fallback to default)
        $rule = null;
        if ($serviceAreaId) {
            $stmt = $db->prepare("SELECT * FROM fare_rules WHERE service_area_id = ? AND is_active = 1 LIMIT 1");
            $stmt->execute([$serviceAreaId]);
            $rule = $stmt->fetch();
        }

        if (!$rule) {
            $stmt = $db->query("SELECT * FROM fare_rules WHERE is_active = 1 ORDER BY id ASC LIMIT 1");
            $rule = $stmt->fetch();
        }

        // Default fallback if no rules exist in db
        $baseFare = (float)($rule['base_fare'] ?? 20.00);
        $baseDistanceKm = (float)($rule['base_distance_km'] ?? 1.50);
        $perKmRate = (float)($rule['per_km_rate'] ?? 10.00);
        $minimumFare = (float)($rule['minimum_fare'] ?? 20.00);
        $waitingChargePerMin = (float)($rule['per_minute_waiting_charge'] ?? 1.00);
        $freeWaitingMins = (int)($rule['free_waiting_minutes'] ?? 3);
        $nightSurgeMultiplier = (float)($rule['night_surge_multiplier'] ?? 1.25);
        $nightStart = $rule['night_surge_start'] ?? '22:00:00';
        $nightEnd = $rule['night_surge_end'] ?? '05:00:00';
        $commissionPercent = (float)($rule['platform_commission_percentage'] ?? 10.00);

        // 2. Base & Distance fare calculation
        $baseFareCharged = $baseFare;
        $distanceFareCharged = 0.00;

        if ($distanceKm > $baseDistanceKm) {
            $extraDistance = $distanceKm - $baseDistanceKm;
            $distanceFareCharged = round($extraDistance * $perKmRate, 2);
        }

        // 3. Waiting fare calculation
        $chargeableWaitingMins = max(0, $waitingMinutes - $freeWaitingMins);
        $waitingFareCharged = round($chargeableWaitingMins * $waitingChargePerMin, 2);

        $subtotal = $baseFareCharged + $distanceFareCharged + $waitingFareCharged;

        // 4. Night surge detection
        $currentTimeStr = $bookingTime ? date('H:i:s', strtotime($bookingTime)) : date('H:i:s');
        $isNight = false;
        if ($nightStart > $nightEnd) { // Overnight cross (e.g. 22:00 to 05:00)
            if ($currentTimeStr >= $nightStart || $currentTimeStr <= $nightEnd) {
                $isNight = true;
            }
        } else {
            if ($currentTimeStr >= $nightStart && $currentTimeStr <= $nightEnd) {
                $isNight = true;
            }
        }

        $surgeFareCharged = 0.00;
        if ($isNight && $nightSurgeMultiplier > 1.0) {
            $surgeFareCharged = round($subtotal * ($nightSurgeMultiplier - 1.0), 2);
            $subtotal += $surgeFareCharged;
        }

        // Ensure minimum fare
        if ($subtotal < $minimumFare) {
            $subtotal = $minimumFare;
        }

        // 5. Promo code discount
        $discountAmount = 0.00;
        $appliedPromo = null;
        if (!empty($promoCode)) {
            $pStmt = $db->prepare("
                SELECT * FROM promotions 
                WHERE promo_code = ? AND is_active = 1 
                  AND valid_from <= NOW() AND valid_to >= NOW() 
                LIMIT 1
            ");
            $pStmt->execute([strtoupper(trim($promoCode))]);
            $promo = $pStmt->fetch();

            if ($promo && $subtotal >= (float)$promo['min_fare_required']) {
                if ($promo['discount_type'] === 'percentage') {
                    $disc = ($subtotal * (float)$promo['discount_value']) / 100.0;
                    $discountAmount = min($disc, (float)$promo['max_discount']);
                } else {
                    $discountAmount = min((float)$promo['discount_value'], (float)$promo['max_discount']);
                }
                $discountAmount = round($discountAmount, 2);
                $appliedPromo = $promo['promo_code'];
            }
        }

        $finalFare = round(max(0.00, $subtotal - $discountAmount), 2);

        // 6. Platform commission & Driver earnings
        $platformCommissionAmount = round(($finalFare * $commissionPercent) / 100.0, 2);
        $driverEarningsAmount = round($finalFare - $platformCommissionAmount, 2);

        return [
            'base_fare_charged' => $baseFareCharged,
            'distance_km' => $distanceKm,
            'base_distance_km' => $baseDistanceKm,
            'per_km_rate' => $perKmRate,
            'distance_fare_charged' => $distanceFareCharged,
            'waiting_minutes' => $waitingMinutes,
            'waiting_fare_charged' => $waitingFareCharged,
            'is_night_surge' => $isNight,
            'surge_multiplier' => $isNight ? $nightSurgeMultiplier : 1.0,
            'surge_fare_charged' => $surgeFareCharged,
            'subtotal' => $subtotal,
            'applied_promo' => $appliedPromo,
            'discount_amount' => $discountAmount,
            'final_fare' => $finalFare,
            'platform_commission_percent' => $commissionPercent,
            'platform_commission_amount' => $platformCommissionAmount,
            'driver_earnings_amount' => $driverEarningsAmount,
            'currency' => '₹',
            'rule_id' => $rule['id'] ?? null
        ];
    }
}
