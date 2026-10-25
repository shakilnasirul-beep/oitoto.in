<?php
declare(strict_types=1);

namespace OiToto\Middleware;

use OiToto\Core\Request;

class CorsMiddleware
{
    public function handle(Request $request): bool
    {
        $origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
        if ($origin === 'null' || empty($origin)) {
            $origin = '*';
        }
        
        header("Access-Control-Allow-Origin: {$origin}");
        header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
        header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization, X-Authorization, X-Admin-Token, X-Device-Id, X-App-Version, X-Language");
        if ($origin !== '*') {
            header("Access-Control-Allow-Credentials: true");
        }
        header("Access-Control-Max-Age: 86400");

        if ($request->getMethod() === 'OPTIONS') {
            http_response_code(200);
            exit;
        }

        return true;
    }
}
