<?php
declare(strict_types=1);

namespace OiToto\Services;

use OiToto\Core\Auth;
use OiToto\Core\Config;
use OiToto\Core\Database;
use OiToto\Core\Logger;
use PDO;
use RuntimeException;

class OtpService
{
    public static function formatPhone(string $phone): string
    {
        $clean = preg_replace('/[^0-9]/', '', $phone);
        if (str_starts_with($clean, '91') && strlen($clean) === 12) {
            $clean = substr($clean, 2);
        } elseif (str_starts_with($clean, '0') && strlen($clean) === 11) {
            $clean = substr($clean, 1);
        }
        return $clean;
    }

    public static function requestOtp(string $rawPhone, string $role = 'customer'): array
    {
        $phone = self::formatPhone($rawPhone);
        if (strlen($phone) !== 10) {
            throw new RuntimeException("Invalid 10-digit mobile number: {$rawPhone}");
        }

        $db = Database::getConnection();

        // Check if user exists
        $stmt = $db->prepare("SELECT id, phone, role, status, otp_attempts, otp_expires_at FROM users WHERE phone = ?");
        $stmt->execute([$phone]);
        $user = $stmt->fetch();

        if ($user && in_array($user['status'], ['suspended', 'deactivated'], true)) {
            throw new RuntimeException("This mobile number is {$user['status']}. Contact Oi Toto support.");
        }

        // Generate 6 digit OTP
        $otp = (string)random_int(100000, 999999);
        $expiresAt = date('Y-m-d H:i:s', time() + 300); // 5 minutes

        if (!$user) {
            // Pre-create user in pending status
            $insert = $db->prepare("
                INSERT INTO users (phone, full_name, role, status, language, otp_code, otp_expires_at, otp_attempts)
                VALUES (?, ?, ?, 'pending', 'en', ?, ?, 0)
            ");
            $insert->execute([$phone, 'Oi Toto User', $role, $otp, $expiresAt]);
        } else {
            $update = $db->prepare("
                UPDATE users 
                SET otp_code = ?, otp_expires_at = ?, otp_attempts = 0 
                WHERE id = ?
            ");
            $update->execute([$otp, $expiresAt, $user['id']]);
        }

        $provider = Config::get('SMS_PROVIDER', 'sandbox');
        $smsSent = false;

        if ($provider === 'fast2sms') {
            $smsSent = self::sendFast2Sms($phone, $otp);
        } elseif ($provider === 'msg91') {
            $smsSent = self::sendMsg91($phone, $otp);
        } else {
            // Sandbox mode: print to log
            Logger::info("Oi Toto Sandbox OTP for {$phone}: {$otp}");
            $smsSent = true;
        }

        $isDev = Config::get('APP_ENV') === 'development' || $provider === 'sandbox';

        return [
            'phone' => $phone,
            'message' => 'OTP sent successfully to your mobile number.',
            'expires_in_seconds' => 300,
            'sandbox_otp' => $isDev ? $otp : null
        ];
    }

    public static function verifyOtp(string $rawPhone, string $otp, string $role = 'customer', ?string $fullName = null, string $category = 'toto'): array
    {
        $phone = self::formatPhone($rawPhone);
        $db = Database::getConnection();

        $stmt = $db->prepare("SELECT * FROM users WHERE phone = ?");
        $stmt->execute([$phone]);
        $user = $stmt->fetch();

        if (!$user) {
            throw new RuntimeException("No account request found for {$phone}. Please request OTP first.");
        }

        // Check attempts
        if ((int)$user['otp_attempts'] >= 5) {
            throw new RuntimeException("Too many incorrect OTP attempts. Please request a new OTP.");
        }

        // Check expiry
        if (empty($user['otp_code']) || empty($user['otp_expires_at']) || strtotime($user['otp_expires_at']) < time()) {
            throw new RuntimeException("OTP has expired. Please request a new OTP.");
        }

        // Test bypass check or match
        $valid = ($user['otp_code'] === $otp);
        if (!$valid && Config::getBool('OTP_DEFAULT_BYPASS') && $otp === Config::get('OTP_TEST_CODE', '123456')) {
            $valid = true;
        }

        if (!$valid) {
            $db->prepare("UPDATE users SET otp_attempts = otp_attempts + 1 WHERE id = ?")->execute([$user['id']]);
            $remaining = 4 - (int)$user['otp_attempts'];
            throw new RuntimeException("Invalid OTP code. {$remaining} attempts remaining.");
        }

        // Success! Clear OTP and activate user
        $nameToSave = !empty($fullName) ? trim($fullName) : ($user['full_name'] !== 'Oi Toto User' ? $user['full_name'] : 'Oi Toto Rider');
        $finalStatus = ($role === 'driver') ? ($user['status'] === 'active' ? 'active' : 'pending') : 'active';

        $db->beginTransaction();
        try {
            $update = $db->prepare("
                UPDATE users 
                SET otp_code = NULL, otp_expires_at = NULL, otp_attempts = 0,
                    status = ?, full_name = ?, last_login_at = NOW()
                WHERE id = ?
            ");
            $update->execute([$finalStatus, $nameToSave, $user['id']]);

            // Ensure profile exists
            $profile = null;
            if ($role === 'driver' || $user['role'] === 'driver') {
                $checkProf = $db->prepare("SELECT * FROM driver_profiles WHERE user_id = ?");
                $checkProf->execute([$user['id']]);
                $profile = $checkProf->fetch();
                if (!$profile) {
                    $insProf = $db->prepare("
                        INSERT INTO driver_profiles (user_id, status, ownership_model, vehicle_category)
                        VALUES (?, 'pending_review', 'owner_operator', ?)
                    ");
                    $insProf->execute([$user['id'], $category]);
                    $profileId = $db->lastInsertId();

                    // Create wallet
                    $insWallet = $db->prepare("INSERT INTO driver_wallets (driver_id) VALUES (?)");
                    $insWallet->execute([$profileId]);

                    $profile = ['id' => $profileId, 'status' => 'pending_review', 'vehicle_category' => $category];
                } else {
                    if (!empty($category)) {
                        $db->prepare("UPDATE driver_profiles SET vehicle_category = ? WHERE id = ?")->execute([$category, $profile['id']]);
                        $profile['vehicle_category'] = $category;
                    }
                }
            } else {
                $checkProf = $db->prepare("SELECT * FROM customer_profiles WHERE user_id = ?");
                $checkProf->execute([$user['id']]);
                $profile = $checkProf->fetch();
                if (!$profile) {
                    $insProf = $db->prepare("INSERT INTO customer_profiles (user_id) VALUES (?)");
                    $insProf->execute([$user['id']]);
                    $profile = ['id' => $db->lastInsertId(), 'rating_avg' => 5.0];
                }
            }

            $db->commit();
        } catch (\Exception $e) {
            $db->rollBack();
            throw $e;
        }

        // Generate JWT Token
        $token = Auth::generateToken([
            'sub' => $user['id'],
            'phone' => $phone,
            'role' => $user['role'],
            'name' => $nameToSave
        ], Config::getInt('JWT_EXPIRY_DAYS', 30));

        return [
            'token' => $token,
            'user' => [
                'id' => (int)$user['id'],
                'phone' => $phone,
                'full_name' => $nameToSave,
                'email' => $user['email'],
                'role' => $user['role'],
                'status' => $finalStatus,
                'language' => $user['language'] ?? 'en',
            ],
            'profile' => $profile
        ];
    }

    private static function sendFast2Sms(string $phone, string $otp): bool
    {
        $apiKey = Config::get('SMS_API_KEY');
        if (empty($apiKey)) return false;

        $url = 'https://www.fast2sms.com/dev/bulkV2';
        $data = [
            'route' => 'otp',
            'variables_values' => $otp,
            'numbers' => $phone,
            'flash' => '0'
        ];

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($data));
        curl_setopt($ch, CURLOPT_HTTPHEADER, ["authorization: {$apiKey}"]);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 5);
        $res = curl_exec($ch);
        curl_close($ch);
        return $res !== false;
    }

    private static function sendMsg91(string $phone, string $otp): bool
    {
        $authKey = Config::get('SMS_API_KEY');
        if (empty($authKey)) return false;

        $url = "https://api.msg91.com/api/v5/otp?template_id=DEFAULT&mobile=91{$phone}&authkey={$authKey}&otp={$otp}";
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 5);
        $res = curl_exec($ch);
        curl_close($ch);
        return $res !== false;
    }
}
