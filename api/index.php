<?php
declare(strict_types=1);

// =====================================================================
// OI TOTO! — PAN-INDIA E-RICKSHAW BOOKING PLATFORM REST API ENGINE
// =====================================================================

require_once dirname(__DIR__) . '/backend/src/Core/Autoloader.php';
\OiToto\Core\Autoloader::register();

use OiToto\Core\Config;
use OiToto\Core\Request;
use OiToto\Core\Response;
use OiToto\Core\Router;
use OiToto\Middleware\AuthMiddleware;
use OiToto\Middleware\CorsMiddleware;
use OiToto\Middleware\RateLimitMiddleware;
use OiToto\Middleware\RoleMiddleware;

use OiToto\Controllers\AuthController;
use OiToto\Controllers\CustomerController;
use OiToto\Controllers\DriverController;
use OiToto\Controllers\VehicleController;
use OiToto\Controllers\ServiceAreaController;
use OiToto\Controllers\FareController;
use OiToto\Controllers\BookingController;
use OiToto\Controllers\PaymentController;
use OiToto\Controllers\ReviewController;
use OiToto\Controllers\SupportController;
use OiToto\Controllers\AdminController;

// Load .env
Config::load(dirname(__DIR__) . '/backend/.env');

// Handle CORS
$cors = new CorsMiddleware();
$request = new Request();
$cors->handle($request);

// Router
$router = new Router();

// Health check / root
$router->get('/', function() {
    Response::success([
        'brand' => 'Oi Toto! — Pan-India E-Rickshaw Booking Platform',
        'tagline' => 'Tap. Book. Cholo!',
        'vehicle_type' => 'Electric Rickshaw (E-Rickshaw)',
        'version' => '1.0.0',
        'status' => 'operational',
        'server_time' => date('c')
    ], 'Oi Toto API Server is running.');
});

// Group: API v1
$router->group('/api/v1', function(Router $r) {

    // API v1 Index / Info
    $r->get('/', function() {
        Response::success([
            'api_version' => 'v1',
            'status' => 'active',
            'endpoints' => [
                'health_check' => 'GET /',
                'vehicles' => 'GET /api/v1/vehicles',
                'service_areas' => 'GET /api/v1/service-areas',
                'fare_rules' => 'GET /api/v1/fare/rules',
                'nearby_totos' => 'GET /api/v1/bookings/nearby-totos',
                'admin_login' => 'POST /api/v1/auth/admin-login',
                'request_otp' => 'POST /api/v1/auth/request-otp'
            ]
        ], 'Oi Toto API v1 is operational and connected to MySQL database.');
    });

    // --- AUTHENTICATION MODULE ---
    $r->post('/auth/request-otp', [AuthController::class, 'requestOtp'], [RateLimitMiddleware::limit(10, 60)]);
    $r->post('/auth/verify-otp', [AuthController::class, 'verifyOtp'], [RateLimitMiddleware::limit(10, 60)]);
    $r->post('/auth/admin-login', [AuthController::class, 'adminLogin']);
    $r->get('/auth/me', [AuthController::class, 'me'], [AuthMiddleware::class]);

    // --- CUSTOMER PROFILE ---
    $r->get('/customer/profile', [CustomerController::class, 'getProfile'], [AuthMiddleware::class]);
    $r->put('/customer/profile', [CustomerController::class, 'updateProfile'], [AuthMiddleware::class]);
    $r->post('/customer/emergency-contacts', [CustomerController::class, 'updateEmergencyContact'], [AuthMiddleware::class]);
    $r->post('/customer/saved-locations', [CustomerController::class, 'updateSavedPlaces'], [AuthMiddleware::class]);

    // --- DRIVER PROFILE & FLEET TELEMETRY ---
    $r->get('/driver/profile', [DriverController::class, 'getProfile'], [AuthMiddleware::class]);
    $r->put('/driver/profile', [DriverController::class, 'updateProfile'], [AuthMiddleware::class]);
    $r->post('/driver/toggle-online', [DriverController::class, 'toggleOnline'], [AuthMiddleware::class]);
    $r->post('/driver/location', [DriverController::class, 'updateLocation'], [AuthMiddleware::class]);
    $r->post('/driver/upload-document', [DriverController::class, 'uploadDocument'], [AuthMiddleware::class]);
    $r->get('/driver/documents', [DriverController::class, 'getDocuments'], [AuthMiddleware::class]);
    $r->get('/driver/earnings', [DriverController::class, 'getEarnings'], [AuthMiddleware::class]);
    $r->get('/driver/wallet', [DriverController::class, 'getWallet'], [AuthMiddleware::class]);
    $r->post('/driver/payout-request', [DriverController::class, 'requestPayout'], [AuthMiddleware::class]);

    // --- VEHICLE FLEET MANAGEMENT ---
    $r->get('/vehicles', [VehicleController::class, 'index']);
    $r->get('/vehicles/{id}', [VehicleController::class, 'show']);
    $r->post('/vehicles', [VehicleController::class, 'store'], [AuthMiddleware::class]);
    $r->post('/vehicles/{id}/assign-driver', [VehicleController::class, 'assignDriver'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin', 'owner')]);

    // --- SERVICE AREAS & ZONING ---
    $r->get('/service-areas', [ServiceAreaController::class, 'index']);
    $r->get('/service-areas/{id}', [ServiceAreaController::class, 'show']);
    $r->post('/service-areas', [ServiceAreaController::class, 'store'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->put('/service-areas/{id}', [ServiceAreaController::class, 'update'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->delete('/service-areas/{id}', [ServiceAreaController::class, 'destroy'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);

    // --- FARE CALCULATION ENGINE ---
    $r->post('/fare/estimate', [FareController::class, 'estimate']);
    $r->get('/fare/rules', [FareController::class, 'rules']);
    $r->put('/fare/rules/{id}', [FareController::class, 'updateRule'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);

    // --- BOOKING LIFECYCLE & DRIVER MATCHING ---
    $r->get('/bookings/nearby-totos', [BookingController::class, 'nearbyTotos']);
    $r->post('/bookings/estimate-and-create', [BookingController::class, 'estimateAndCreate'], [AuthMiddleware::class]);
    $r->get('/bookings/active', [BookingController::class, 'activeBooking'], [AuthMiddleware::class]);
    $r->get('/bookings/history', [BookingController::class, 'history'], [AuthMiddleware::class]);
    $r->get('/bookings/{id}', [BookingController::class, 'show'], [AuthMiddleware::class]);

    // Driver trip execution steps
    $r->post('/bookings/{id}/accept', [BookingController::class, 'accept'], [AuthMiddleware::class, RoleMiddleware::allow('driver')]);
    $r->post('/bookings/{id}/arrived', [BookingController::class, 'arrived'], [AuthMiddleware::class, RoleMiddleware::allow('driver')]);
    $r->post('/bookings/{id}/start-trip', [BookingController::class, 'startTrip'], [AuthMiddleware::class, RoleMiddleware::allow('driver')]);
    $r->post('/bookings/{id}/complete-trip', [BookingController::class, 'completeTrip'], [AuthMiddleware::class, RoleMiddleware::allow('driver')]);
    $r->post('/bookings/{id}/cancel', [BookingController::class, 'cancel'], [AuthMiddleware::class]);

    // --- PAYMENT GATEWAY & CASH ---
    $r->post('/payments/create-order', [PaymentController::class, 'createOrder'], [AuthMiddleware::class]);
    $r->post('/payments/verify-signature', [PaymentController::class, 'verifyPayment'], [AuthMiddleware::class]);
    $r->post('/payments/cash-collected', [PaymentController::class, 'cashCollected'], [AuthMiddleware::class, RoleMiddleware::allow('driver')]);

    // --- RATINGS & REVIEWS ---
    $r->post('/reviews', [ReviewController::class, 'store'], [AuthMiddleware::class]);
    $r->get('/reviews/driver/{id}', [ReviewController::class, 'driverReviews']);

    // --- CUSTOMER SUPPORT, INCIDENTS & SOS ---
    $r->post('/support/complaints', [SupportController::class, 'createComplaint'], [AuthMiddleware::class]);
    $r->post('/support/sos', [SupportController::class, 'sosAlert'], [AuthMiddleware::class]);
    $r->get('/support/notifications', [SupportController::class, 'notifications'], [AuthMiddleware::class]);

    // --- SUPER ADMIN PORTAL APIS ---
    $r->get('/admin/dashboard-stats', [AdminController::class, 'dashboardStats'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->get('/admin/drivers', [AdminController::class, 'drivers'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->post('/admin/drivers/{id}/verify', [AdminController::class, 'verifyDriver'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->delete('/admin/drivers/{id}', [AdminController::class, 'deleteDriver'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->post('/admin/drivers/{id}/delete', [AdminController::class, 'deleteDriver'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->post('/admin/documents/{id}/verify', [AdminController::class, 'verifyDocument'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->post('/admin/vehicles/{id}/verify', [AdminController::class, 'verifyVehicle'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->get('/admin/bookings', [AdminController::class, 'bookings'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->get('/admin/settlements', [AdminController::class, 'settlements'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->post('/admin/payouts/{id}/process', [AdminController::class, 'processPayout'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->get('/admin/complaints', [AdminController::class, 'complaints'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->post('/admin/complaints/{id}/resolve', [AdminController::class, 'resolveComplaint'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->get('/admin/audit-logs', [AdminController::class, 'auditLogs'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->get('/admin/customers', [AdminController::class, 'customers'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
    $r->get('/admin/customers/{id}', [AdminController::class, 'customerDetails'], [AuthMiddleware::class, RoleMiddleware::allow('admin', 'super_admin')]);
});

// Dispatch request
$router->dispatch($request);
