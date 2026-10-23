<?php
declare(strict_types=1);

namespace OiToto\Services;

use OiToto\Core\Config;
use OiToto\Core\Database;
use OiToto\Core\Logger;
use PDO;
use RuntimeException;

class PaymentService
{
    /**
     * Create an online payment order (Razorpay UPI / Sandbox)
     */
    public static function createOrder(int $bookingId, int $customerId, float $amount, string $paymentMode = 'upi'): array
    {
        $db = Database::getConnection();

        // Check booking
        $bStmt = $db->prepare("SELECT * FROM bookings WHERE id = ?");
        $bStmt->execute([$bookingId]);
        $booking = $bStmt->fetch();

        if (!$booking) {
            throw new RuntimeException("Booking not found");
        }

        $idempotencyKey = 'IDEMP_' . $bookingId . '_' . time();
        $isSandbox = Config::get('PAYMENT_MODE', 'sandbox') === 'sandbox';
        $keyId = Config::get('RAZORPAY_KEY_ID', 'rzp_test_oitoto_demo2026');
        $keySecret = Config::get('RAZORPAY_KEY_SECRET', 'test_secret');

        $orderId = 'order_sandbox_' . bin2hex(random_bytes(8));

        // If real Razorpay credentials provided
        if (!$isSandbox && !empty($keyId) && !empty($keySecret) && !str_starts_with($keyId, 'rzp_test_oitoto_demo')) {
            $amountInPaise = (int)round($amount * 100);
            $ch = curl_init('https://api.razorpay.com/v1/orders');
            curl_setopt($ch, CURLOPT_USERPWD, "{$keyId}:{$keySecret}");
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
                'amount' => $amountInPaise,
                'currency' => 'INR',
                'receipt' => $booking['booking_code'],
                'notes' => ['booking_id' => $bookingId, 'app' => 'Oi Toto']
            ]));
            curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            $res = curl_exec($ch);
            curl_close($ch);

            if ($res) {
                $orderData = json_decode($res, true);
                if (!empty($orderData['id'])) {
                    $orderId = $orderData['id'];
                }
            }
        }

        // Record payment initiation
        $txnRef = 'TXN_OT_' . date('Ymd') . '_' . strtoupper(bin2hex(random_bytes(4)));
        $stmt = $db->prepare("
            INSERT INTO payments (
                booking_id, customer_id, driver_id, transaction_reference,
                payment_gateway, amount, currency, gateway_order_id,
                status, idempotency_key
            ) VALUES (?, ?, ?, ?, 'razorpay_upi', ?, 'INR', ?, 'initiated', ?)
        ");
        $stmt->execute([
            $bookingId,
            $customerId,
            $booking['driver_id'],
            $txnRef,
            $amount,
            $orderId,
            $idempotencyKey
        ]);

        return [
            'payment_id' => (int)$db->lastInsertId(),
            'transaction_reference' => $txnRef,
            'gateway_order_id' => $orderId,
            'razorpay_key' => $keyId,
            'amount' => $amount,
            'currency' => 'INR',
            'is_sandbox' => $isSandbox,
            'booking_code' => $booking['booking_code'],
            'environment_note' => $isSandbox ? '[SANDBOX MODE] Real bank debit will not occur. Test credentials active.' : 'Production Live Gateway'
        ];
    }

    /**
     * Verify payment signature server-side
     */
    public static function verifyPayment(
        int $paymentId,
        string $gatewayPaymentId,
        string $gatewayOrderId,
        string $signature,
        bool $forceSandbox = false
    ): array {
        $db = Database::getConnection();
        $db->beginTransaction();

        try {
            $stmt = $db->prepare("SELECT * FROM payments WHERE id = ? FOR UPDATE");
            $stmt->execute([$paymentId]);
            $payment = $stmt->fetch();

            if (!$payment) {
                $db->rollBack();
                throw new RuntimeException("Payment record not found");
            }

            if ($payment['status'] === 'captured') {
                $db->rollBack();
                return ['success' => true, 'message' => 'Payment already verified successfully.'];
            }

            $isSandbox = Config::get('PAYMENT_MODE', 'sandbox') === 'sandbox' || $forceSandbox;
            $verified = false;

            if ($isSandbox) {
                // In sandbox mode, verify order id matches
                $verified = ($payment['gateway_order_id'] === $gatewayOrderId || str_starts_with($gatewayOrderId, 'order_sandbox_'));
            } else {
                $keySecret = Config::get('RAZORPAY_KEY_SECRET');
                $expectedSig = hash_hmac('sha256', "{$gatewayOrderId}|{$gatewayPaymentId}", (string)$keySecret);
                $verified = hash_equals($expectedSig, $signature);
            }

            if (!$verified) {
                $db->prepare("UPDATE payments SET status = 'failed' WHERE id = ?")->execute([$paymentId]);
                $db->commit();
                throw new RuntimeException("Payment verification signature mismatch. Security check failed.");
            }

            // Update payment status
            $db->prepare("
                UPDATE payments 
                SET status = 'captured', gateway_payment_id = ?, gateway_signature = ?, updated_at = NOW() 
                WHERE id = ?
            ")->execute([$gatewayPaymentId, $signature, $paymentId]);

            // Update booking payment status
            $db->prepare("UPDATE bookings SET payment_status = 'paid', payment_mode = 'upi' WHERE id = ?")
               ->execute([$payment['booking_id']]);

            // Settle driver earnings and ledger
            if ($payment['driver_id']) {
                self::creditDriverAccount((int)$payment['driver_id'], (int)$payment['booking_id'], (float)$payment['amount'], false);
            }

            $db->commit();

            return [
                'success' => true,
                'message' => 'Payment verified and captured successfully.',
                'status' => 'captured',
                'is_sandbox' => $isSandbox
            ];
        } catch (\Exception $e) {
            if ($db->inTransaction()) {
                $db->rollBack();
            }
            throw $e;
        }
    }

    /**
     * Record cash collected by driver at end of trip
     */
    public static function recordCashCollected(int $bookingId, int $driverId, float $amount): array
    {
        $db = Database::getConnection();
        $db->beginTransaction();

        try {
            $bStmt = $db->prepare("SELECT * FROM bookings WHERE id = ? FOR UPDATE");
            $bStmt->execute([$bookingId]);
            $booking = $bStmt->fetch();

            if (!$booking) {
                $db->rollBack();
                throw new RuntimeException("Booking not found");
            }

            if ((int)$booking['driver_id'] !== $driverId) {
                $db->rollBack();
                throw new RuntimeException("Unauthorized: Driver does not own this booking");
            }

            $txnRef = 'CASH_OT_' . date('Ymd') . '_' . strtoupper(bin2hex(random_bytes(4)));
            $idempKey = 'CASH_IDEMP_' . $bookingId;

            // Record payment
            $pStmt = $db->prepare("
                INSERT INTO payments (
                    booking_id, customer_id, driver_id, transaction_reference,
                    payment_gateway, amount, currency, gateway_payment_id,
                    status, idempotency_key
                ) VALUES (?, ?, ?, ?, 'cash', ?, 'INR', 'cash_in_hand', 'captured', ?)
            ");
            $pStmt->execute([
                $bookingId,
                $booking['customer_id'],
                $driverId,
                $txnRef,
                $amount,
                $idempKey
            ]);

            // Update booking
            $db->prepare("UPDATE bookings SET payment_status = 'paid', payment_mode = 'cash' WHERE id = ?")
               ->execute([$bookingId]);

            // Credit driver account with cash collection adjustment
            self::creditDriverAccount($driverId, $bookingId, $amount, true);

            $db->commit();

            return [
                'success' => true,
                'message' => 'Cash collection recorded successfully.',
                'amount_collected' => $amount,
                'payment_status' => 'paid'
            ];
        } catch (\Exception $e) {
            if ($db->inTransaction()) {
                $db->rollBack();
            }
            throw $e;
        }
    }

    /**
     * Credit driver ledger and calculate commissions
     */
    private static function creditDriverAccount(int $driverId, int $bookingId, float $grossFare, bool $isCash): void
    {
        $db = Database::getConnection();

        // Fetch booking commissions
        $bStmt = $db->prepare("SELECT platform_commission_amount, driver_earnings_amount FROM bookings WHERE id = ?");
        $bStmt->execute([$bookingId]);
        $booking = $bStmt->fetch();

        $commissionAmount = (float)($booking['platform_commission_amount'] ?? ($grossFare * 0.10));
        $driverNetShare = (float)($booking['driver_earnings_amount'] ?? ($grossFare - $commissionAmount));

        // Insert commission record
        $cStmt = $db->prepare("
            INSERT INTO commissions (booking_id, driver_id, gross_fare, commission_percentage, commission_amount, net_driver_share, settlement_status)
            VALUES (?, ?, ?, 10.00, ?, ?, 'settled')
        ");
        $cStmt->execute([$bookingId, $driverId, $grossFare, $commissionAmount, $driverNetShare]);

        // Fetch current wallet
        $wStmt = $db->prepare("SELECT * FROM driver_wallets WHERE driver_id = ? FOR UPDATE");
        $wStmt->execute([$driverId]);
        $wallet = $wStmt->fetch();

        if (!$wallet) {
            $db->prepare("INSERT INTO driver_wallets (driver_id) VALUES (?)")->execute([$driverId]);
            $wStmt->execute([$driverId]);
            $wallet = $wStmt->fetch();
        }

        $balanceBefore = (float)$wallet['current_balance'];

        if ($isCash) {
            // Driver collected physical cash. Commission is deducted from driver's digital wallet balance!
            $newBalance = $balanceBefore - $commissionAmount;
            $newCashHeld = (float)$wallet['cash_collected_held'] + $grossFare;

            $upd = $db->prepare("
                UPDATE driver_wallets 
                SET current_balance = ?, total_earned = total_earned + ?, cash_collected_held = ?
                WHERE driver_id = ?
            ");
            $upd->execute([$newBalance, $driverNetShare, $newCashHeld, $driverId]);

            // Ledger: Commission Debit
            $db->prepare("
                INSERT INTO ledger_entries (driver_id, booking_id, entry_type, amount, balance_after, description)
                VALUES (?, ?, 'platform_commission_debit', ?, ?, ?)
            ")->execute([
                $driverId,
                $bookingId,
                -$commissionAmount,
                $newBalance,
                "Oi Toto 10% platform fee for trip #{$bookingId} (Cash collection)"
            ]);
        } else {
            // Digital / UPI payment received. Net driver earnings credited to wallet!
            $newBalance = $balanceBefore + $driverNetShare;

            $upd = $db->prepare("
                UPDATE driver_wallets 
                SET current_balance = ?, total_earned = total_earned + ?
                WHERE driver_id = ?
            ");
            $upd->execute([$newBalance, $driverNetShare, $driverId]);

            // Ledger: Trip Earning Credit
            $db->prepare("
                INSERT INTO ledger_entries (driver_id, booking_id, entry_type, amount, balance_after, description)
                VALUES (?, ?, 'trip_earning', ?, ?, ?)
            ")->execute([
                $driverId,
                $bookingId,
                $driverNetShare,
                $newBalance,
                "Net trip earnings for trip #{$bookingId} (UPI Payment)"
            ]);
        }
    }
}
