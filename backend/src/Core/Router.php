<?php
declare(strict_types=1);

namespace OiToto\Core;

use Throwable;

class Router
{
    private array $routes = [];
    private array $middlewares = [];
    private string $currentPrefix = '';

    public function group(string $prefix, callable $callback, array $middlewares = []): void
    {
        $prevPrefix = $this->currentPrefix;
        $prevMiddlewares = $this->middlewares;

        $this->currentPrefix .= '/' . trim($prefix, '/');
        $this->middlewares = array_merge($this->middlewares, $middlewares);

        $callback($this);

        $this->currentPrefix = $prevPrefix;
        $this->middlewares = $prevMiddlewares;
    }

    public function add(string $method, string $path, mixed $handler, array $middlewares = []): void
    {
        $fullPath = rtrim($this->currentPrefix . '/' . trim($path, '/'), '/');
        if ($fullPath === '') {
            $fullPath = '/';
        }

        $allMiddlewares = array_merge($this->middlewares, $middlewares);

        $this->routes[] = [
            'method' => strtoupper($method),
            'path' => $fullPath,
            'handler' => $handler,
            'middlewares' => $allMiddlewares,
            'pattern' => $this->compilePattern($fullPath)
        ];
    }

    public function get(string $path, mixed $handler, array $middlewares = []): void
    {
        $this->add('GET', $path, $handler, $middlewares);
    }

    public function post(string $path, mixed $handler, array $middlewares = []): void
    {
        $this->add('POST', $path, $handler, $middlewares);
    }

    public function put(string $path, mixed $handler, array $middlewares = []): void
    {
        $this->add('PUT', $path, $handler, $middlewares);
    }

    public function delete(string $path, mixed $handler, array $middlewares = []): void
    {
        $this->add('DELETE', $path, $handler, $middlewares);
    }

    public function options(string $path, mixed $handler, array $middlewares = []): void
    {
        $this->add('OPTIONS', $path, $handler, $middlewares);
    }

    private function compilePattern(string $path): string
    {
        $pattern = preg_replace('/\{([a-zA-Z0-9_]+)\}/', '(?P<$1>[^/]+)', $path);
        return '#^' . $pattern . '$#';
    }

    public function dispatch(Request $request): void
    {
        $requestMethod = $request->getMethod();
        $requestPath = rtrim($request->getPath(), '/');
        if ($requestPath === '') {
            $requestPath = '/';
        }

        // Handle preflight OPTIONS
        if ($requestMethod === 'OPTIONS') {
            http_response_code(200);
            exit;
        }

        foreach ($this->routes as $route) {
            if ($route['method'] !== $requestMethod) {
                continue;
            }

            if (preg_match($route['pattern'], $requestPath, $matches)) {
                $params = [];
                foreach ($matches as $key => $val) {
                    if (is_string($key)) {
                        $params[$key] = $val;
                    }
                }
                $request->setRouteParams($params);

                try {
                    // Run middlewares
                    foreach ($route['middlewares'] as $mw) {
                        if (is_callable($mw)) {
                            $res = $mw($request);
                            if ($res === false) {
                                return;
                            }
                        } elseif (is_string($mw) && class_exists($mw)) {
                            $instance = new $mw();
                            if (method_exists($instance, 'handle')) {
                                $res = $instance->handle($request);
                                if ($res === false) {
                                    return;
                                }
                            }
                        }
                    }

                    // Execute Handler
                    $handler = $route['handler'];
                    if (is_callable($handler)) {
                        $handler($request);
                        return;
                    }

                    if (is_array($handler) && count($handler) === 2) {
                        [$controllerClass, $action] = $handler;
                        if (!class_exists($controllerClass)) {
                            Response::error("Controller {$controllerClass} not found", 500);
                            return;
                        }
                        $controller = new $controllerClass();
                        if (!method_exists($controller, $action)) {
                            Response::error("Action {$action} not found in {$controllerClass}", 500);
                            return;
                        }
                        $controller->$action($request);
                        return;
                    }
                } catch (Throwable $e) {
                    Logger::exception($e, ['path' => $requestPath, 'method' => $requestMethod]);
                    $debug = Config::getBool('APP_DEBUG', false);
                    Response::error(
                        $debug ? $e->getMessage() : 'An unexpected internal server error occurred.',
                        500,
                        $debug ? ['file' => $e->getFile(), 'line' => $e->getLine()] : null
                    );
                    return;
                }
            }
        }

        // Route Not Found
        Response::error("Route not found: {$requestMethod} {$requestPath}", 404);
    }
}
