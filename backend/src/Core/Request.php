<?php
declare(strict_types=1);

namespace OiToto\Core;

class Request
{
    private string $method;
    private string $uri;
    private string $path;
    private array $queryParams;
    private array $body;
    private array $headers;
    private array $files;
    private array $routeParams = [];
    private ?array $user = null;

    public function __construct()
    {
        $this->method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
        $this->uri = $_SERVER['REQUEST_URI'] ?? '/';
        $this->path = parse_url($this->uri, PHP_URL_PATH) ?? '/';
        $this->queryParams = $_GET;
        $this->files = $_FILES;
        $this->headers = $this->extractHeaders();
        $this->body = $this->extractBody();
    }

    private function extractHeaders(): array
    {
        $headers = [];
        foreach ($_SERVER as $key => $value) {
            if (str_starts_with($key, 'HTTP_')) {
                $name = str_replace('_', '-', strtolower(substr($key, 5)));
                $headers[$name] = $value;
            } elseif (in_array($key, ['CONTENT_TYPE', 'CONTENT_LENGTH'], true)) {
                $name = str_replace('_', '-', strtolower($key));
                $headers[$name] = $value;
            }
        }
        return $headers;
    }

    private function extractBody(): array
    {
        $contentType = $this->getHeader('content-type') ?? '';
        if (str_contains(strtolower($contentType), 'application/json')) {
            $raw = file_get_contents('php://input');
            if (!empty($raw)) {
                $decoded = json_decode($raw, true);
                if (is_array($decoded)) {
                    return $decoded;
                }
            }
            return [];
        }

        return $_POST;
    }

    public function getMethod(): string
    {
        return $this->method;
    }

    public function getPath(): string
    {
        return $this->path;
    }

    public function getHeader(string $name, ?string $default = null): ?string
    {
        $key = strtolower($name);
        return $this->headers[$key] ?? $default;
    }

    public function getBearerToken(): ?string
    {
        $auth = $this->getHeader('authorization');
        if (!$auth) {
            $auth = $this->getHeader('x-authorization') ?? $this->getHeader('x-admin-token');
        }
        if (!$auth && isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $auth = $_SERVER['HTTP_AUTHORIZATION'];
        }
        if (!$auth && isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
            $auth = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        }
        if (!$auth && function_exists('apache_request_headers')) {
            $apacheHeaders = apache_request_headers();
            $auth = $apacheHeaders['Authorization'] ?? $apacheHeaders['authorization'] ?? $apacheHeaders['X-Authorization'] ?? $apacheHeaders['x-authorization'] ?? null;
        }
        if (!$auth && function_exists('getallheaders')) {
            $allHeaders = getallheaders();
            $auth = $allHeaders['Authorization'] ?? $allHeaders['authorization'] ?? $allHeaders['X-Authorization'] ?? $allHeaders['x-authorization'] ?? null;
        }
        if (!$auth) {
            $auth = $this->get('token') ?? $this->queryParams['token'] ?? null;
        }
        if ($auth) {
            if (preg_match('/Bearer\s+(.*)$/i', $auth, $matches)) {
                return trim($matches[1]);
            }
            return trim($auth);
        }
        return null;
    }

    public function get(string $key, mixed $default = null): mixed
    {
        return $this->body[$key] ?? $this->queryParams[$key] ?? $default;
    }

    public function all(): array
    {
        return array_merge($this->queryParams, $this->body);
    }

    public function getQueryParams(): array
    {
        return $this->queryParams;
    }

    public function getFiles(): array
    {
        return $this->files;
    }

    public function getFile(string $key): ?array
    {
        return $this->files[$key] ?? null;
    }

    public function setRouteParams(array $params): void
    {
        $this->routeParams = $params;
    }

    public function param(string $key, mixed $default = null): mixed
    {
        return $this->routeParams[$key] ?? $default;
    }

    public function setUser(?array $user): void
    {
        $this->user = $user;
    }

    public function getUser(): ?array
    {
        return $this->user;
    }

    public function getIp(): string
    {
        if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
            $list = explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']);
            return trim($list[0]);
        }
        return $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
    }

    public function getUserAgent(): string
    {
        return $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';
    }
}
