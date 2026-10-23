<?php
declare(strict_types=1);

namespace OiToto\Core;

use PDO;
use Throwable;

class Logger
{
    private static function getLogPath(): string
    {
        $dir = dirname(__DIR__, 2) . '/storage/logs';
        if (!is_dir($dir)) {
            mkdir($dir, 0777, true);
        }
        return $dir . '/oitoto.log';
    }

    public static function info(string $message, array $context = []): void
    {
        self::write('INFO', $message, $context);
    }

    public static function error(string $message, array $context = []): void
    {
        self::write('ERROR', $message, $context);
    }

    public static function exception(Throwable $e, array $context = []): void
    {
        $context['file'] = $e->getFile();
        $context['line'] = $e->getLine();
        $context['trace'] = $e->getTraceAsString();
        self::write('EXCEPTION', $e->getMessage(), $context);
    }

    private static function write(string $level, string $message, array $context): void
    {
        $timestamp = date('Y-m-d H:i:s');
        $contextStr = !empty($context) ? ' ' . json_encode($context, JSON_UNESCAPED_SLASHES) : '';
        $entry = "[{$timestamp}] [{$level}] {$message}{$contextStr}" . PHP_EOL;
        @file_put_contents(self::getLogPath(), $entry, FILE_APPEND);
    }

    public static function audit(?int $adminId, string $action, string $entityType, ?int $entityId = null, ?array $oldVals = null, ?array $newVals = null): void
    {
        try {
            $db = Database::getConnection();
            $stmt = $db->prepare("
                INSERT INTO audit_logs (admin_id, action, entity_type, entity_id, old_values, new_values, ip_address, user_agent)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $ip = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
            $ua = $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';
            $stmt->execute([
                $adminId,
                $action,
                $entityType,
                $entityId,
                $oldVals ? json_encode($oldVals) : null,
                $newVals ? json_encode($newVals) : null,
                $ip,
                $ua
            ]);
        } catch (\Exception $e) {
            self::error("Failed to write audit log: " . $e->getMessage());
        }
    }
}
