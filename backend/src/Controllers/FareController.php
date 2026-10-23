<?php
declare(strict_types=1);

namespace OiToto\Controllers;

use OiToto\Core\Database;
use OiToto\Core\Request;
use OiToto\Core\Response;
use OiToto\Core\Validator;
use OiToto\Services\FareCalculatorService;
use OiToto\Services\LocationService;

class FareController
{
    public function estimate(Request $request): void
    {
        $v = Validator::make($request->all(), [
            'pickup_lat' => 'required|numeric',
            'pickup_lng' => 'required|numeric',
            'drop_lat' => 'required|numeric',
            'drop_lng' => 'required|numeric'
        ]);

        if (!$v->validate()) {
            Response::error($v->getFirstError(), 422);
            return;
        }

        $pLat = (float)$request->get('pickup_lat');
        $pLng = (float)$request->get('pickup_lng');
        $dLat = (float)$request->get('drop_lat');
        $dLng = (float)$request->get('drop_lng');
        $promoCode = $request->get('promo_code');

        $distanceKm = LocationService::calculateDistance($pLat, $pLng, $dLat, $dLng);
        $estimatedMins = LocationService::estimateDurationMinutes($distanceKm, 18.0);
        $serviceArea = LocationService::findServiceArea($pLat, $pLng);
        $areaId = $serviceArea['id'] ?? null;

        $fareBreakdown = FareCalculatorService::calculate(
            $distanceKm,
            0,
            $areaId ? (int)$areaId : null,
            $promoCode ? (string)$promoCode : null
        );

        $fareBreakdown['estimated_duration_mins'] = $estimatedMins;
        $fareBreakdown['service_area'] = $serviceArea ? [
            'id' => $serviceArea['id'],
            'name' => $serviceArea['name'],
            'city' => $serviceArea['city']
        ] : null;

        Response::success($fareBreakdown);
    }

    public function rules(Request $request): void
    {
        $db = Database::getConnection();
        $stmt = $db->query("
            SELECT fr.*, sa.name AS service_area_name, sa.city, sa.state 
            FROM fare_rules fr
            JOIN service_areas sa ON sa.id = fr.service_area_id
            ORDER BY sa.name ASC
        ");
        $rules = $stmt->fetchAll();

        Response::success($rules);
    }

    public function updateRule(Request $request): void
    {
        $id = (int)$request->param('id');
        $db = Database::getConnection();

        $stmt = $db->prepare("
            UPDATE fare_rules 
            SET base_fare = COALESCE(?, base_fare),
                base_distance_km = COALESCE(?, base_distance_km),
                per_km_rate = COALESCE(?, per_km_rate),
                minimum_fare = COALESCE(?, minimum_fare),
                per_minute_waiting_charge = COALESCE(?, per_minute_waiting_charge),
                night_surge_multiplier = COALESCE(?, night_surge_multiplier),
                platform_commission_percentage = COALESCE(?, platform_commission_percentage),
                cancellation_fee_customer = COALESCE(?, cancellation_fee_customer),
                is_active = COALESCE(?, is_active)
            WHERE id = ?
        ");
        $stmt->execute([
            $request->get('base_fare'),
            $request->get('base_distance_km'),
            $request->get('per_km_rate'),
            $request->get('minimum_fare'),
            $request->get('per_minute_waiting_charge'),
            $request->get('night_surge_multiplier'),
            $request->get('platform_commission_percentage'),
            $request->get('cancellation_fee_customer'),
            $request->get('is_active'),
            $id
        ]);

        Response::success(null, 'Fare rules updated successfully.');
    }
}
