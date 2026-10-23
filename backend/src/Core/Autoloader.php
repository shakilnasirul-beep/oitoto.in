<?php
declare(strict_types=1);

namespace OiToto\Core;

class Autoloader
{
    public static function register(): void
    {
        spl_autoload_register(function (string $class) {
            $prefix = 'OiToto\\';
            $baseDir = dirname(__DIR__) . DIRECTORY_SEPARATOR;

            $len = strlen($prefix);
            if (strncmp($prefix, $class, $len) !== 0) {
                return;
            }

            $relativeClass = substr($class, $len);
            $file = $baseDir . str_replace('\\', DIRECTORY_SEPARATOR, $relativeClass) . '.php';

            if (file_exists($file)) {
                require_once $file;
            }
        });
    }
}
