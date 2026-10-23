<?php
declare(strict_types=1);

namespace OiToto\Controllers;

use OiToto\Core\Request;
use OiToto\Core\Response;
use OiToto\Core\Validator;
use OiToto\Services\PaymentService;
use Throwable;

class PaymentController
{
    public function createOrder(Request $request): void
    {
        $user = $request->getUser();
        $v = Validator::make($request->all(), [
            'booking_id' => 'required|numeric',
            'amount' => 'required|numeric'
        ]);

        if (!$v->validate()) {
            Response::error($v->getFirstError(), 422);
            return;
        }

        $bookingId = (int)$request->get('booking_id');
        $amount = (float)$request->get('amount');
        $mode = (string)$request->get('payment_mode', 'upi');

        try {
            $order = PaymentService::createOrder($bookingId, (int)$user['id'], $amount, $mode);
            Response::success($order, 'Payment order initiated.');
        } catch (Throwable $e) {
            Response::error($e->getMessage(), 400);
        }
    }

    public function verifyPayment(Request $request): void
    {
        $v = Validator::make($request->all(), [
            'payment_id' => 'required|numeric',
            'gateway_payment_id' => 'required',
            'gateway_order_id' => 'required'
        ]);

        if (!$v->validate()) {
            Response::error($v->getFirstError(), 422);
            return;
        }

        $paymentId = (int)$request->get('payment_id');
        $gatewayPaymentId = (string)$request->get('gateway_payment_id');
        $gatewayOrderId = (string)$request->get('gateway_order_id');
        $signature = (string)$request->get('signature', '');

        try {
            $res = PaymentService::verifyPayment($paymentId, $gatewayPaymentId, $gatewayOrderId, $signature);
            Response::success($res, $res['message']);
        } catch (Throwable $e) {
            Response::error($e->getMessage(), 400);
        }
    }

    public function cashCollected(Request $request): void
    {
        $user = $request->getUser();
        $v = Validator::make($request->all(), [
            'booking_id' => 'required|numeric',
            'amount' => 'required|numeric'
        ]);

        if (!$v->validate()) {
            Response::error($v->getFirstError(), 422);
            return;
        }

        $bookingId = (int)$request->get('booking_id');
        $amount = (float)$request->get('amount');

        // Fetch driver profile id
        $db = \OiToto\Core\Database::getConnection();
        $dStmt = $db->prepare("SELECT id FROM driver_profiles WHERE user_id = ?");
        $dStmt->execute([$user['id']]);
        $driver = $dStmt->fetch();

        if (!$driver) {
            Response::error('Driver profile not found.', 404);
            return;
        }

        try {
            $res = PaymentService::recordCashCollected($bookingId, (int)$driver['id'], $amount);
            Response::success($res, $res['message']);
        } catch (Throwable $e) {
            Response::error($e->getMessage(), 400);
        }
    }
}
