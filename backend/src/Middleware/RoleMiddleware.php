<?php
declare(strict_types=1);

namespace OiToto\Middleware;

use OiToto\Core\Request;
use OiToto\Core\Response;

class RoleMiddleware
{
    private array $allowedRoles;

    public function __construct(array|string $roles = [])
    {
        $this->allowedRoles = is_array($roles) ? $roles : explode(',', $roles);
    }

    public static function allow(string ...$roles): callable
    {
        return function (Request $request) use ($roles): bool {
            $user = $request->getUser();
            if (!$user) {
                Response::error('Unauthorized. Authentication required.', 401);
                return false;
            }

            if (!in_array($user['role'], $roles, true) && $user['role'] !== 'super_admin') {
                Response::error('Forbidden. Insufficient role permissions for this endpoint.', 403);
                return false;
            }

            return true;
        };
    }
}
