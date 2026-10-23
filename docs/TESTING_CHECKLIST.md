# 🧪 Oi Toto! — Quality Assurance & Testing Checklist

---

## 1. Automated Test Suite Execution

Run the built-in automated backend test suite:
```bash
C:\php82\php.exe G:\oitoto\backend\tests\test_api.php
```

### Automated Assertions Matrix
| # | Test Case | Target Service / Logic | Expected Output | Status |
| :-: | :--- | :--- | :--- | :-: |
| 1 | MySQL Connection | `Core\Database` | Connected to `oitoto_db` | **PASS** |
| 2 | E-Rickshaw Fare Formula | `Services\FareCalculatorService` | Base ₹20 + ₹10/km, 10% commission | **PASS** |
| 3 | Haversine Distance Math | `Services\LocationService` | Accurate spatial distance within 0.1 km | **PASS** |
| 4 | Cryptographic OTP Generation | `Services\OtpService` | 6-digit random code + Sandbox support | **PASS** |
| 5 | OTP Verification & JWT | `Core\Auth` | Valid token issued, role assigned | **PASS** |
| 6 | JWT Signature & Expiry | `Core\Auth` | HMAC-SHA256 signature verified | **PASS** |
| 7 | Driver Spatial Discovery | `Services\MatchingService` | Finds online, unbusy E-Rickshaws | **PASS** |
| 8 | Trip Request Creation | `Controllers\BookingController` | Booking row created, 4-digit OTP issued | **PASS** |
| 9 | Atomic Driver Acceptance | `Services\MatchingService` | Row updated, driver marked busy | **PASS** |
| 10 | Concurrency Lock Protection | `Services\MatchingService` | Second driver rejected (Race condition prevented) | **PASS** |
| 11 | Driver Arrival at Pickup | `Controllers\BookingController` | Status transitions to `arrived` | **PASS** |
| 12 | 4-Digit Ride OTP Verification | `Controllers\BookingController` | Trip unlocks only with correct rider OTP | **PASS** |
| 13 | Trip Completion & Receipt | `Controllers\BookingController` | Final fare computed, driver freed | **PASS** |
| 14 | Cash Reconciliation & Ledger | `Services\PaymentService` | 10% platform fee debited from wallet | **PASS** |

---

## 2. Customer App Manual QA Checklist

- [x] **Splash Screen:** Official Oi Toto logo rendered cleanly without distortion.
- [x] **Onboarding Carousel:** 3 slides on E-Rickshaw benefits, fares, and safety swipe smoothly.
- [x] **Trilingual Switch:** English, Bengali (বাংলা), and Hindi (हिन्दी) switch instantly without restarts.
- [x] **Phone Input:** Auto +91 prefix, 10-digit validation.
- [x] **OTP Screen:** Auto countdown timer, sandbox auto-fill during demo mode.
- [x] **Home Map Screen:** Map renders pickup point and nearby online E-Rickshaws (`🛺`).
- [x] **Destination Selection:** Quick chips (Metro, Railway, Market) and custom pin drops update fare in real time.
- [x] **Active Trip Screen:** Live driver name, Mayuri EV make, plate number, call button.
- [x] **Ride Start OTP:** Prominently displays 4-digit code with safety instructions.
- [x] **Emergency SOS:** Triggers 112 helpline and notifies registered family contact.
- [x] **Digital Receipt & Rating:** 5-star rating, tag pills ("Clean E-Rickshaw", "Polite Driver"), comment submission.

---

## 3. Driver Partner App Manual QA Checklist

- [x] **Driver Sign In:** Dedicated driver authentication and role verification.
- [x] **Online/Offline Switch:** Toggle updates live status in backend. Prevents unverified drivers from going online.
- [x] **Incoming Ride Radar Dialog:** Shows pickup address, trip distance, fare, and payment mode.
- [x] **Atomic Acceptance:** First driver to accept gets the ride; simultaneous taps gracefully display rejection notice.
- [x] **Pickup Arrival Button:** Notifies rider that Toto has arrived at pickup point.
- [x] **Ride OTP Verification:** Trip will NOT start until driver inputs the 4-digit OTP from passenger.
- [x] **Trip Completion:** Accurately calculates actual distance and waiting charges.
- [x] **Cash Collection:** Displays exact amount to collect from passenger and settles 10% platform fee in wallet.
- [x] **KYC Documents:** Upload Driving License, RC, Aadhaar, Insurance with status badges (`pending`, `approved`, `rejected`).
- [x] **Wallet & Payouts:** Requests instant UPI withdrawal for balance above ₹100.

---

## 4. Admin Panel QA Checklist

- [x] **Dashboard Stats:** Real-time counters for active rides, online Totos, completed trips, platform commission.
- [x] **Live Fleet Radar Map:** Shows online drivers on Leaflet map across Kolkata, Howrah, and Siliguri.
- [x] **Driver Approvals:** Review new driver applications, approve or reject KYC documents.
- [x] **Fleet Inventory:** Register company-owned vs independent driver-owned electric rickshaws.
- [x] **Service Zones:** Manage operational corridors, radius boundaries, and maximum search radiuses.
- [x] **Fare Engine Config:** Update base fares, per-km rates, waiting charges, and night surge multipliers per zone.
- [x] **Settlements & Payouts:** Process driver UPI withdrawal requests with transaction references.
- [x] **Safety & Complaints:** Review rider dispute tickets and emergency SOS incident logs.
- [x] **Audit Trail:** View tamper-proof administrative log records.
