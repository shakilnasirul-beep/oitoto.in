<?php
declare(strict_types=1);

namespace OiToto\Services;

use OiToto\Core\Config;
use OiToto\Core\Database;
use OiToto\Core\Logger;
use PDO;

class NotificationService
{
    public static function send(
        int $userId,
        string $title,
        string $body,
        string $type = 'booking_alert',
        array $data = []
    ): bool {
        $db = Database::getConnection();

        // 1. Store in internal notifications table
        try {
            $stmt = $db->prepare("
                INSERT INTO notifications (user_id, title, body, notification_type, data_payload)
                VALUES (?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $userId,
                $title,
                $body,
                $type,
                json_encode($data, JSON_UNESCAPED_SLASHES)
            ]);
        } catch (\Exception $e) {
            Logger::error("Failed to insert notification: " . $e->getMessage());
        }

        // 2. Fetch user's FCM token if available
        $uStmt = $db->prepare("SELECT fcm_token FROM users WHERE id = ?");
        $uStmt->execute([$userId]);
        $user = $uStmt->fetch();

        if ($user && !empty($user['fcm_token'])) {
            self::sendFcmPush($user['fcm_token'], $title, $body, $data);
        }

        return true;
    }

    private static function sendFcmPush(string $token, string $title, string $body, array $data): bool
    {
        $serverKey = Config::get('FCM_SERVER_KEY');
        if (empty($serverKey)) {
            Logger::info("FCM push notification skipped (No FCM_SERVER_KEY). Target: {$title}");
            return false;
        }

        $url = 'https://fcm.googleapis.com/fcm/send';
        $fields = [
            'to' => $token,
            'notification' => [
                'title' => $title,
                'body' => $body,
                'sound' => 'default',
                'color' => '#0A8B42'
            ],
            'data' => $data
        ];

        $headers = [
            'Authorization: key=' . $serverKey,
            'Content-Type: application/json'
        ];

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));
        curl_setopt($ch, CURLOPT_TIMEOUT, 5);
        $result = curl_exec($ch);
        curl_close($ch);

        return $result !== false;
    }
}
