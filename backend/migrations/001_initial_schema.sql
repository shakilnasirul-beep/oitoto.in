-- =====================================================================
-- OI TOTO! — PAN-INDIA E-RICKSHAW BOOKING PLATFORM DATABASE SCHEMA
-- Target Engine: MySQL 8.0+ / MariaDB 10.4+
-- Charset: utf8mb4 (Supports multilingual English, Hindi, Bengali)
-- =====================================================================

CREATE DATABASE IF NOT EXISTS `oitoto_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `oitoto_db`;

SET FOREIGN_KEY_CHECKS = 0;

-- 1. USERS TABLE (Core Authentication & Role Management)
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `phone` VARCHAR(15) NOT NULL UNIQUE,
    `full_name` VARCHAR(120) NOT NULL,
    `email` VARCHAR(150) NULL,
    `role` ENUM('customer', 'driver', 'owner', 'admin', 'super_admin') NOT NULL DEFAULT 'customer',
    `status` ENUM('active', 'pending', 'suspended', 'deactivated') NOT NULL DEFAULT 'active',
    `language` VARCHAR(10) NOT NULL DEFAULT 'en', -- en, hi, bn
    `avatar_url` VARCHAR(255) NULL,
    `fcm_token` VARCHAR(255) NULL,
    `otp_code` VARCHAR(10) NULL,
    `otp_expires_at` DATETIME NULL,
    `otp_attempts` INT NOT NULL DEFAULT 0,
    `password_hash` VARCHAR(255) NULL, -- For admin users
    `last_login_at` DATETIME NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_users_phone` (`phone`),
    INDEX `idx_users_role_status` (`role`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. CUSTOMER PROFILES
DROP TABLE IF EXISTS `customer_profiles`;
CREATE TABLE `customer_profiles` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL UNIQUE,
    `emergency_contact_name` VARCHAR(120) NULL,
    `emergency_contact_phone` VARCHAR(15) NULL,
    `home_address` VARCHAR(255) NULL,
    `home_lat` DECIMAL(10, 8) NULL,
    `home_lng` DECIMAL(11, 8) NULL,
    `work_address` VARCHAR(255) NULL,
    `work_lat` DECIMAL(10, 8) NULL,
    `work_lng` DECIMAL(11, 8) NULL,
    `rating_avg` DECIMAL(3, 2) NOT NULL DEFAULT 5.00,
    `total_rides` INT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_cust_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. VEHICLE OWNERS (Company or Fleet or Individual)
DROP TABLE IF EXISTS `vehicle_owners`;
CREATE TABLE `vehicle_owners` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `business_name` VARCHAR(150) NOT NULL,
    `owner_type` ENUM('company_owned', 'independent_owner', 'fleet_operator') NOT NULL DEFAULT 'company_owned',
    `pan_number` VARCHAR(20) NULL,
    `gst_number` VARCHAR(30) NULL,
    `bank_account_no` VARCHAR(40) NULL,
    `bank_ifsc` VARCHAR(20) NULL,
    `bank_name` VARCHAR(100) NULL,
    `is_verified` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_owner_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. SERVICE AREAS (Zoning, Cities, Districts, Towns)
DROP TABLE IF EXISTS `service_areas`;
CREATE TABLE `service_areas` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(150) NOT NULL,
    `state` VARCHAR(100) NOT NULL,
    `city` VARCHAR(100) NOT NULL,
    `center_lat` DECIMAL(10, 8) NOT NULL,
    `center_lng` DECIMAL(11, 8) NOT NULL,
    `radius_km` DECIMAL(6, 2) NOT NULL DEFAULT 15.00,
    `boundary_geojson` JSON NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `max_search_radius_km` DECIMAL(5, 2) NOT NULL DEFAULT 4.00,
    `legal_compliance_status` ENUM('approved', 'pending_approval', 'suspended') NOT NULL DEFAULT 'approved',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_service_area_city` (`city`, `state`, `is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. VEHICLES (E-Rickshaw Fleet Details)
DROP TABLE IF EXISTS `vehicles`;
CREATE TABLE `vehicles` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `owner_id` BIGINT UNSIGNED NULL,
    `vehicle_number` VARCHAR(30) NOT NULL UNIQUE,
    `registration_certificate_no` VARCHAR(50) NULL,
    `vehicle_type` ENUM('e_rickshaw', 'e_loader', 'e_cart') NOT NULL DEFAULT 'e_rickshaw',
    `brand_make` VARCHAR(100) NOT NULL DEFAULT 'Mayuri EV',
    `model_year` INT NOT NULL DEFAULT 2024,
    `battery_type` ENUM('lithium_ion', 'lead_acid') NOT NULL DEFAULT 'lithium_ion',
    `ownership_type` ENUM('company_owned', 'driver_owned', 'fleet_owned') NOT NULL DEFAULT 'company_owned',
    `seating_capacity` INT NOT NULL DEFAULT 4,
    `color` VARCHAR(50) NOT NULL DEFAULT 'Green and Yellow',
    `current_driver_id` BIGINT UNSIGNED NULL,
    `service_area_id` BIGINT UNSIGNED NULL,
    `status` ENUM('pending_verification', 'approved', 'rejected', 'maintenance', 'inactive') NOT NULL DEFAULT 'pending_verification',
    `fitness_expiry` DATE NULL,
    `insurance_expiry` DATE NULL,
    `permit_expiry` DATE NULL,
    `rc_photo_path` VARCHAR(255) NULL,
    `vehicle_photo_front` VARCHAR(255) NULL,
    `vehicle_photo_side` VARCHAR(255) NULL,
    `rejection_reason` TEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_veh_number` (`vehicle_number`),
    INDEX `idx_veh_status` (`status`, `ownership_type`),
    CONSTRAINT `fk_veh_owner` FOREIGN KEY (`owner_id`) REFERENCES `vehicle_owners` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_veh_area` FOREIGN KEY (`service_area_id`) REFERENCES `service_areas` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. DRIVER PROFILES
DROP TABLE IF EXISTS `driver_profiles`;
CREATE TABLE `driver_profiles` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL UNIQUE,
    `vehicle_id` BIGINT UNSIGNED NULL,
    `service_area_id` BIGINT UNSIGNED NULL,
    `ownership_model` ENUM('company_driver', 'owner_operator', 'fleet_driver') NOT NULL DEFAULT 'owner_operator',
    `driving_license_no` VARCHAR(50) NULL,
    `dl_expiry` DATE NULL,
    `badge_number` VARCHAR(50) NULL,
    `aadhaar_number` VARCHAR(20) NULL,
    `pan_number` VARCHAR(20) NULL,
    `bank_account_no` VARCHAR(40) NULL,
    `bank_ifsc` VARCHAR(20) NULL,
    `bank_beneficiary_name` VARCHAR(120) NULL,
    `current_lat` DECIMAL(10, 8) NULL,
    `current_lng` DECIMAL(11, 8) NULL,
    `heading` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    `last_location_updated_at` DATETIME NULL,
    `is_online` TINYINT(1) NOT NULL DEFAULT 0,
    `is_busy` TINYINT(1) NOT NULL DEFAULT 0,
    `status` ENUM('pending_review', 'verified_active', 'rejected', 'suspended') NOT NULL DEFAULT 'pending_review',
    `rejection_reason` TEXT NULL,
    `rating_avg` DECIMAL(3, 2) NOT NULL DEFAULT 5.00,
    `total_trips` INT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_driver_online_busy` (`is_online`, `is_busy`, `status`),
    INDEX `idx_driver_coords` (`current_lat`, `current_lng`),
    CONSTRAINT `fk_driver_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_driver_vehicle` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_driver_area` FOREIGN KEY (`service_area_id`) REFERENCES `service_areas` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add reverse constraint to vehicles table for current_driver_id
ALTER TABLE `vehicles` ADD CONSTRAINT `fk_veh_curr_driver` FOREIGN KEY (`current_driver_id`) REFERENCES `driver_profiles` (`id`) ON DELETE SET NULL;

-- 7. DRIVER DOCUMENTS (KYC, DL, RC, Insurance, Permits)
DROP TABLE IF EXISTS `driver_documents`;
CREATE TABLE `driver_documents` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `driver_id` BIGINT UNSIGNED NOT NULL,
    `vehicle_id` BIGINT UNSIGNED NULL,
    `document_type` ENUM('driving_license', 'aadhaar_card', 'pan_card', 'vehicle_rc', 'insurance_policy', 'fitness_certificate', 'police_verification', 'profile_photo') NOT NULL,
    `document_number` VARCHAR(80) NULL,
    `file_path` VARCHAR(255) NOT NULL,
    `expiry_date` DATE NULL,
    `verification_status` ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    `verified_by` BIGINT UNSIGNED NULL,
    `verified_at` DATETIME NULL,
    `rejection_notes` TEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_doc_driver_type` (`driver_id`, `document_type`),
    CONSTRAINT `fk_doc_driver` FOREIGN KEY (`driver_id`) REFERENCES `driver_profiles` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_doc_veh` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_doc_verifier` FOREIGN KEY (`verified_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. FARE RULES (E-Rickshaw Pricing Engine)
DROP TABLE IF EXISTS `fare_rules`;
CREATE TABLE `fare_rules` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `service_area_id` BIGINT UNSIGNED NOT NULL,
    `vehicle_type` ENUM('e_rickshaw', 'e_loader', 'e_cart') NOT NULL DEFAULT 'e_rickshaw',
    `base_fare` DECIMAL(8, 2) NOT NULL DEFAULT 20.00, -- Up to base_distance_km
    `base_distance_km` DECIMAL(5, 2) NOT NULL DEFAULT 1.50,
    `per_km_rate` DECIMAL(8, 2) NOT NULL DEFAULT 10.00,
    `minimum_fare` DECIMAL(8, 2) NOT NULL DEFAULT 20.00,
    `per_minute_waiting_charge` DECIMAL(8, 2) NOT NULL DEFAULT 1.00,
    `free_waiting_minutes` INT NOT NULL DEFAULT 3,
    `night_surge_multiplier` DECIMAL(4, 2) NOT NULL DEFAULT 1.25,
    `night_surge_start` TIME NOT NULL DEFAULT '22:00:00',
    `night_surge_end` TIME NOT NULL DEFAULT '05:00:00',
    `platform_commission_percentage` DECIMAL(5, 2) NOT NULL DEFAULT 10.00, -- 10% Platform fee
    `cancellation_fee_customer` DECIMAL(8, 2) NOT NULL DEFAULT 15.00,
    `cancellation_fee_driver` DECIMAL(8, 2) NOT NULL DEFAULT 20.00,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_fare_area_active` (`service_area_id`, `is_active`),
    CONSTRAINT `fk_fare_area` FOREIGN KEY (`service_area_id`) REFERENCES `service_areas` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. BOOKINGS (Trip State Machine & Atomic Driver Acceptance)
DROP TABLE IF EXISTS `bookings`;
CREATE TABLE `bookings` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `booking_code` VARCHAR(30) NOT NULL UNIQUE,
    `customer_id` BIGINT UNSIGNED NOT NULL,
    `driver_id` BIGINT UNSIGNED NULL,
    `vehicle_id` BIGINT UNSIGNED NULL,
    `service_area_id` BIGINT UNSIGNED NULL,
    `pickup_address` VARCHAR(255) NOT NULL,
    `pickup_lat` DECIMAL(10, 8) NOT NULL,
    `pickup_lng` DECIMAL(11, 8) NOT NULL,
    `drop_address` VARCHAR(255) NOT NULL,
    `drop_lat` DECIMAL(10, 8) NOT NULL,
    `drop_lng` DECIMAL(11, 8) NOT NULL,
    `estimated_distance_km` DECIMAL(6, 2) NOT NULL DEFAULT 0.00,
    `estimated_duration_mins` INT NOT NULL DEFAULT 0,
    `estimated_fare` DECIMAL(8, 2) NOT NULL DEFAULT 0.00,
    `actual_distance_km` DECIMAL(6, 2) NOT NULL DEFAULT 0.00,
    `actual_duration_mins` INT NOT NULL DEFAULT 0,
    `waiting_duration_mins` INT NOT NULL DEFAULT 0,
    `final_fare` DECIMAL(8, 2) NOT NULL DEFAULT 0.00,
    `base_fare_charged` DECIMAL(8, 2) NOT NULL DEFAULT 0.00,
    `distance_fare_charged` DECIMAL(8, 2) NOT NULL DEFAULT 0.00,
    `waiting_fare_charged` DECIMAL(8, 2) NOT NULL DEFAULT 0.00,
    `surge_fare_charged` DECIMAL(8, 2) NOT NULL DEFAULT 0.00,
    `discount_amount` DECIMAL(8, 2) NOT NULL DEFAULT 0.00,
    `platform_commission_amount` DECIMAL(8, 2) NOT NULL DEFAULT 0.00,
    `driver_earnings_amount` DECIMAL(8, 2) NOT NULL DEFAULT 0.00,
    `payment_mode` ENUM('cash', 'upi', 'wallet', 'online') NOT NULL DEFAULT 'cash',
    `payment_status` ENUM('pending', 'paid', 'failed', 'refunded') NOT NULL DEFAULT 'pending',
    `booking_status` ENUM('requested', 'dispatched', 'accepted', 'arrived', 'in_progress', 'completed', 'cancelled', 'expired') NOT NULL DEFAULT 'requested',
    `start_otp` VARCHAR(6) NOT NULL,
    `scheduled_at` DATETIME NULL,
    `requested_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `accepted_at` DATETIME NULL,
    `arrived_at` DATETIME NULL,
    `started_at` DATETIME NULL,
    `completed_at` DATETIME NULL,
    `cancelled_at` DATETIME NULL,
    `cancelled_by` ENUM('customer', 'driver', 'admin', 'system') NULL,
    `cancellation_reason` VARCHAR(255) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_booking_status` (`booking_status`),
    INDEX `idx_booking_customer` (`customer_id`),
    INDEX `idx_booking_driver` (`driver_id`),
    INDEX `idx_booking_code` (`booking_code`),
    CONSTRAINT `fk_book_cust` FOREIGN KEY (`customer_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `fk_book_driver` FOREIGN KEY (`driver_id`) REFERENCES `driver_profiles` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_book_veh` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_book_area` FOREIGN KEY (`service_area_id`) REFERENCES `service_areas` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. BOOKING EVENTS (Auditable Event Log for Trips)
DROP TABLE IF EXISTS `booking_events`;
CREATE TABLE `booking_events` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `booking_id` BIGINT UNSIGNED NOT NULL,
    `event_name` VARCHAR(50) NOT NULL,
    `actor_id` BIGINT UNSIGNED NULL,
    `actor_type` ENUM('customer', 'driver', 'admin', 'system') NOT NULL DEFAULT 'system',
    `payload` JSON NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_event_booking` (`booking_id`),
    CONSTRAINT `fk_event_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. DRIVER LOCATIONS (Telemetry & Breadcrumb Tracking)
DROP TABLE IF EXISTS `driver_locations`;
CREATE TABLE `driver_locations` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `driver_id` BIGINT UNSIGNED NOT NULL,
    `booking_id` BIGINT UNSIGNED NULL,
    `latitude` DECIMAL(10, 8) NOT NULL,
    `longitude` DECIMAL(11, 8) NOT NULL,
    `heading` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    `speed_kmh` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    `battery_percentage` INT NULL,
    `recorded_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_loc_driver_rec` (`driver_id`, `recorded_at`),
    INDEX `idx_loc_booking` (`booking_id`),
    CONSTRAINT `fk_loc_driver` FOREIGN KEY (`driver_id`) REFERENCES `driver_profiles` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_loc_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. PAYMENTS (Cash, UPI, Gateway Integration with Idempotency)
DROP TABLE IF EXISTS `payments`;
CREATE TABLE `payments` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `booking_id` BIGINT UNSIGNED NOT NULL,
    `customer_id` BIGINT UNSIGNED NOT NULL,
    `driver_id` BIGINT UNSIGNED NULL,
    `transaction_reference` VARCHAR(100) NOT NULL UNIQUE,
    `payment_gateway` ENUM('cash', 'razorpay_upi', 'phonepe_upi', 'in_app_wallet') NOT NULL DEFAULT 'cash',
    `amount` DECIMAL(8, 2) NOT NULL,
    `currency` VARCHAR(5) NOT NULL DEFAULT 'INR',
    `gateway_order_id` VARCHAR(100) NULL,
    `gateway_payment_id` VARCHAR(100) NULL,
    `gateway_signature` VARCHAR(255) NULL,
    `status` ENUM('initiated', 'authorized', 'captured', 'refunded', 'failed') NOT NULL DEFAULT 'initiated',
    `idempotency_key` VARCHAR(100) NOT NULL UNIQUE,
    `response_payload` JSON NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_pay_status` (`status`),
    INDEX `idx_pay_ref` (`transaction_reference`),
    CONSTRAINT `fk_pay_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_pay_cust` FOREIGN KEY (`customer_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13. REFUNDS
DROP TABLE IF EXISTS `refunds`;
CREATE TABLE `refunds` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `payment_id` BIGINT UNSIGNED NOT NULL,
    `booking_id` BIGINT UNSIGNED NOT NULL,
    `amount` DECIMAL(8, 2) NOT NULL,
    `reason` VARCHAR(255) NOT NULL,
    `gateway_refund_id` VARCHAR(100) NULL,
    `status` ENUM('pending', 'processed', 'failed') NOT NULL DEFAULT 'pending',
    `processed_by` BIGINT UNSIGNED NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_ref_pay` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ref_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 14. DRIVER WALLETS
DROP TABLE IF EXISTS `driver_wallets`;
CREATE TABLE `driver_wallets` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `driver_id` BIGINT UNSIGNED NOT NULL UNIQUE,
    `current_balance` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `total_earned` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `total_withdrawn` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `pending_settlement` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `cash_collected_held` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_wallet_driver` FOREIGN KEY (`driver_id`) REFERENCES `driver_profiles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 15. LEDGER ENTRIES (Double-entry / Audit Trail for Driver FinTech)
DROP TABLE IF EXISTS `ledger_entries`;
CREATE TABLE `ledger_entries` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `driver_id` BIGINT UNSIGNED NOT NULL,
    `booking_id` BIGINT UNSIGNED NULL,
    `entry_type` ENUM('trip_earning', 'platform_commission_debit', 'cash_collected_deduction', 'payout_credit', 'incentive_credit', 'cancellation_compensation', 'penalty') NOT NULL,
    `amount` DECIMAL(10, 2) NOT NULL,
    `balance_after` DECIMAL(10, 2) NOT NULL,
    `description` VARCHAR(255) NOT NULL,
    `reference_id` VARCHAR(100) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_ledger_driver` (`driver_id`),
    CONSTRAINT `fk_ledger_driver` FOREIGN KEY (`driver_id`) REFERENCES `driver_profiles` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_ledger_book` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 16. COMMISSIONS
DROP TABLE IF EXISTS `commissions`;
CREATE TABLE `commissions` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `booking_id` BIGINT UNSIGNED NOT NULL,
    `driver_id` BIGINT UNSIGNED NOT NULL,
    `gross_fare` DECIMAL(8, 2) NOT NULL,
    `commission_percentage` DECIMAL(5, 2) NOT NULL,
    `commission_amount` DECIMAL(8, 2) NOT NULL,
    `gst_amount` DECIMAL(8, 2) NOT NULL DEFAULT 0.00,
    `net_driver_share` DECIMAL(8, 2) NOT NULL,
    `settlement_status` ENUM('unsettled', 'settled') NOT NULL DEFAULT 'unsettled',
    `settled_at` DATETIME NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_comm_driver` (`driver_id`),
    CONSTRAINT `fk_comm_book` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_comm_driver` FOREIGN KEY (`driver_id`) REFERENCES `driver_profiles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 17. PAYOUTS
DROP TABLE IF EXISTS `payouts`;
CREATE TABLE `payouts` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `driver_id` BIGINT UNSIGNED NOT NULL,
    `requested_amount` DECIMAL(10, 2) NOT NULL,
    `processing_fee` DECIMAL(8, 2) NOT NULL DEFAULT 0.00,
    `net_payout` DECIMAL(10, 2) NOT NULL,
    `payout_method` ENUM('bank_transfer', 'upi_vpa') NOT NULL DEFAULT 'upi_vpa',
    `upi_id` VARCHAR(100) NULL,
    `bank_account_no` VARCHAR(40) NULL,
    `bank_ifsc` VARCHAR(20) NULL,
    `transaction_ref` VARCHAR(100) NULL,
    `status` ENUM('requested', 'approved', 'processing', 'completed', 'rejected') NOT NULL DEFAULT 'requested',
    `reviewed_by` BIGINT UNSIGNED NULL,
    `remarks` VARCHAR(255) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_payout_driver` FOREIGN KEY (`driver_id`) REFERENCES `driver_profiles` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_payout_reviewer` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 18. RATINGS & REVIEWS
DROP TABLE IF EXISTS `ratings`;
CREATE TABLE `ratings` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `booking_id` BIGINT UNSIGNED NOT NULL,
    `from_user_id` BIGINT UNSIGNED NOT NULL,
    `to_user_id` BIGINT UNSIGNED NOT NULL,
    `rating` TINYINT UNSIGNED NOT NULL CHECK (`rating` BETWEEN 1 AND 5),
    `tags` VARCHAR(255) NULL,
    `comments` TEXT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_rat_to_user` (`to_user_id`),
    CONSTRAINT `fk_rat_book` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_rat_from` FOREIGN KEY (`from_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_rat_to` FOREIGN KEY (`to_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 19. COMPLAINTS & INCIDENT REPORTING
DROP TABLE IF EXISTS `complaints`;
CREATE TABLE `complaints` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `booking_id` BIGINT UNSIGNED NULL,
    `reported_by_user_id` BIGINT UNSIGNED NOT NULL,
    `against_user_id` BIGINT UNSIGNED NULL,
    `category` ENUM('fare_dispute', 'driver_behavior', 'vehicle_condition', 'safety_sos', 'rash_driving', 'overcharging', 'other') NOT NULL DEFAULT 'other',
    `description` TEXT NOT NULL,
    `status` ENUM('open', 'under_investigation', 'resolved', 'dismissed') NOT NULL DEFAULT 'open',
    `resolution_notes` TEXT NULL,
    `resolved_by` BIGINT UNSIGNED NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_comp_book` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_comp_rep_user` FOREIGN KEY (`reported_by_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_comp_against_user` FOREIGN KEY (`against_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_comp_res_by` FOREIGN KEY (`resolved_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 20. NOTIFICATIONS
DROP TABLE IF EXISTS `notifications`;
CREATE TABLE `notifications` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `title` VARCHAR(150) NOT NULL,
    `body` TEXT NOT NULL,
    `notification_type` ENUM('booking_alert', 'trip_status', 'payment_receipt', 'document_expiry', 'system_announcement') NOT NULL DEFAULT 'booking_alert',
    `data_payload` JSON NULL,
    `is_read` TINYINT(1) NOT NULL DEFAULT 0,
    `sent_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `read_at` DATETIME NULL,
    INDEX `idx_notif_user` (`user_id`, `is_read`),
    CONSTRAINT `fk_notif_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 21. SUPPORT TICKETS
DROP TABLE IF EXISTS `support_tickets`;
CREATE TABLE `support_tickets` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `ticket_code` VARCHAR(30) NOT NULL UNIQUE,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `subject` VARCHAR(200) NOT NULL,
    `priority` ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium',
    `status` ENUM('open', 'in_progress', 'resolved', 'closed') NOT NULL DEFAULT 'open',
    `messages` JSON NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_tick_user` (`user_id`),
    CONSTRAINT `fk_tick_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 22. PROMOTIONS & COUPONS
DROP TABLE IF EXISTS `promotions`;
CREATE TABLE `promotions` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `promo_code` VARCHAR(30) NOT NULL UNIQUE,
    `description` VARCHAR(255) NOT NULL,
    `discount_type` ENUM('percentage', 'flat') NOT NULL DEFAULT 'flat',
    `discount_value` DECIMAL(8, 2) NOT NULL,
    `max_discount` DECIMAL(8, 2) NOT NULL DEFAULT 50.00,
    `min_fare_required` DECIMAL(8, 2) NOT NULL DEFAULT 30.00,
    `usage_limit_per_user` INT NOT NULL DEFAULT 1,
    `total_usage_limit` INT NOT NULL DEFAULT 1000,
    `times_used` INT NOT NULL DEFAULT 0,
    `valid_from` DATETIME NOT NULL,
    `valid_to` DATETIME NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_promo_code` (`promo_code`, `is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 23. AUDIT LOGS (Admin actions, config changes, approval logs)
DROP TABLE IF EXISTS `audit_logs`;
CREATE TABLE `audit_logs` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `admin_id` BIGINT UNSIGNED NULL,
    `action` VARCHAR(100) NOT NULL,
    `entity_type` VARCHAR(50) NOT NULL,
    `entity_id` BIGINT UNSIGNED NULL,
    `old_values` JSON NULL,
    `new_values` JSON NULL,
    `ip_address` VARCHAR(45) NULL,
    `user_agent` VARCHAR(255) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_audit_admin` (`admin_id`),
    CONSTRAINT `fk_audit_admin` FOREIGN KEY (`admin_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
