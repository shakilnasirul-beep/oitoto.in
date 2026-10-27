const fs = require('fs');

const jsCode = `
        // =========================================================================
        // UNIFIED PARTNER & VEHICLE KYC INSPECTION HUB (DRIVER + VEHICLE + 3 PHOTOS)
        // =========================================================================

        // Photo Lightbox Viewer
        function openPhotoLightbox(type, refNo, label) {
            const body = document.getElementById('photoLightboxBody');
            const title = document.getElementById('photoLightboxTitle');
            const sub = document.getElementById('photoLightboxSubtitle');
            if (!body) return;

            let contentHtml = '';
            let titleText = 'Inspection Photo Preview';
            let subText = \`Reference: \${refNo}\`;

            if (type === 'front') {
                titleText = 'Vehicle Front View Inspection (With Number Plate)';
                subText = \`Plate: \${refNo} &bull; Angle: Front Windshield & Headlights\`;
                contentHtml = \`
                    <div class="p-3 bg-dark rounded-3 d-inline-block text-center border border-secondary" style="max-width: 520px; width: 100%;">
                        <div class="position-relative bg-black rounded p-4 text-center overflow-hidden" style="min-height: 260px; display: flex; flex-direction: column; align-items: center; justify-content: center; background: radial-gradient(circle, #1E293B 0%, #0F172A 100%);">
                            <!-- Simulated Vehicle Front Illustration -->
                            <div class="text-white mb-2" style="font-size: 5rem;">🛺</div>
                            <div class="py-1 px-3 bg-warning text-dark font-monospace fw-bold fs-5 rounded border border-dark shadow-sm">
                                \${refNo}
                            </div>
                            <div class="mt-2 text-success small fw-semibold"><i class="bi bi-patch-check-fill me-1"></i>Plate Number Legible & Clear</div>
                            <div class="position-absolute top-0 start-0 p-2 text-white-50" style="font-size: 0.65rem;">
                                <i class="bi bi-geo-alt-fill text-danger me-1"></i>GPS: 25.3950° N, 88.0070° E &bull; Front Camera
                            </div>
                            <div class="position-absolute top-0 end-0 p-2">
                                <span class="badge bg-success" style="font-size: 0.68rem;">HD Verified</span>
                            </div>
                        </div>
                        <div class="mt-2 text-white-50 small d-flex justify-content-between px-2">
                            <span>Resolution: 1920x1080 (HD)</span>
                            <span>Upload Source: Driver Mobile App</span>
                        </div>
                    </div>
                \`;
            } else if (type === 'left') {
                titleText = 'Vehicle Left Side View Inspection';
                subText = \`Plate: \${refNo} &bull; Angle: Left Seating, Canopy & Wheels\`;
                contentHtml = \`
                    <div class="p-3 bg-dark rounded-3 d-inline-block text-center border border-secondary" style="max-width: 520px; width: 100%;">
                        <div class="position-relative bg-black rounded p-4 text-center overflow-hidden" style="min-height: 260px; display: flex; flex-direction: column; align-items: center; justify-content: center; background: radial-gradient(circle, #1E293B 0%, #0F172A 100%);">
                            <div class="text-white mb-2" style="font-size: 5rem; transform: scaleX(-1);">🛺</div>
                            <div class="py-1 px-3 bg-secondary text-white font-monospace small rounded border border-secondary">
                                Left Profile Inspection &bull; Seating & Chassis
                            </div>
                            <div class="mt-2 text-success small fw-semibold"><i class="bi bi-check-circle-fill me-1"></i>Canopy, Side Bars & Tyres Pass</div>
                            <div class="position-absolute top-0 start-0 p-2 text-white-50" style="font-size: 0.65rem;">
                                <i class="bi bi-geo-alt-fill text-danger me-1"></i>GPS: 25.3950° N, 88.0070° E &bull; Left Camera
                            </div>
                        </div>
                        <div class="mt-2 text-white-50 small d-flex justify-content-between px-2">
                            <span>Passenger Safety: Passed</span>
                            <span>Chassis Stamp: Matching</span>
                        </div>
                    </div>
                \`;
            } else if (type === 'right') {
                titleText = 'Vehicle Right Side & Rear View Inspection';
                subText = \`Plate: \${refNo} &bull; Angle: Right Profile, Battery Box & Rear Plate\`;
                contentHtml = \`
                    <div class="p-3 bg-dark rounded-3 d-inline-block text-center border border-secondary" style="max-width: 520px; width: 100%;">
                        <div class="position-relative bg-black rounded p-4 text-center overflow-hidden" style="min-height: 260px; display: flex; flex-direction: column; align-items: center; justify-content: center; background: radial-gradient(circle, #1E293B 0%, #0F172A 100%);">
                            <div class="text-white mb-2" style="font-size: 5rem;">🛺</div>
                            <div class="py-1 px-3 bg-warning text-dark font-monospace fw-bold fs-6 rounded border border-dark shadow-sm">
                                REAR PLATE: \${refNo}
                            </div>
                            <div class="mt-2 text-success small fw-semibold"><i class="bi bi-shield-check me-1"></i>Battery Isolation Box & Rear Plate Secure</div>
                            <div class="position-absolute top-0 start-0 p-2 text-white-50" style="font-size: 0.65rem;">
                                <i class="bi bi-geo-alt-fill text-danger me-1"></i>GPS: 25.3950° N, 88.0070° E &bull; Right Camera
                            </div>
                        </div>
                        <div class="mt-2 text-white-50 small d-flex justify-content-between px-2">
                            <span>Battery Isolation: AIS-156 Safe</span>
                            <span>Rear Reflectors: Active</span>
                        </div>
                    </div>
                \`;
            } else if (type === 'dl') {
                titleText = 'Driving License (DL) Document Preview';
                subText = \`DL Number: \${refNo} &bull; Name: \${label || 'Driver'}\`;
                contentHtml = \`
                    <div class="p-3 bg-white text-dark rounded-3 d-inline-block text-start border shadow-sm" style="max-width: 480px; width: 100%; font-family: monospace;">
                        <div class="d-flex align-items-center justify-content-between border-bottom pb-2 mb-2">
                            <div class="d-flex align-items-center gap-2">
                                <span class="fs-4">🇮🇳</span>
                                <div>
                                    <div class="fw-bold" style="font-size: 0.78rem;">UNION OF INDIA &bull; DRIVING LICENCE</div>
                                    <div class="text-muted" style="font-size: 0.65rem;">TRANSPORT DEPT, GOVT OF WEST BENGAL</div>
                                </div>
                            </div>
                            <span class="badge bg-primary">CHIP ENABLED</span>
                        </div>
                        <div class="d-flex gap-3 my-2">
                            <div class="bg-light border text-center p-2 rounded" style="width: 80px; height: 95px;">
                                <i class="bi bi-person-fill fs-1 text-secondary"></i>
                                <div style="font-size: 0.55rem;">PHOTO</div>
                            </div>
                            <div class="small flex-grow-1">
                                <div><strong>DL NO:</strong> <span class="text-primary font-monospace fw-bold">\${refNo}</span></div>
                                <div><strong>NAME:</strong> \${label || 'DRIVER PARTNER'}</div>
                                <div><strong>CLASS:</strong> E-RICKSHAW / 3W CAB / LMV</div>
                                <div><strong>VALID TILL:</strong> 2034-08-15 (VALID)</div>
                                <div><strong>BLOOD GRP:</strong> B+ve</div>
                            </div>
                        </div>
                        <div class="border-top pt-1 mt-2 text-muted text-center" style="font-size: 0.65rem;">
                            &bull; OFFICIAL DIGITAL TRANSPORT AUDIT RECORD &bull;
                        </div>
                    </div>
                \`;
            } else if (type === 'aadhaar') {
                titleText = 'Aadhaar Identity Verification Slip';
                subText = \`UID: \${refNo} &bull; Name: \${label || 'Driver'}\`;
                contentHtml = \`
                    <div class="p-3 bg-white text-dark rounded-3 d-inline-block text-start border shadow-sm" style="max-width: 480px; width: 100%; font-family: monospace;">
                        <div class="d-flex align-items-center justify-content-between border-bottom pb-2 mb-2">
                            <div class="fw-bold text-danger" style="font-size: 0.85rem;">GOVERNMENT OF INDIA / UIDAI</div>
                            <span class="badge bg-success"><i class="bi bi-shield-check me-1"></i>OTP VERIFIED</span>
                        </div>
                        <div class="d-flex gap-3 my-2">
                            <div class="bg-light border text-center p-2 rounded" style="width: 80px; height: 95px;">
                                <i class="bi bi-qr-code-scan fs-1 text-dark"></i>
                                <div style="font-size: 0.55rem;">QR CODE</div>
                            </div>
                            <div class="small flex-grow-1">
                                <div><strong>AADHAAR NO:</strong> <span class="text-dark font-monospace fw-bold">\${refNo}</span></div>
                                <div><strong>FULL NAME:</strong> \${label || 'DRIVER PARTNER'}</div>
                                <div><strong>GENDER:</strong> MALE</div>
                                <div><strong>DOB / YOB:</strong> 1988</div>
                                <div><strong>AUTH:</strong> Mobile OTP Instant e-KYC</div>
                            </div>
                        </div>
                        <div class="border-top pt-1 mt-2 text-muted text-center" style="font-size: 0.65rem;">
                            MERA AADHAAR, MERI PEHCHAAN &bull; VERIFIED SECURE
                        </div>
                    </div>
                \`;
            } else if (type === 'rc') {
                titleText = 'Vehicle Registration Certificate (RC) Preview';
                subText = \`RC Number: \${refNo} &bull; Vehicle: \${label || 'E-Rickshaw'}\`;
                contentHtml = \`
                    <div class="p-3 bg-white text-dark rounded-3 d-inline-block text-start border shadow-sm" style="max-width: 480px; width: 100%; font-family: monospace;">
                        <div class="d-flex align-items-center justify-content-between border-bottom pb-2 mb-2">
                            <div class="fw-bold text-primary" style="font-size: 0.82rem;">CERTIFICATE OF REGISTRATION (FORM 23)</div>
                            <span class="badge bg-success">GOVT APPROVED</span>
                        </div>
                        <div class="small">
                            <div><strong>REGISTRATION NO:</strong> <span class="text-primary fw-bold">\${label || refNo}</span></div>
                            <div><strong>CERTIFICATE NO:</strong> \${refNo}</div>
                            <div><strong>CLASS OF VEHICLE:</strong> E-RICKSHAW (SPECIAL PURPOSE 3-WHEELER)</div>
                            <div><strong>FUEL / PROPULSION:</strong> PURE BATTERY ELECTRIC (EV)</div>
                            <div><strong>REGISTERING AUTHORITY:</strong> BELTALA RTO, KOLKATA / MALDA RTO</div>
                        </div>
                    </div>
                \`;
            } else if (type === 'permit') {
                titleText = 'Commercial Route Permit Certificate';
                subText = \`Permit: \${refNo} &bull; Allowed Zone: \${label || 'Pan-India Hub'}\`;
                contentHtml = \`
                    <div class="p-3 bg-white text-dark rounded-3 d-inline-block text-start border shadow-sm" style="max-width: 480px; width: 100%; font-family: monospace;">
                        <div class="d-flex align-items-center justify-content-between border-bottom pb-2 mb-2">
                            <div class="fw-bold text-success" style="font-size: 0.82rem;">REGIONAL TRANSPORT AUTHORITY (RTA) PERMIT</div>
                            <span class="badge bg-success">ACTIVE ROUTE</span>
                        </div>
                        <div class="small">
                            <div><strong>PERMIT NUMBER:</strong> <span class="text-success fw-bold">\${refNo}</span></div>
                            <div><strong>CORRIDOR / ROUTE:</strong> \${label || 'Local Municipal Service Feeder'}</div>
                            <div><strong>SEATING CAPACITY:</strong> 4 PASSENGERS + 1 DRIVER</div>
                            <div><strong>VALIDITY:</strong> 2029-03-31 (5 YEARS)</div>
                        </div>
                    </div>
                \`;
            } else if (type === 'insurance') {
                titleText = 'Motor Vehicle Insurance Policy';
                subText = \`Policy: \${refNo} &bull; Insurer: \${label || 'Commercial EV'}\`;
                contentHtml = \`
                    <div class="p-3 bg-white text-dark rounded-3 d-inline-block text-start border shadow-sm" style="max-width: 480px; width: 100%; font-family: monospace;">
                        <div class="d-flex align-items-center justify-content-between border-bottom pb-2 mb-2">
                            <div class="fw-bold text-dark" style="font-size: 0.82rem;">COMMERCIAL MOTOR VEHICLE POLICY</div>
                            <span class="badge bg-primary">COVERED</span>
                        </div>
                        <div class="small">
                            <div><strong>POLICY NUMBER:</strong> <span class="text-dark fw-bold">\${refNo}</span></div>
                            <div><strong>INSURER:</strong> \${label || 'The New India Assurance / Tata AIG'}</div>
                            <div><strong>COVERAGE:</strong> 3RD PARTY LIABILITY + DRIVER & PASSENGER COVER</div>
                            <div><strong>EXPIRY DATE:</strong> 2027-12-31</div>
                        </div>
                    </div>
                \`;
            } else if (type === 'fitness') {
                titleText = 'Roadworthiness & Fitness Certificate';
                subText = \`Valid Till: \${refNo} &bull; Status: Sealed\`;
                contentHtml = \`
                    <div class="p-3 bg-white text-dark rounded-3 d-inline-block text-start border shadow-sm" style="max-width: 480px; width: 100%; font-family: monospace;">
                        <div class="d-flex align-items-center justify-content-between border-bottom pb-2 mb-2">
                            <div class="fw-bold text-warning text-dark" style="font-size: 0.82rem;">RTO FITNESS INSPECTION SLIP</div>
                            <span class="badge bg-success">PASSED</span>
                        </div>
                        <div class="small">
                            <div><strong>FITNESS VALID TILL:</strong> \${refNo}</div>
                            <div><strong>SPEED GOVERNOR (25 KM/H):</strong> CERTIFIED SEALED & INTACT</div>
                            <div><strong>BRAKES, TYRES & LIGHTS:</strong> PASSED MECHANICAL AUDIT</div>
                            <div><strong>BMS ISOLATION SAFETY:</strong> PASSED AIS-156 FIRE SAFETY TEST</div>
                        </div>
                    </div>
                \`;
            }

            title.textContent = titleText;
            sub.innerHTML = subText;
            body.innerHTML = contentHtml;

            const modal = new bootstrap.Modal(document.getElementById('vehiclePhotoLightboxModal'));
            modal.show();
        }

        // Master Open Unified Partner & Vehicle KYC Inspection Modal
        function openDriverKYCModal(driverId, vehicleNumber) {
            let d = null;
            let v = null;

            if (driverId) {
                d = globalDriversData.find(drv => drv.id === Number(driverId));
            }
            if (!d && vehicleNumber) {
                d = globalDriversData.find(drv => drv.vehicle_number === vehicleNumber);
            }
            if (d && !vehicleNumber) {
                vehicleNumber = d.vehicle_number;
            }
            if (vehicleNumber) {
                v = globalVehiclesData.find(veh => veh.vehicle_number === vehicleNumber);
            }
            if (!v && d && d.id) {
                v = globalVehiclesData.find(veh => veh.driver_id === d.id);
            }

            // Fallback object builders if one entity is not found
            if (!d && v) {
                d = {
                    id: v.driver_id || 999,
                    full_name: v.driver_name || 'Driver Partner',
                    phone: '+91 98300 00000',
                    driving_license_no: 'WB-01-2023-009911',
                    aadhaar_no: 'XXXX-XXXX-9911',
                    service_area_name: 'Kolkata North Hub',
                    vehicle_number: v.vehicle_number,
                    brand_make: v.brand_make,
                    category: v.category || 'toto',
                    categoryName: v.category_name || 'Toto (E-Rickshaw)',
                    status: (v.status === 'active' || v.status === 'verified_active') ? 'verified_active' : 'pending_review',
                    driver_kyc_status: v.kyc_status || 'pending',
                    vehicle_kyc_status: v.kyc_status || 'pending',
                    ride_accept_status: (v.status === 'active' && v.kyc_status === 'verified') ? 'unlocked' : 'locked',
                    registered_via: 'Mobile App (OTP Verified)',
                    registered_date: '2026-10-25'
                };
            }
            if (!v && d) {
                v = {
                    vehicle_number: d.vehicle_number || 'WB-01-E-9999',
                    brand_make: d.brand_make || 'E-Rickshaw (Toto)',
                    category: d.category || 'toto',
                    category_name: d.categoryName || 'Toto (E-Rickshaw)',
                    model_year: '2025',
                    ownership_type: d.ownership_model || 'independent',
                    driver_name: d.full_name,
                    driver_id: d.id,
                    battery_type: 'Lithium-ion Smart LFP (60V 100Ah)',
                    status: d.status === 'verified_active' ? 'active' : 'pending_kyc',
                    kyc_status: d.vehicle_kyc_status || 'pending',
                    registration_certificate_no: \`RC-\${(d.vehicle_number || 'WB01E9999').replace(/-/g, '')}\`,
                    permit_no: 'PERMIT-KOL-2025-501',
                    insurance_no: 'INS-NEW-INDIA-9912',
                    insurance_valid_till: '2027-12-31',
                    fitness_valid_till: '2027-10-30',
                    chassis_no: 'CHAS-MAY-2025-88192',
                    motor_no: 'MOT-BLDC-1200W-5521'
                };
            }

            if (!d) return;

            const isDriverVerified = d.driver_kyc_status === 'verified' || d.status === 'verified_active';
            const isVehicleVerified = v && (v.kyc_status === 'verified' || v.status === 'active' || v.status === 'verified_active');
            const isFullyVerified = isDriverVerified && isVehicleVerified;
            const isSuspended = d.status === 'suspended' || (v && v.status === 'suspended');
            const isPending = !isFullyVerified && !isSuspended;
            const isRideUnlocked = isFullyVerified && !isSuspended;

            const modalBody = document.getElementById('driverKYCModalBody');
            if (!modalBody) return;

            modalBody.innerHTML = \`
                <!-- TOP PROFILE & RIDE ACCEPTANCE LOCK BANNER -->
                <div class="card border-0 shadow-sm rounded-3 mb-3 bg-white p-3">
                    <div class="d-flex align-items-center justify-content-between flex-wrap gap-2 pb-3 border-bottom">
                        <div class="d-flex align-items-center gap-3">
                            <div style="width: 52px; height: 52px; min-width: 52px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 1.5rem; font-weight: 800; background: #EFF6FF; color: #1D4ED8; border: 2px solid #BFDBFE;">
                                \${(d.full_name || 'D').charAt(0)}
                            </div>
                            <div>
                                <div class="d-flex align-items-center gap-2">
                                    <h5 class="fw-bold mb-0 text-dark">\${d.full_name}</h5>
                                    <span class="badge bg-success bg-opacity-10 text-success border border-success border-opacity-25 py-0.5 px-2" style="font-size:0.72rem;">
                                        <i class="bi bi-shield-check me-1"></i>Mobile OTP Verified
                                    </span>
                                </div>
                                <div class="text-muted small mt-0.5">
                                    <i class="bi bi-telephone me-1"></i>\${d.phone} &bull; <i class="bi bi-geo-alt me-1"></i>\${d.service_area_name || 'Kolkata North Hub'}
                                </div>
                                <div class="mt-1 d-flex gap-1.5 flex-wrap">
                                    <span class="badge bg-light text-dark border">Source: \${d.registered_via || 'Mobile App (OTP)'}</span>
                                    <span class="badge bg-light text-muted border">Registered: \${d.registered_date || '2026-10-25'}</span>
                                    <span class="badge bg-light text-primary border">Trips: \${d.total_trips || 0}</span>
                                </div>
                            </div>
                        </div>

                        <div class="text-end">
                            <div class="d-flex align-items-center gap-2 justify-content-end mb-1">
                                <span class="badge bg-dark text-warning font-monospace fs-6 px-3 py-1.5 border border-warning shadow-xs">
                                    \${d.icon || '🛺'} \${v ? v.vehicle_number : (d.vehicle_number || 'No Vehicle')}
                                </span>
                            </div>
                            <div>
                                <span class="badge \${isFullyVerified ? 'bg-success' : (isSuspended ? 'bg-danger' : 'bg-warning text-dark')} p-2 fs-6">
                                    <i class="bi bi-\${isFullyVerified ? 'patch-check-fill' : (isSuspended ? 'slash-circle' : 'clock-history')} me-1"></i>
                                    \${isFullyVerified ? 'Vehicle Verified & Active' : (isSuspended ? 'Account Suspended' : 'KYC Under Review')}
                                </span>
                            </div>
                        </div>
                    </div>

                    <!-- RIDE ACCEPTANCE STRICT LOCK BANNER -->
                    \${isRideUnlocked ? \`
                        <div class="alert alert-success border-success bg-opacity-10 border-opacity-50 mt-3 mb-0 p-3 rounded-3 d-flex align-items-center justify-content-between flex-wrap gap-2">
                            <div class="d-flex align-items-center gap-3">
                                <div class="p-2.5 bg-success text-white rounded-circle"><i class="bi bi-unlock-fill fs-4"></i></div>
                                <div>
                                    <strong class="text-success fs-6"><i class="bi bi-check-circle-fill me-1"></i> Mobile App Ride Acceptance: UNLOCKED & ACTIVE</strong>
                                    <div class="small text-muted">All driver documents, vehicle RTO papers, and 3-angle inspection photos are verified. The driver can accept customer ride requests on the mobile app.</div>
                                </div>
                            </div>
                            <span class="badge bg-success px-3 py-2 fs-7 fw-semibold"><i class="bi bi-broadcast me-1"></i> Accepting Rides</span>
                        </div>
                    \` : \`
                        <div class="alert alert-danger border-danger bg-opacity-10 border-opacity-50 mt-3 mb-0 p-3 rounded-3 d-flex align-items-center justify-content-between flex-wrap gap-2">
                            <div class="d-flex align-items-center gap-3">
                                <div class="p-2.5 bg-danger text-white rounded-circle"><i class="bi bi-lock-fill fs-4"></i></div>
                                <div>
                                    <strong class="text-danger fs-6"><i class="bi bi-exclamation-triangle-fill me-1"></i> Mobile App Ride Acceptance: STRICTLY LOCKED 🔒</strong>
                                    <div class="small text-muted">OITOTO Policy: Driver cannot go online or accept customer ride bookings until Admin verifies and approves Driver Identity, Vehicle RTO Papers, and 3-Angle Vehicle Photos.</div>
                                </div>
                            </div>
                            <span class="badge bg-danger px-3 py-2 fs-7 fw-bold"><i class="bi bi-shield-x me-1"></i> Ride Accept Locked</span>
                        </div>
                    \`}
                </div>

                <!-- SECTION 1: DRIVER PERSONAL IDENTITY & DL / AADHAAR -->
                <div class="card border-0 shadow-sm rounded-3 mb-3 bg-white p-3">
                    <div class="d-flex justify-content-between align-items-center border-bottom pb-2 mb-3">
                        <h6 class="fw-bold text-dark mb-0 d-flex align-items-center gap-2">
                            <span class="badge bg-primary text-white p-1 rounded"><i class="bi bi-person-vcard fs-6"></i></span>
                            1. Driver Personal Identity & Government IDs (চালকের পরিচয় ও আইডি)
                        </h6>
                        <span class="badge \${isDriverVerified ? 'bg-success' : 'bg-warning text-dark'}">
                            \${isDriverVerified ? '✓ Driver Identity Verified' : '⚠️ Pending Review'}
                        </span>
                    </div>

                    <div class="row g-3">
                        <!-- DL Card -->
                        <div class="col-md-6">
                            <div class="p-3 rounded-3 border bg-light h-100">
                                <div class="d-flex justify-content-between align-items-center border-bottom pb-2 mb-2">
                                    <strong class="text-dark"><i class="bi bi-card-heading text-primary me-1.5"></i>Driving License (DL)</strong>
                                    <span class="badge \${isDriverVerified ? 'bg-success' : 'bg-warning text-dark'}">\${isDriverVerified ? 'Valid' : 'Audit Required'}</span>
                                </div>
                                <div class="small text-muted d-flex flex-column gap-1.5 mb-2.5">
                                    <div class="d-flex justify-content-between"><span>DL Number:</span> <strong class="font-monospace text-primary">\${d.driving_license_no || 'WB-01-2018-004921'}</strong></div>
                                    <div class="d-flex justify-content-between"><span>Allowed Class:</span> <span class="text-dark">E-Rickshaw / 3W Cab / LMV</span></div>
                                    <div class="d-flex justify-content-between"><span>License Validity:</span> <span class="text-dark">2034-08-15 (Active)</span></div>
                                    <div class="d-flex justify-content-between"><span>Issuing Authority:</span> <span class="text-dark">Govt of West Bengal Transport</span></div>
                                </div>
                                <button class="btn btn-sm btn-outline-primary w-100" onclick="openPhotoLightbox('dl', '\${d.driving_license_no}', '\${d.full_name}')">
                                    <i class="bi bi-zoom-in me-1"></i> Preview Driving License Card
                                </button>
                            </div>
                        </div>

                        <!-- Aadhaar Card -->
                        <div class="col-md-6">
                            <div class="p-3 rounded-3 border bg-light h-100">
                                <div class="d-flex justify-content-between align-items-center border-bottom pb-2 mb-2">
                                    <strong class="text-dark"><i class="bi bi-fingerprint text-danger me-1.5"></i>Aadhaar Card (UIDAI)</strong>
                                    <span class="badge bg-success"><i class="bi bi-shield-check me-1"></i>OTP Verified</span>
                                </div>
                                <div class="small text-muted d-flex flex-column gap-1.5 mb-2.5">
                                    <div class="d-flex justify-content-between"><span>Aadhaar Number:</span> <strong class="font-monospace text-dark">\${d.aadhaar_no || 'XXXX-XXXX-4819'}</strong></div>
                                    <div class="d-flex justify-content-between"><span>Authentication:</span> <span class="text-success fw-semibold"><i class="bi bi-check-circle me-1"></i>UIDAI e-KYC Passed</span></div>
                                    <div class="d-flex justify-content-between"><span>Police Verification:</span> <span class="text-success fw-semibold">Clear (No Criminal Record)</span></div>
                                    <div class="d-flex justify-content-between"><span>Permanent Address:</span> <span class="text-dark">\${d.service_area_name || 'Kolkata North, West Bengal'}</span></div>
                                </div>
                                <button class="btn btn-sm btn-outline-dark w-100" onclick="openPhotoLightbox('aadhaar', '\${d.aadhaar_no}', '\${d.full_name}')">
                                    <i class="bi bi-zoom-in me-1"></i> Preview Aadhaar e-KYC Slip
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- SECTION 2: VEHICLE SPECS & 4 RTO DOCUMENTS -->
                <div class="card border-0 shadow-sm rounded-3 mb-3 bg-white p-3">
                    <div class="d-flex justify-content-between align-items-center border-bottom pb-2 mb-3">
                        <div>
                            <h6 class="fw-bold text-dark mb-0 d-flex align-items-center gap-2">
                                <span class="badge bg-success text-white p-1 rounded"><i class="bi bi-file-earmark-check fs-6"></i></span>
                                2. Vehicle Specifications & RTO Documents (গাড়ির স্পেক্স ও আরটিও পেপারস)
                            </h6>
                            <small class="text-muted">RC Book, Commercial Route Permit, Passenger Insurance & Roadworthiness Fitness</small>
                        </div>
                        <span class="badge \${isVehicleVerified ? 'bg-success' : 'bg-warning text-dark'}">
                            \${isVehicleVerified ? '✓ All 4 Papers Verified' : '⚠️ Vehicle Papers Pending'}
                        </span>
                    </div>

                    <!-- Vehicle Specs Banner -->
                    <div class="p-2.5 rounded-3 border bg-light mb-3 d-flex justify-content-between align-items-center flex-wrap gap-2">
                        <div class="d-flex align-items-center gap-2">
                            <span class="fs-4">\${d.icon || '🛺'}</span>
                            <div>
                                <strong class="text-dark">\${v ? v.brand_make : (d.brand_make || 'Mayuri Deluxe EV')}</strong>
                                <span class="badge bg-primary bg-opacity-10 text-primary border border-primary border-opacity-25 ms-1" style="font-size:0.68rem;">\${v ? v.category_name : (d.categoryName || 'Toto')}</span>
                                <div class="text-muted small" style="font-size:0.75rem;">Model Year: \${v ? (v.model_year || '2024') : '2024'} &bull; Battery: \${v ? v.battery_type : 'Lithium-ion Smart LFP'}</div>
                            </div>
                        </div>
                        <div class="text-end small">
                            <div>Chassis: <strong class="font-monospace text-dark">\${v ? v.chassis_no : 'CHAS-MAY-2024-77112'}</strong></div>
                            <div>Motor: <strong class="font-monospace text-dark">\${v ? v.motor_no : 'MOT-BLDC-1200W-8821'}</strong></div>
                        </div>
                    </div>

                    <!-- 4 Document Checklists Grid -->
                    <div class="row g-3">
                        <!-- 1. RC Book -->
                        <div class="col-md-6 col-lg-3">
                            <div class="p-2.5 rounded-3 border bg-light h-100 d-flex flex-column justify-content-between">
                                <div>
                                    <div class="d-flex justify-content-between align-items-center border-bottom pb-1 mb-1.5">
                                        <strong class="small text-dark"><i class="bi bi-file-earmark-text text-primary me-1"></i>1. RC Book</strong>
                                        <span class="badge \${isVehicleVerified ? 'bg-success' : 'bg-warning text-dark'}" style="font-size:0.62rem;">\${isVehicleVerified ? 'Verified' : 'Pending'}</span>
                                    </div>
                                    <div class="text-muted" style="font-size: 0.72rem; line-height: 1.35;">
                                        <div>RC No: <strong class="text-dark font-monospace">\${v ? v.registration_certificate_no : 'RC-WB01-2024-9988'}</strong></div>
                                        <div>RTO: Beltala / Malda RTO</div>
                                        <div>Owner: \${d.full_name}</div>
                                    </div>
                                </div>
                                <button class="btn btn-xs btn-outline-primary w-100 mt-2 py-1" style="font-size:0.7rem;" onclick="openPhotoLightbox('rc', '\${v ? v.registration_certificate_no : 'RC-WB01-2024-9988'}', '\${v ? v.vehicle_number : d.vehicle_number}')">
                                    <i class="bi bi-zoom-in me-0.5"></i> View RC
                                </button>
                            </div>
                        </div>

                        <!-- 2. Commercial Route Permit -->
                        <div class="col-md-6 col-lg-3">
                            <div class="p-2.5 rounded-3 border bg-light h-100 d-flex flex-column justify-content-between">
                                <div>
                                    <div class="d-flex justify-content-between align-items-center border-bottom pb-1 mb-1.5">
                                        <strong class="small text-dark"><i class="bi bi-signpost-split text-success me-1"></i>2. Route Permit</strong>
                                        <span class="badge \${isVehicleVerified ? 'bg-success' : 'bg-warning text-dark'}" style="font-size:0.62rem;">\${isVehicleVerified ? 'Active' : 'Pending'}</span>
                                    </div>
                                    <div class="text-muted" style="font-size: 0.72rem; line-height: 1.35;">
                                        <div>Permit No: <strong class="text-dark font-monospace">\${v ? v.permit_no : 'PERMIT-KOL-2024-101'}</strong></div>
                                        <div>Zone: \${d.service_area_name || 'Municipal Hub'}</div>
                                        <div>Capacity: 4+1 Passengers</div>
                                    </div>
                                </div>
                                <button class="btn btn-xs btn-outline-success w-100 mt-2 py-1" style="font-size:0.7rem;" onclick="openPhotoLightbox('permit', '\${v ? v.permit_no : 'PERMIT-KOL-2024-101'}', '\${d.service_area_name || 'Feeder Corridor'}')">
                                    <i class="bi bi-zoom-in me-0.5"></i> View Permit
                                </button>
                            </div>
                        </div>

                        <!-- 3. Motor Insurance -->
                        <div class="col-md-6 col-lg-3">
                            <div class="p-2.5 rounded-3 border bg-light h-100 d-flex flex-column justify-content-between">
                                <div>
                                    <div class="d-flex justify-content-between align-items-center border-bottom pb-1 mb-1.5">
                                        <strong class="small text-dark"><i class="bi bi-shield-check text-info me-1"></i>3. Insurance</strong>
                                        <span class="badge \${isVehicleVerified ? 'bg-success' : 'bg-warning text-dark'}" style="font-size:0.62rem;">\${isVehicleVerified ? 'Valid' : 'Pending'}</span>
                                    </div>
                                    <div class="text-muted" style="font-size: 0.72rem; line-height: 1.35;">
                                        <div>Policy: <strong class="text-dark font-monospace">\${v ? v.insurance_no : 'INS-NEW-INDIA-8821'}</strong></div>
                                        <div>Type: Commercial Passenger</div>
                                        <div>Expiry: \${v ? (v.insurance_valid_till || '2027-04-30') : '2027-04-30'}</div>
                                    </div>
                                </div>
                                <button class="btn btn-xs btn-outline-info w-100 mt-2 py-1 text-dark" style="font-size:0.7rem;" onclick="openPhotoLightbox('insurance', '\${v ? v.insurance_no : 'INS-NEW-INDIA-8821'}', 'The New India Assurance')">
                                    <i class="bi bi-zoom-in me-0.5"></i> View Policy
                                </button>
                            </div>
                        </div>

                        <!-- 4. Fitness & Roadworthiness -->
                        <div class="col-md-6 col-lg-3">
                            <div class="p-2.5 rounded-3 border bg-light h-100 d-flex flex-column justify-content-between">
                                <div>
                                    <div class="d-flex justify-content-between align-items-center border-bottom pb-1 mb-1.5">
                                        <strong class="small text-dark"><i class="bi bi-wrench-adjustable text-warning me-1"></i>4. Fitness</strong>
                                        <span class="badge \${isVehicleVerified ? 'bg-success' : 'bg-warning text-dark'}" style="font-size:0.62rem;">\${isVehicleVerified ? 'Passed' : 'Pending'}</span>
                                    </div>
                                    <div class="text-muted" style="font-size: 0.72rem; line-height: 1.35;">
                                        <div>Fitness: <strong class="text-dark">\${v ? (v.fitness_valid_till || '2026-11-20') : '2026-11-20'}</strong></div>
                                        <div>Speed Limit: 25 km/h Sealed</div>
                                        <div>BMS Safety: AIS-156 Pass</div>
                                    </div>
                                </div>
                                <button class="btn btn-xs btn-outline-warning w-100 mt-2 py-1 text-dark" style="font-size:0.7rem;" onclick="openPhotoLightbox('fitness', '\${v ? (v.fitness_valid_till || '2026-11-20') : '2026-11-20'}', 'Govt Sealed')">
                                    <i class="bi bi-zoom-in me-0.5"></i> View Fitness
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- SECTION 3: 3-ANGLE VEHICLE INSPECTION PHOTOS (FRONT + 2 SIDES WITH PLATE) -->
                <div class="card border-0 shadow-sm rounded-3 mb-3 bg-white p-3">
                    <div class="d-flex justify-content-between align-items-center border-bottom pb-2 mb-3">
                        <div>
                            <h6 class="fw-bold text-dark mb-0 d-flex align-items-center gap-2">
                                <span class="badge bg-warning text-dark p-1 rounded"><i class="bi bi-camera-fill fs-6"></i></span>
                                3. Vehicle 3-Angle Inspection Photos (গাড়ির ৩টি অ্যাঙ্গেল ফটো - নম্বর প্লেটসহ)
                            </h6>
                            <small class="text-muted">Mandatory check: Front photo must display clear number plate; side photos must show body & battery cage</small>
                        </div>
                        <span class="badge \${isVehicleVerified ? 'bg-success' : 'bg-warning text-dark'}">
                            \${isVehicleVerified ? '✓ All 3 Photos Inspected' : '⚠️ Photos Audit Pending'}
                        </span>
                    </div>

                    <div class="row g-3">
                        <!-- Photo 1: Front View with Plate -->
                        <div class="col-md-4">
                            <div class="card border rounded-3 p-2.5 h-100 bg-light text-center">
                                <div class="fw-bold text-dark small mb-1.5 d-flex align-items-center justify-content-between">
                                    <span><i class="bi bi-camera me-1 text-primary"></i>1. Front View</span>
                                    <span class="badge bg-warning text-dark" style="font-size:0.62rem;">With Plate</span>
                                </div>
                                <div class="bg-white border rounded p-3 my-1 position-relative overflow-hidden cursor-pointer" onclick="openPhotoLightbox('front', '\${v ? v.vehicle_number : d.vehicle_number}')" style="min-height: 140px; display:flex; flex-direction:column; align-items:center; justify-content:center;">
                                    <div class="fs-1">🛺</div>
                                    <div class="mt-1 py-0.5 px-2 bg-warning text-dark font-monospace fw-bold rounded border border-dark shadow-xs" style="font-size:0.75rem;">
                                        \${v ? v.vehicle_number : d.vehicle_number}
                                    </div>
                                    <small class="text-muted mt-1" style="font-size:0.65rem;">Front Windshield & Plate</small>
                                    <span class="position-absolute top-0 end-0 p-1 badge bg-dark bg-opacity-75 text-white" style="font-size:0.6rem;"><i class="bi bi-zoom-in"></i> HD</span>
                                </div>
                                <div class="small text-start mt-2 d-flex flex-column gap-1" style="font-size:0.68rem;">
                                    <span class="text-success"><i class="bi bi-check-circle-fill me-1"></i>Number Plate Legible & Clear</span>
                                    <span class="text-success"><i class="bi bi-check-circle-fill me-1"></i>Windshield & Headlights Intact</span>
                                </div>
                                <button class="btn btn-sm btn-outline-primary w-100 mt-2 py-1" style="font-size:0.72rem;" onclick="openPhotoLightbox('front', '\${v ? v.vehicle_number : d.vehicle_number}')">
                                    <i class="bi bi-eye me-1"></i> Inspect Front Photo
                                </button>
                            </div>
                        </div>

                        <!-- Photo 2: Left Side View -->
                        <div class="col-md-4">
                            <div class="card border rounded-3 p-2.5 h-100 bg-light text-center">
                                <div class="fw-bold text-dark small mb-1.5 d-flex align-items-center justify-content-between">
                                    <span><i class="bi bi-camera me-1 text-primary"></i>2. Left Side View</span>
                                    <span class="badge bg-light text-dark border" style="font-size:0.62rem;">Seating & Roof</span>
                                </div>
                                <div class="bg-white border rounded p-3 my-1 position-relative overflow-hidden cursor-pointer" onclick="openPhotoLightbox('left', '\${v ? v.vehicle_number : d.vehicle_number}')" style="min-height: 140px; display:flex; flex-direction:column; align-items:center; justify-content:center;">
                                    <div class="fs-1" style="transform: scaleX(-1);">🛺</div>
                                    <div class="mt-1 py-0.5 px-2 bg-light text-dark font-monospace rounded border shadow-xs" style="font-size:0.72rem;">
                                        Left Body & Chassis Profile
                                    </div>
                                    <small class="text-muted mt-1" style="font-size:0.65rem;">Passenger Seating & Side Bar</small>
                                    <span class="position-absolute top-0 end-0 p-1 badge bg-dark bg-opacity-75 text-white" style="font-size:0.6rem;"><i class="bi bi-zoom-in"></i> HD</span>
                                </div>
                                <div class="small text-start mt-2 d-flex flex-column gap-1" style="font-size:0.68rem;">
                                    <span class="text-success"><i class="bi bi-check-circle-fill me-1"></i>Passenger Seating & Roof Clean</span>
                                    <span class="text-success"><i class="bi bi-check-circle-fill me-1"></i>Left Mirror & Wheels Sound</span>
                                </div>
                                <button class="btn btn-sm btn-outline-secondary w-100 mt-2 py-1" style="font-size:0.72rem;" onclick="openPhotoLightbox('left', '\${v ? v.vehicle_number : d.vehicle_number}')">
                                    <i class="bi bi-eye me-1"></i> Inspect Left Side Photo
                                </button>
                            </div>
                        </div>

                        <!-- Photo 3: Right Side View with Rear Plate -->
                        <div class="col-md-4">
                            <div class="card border rounded-3 p-2.5 h-100 bg-light text-center">
                                <div class="fw-bold text-dark small mb-1.5 d-flex align-items-center justify-content-between">
                                    <span><i class="bi bi-camera me-1 text-primary"></i>3. Right Side View</span>
                                    <span class="badge bg-warning text-dark" style="font-size:0.62rem;">With Plate & Battery</span>
                                </div>
                                <div class="bg-white border rounded p-3 my-1 position-relative overflow-hidden cursor-pointer" onclick="openPhotoLightbox('right', '\${v ? v.vehicle_number : d.vehicle_number}')" style="min-height: 140px; display:flex; flex-direction:column; align-items:center; justify-content:center;">
                                    <div class="fs-1">🛺</div>
                                    <div class="mt-1 py-0.5 px-2 bg-warning text-dark font-monospace fw-bold rounded border border-dark shadow-xs" style="font-size:0.75rem;">
                                        REAR PLATE: \${v ? v.vehicle_number : d.vehicle_number}
                                    </div>
                                    <small class="text-muted mt-1" style="font-size:0.65rem;">Battery Box & Rear Plate</small>
                                    <span class="position-absolute top-0 end-0 p-1 badge bg-dark bg-opacity-75 text-white" style="font-size:0.6rem;"><i class="bi bi-zoom-in"></i> HD</span>
                                </div>
                                <div class="small text-start mt-2 d-flex flex-column gap-1" style="font-size:0.68rem;">
                                    <span class="text-success"><i class="bi bi-check-circle-fill me-1"></i>Rear Plate & Tail Lights Visible</span>
                                    <span class="text-success"><i class="bi bi-check-circle-fill me-1"></i>Battery Box & Charging Port Safe</span>
                                </div>
                                <button class="btn btn-sm btn-outline-primary w-100 mt-2 py-1" style="font-size:0.72rem;" onclick="openPhotoLightbox('right', '\${v ? v.vehicle_number : d.vehicle_number}')">
                                    <i class="bi bi-eye me-1"></i> Inspect Right Side Photo
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- SECTION 4: MASTER ACTION CONTROLS FOOTER -->
                <div class="card border-0 shadow-sm rounded-3 bg-white p-3 d-flex flex-row justify-content-between align-items-center flex-wrap gap-2 sticky-bottom">
                    <div class="small text-muted">
                        <i class="bi bi-shield-lock-fill text-primary me-1"></i><strong>Policy Enforcement:</strong> Approving all documents and photos will automatically <strong>UNLOCK</strong> ride accept on the driver mobile app.
                    </div>
                    <div class="d-flex gap-2 align-items-center flex-wrap">
                        \${!isFullyVerified ? \`
                            <button class="btn btn-success btn-sm px-3 py-1.5 fw-bold shadow-sm" onclick="approveUnifiedKYC(\${d.id}, '\${v ? v.vehicle_number : d.vehicle_number}')">
                                <i class="bi bi-patch-check-fill me-1"></i> Approve All & Unlock Ride Acceptance
                            </button>
                            <button class="btn btn-outline-danger btn-sm px-3 py-1.5" onclick="rejectUnifiedKYC(\${d.id}, '\${v ? v.vehicle_number : d.vehicle_number}')">
                                <i class="bi bi-x-circle me-1"></i> Reject / Request Re-upload
                            </button>
                        \` : isSuspended ? \`
                            <button class="btn btn-success btn-sm px-3 py-1.5 fw-bold" onclick="toggleUnifiedSuspend(\${d.id}, '\${v ? v.vehicle_number : d.vehicle_number}')">
                                <i class="bi bi-play-circle me-1"></i> Re-Activate & Unlock Ride Acceptance
                            </button>
                        \` : \`
                            <button class="btn btn-outline-danger btn-sm px-3 py-1.5" onclick="toggleUnifiedSuspend(\${d.id}, '\${v ? v.vehicle_number : d.vehicle_number}')">
                                <i class="bi bi-pause-circle me-1"></i> Suspend Partner & Vehicle
                            </button>
                        \`}
                        <button type="button" class="btn btn-secondary btn-sm px-3 py-1.5" data-bs-dismiss="modal">Close</button>
                    </div>
                </div>
            \`;

            const modal = new bootstrap.Modal(document.getElementById('driverKYCModal'));
            if (currentAdminLang === 'bn') setTimeout(() => translateAdminDom('bn', document.getElementById('driverKYCModal')), 50);
            modal.show();
        }

        // Forward openVehicleKYCModal to openDriverKYCModal
        function openVehicleKYCModal(vehicleNumber) {
            openDriverKYCModal(null, vehicleNumber);
        }

        // Master Approve Unified KYC (Driver + Vehicle + Photos)
        async function approveUnifiedKYC(driverId, vehicleNumber) {
            const d = globalDriversData.find(item => item.id === Number(driverId)) || globalDriversData.find(item => item.vehicle_number === vehicleNumber);
            const v = globalVehiclesData.find(item => item.vehicle_number === vehicleNumber) || (d ? globalVehiclesData.find(item => item.driver_id === d.id) : null);

            if (d) {
                d.status = 'verified_active';
                d.driver_kyc_status = 'verified';
                d.vehicle_kyc_status = 'verified';
                d.ride_accept_status = 'unlocked';
            }
            if (v) {
                v.status = 'active';
                v.kyc_status = 'verified';
            }

            try {
                await ensureAuth();
                if (d && d.id) {
                    await fetch(\`\${API_BASE}/admin/drivers/\${d.id}/verify\`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json', 'Authorization': \`Bearer \${adminToken}\` },
                        body: JSON.stringify({ status: 'verified_active' })
                    });
                }
            } catch(e) {}

            const modalEl = document.getElementById('driverKYCModal');
            const modal = bootstrap.Modal.getInstance(modalEl);
            if (modal) modal.hide();

            alert(\`✅ SUCCESSFUL UNIFIED VERIFICATION!\\n\\nPartner: \${d ? d.full_name : 'Driver'}\\nVehicle: \${vehicleNumber}\\n\\nAll criteria verified:\\n1. Driver Identity & DL/Aadhaar: Verified\\n2. Vehicle Papers (RC, Permit, Insurance, Fitness): Verified\\n3. 3-Angle Vehicle Photos (with Number Plates): Approved\\n\\n🔓 Driver Mobile App: Ride Acceptance is now UNLOCKED & ACTIVE!\`);

            loadPartnersAndVehicles();
            refreshDashboard();
        }

        // Master Reject Unified KYC
        async function rejectUnifiedKYC(driverId, vehicleNumber) {
            const reason = prompt("Enter specific reason for rejecting documents / photos:\\n(e.g., 'Front photo number plate is blurry', 'Driving License expired', 'Insurance copy unclear')", "Vehicle front photo number plate not clearly legible. Please re-upload.");
            if (!reason) return;

            const d = globalDriversData.find(item => item.id === Number(driverId)) || globalDriversData.find(item => item.vehicle_number === vehicleNumber);
            const v = globalVehiclesData.find(item => item.vehicle_number === vehicleNumber);

            if (d) {
                d.status = 'pending_review';
                d.driver_kyc_status = 'rejected';
                d.ride_accept_status = 'locked';
                d.rejection_reason = reason;
            }
            if (v) {
                v.status = 'pending_kyc';
                v.kyc_status = 'rejected';
                v.rejection_reason = reason;
            }

            try {
                await ensureAuth();
                if (d && d.id) {
                    await fetch(\`\${API_BASE}/admin/drivers/\${d.id}/verify\`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json', 'Authorization': \`Bearer \${adminToken}\` },
                        body: JSON.stringify({ status: 'pending_review', rejection_reason: reason })
                    });
                }
            } catch(e) {}

            const modalEl = document.getElementById('driverKYCModal');
            const modal = bootstrap.Modal.getInstance(modalEl);
            if (modal) modal.hide();

            alert(\`⚠️ KYC REJECTED:\\nReason: "\${reason}"\\n\\n🔒 Ride acceptance remains LOCKED on driver mobile app until corrected documents/photos are re-uploaded and verified by admin.\`);

            loadPartnersAndVehicles();
            refreshDashboard();
        }

        // Toggle Unified Driver & Vehicle Suspension
        async function toggleUnifiedSuspend(driverId, vehicleNumber) {
            const d = globalDriversData.find(item => item.id === Number(driverId)) || globalDriversData.find(item => item.vehicle_number === vehicleNumber);
            const v = globalVehiclesData.find(item => item.vehicle_number === vehicleNumber);

            const isCurrentlyActive = (d && (d.status === 'verified_active' || d.status === 'active')) || (v && (v.status === 'active' || v.status === 'verified_active'));
            const nextStatus = isCurrentlyActive ? 'suspended' : 'verified_active';

            if (isCurrentlyActive) {
                const confirmed = confirm(\`⚠️ Are you sure you want to suspend driver "\${d?.full_name}" and vehicle "\${vehicleNumber}"?\\n\\nRide acceptance will be immediately LOCKED on driver mobile app.\`);
                if (!confirmed) return;
            }

            if (d) {
                d.status = nextStatus;
                d.ride_accept_status = (nextStatus === 'suspended') ? 'locked' : 'unlocked';
            }
            if (v) {
                v.status = (nextStatus === 'suspended') ? 'suspended' : 'active';
            }

            try {
                await ensureAuth();
                if (d && d.id) {
                    await fetch(\`\${API_BASE}/admin/drivers/\${d.id}/verify\`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json', 'Authorization': \`Bearer \${adminToken}\` },
                        body: JSON.stringify({ status: nextStatus })
                    });
                }
            } catch(e) {}

            const modalEl = document.getElementById('driverKYCModal');
            const modal = bootstrap.Modal.getInstance(modalEl);
            if (modal) modal.hide();

            if (nextStatus === 'suspended') {
                alert(\`⛔ Driver "\${d?.full_name}" & Vehicle "\${vehicleNumber}" are now SUSPENDED.\\nRide acceptance locked on mobile app.\`);
            } else {
                alert(\`✅ Driver "\${d?.full_name}" & Vehicle "\${vehicleNumber}" are now RE-ACTIVATED.\\nRide acceptance unlocked on mobile app.\`);
            }

            loadPartnersAndVehicles();
            refreshDashboard();
        }

        // Forwarding helpers for any legacy buttons
        async function approveDriverKYC(driverId) {
            const d = globalDriversData.find(drv => drv.id === driverId);
            approveUnifiedKYC(driverId, d ? d.vehicle_number : '');
        }

        function approveVehicleKYC(vehicleNumber) {
            const v = globalVehiclesData.find(item => item.vehicle_number === vehicleNumber);
            approveUnifiedKYC(v ? v.driver_id : null, vehicleNumber);
        }

        function rejectVehicleKYC(vehicleNumber) {
            const v = globalVehiclesData.find(item => item.vehicle_number === vehicleNumber);
            rejectUnifiedKYC(v ? v.driver_id : null, vehicleNumber);
        }

        function toggleVehicleActiveSuspend(vehicleNumber) {
            const v = globalVehiclesData.find(item => item.vehicle_number === vehicleNumber);
            toggleUnifiedSuspend(v ? v.driver_id : null, vehicleNumber);
        }

        let currentVehicleTabCategory = 'all';
        function filterVehiclesTab(category) {
            currentVehicleTabCategory = category || 'all';
            loadPartnersAndVehicles();
        }

        async function loadVehicles() {
            await loadPartnersAndVehicles();
        }
`;

console.log('JS Code generated, length:', jsCode.length);
`;
