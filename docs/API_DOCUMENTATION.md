# 📡 Oi Toto! — REST API Documentation

**Base URL:** `http://localhost:8000/api/v1` (or your domain in production)  
**Authentication Scheme:** HTTP Bearer Token (`Authorization: Bearer <JWT_TOKEN>`)  
**Format:** `application/json` (UTF-8)

---

## 1. Authentication Endpoints

### 1.1 Request OTP
Generate and dispatch a 6-digit cryptographic verification code to a mobile number.
- **Method:** `POST`
- **Endpoint:** `/auth/request-otp`
- **Rate Limit:** 10 requests / 60 seconds

**Request Body:**
```json
{
  "phone": "9876543210",
  "role": "customer" // "customer" or "driver"
}
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "OTP sent successfully to your mobile number.",
  "data": {
    "phone": "9876543210",
    "expires_in_seconds": 300,
    "sandbox_otp": "877453" // Available in sandbox/development mode
  },
  "timestamp": "2026-10-15T21:00:00+05:30"
}
```

---

### 1.2 Verify OTP
Verify the 6-digit OTP, automatically provision an account if new, and issue a signed JWT token.
- **Method:** `POST`
- **Endpoint:** `/auth/verify-otp`

**Request Body:**
```json
{
  "phone": "9876543210",
  "otp": "877453",
  "role": "customer",
  "full_name": "Rishit Ganguly"
}
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Logged in successfully.",
  "data": {
    "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "user": {
      "id": 8,
      "phone": "9876543210",
      "full_name": "Rishit Ganguly",
      "email": null,
      "role": "customer",
      "status": "active",
      "language": "en"
    },
    "profile": {
      "id": 5,
      "rating_avg": 5.0
    }
  }
}
```

---

### 1.3 Super Admin Login
- **Method:** `POST`
- **Endpoint:** `/auth/admin-login`

**Request Body:**
```json
{
  "phone_or_email": "9876543210",
  "password": "Admin@OiToto2026"
}
```

---

## 2. Customer Endpoints

### 2.1 Get Customer Profile
- **Method:** `GET`
- **Endpoint:** `/customer/profile`
- **Headers:** `Authorization: Bearer <TOKEN>`

---

### 2.2 Update Saved Places
- **Method:** `POST`
- **Endpoint:** `/customer/saved-locations`

**Request Body:**
```json
{
  "home_address": "Shyambazar Five Point, Kolkata",
  "home_lat": 22.6038,
  "home_lng": 88.3713,
  "work_address": "College Street Coffee House, Kolkata",
  "work_lat": 22.5754,
  "work_lng": 88.3639
}
```

---

## 3. Booking & Dispatch Endpoints

### 3.1 Nearby Available E-Rickshaws
Discover active, online E-Rickshaw drivers within a search radius.
- **Method:** `GET`
- **Endpoint:** `/bookings/nearby-totos?pickup_lat=22.5726&pickup_lng=88.3639&radius_km=4.0`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "driver_id": 1,
      "driver_name": "Subhash Das",
      "driver_phone": "9831100001",
      "vehicle_number": "WB-01-E-1001",
      "brand_make": "Mayuri Grand EV",
      "ownership_type": "company_owned",
      "current_lat": 22.5732,
      "current_lng": 88.3645,
      "rating_avg": 4.9,
      "distance_to_pickup_km": 0.09,
      "estimated_pickup_mins": 3
    }
  ]
}
```

---

### 3.2 Fare Estimate Calculation
- **Method:** `POST`
- **Endpoint:** `/fare/estimate`

**Request Body:**
```json
{
  "pickup_lat": 22.6038,
  "pickup_lng": 88.3713,
  "drop_lat": 22.5942,
  "drop_lng": 88.3710,
  "promo_code": "CHOLO50"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "base_fare_charged": 20.00,
    "distance_km": 1.07,
    "base_distance_km": 1.5,
    "per_km_rate": 10.0,
    "distance_fare_charged": 0.0,
    "waiting_fare_charged": 0.0,
    "is_night_surge": false,
    "subtotal": 20.0,
    "applied_promo": "CHOLO50",
    "discount_amount": 10.0,
    "final_fare": 20.0,
    "platform_commission_amount": 2.0,
    "driver_earnings_amount": 18.0,
    "estimated_duration_mins": 4
  }
}
```

---

### 3.3 Create Booking Request
- **Method:** `POST`
- **Endpoint:** `/bookings/estimate-and-create`
- **Headers:** `Authorization: Bearer <TOKEN>`

**Request Body:**
```json
{
  "pickup_address": "Shyambazar Metro Gate 1",
  "pickup_lat": 22.6038,
  "pickup_lng": 88.3713,
  "drop_address": "Hatibagan Market Crossing",
  "drop_lat": 22.5942,
  "drop_lng": 88.3710,
  "payment_mode": "cash" // or "upi"
}
```

**Response:**
```json
{
  "success": true,
  "message": "E-Rickshaw requested! Searching for nearby available drivers...",
  "data": {
    "booking_id": 5,
    "booking_code": "OT-20261015-A1B2",
    "start_otp": "4821",
    "estimated_fare": 20.0,
    "estimated_distance_km": 1.07,
    "status": "requested",
    "nearby_drivers_notified": 2
  }
}
```

---

### 3.4 Driver Atomic Acceptance
First driver to accept locks the booking row atomically via database transaction.
- **Method:** `POST`
- **Endpoint:** `/bookings/{id}/accept`
- **Headers:** `Authorization: Bearer <DRIVER_TOKEN>`

---

### 3.5 Mark Arrived at Pickup
- **Method:** `POST`
- **Endpoint:** `/bookings/{id}/arrived`
- **Headers:** `Authorization: Bearer <DRIVER_TOKEN>`

---

### 3.6 Start Trip (Verify 4-Digit OTP)
- **Method:** `POST`
- **Endpoint:** `/bookings/{id}/start-trip`
- **Headers:** `Authorization: Bearer <DRIVER_TOKEN>`

**Request Body:**
```json
{
  "otp": "4821"
}
```

---

### 3.7 Complete Trip & Generate Receipt
- **Method:** `POST`
- **Endpoint:** `/bookings/{id}/complete-trip`
- **Headers:** `Authorization: Bearer <DRIVER_TOKEN>`

**Request Body:**
```json
{
  "actual_distance_km": 1.15,
  "waiting_duration_mins": 2
}
```

---

### 3.8 Cash Collection Confirmation
- **Method:** `POST`
- **Endpoint:** `/payments/cash-collected`
- **Headers:** `Authorization: Bearer <DRIVER_TOKEN>`

**Request Body:**
```json
{
  "booking_id": 5,
  "amount": 20.0
}
```

---

## 4. Driver Partner Controls

### 4.1 Toggle Online / Offline
- **Method:** `POST`
- **Endpoint:** `/driver/toggle-online`
- **Headers:** `Authorization: Bearer <DRIVER_TOKEN>`

**Request Body:**
```json
{
  "is_online": 1
}
```

---

### 4.2 Stream GPS Telemetry
- **Method:** `POST`
- **Endpoint:** `/driver/location`
- **Headers:** `Authorization: Bearer <DRIVER_TOKEN>`

**Request Body:**
```json
{
  "latitude": 22.5732,
  "longitude": 88.3645,
  "heading": 45.0,
  "speed_kmh": 16.5,
  "battery_percentage": 88
}
```

---

### 4.3 Payout Request
- **Method:** `POST`
- **Endpoint:** `/driver/payout-request`
- **Headers:** `Authorization: Bearer <DRIVER_TOKEN>`

**Request Body:**
```json
{
  "amount": 500.0,
  "payout_method": "upi_vpa",
  "upi_id": "driver@okaxis"
}
```

---

## 5. Super Admin Endpoints

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/admin/dashboard-stats` | Comprehensive platform stats, fleet counts, revenues |
| `GET` | `/admin/drivers` | Filter drivers by status (`pending_review`, `verified_active`) |
| `POST` | `/admin/drivers/{id}/verify` | Approve or reject driver application |
| `POST` | `/admin/documents/{id}/verify` | Approve or reject uploaded KYC documents |
| `GET` | `/vehicles` | List all company-owned and independent E-Rickshaws |
| `POST` | `/vehicles` | Register a new electric rickshaw |
| `POST` | `/vehicles/{id}/assign-driver` | Assign vehicle to an approved driver |
| `GET` | `/service-areas` | List Pan-India operating zones and cities |
| `POST` | `/service-areas` | Add a new service area / town corridor |
| `GET` | `/fare/rules` | Inspect fare formulas per service area |
| `PUT` | `/fare/rules/{id}` | Update base fare, per-km rates, night surge |
| `GET` | `/admin/settlements` | Review driver withdrawal requests |
| `POST` | `/admin/payouts/{id}/process` | Approve / mark completed / reject payout |
| `GET` | `/admin/complaints` | Review customer disputes and safety SOS tickets |
| `POST` | `/admin/complaints/{id}/resolve` | Resolve dispute with administrative notes |
| `GET` | `/admin/audit-logs` | Tamper-proof security audit log |
