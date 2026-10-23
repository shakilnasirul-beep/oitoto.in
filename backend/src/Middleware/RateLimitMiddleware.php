<?php
declare(strict_types=1);

namespace OiToto\Middleware;

use OiToto\Core\Request;
use OiToto\Core\Response;

class RateLimitMiddleware
{
    private int $maxAttempts;
    private int $decaySeconds;

    public function __construct(int $maxAttempts = 5, int $decaySeconds = 60)
    {
        $this->maxAttempts = $maxAttempts;
        $this->decaySeconds = $decaySeconds;
    }

    public static function limit(int $maxAttempts = 5, int $decaySeconds = 60): callable
    {
        $instance = new self($maxAttempts, $decaySeconds);
        return [$instance, 'handle'];
    }

    public function handle(Request $request): bool
    {
        $ip = $request->getIp();
        $path = md5($request->getPath());
        $cacheDir = dirname(__DIR__, 2) . '/storage/ratelimit';
        if (!is_dir($cacheDir)) {
            mkdir($cacheDir, 0777, true);
        }

        $file = $cacheDir . '/' . md5("{$ip}_{$path}") . '.json';
        $now = time();

        $data = ['attempts' => 0, 'reset_at' => $now + $this->decaySeconds];
        if (file_exists($file)) {
            $content = json_decode((string)file_get_contents($file), true);
            if (is_array($content) && ($content['reset_at'] ?? 0) > $now) {
                $data = $content;
            }
        }

        $data['attempts']++;
        file_put_contents($file, json_encode($data));

        if ($data['attempts'] > $this->maxAttempts) {
            $retryAfter = $data['reset_at'] - $now;
            header("Retry-After: {$retryAfter}");
            Response::error("Too many requests. Please retry in {$retryAfter} seconds.", 429);
            return false;
        }

        return true;
    }
}
