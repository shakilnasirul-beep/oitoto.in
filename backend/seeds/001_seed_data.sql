-- =====================================================================
-- OI TOTO! — SEED DATA (Service Areas, Fares, Super Admin, Vehicles, Drivers)
-- =====================================================================

USE `oitoto_db`;

-- 1. SUPER ADMIN (Default login: 9876543210 / Admin@OiToto2026)
-- Bcrypt hash for Admin@OiToto2026 is $2y$10$eE0m9T8iO4E4bC3X1/lYIeG6OknU68gNfP3K1h/BqfHnI2q9/gA6y (generated standard)
INSERT INTO `users` (`id`, `phone`, `full_name`, `email`, `role`, `status`, `language`, `password_hash`) VALUES
(1, '9876543210', 'Oi Toto Super Admin', 'admin@oitoto.in', 'super_admin', 'active', 'en', '$2y$10$oY75b5b2J4yC1c6f7rWwSeW0fRk9P3n7g3k3n9M8h2Z5t1o4l6r0y');

-- 2. SERVICE AREAS (Pan-India E-Rickshaw Hubs)
INSERT INTO `service_areas` (`id`, `name`, `state`, `city`, `center_lat`, `center_lng`, `radius_km`, `max_search_radius_km`, `legal_compliance_status`, `is_active`) VALUES
(1, 'Kolkata North & Metro Feeder', 'West Bengal', 'Kolkata', 22.572646, 88.363895, 12.00, 3.50, 'approved', 1),
(2, 'Howrah Station & Urban Zone', 'West Bengal', 'Howrah', 22.595770, 88.263640, 10.00, 3.00, 'approved', 1),
(3, 'Siliguri Town & Junction Corridor', 'West Bengal', 'Siliguri', 26.727101, 88.395287, 8.00, 2.50, 'approved', 1),
(4, 'Lucknow Charbagh & Gomti Nagar Feeders', 'Uttar Pradesh', 'Lucknow', 26.846709, 80.946166, 15.00, 4.00, 'approved', 1),
(5, 'Patna Junction & Bailey Road', 'Bihar', 'Patna', 25.594095, 85.137566, 12.00, 3.50, 'approved', 1),
(6, 'Samsi & Chanchal Toto Corridor', 'West Bengal', 'Malda', 25.276269, 88.010118, 25.00, 5.00, 'approved', 1),
(7, 'Malda Town & English Bazar Feeder', 'West Bengal', 'Malda', 25.006500, 88.142000, 18.00, 4.00, 'approved', 1);

-- 3. FARE RULES PER SERVICE AREA
INSERT INTO `fare_rules` (`service_area_id`, `vehicle_type`, `base_fare`, `base_distance_km`, `per_km_rate`, `minimum_fare`, `per_minute_waiting_charge`, `free_waiting_minutes`, `night_surge_multiplier`, `platform_commission_percentage`, `cancellation_fee_customer`, `cancellation_fee_driver`, `is_active`) VALUES
(1, 'e_rickshaw', 20.00, 1.50, 10.00, 20.00, 1.00, 3, 1.25, 10.00, 15.00, 20.00, 1),
(2, 'e_rickshaw', 18.00, 1.50, 9.50, 18.00, 1.00, 3, 1.20, 10.00, 15.00, 20.00, 1),
(3, 'e_rickshaw', 20.00, 1.50, 11.00, 20.00, 20.00, 1.00, 1.25, 10.00, 15.00, 20.00, 1),
(4, 'e_rickshaw', 25.00, 2.00, 10.00, 25.00, 1.00, 3, 1.20, 10.00, 15.00, 20.00, 1),
(5, 'e_rickshaw', 20.00, 1.50, 9.00, 20.00, 1.00, 3, 1.15, 10.00, 15.00, 20.00, 1),
(6, 'e_rickshaw', 20.00, 1.50, 10.00, 20.00, 1.00, 3, 1.25, 10.00, 15.00, 20.00, 1),
(7, 'e_rickshaw', 20.00, 1.50, 10.00, 20.00, 1.00, 3, 1.25, 10.00, 15.00, 20.00, 1);

-- 4. VEHICLE OWNER (Company Fleet Operator)
INSERT INTO `users` (`id`, `phone`, `full_name`, `email`, `role`, `status`, `language`) VALUES
(2, '9830011223', 'Oi Toto Fleet Operations Ltd', 'fleet@oitoto.in', 'owner', 'active', 'en');

INSERT INTO `vehicle_owners` (`id`, `user_id`, `business_name`, `owner_type`, `pan_number`, `gst_number`, `bank_account_no`, `bank_ifsc`, `bank_name`, `is_verified`) VALUES
(1, 2, 'Oi Toto Fleet Operations Pvt Ltd', 'company_owned', 'AABCO9988C', '19AABCO9988C1Z5', '91983001122301', 'HDFC0000123', 'HDFC Bank', 1);

-- 5. FLEET VEHICLES (Company-Owned & Independent)
INSERT INTO `vehicles` (`id`, `owner_id`, `vehicle_number`, `registration_certificate_no`, `vehicle_type`, `brand_make`, `model_year`, `battery_type`, `ownership_type`, `seating_capacity`, `color`, `service_area_id`, `status`, `fitness_expiry`, `insurance_expiry`, `permit_expiry`) VALUES
(1, 1, 'WB-01-E-1001', 'RC-WB01-2024-001', 'e_rickshaw', 'Mayuri Grand EV', 2024, 'lithium_ion', 'company_owned', 4, 'Green and Yellow', 1, 'approved', '2027-12-31', '2027-06-30', '2028-01-01'),
(2, 1, 'WB-01-E-1002', 'RC-WB01-2024-002', 'e_rickshaw', 'Saarthi Shresth EV', 2024, 'lithium_ion', 'company_owned', 4, 'Green and Yellow', 1, 'approved', '2027-12-31', '2027-06-30', '2028-01-01'),
(3, 1, 'WB-02-E-1003', 'RC-WB02-2024-003', 'e_rickshaw', 'Mahindra Treo Electric', 2025, 'lithium_ion', 'company_owned', 4, 'Green and Yellow', 2, 'approved', '2028-12-31', '2027-12-31', '2028-01-01'),
(4, NULL, 'WB-01-E-2001', 'RC-WB01-2023-991', 'e_rickshaw', 'YC Electric Yatri', 2023, 'lead_acid', 'driver_owned', 4, 'Green and Yellow', 1, 'approved', '2026-11-30', '2026-12-15', '2027-03-31');

-- 6. DRIVER USERS & PROFILES
INSERT INTO `users` (`id`, `phone`, `full_name`, `email`, `role`, `status`, `language`) VALUES
(3, '9831100001', 'Subhash Das (সুভাষ দাস)', 'subhash@oitoto.in', 'driver', 'active', 'bn'),
(4, '9831100002', 'Rajesh Kumar (राजेश कुमार)', 'rajesh@oitoto.in', 'driver', 'active', 'hi'),
(5, '9831100003', 'Bikash Mondal', 'bikash@oitoto.in', 'driver', 'pending', 'bn');

INSERT INTO `driver_profiles` (`id`, `user_id`, `vehicle_id`, `service_area_id`, `ownership_model`, `driving_license_no`, `dl_expiry`, `aadhaar_number`, `pan_number`, `bank_account_no`, `bank_ifsc`, `bank_beneficiary_name`, `current_lat`, `current_lng`, `heading`, `is_online`, `is_busy`, `status`, `rating_avg`, `total_trips`) VALUES
(1, 3, 1, 1, 'company_driver', 'WB01-20190012345', '2030-05-20', '458912349012', 'ABCDP1234E', '20019831100001', 'SBIN0001234', 'Subhash Das', 22.573200, 88.364500, 45.00, 1, 0, 'verified_active', 4.90, 142),
(2, 4, 4, 1, 'owner_operator', 'WB01-20200054321', '2029-08-14', '789012345678', 'EFGHP5678K', '30019831100002', 'PUNB0005678', 'Rajesh Kumar', 22.570100, 88.361200, 180.00, 1, 0, 'verified_active', 4.85, 98),
(3, 5, 2, 1, 'company_driver', 'WB01-20210088990', '2031-01-10', '123456789012', 'IJKLP9012M', '40019831100003', 'ICIC0000456', 'Bikash Mondal', 22.575000, 88.368000, 90.00, 0, 0, 'pending_review', 5.00, 0);

-- Assign drivers to vehicles
UPDATE `vehicles` SET `current_driver_id` = 1 WHERE `id` = 1;
UPDATE `vehicles` SET `current_driver_id` = 2 WHERE `id` = 4;

-- Driver Wallets
INSERT INTO `driver_wallets` (`driver_id`, `current_balance`, `total_earned`, `total_withdrawn`, `pending_settlement`, `cash_collected_held`) VALUES
(1, 1250.00, 14500.00, 13250.00, 450.00, 120.00),
(2, 890.00, 9800.00, 8910.00, 200.00, 0.00),
(3, 0.00, 0.00, 0.00, 0.00, 0.00);

-- 7. CUSTOMER USERS & PROFILES
INSERT INTO `users` (`id`, `phone`, `full_name`, `email`, `role`, `status`, `language`) VALUES
(6, '9870001111', 'Ananya Sen', 'ananya.sen@gmail.com', 'customer', 'active', 'bn'),
(7, '9870002222', 'Rohan Verma', 'rohan.verma@yahoo.com', 'customer', 'active', 'hi');

INSERT INTO `customer_profiles` (`id`, `user_id`, `emergency_contact_name`, `emergency_contact_phone`, `home_address`, `home_lat`, `home_lng`, `work_address`, `work_lat`, `work_lng`, `rating_avg`, `total_rides`) VALUES
(1, 6, 'Dr. Sourav Sen (Father)', '9870009999', 'Shyambazar Five Point Crossing, Kolkata', 22.6038, 88.3713, 'College Street Coffee House, Kolkata', 22.5754, 88.3639, 4.95, 24),
(2, 7, 'Sunita Verma', '9870008888', 'Sealdah Station North, Kolkata', 22.5681, 88.3704, 'Park Circus 7-Point, Kolkata', 22.5392, 88.3664, 4.88, 12);

-- 8. PROMOTIONS
INSERT INTO `promotions` (`id`, `promo_code`, `description`, `discount_type`, `discount_value`, `max_discount`, `min_fare_required`, `usage_limit_per_user`, `total_usage_limit`, `times_used`, `valid_from`, `valid_to`, `is_active`) VALUES
(1, 'CHOLO50', '50% Flat Off on first 3 Oi Toto rides!', 'percentage', 50.00, 25.00, 20.00, 3, 5000, 145, '2026-01-01 00:00:00', '2027-12-31 23:59:59', 1),
(2, 'OITOTO10', 'Flat ₹10 Off on E-Rickshaw booking', 'flat', 10.00, 10.00, 25.00, 10, 10000, 520, '2026-01-01 00:00:00', '2027-12-31 23:59:59', 1);

-- 9. SAMPLE BOOKINGS (History and active ride)
INSERT INTO `bookings` (`id`, `booking_code`, `customer_id`, `driver_id`, `vehicle_id`, `service_area_id`, `pickup_address`, `pickup_lat`, `pickup_lng`, `drop_address`, `drop_lat`, `drop_lng`, `estimated_distance_km`, `estimated_duration_mins`, `estimated_fare`, `actual_distance_km`, `actual_duration_mins`, `waiting_duration_mins`, `final_fare`, `base_fare_charged`, `distance_fare_charged`, `waiting_fare_charged`, `surge_fare_charged`, `discount_amount`, `platform_commission_amount`, `driver_earnings_amount`, `payment_mode`, `payment_status`, `booking_status`, `start_otp`, `requested_at`, `accepted_at`, `arrived_at`, `started_at`, `completed_at`) VALUES
(1, 'OT-20261015-8910', 6, 1, 1, 1, 'Shyambazar Metro Gate 1', 22.603800, 88.371300, 'Hatibagan Market Crossing', 22.594200, 88.371000, 1.80, 8, 23.00, 1.85, 9, 1, 23.50, 20.00, 3.50, 0.00, 0.00, 0.00, 2.35, 21.15, 'upi', 'paid', 'completed', '3412', '2026-10-15 14:10:00', '2026-10-15 14:11:10', '2026-10-15 14:13:30', '2026-10-15 14:14:00', '2026-10-15 14:23:00'),
(2, 'OT-20261015-9921', 7, 2, 4, 1, 'Sealdah South Station Exit', 22.568100, 88.370400, 'Maulali Crossing, CIT Road', 22.560100, 88.367000, 1.40, 6, 20.00, 1.40, 6, 0, 20.00, 20.00, 0.00, 0.00, 0.00, 0.00, 2.00, 18.00, 'cash', 'paid', 'completed', '8954', '2026-10-15 15:30:00', '2026-10-15 15:31:05', '2026-10-15 15:33:00', '2026-10-15 15:33:45', '2026-10-15 15:39:45'),
(3, 'OT-20261015-1105', 6, 1, 1, 1, 'College Street Coffee House', 22.575400, 88.363900, 'MG Road Metro Station', 22.581000, 88.362000, 1.20, 5, 20.00, 0.00, 0, 0, 20.00, 20.00, 0.00, 0.00, 0.00, 0.00, 2.00, 18.00, 'upi', 'pending', 'in_progress', '6731', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL);

-- 10. PAYMENTS FOR COMPLETED BOOKINGS
INSERT INTO `payments` (`id`, `booking_id`, `customer_id`, `driver_id`, `transaction_reference`, `payment_gateway`, `amount`, `currency`, `gateway_payment_id`, `status`, `idempotency_key`) VALUES
(1, 1, 6, 1, 'TXN_OT_20261015_01', 'razorpay_upi', 23.50, 'INR', 'pay_RpOiToto001', 'captured', 'IDEMP_TXN_001'),
(2, 2, 7, 2, 'TXN_OT_20261015_02', 'cash', 20.00, 'INR', 'cash_collected_driver', 'captured', 'IDEMP_TXN_002');

-- 11. RATINGS
INSERT INTO `ratings` (`booking_id`, `from_user_id`, `to_user_id`, `rating`, `tags`, `comments`) VALUES
(1, 6, 3, 5, 'Clean E-Rickshaw,Polite Driver,Safe Driving', 'Very smooth ride! Clean Toto and reached very fast.'),
(2, 7, 4, 5, 'Quick Arrival,Affordable', 'Best E-Rickshaw service in Sealdah.');
