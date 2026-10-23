<?php
declare(strict_types=1);

namespace OiToto\Middleware;

use OiToto\Core\Auth;
use OiToto\Core\Database;
use OiToto\Core\Request;
use OiToto\Core\Response;

class AuthMiddleware
{
    public function handle(Request $request): bool
    {
        $token = $request->getBearerToken();
        if (!$token) {
            Response::error('Authentication required. Missing Bearer token.', 401);
            return false;
        }

        $payload = Auth::validateToken($token);
        if (!$payload || empty($payload['sub'])) {
            Response::error('Invalid or expired authentication token.', 401);
            return false;
        }

        $userId = (int)$payload['sub'];
        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT id, phone, full_name, email, role, status, language FROM users WHERE id = ?");
        $stmt->execute([$userId]);
        $user = $stmt->fetch();

        if (!$user) {
            Response::error('User account not found.', 401);
            return false;
        }

        if ($user['status'] === 'suspended' || $user['status'] === 'deactivated') {
            Response::error("Account is {$user['status']}. Please contact Oi Toto support.", 403);
            return false;
        }

        $request->setUser($user);
        return true;
    }
}
