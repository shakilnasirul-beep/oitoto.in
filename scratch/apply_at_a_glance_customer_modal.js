const fs = require('fs');

let content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const startMarker = 'function viewCustomerDetails(customerId) {';
const endMarker = 'function toggleCustomerStatus(customerId) {';

const startIdx = content.indexOf(startMarker);
const endIdx = content.indexOf(endMarker);

if (startIdx === -1 || endIdx === -1) {
    console.error('Markers not found in admin/index.html');
    process.exit(1);
}

const newViewCustomerDetails = `function viewCustomerDetails(customerId) {
            const customer = currentCustomersData.find(c => c.id == customerId) || SEED_CUSTOMERS.find(s => s.id == customerId);
            if (!customer) {
                alert("Customer profile not found.");
                return;
            }

            const titleEl = document.getElementById('customerModalTitle');
            if (titleEl) {
                titleEl.textContent = \`\${customer.full_name} — একনজরে প্রোফাইল ও রাইড হিস্ট্রি (Customer Profile & Ride History)\`;
            }

            const modalBody = document.getElementById('customerDetailsModalBody');
            if (!modalBody) return;

            const initials = (customer.full_name || 'U').split(' ').map(n => n[0]).filter(Boolean).slice(0, 2).join('').toUpperCase();
            const rides = customer.ride_history || [];

            modalBody.innerHTML = \`
                <!-- 1. TOP AT-A-GLANCE CUSTOMER PROFILE & ACTION STRIP -->
                <div class="card border-0 shadow-sm rounded-3 p-3 mb-3 bg-white">
                    <div class="d-flex align-items-center justify-content-between flex-wrap gap-2.5">
                        <div class="d-flex align-items-center gap-3">
                            <div class="rounded-circle text-white d-flex align-items-center justify-content-center fw-bold shadow-sm" style="width: 52px; height: 52px; min-width: 52px; background: \${customer.avatar_bg || '#3B82F6'}; font-size: 1.3rem;">
                                \${initials}
                            </div>
                            <div>
                                <div class="d-flex align-items-center gap-2 flex-wrap">
                                    <h5 class="fw-bold text-dark mb-0">\${customer.full_name}</h5>
                                    <span class="badge bg-success bg-opacity-10 text-success border border-success border-opacity-25 px-2 py-0.5 rounded-pill" style="font-size:0.72rem;">
                                        <i class="bi bi-patch-check-fill me-1"></i>Verified Rider
                                    </span>
                                    <span class="badge bg-secondary bg-opacity-10 text-secondary border font-monospace py-0.5 px-2" style="font-size:0.72rem;">
                                        \${customer.code}
                                    </span>
                                    <span class="badge \${customer.status === 'active' ? 'bg-success' : 'bg-danger'} py-0.5 px-2" style="font-size:0.72rem;">
                                        \${customer.status === 'active' ? 'Active' : 'Suspended'}
                                    </span>
                                </div>
                                <div class="d-flex align-items-center gap-2 text-muted small mt-1 flex-wrap" style="font-size:0.78rem;">
                                    <span><i class="bi bi-telephone-fill text-success me-1"></i><a href="tel:\${customer.phone}" class="text-decoration-none text-dark fw-semibold">\${customer.phone}</a></span>
                                    <span>&bull;</span>
                                    <span><i class="bi bi-envelope-fill text-primary me-1"></i><a href="mailto:\${customer.email}" class="text-decoration-none text-dark">\${customer.email}</a></span>
                                    <span>&bull;</span>
                                    <span><i class="bi bi-geo-alt-fill text-danger me-1"></i>\${customer.zone || customer.city || 'Kolkata'}</span>
                                    <span>&bull;</span>
                                    <span><i class="bi bi-calendar-check me-1"></i>Member Since: <strong>\${customer.member_since}</strong></span>
                                </div>
                            </div>
                        </div>

                        <div class="d-flex align-items-center gap-1.5 flex-wrap">
                            <a href="https://wa.me/\${(customer.phone || '').replace(/[^0-9]/g, '')}" target="_blank" class="btn btn-sm btn-outline-success py-1 px-2.5" style="font-size:0.78rem;">
                                <i class="bi bi-whatsapp me-1"></i> WhatsApp
                            </a>
                            <a href="tel:\${customer.phone}" class="btn btn-sm btn-outline-primary py-1 px-2.5" style="font-size:0.78rem;">
                                <i class="bi bi-telephone me-1"></i> Call Passenger
                            </a>
                            <button class="btn btn-sm \${customer.status === 'active' ? 'btn-outline-danger' : 'btn-outline-success'} py-1 px-2.5" style="font-size:0.78rem;" onclick="toggleCustomerStatus(\${customer.id})">
                                <i class="bi \${customer.status === 'active' ? 'bi-pause-circle' : 'bi-play-circle'} me-1"></i> \${customer.status === 'active' ? 'Suspend Account' : 'Reactivate'}
                            </button>
                        </div>
                    </div>
                </div>

                <!-- 2. COMPACT 4 KEY PERFORMANCE METRIC CARDS (EKNOJORE SUMMARY) -->
                <div class="row g-2.5 mb-3">
                    <!-- Total Completed Rides -->
                    <div class="col-6 col-md-3">
                        <div class="p-2.5 bg-white rounded-3 border shadow-xs h-100 d-flex align-items-center gap-2.5">
                            <div class="p-2.5 bg-primary bg-opacity-10 text-primary rounded-circle">
                                <i class="bi bi-ev-front-fill fs-5"></i>
                            </div>
                            <div>
                                <small class="text-muted d-block" style="font-size:0.72rem;">মোট রাইড (Trips)</small>
                                <div class="fw-bold text-dark fs-6">\${customer.completed_rides || customer.total_rides} Rides</div>
                                <small class="text-success fw-semibold" style="font-size:0.68rem;"><i class="bi bi-check-circle me-0.5"></i>\${customer.cancelled_rides ? customer.cancelled_rides + ' Cancelled' : '100% Completed'}</small>
                            </div>
                        </div>
                    </div>

                    <!-- Total Fare Spent -->
                    <div class="col-6 col-md-3">
                        <div class="p-2.5 bg-white rounded-3 border shadow-xs h-100 d-flex align-items-center gap-2.5">
                            <div class="p-2.5 bg-success bg-opacity-10 text-success rounded-circle">
                                <i class="bi bi-currency-rupee fs-5"></i>
                            </div>
                            <div>
                                <small class="text-muted d-block" style="font-size:0.72rem;">মোট খরচ (Total Spent)</small>
                                <div class="fw-bold text-dark fs-6">₹\${parseFloat(customer.total_spend || 0).toFixed(2)}</div>
                                <small class="text-muted" style="font-size:0.68rem;">পদ্ধতি: \${customer.preferred_payment || 'Cash'}</small>
                            </div>
                        </div>
                    </div>

                    <!-- Passenger Rating -->
                    <div class="col-6 col-md-3">
                        <div class="p-2.5 bg-white rounded-3 border shadow-xs h-100 d-flex align-items-center gap-2.5">
                            <div class="p-2.5 bg-warning bg-opacity-15 text-warning rounded-circle">
                                <i class="bi bi-star-fill fs-5 text-warning"></i>
                            </div>
                            <div>
                                <small class="text-muted d-block" style="font-size:0.72rem;">যাত্রী রেটিং (Rating)</small>
                                <div class="fw-bold text-dark fs-6">\${customer.rating_avg ? customer.rating_avg + ' ★' : '4.88 ★'}</div>
                                <small class="text-success fw-semibold" style="font-size:0.68rem;">উচ্চ বিশ্বস্ত যাত্রী (Trusted)</small>
                            </div>
                        </div>
                    </div>

                    <!-- Emergency SOS Contact -->
                    <div class="col-6 col-md-3">
                        <div class="p-2.5 bg-white rounded-3 border shadow-xs h-100 d-flex align-items-center gap-2.5">
                            <div class="p-2.5 bg-danger bg-opacity-10 text-danger rounded-circle">
                                <i class="bi bi-shield-fill-plus fs-5"></i>
                            </div>
                            <div>
                                <small class="text-muted d-block" style="font-size:0.72rem;">জরুরি যোগাযোগ (SOS)</small>
                                <div class="fw-bold text-dark text-truncate" style="font-size:0.8rem; max-width:140px;" title="\${customer.emergency_contact_name}">\${customer.emergency_contact_name || 'Sunita Verma'}</div>
                                <small class="text-danger fw-semibold" style="font-size:0.68rem;"><a href="tel:\${customer.emergency_contact_phone}" class="text-danger text-decoration-none">\${customer.emergency_contact_phone}</a></small>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 3. TWO-COLUMN BALANCED MASTER GRID (EKNOJORE DOSSIER & RIDE HISTORY) -->
                <div class="row g-3">
                    <!-- LEFT COLUMN: PASSENGER DOSSIER & SAVED PLACES (4 COLS) -->
                    <div class="col-lg-4 col-md-5">
                        <div class="d-flex flex-column gap-3">
                            <!-- Saved Places Card -->
                            <div class="card border-0 shadow-sm rounded-3 bg-white p-3">
                                <div class="d-flex align-items-center justify-content-between border-bottom pb-2 mb-2.5">
                                    <h6 class="fw-bold text-dark mb-0 small">
                                        <i class="bi bi-geo-alt-fill text-success me-1.5"></i>সেভড ঘনঘন রুট (Saved Places)
                                    </h6>
                                    <span class="badge bg-light text-dark border" style="font-size:0.65rem;">GPS Tracked</span>
                                </div>
                                <div class="d-flex flex-column gap-2">
                                    <!-- Home -->
                                    <div class="p-2 rounded-2 bg-light border">
                                        <div class="d-flex align-items-center justify-content-between">
                                            <strong class="text-primary small"><i class="bi bi-house-door-fill me-1"></i>Home (বাসা)</strong>
                                            <small class="text-muted font-monospace" style="font-size:0.65rem;">\${customer.home_coords || '22.5681, 88.3704'}</small>
                                        </div>
                                        <div class="small text-dark fw-semibold mt-0.5" title="\${customer.home_address}">
                                            \${customer.home_address || 'Sealdah Station North Gate, Kolkata'}
                                        </div>
                                    </div>
                                    <!-- Work -->
                                    <div class="p-2 rounded-2 bg-light border">
                                        <div class="d-flex align-items-center justify-content-between">
                                            <strong class="text-warning text-dark small"><i class="bi bi-briefcase-fill me-1 text-warning"></i>Work (অফিস)</strong>
                                            <small class="text-muted font-monospace" style="font-size:0.65rem;">\${customer.work_coords || '22.5392, 88.3664'}</small>
                                        </div>
                                        <div class="small text-dark fw-semibold mt-0.5" title="\${customer.work_address}">
                                            \${customer.work_address || 'Park Circus 7-Point, Kolkata'}
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Safety & Emergency SOS Card -->
                            <div class="card border-0 shadow-sm rounded-3 bg-white p-3">
                                <div class="d-flex align-items-center justify-content-between border-bottom pb-2 mb-2.5">
                                    <h6 class="fw-bold text-dark mb-0 small">
                                        <i class="bi bi-shield-lock-fill text-danger me-1.5"></i>নিরাপত্তা ও জরুরি কনটাক্ট
                                    </h6>
                                    <span class="badge bg-danger bg-opacity-10 text-danger border border-danger border-opacity-25" style="font-size:0.65rem;">SOS Configured</span>
                                </div>
                                <div class="p-2 rounded-2 bg-light border">
                                    <div class="fw-bold text-dark small">\${customer.emergency_contact_name || 'Sunita Verma (Mother)'}</div>
                                    <div class="d-flex align-items-center justify-content-between mt-1">
                                        <span class="text-muted small"><i class="bi bi-telephone-outbound text-primary me-1"></i>\${customer.emergency_contact_phone || '+91 98700 08888'}</span>
                                        <a href="tel:\${customer.emergency_contact_phone}" class="btn btn-xs btn-outline-danger py-0 px-2" style="font-size:0.7rem;">
                                            <i class="bi bi-telephone-fill"></i> Call
                                        </a>
                                    </div>
                                </div>
                                <small class="text-muted d-block mt-2" style="font-size: 0.72rem; line-height: 1.35;">
                                    <i class="bi bi-info-circle text-primary me-1"></i>জরুরি সময়ে যাত্রী SOS বাটন চাপলে স্বয়ংক্রিয়ভাবে লাইভ জিপিএস ট্র্যাকিং ও এসএমএস এই নম্বরে পাঠানো হয়।
                                </small>
                            </div>

                            <!-- Customer Preferences Card -->
                            <div class="card border-0 shadow-sm rounded-3 bg-white p-3">
                                <h6 class="fw-bold text-dark mb-2.5 small border-bottom pb-2">
                                    <i class="bi bi-sliders text-primary me-1.5"></i>ভাষা ও পছন্দসমূহ (Preferences)
                                </h6>
                                <div class="small d-flex flex-column gap-1.5 text-muted" style="font-size:0.75rem;">
                                    <div class="d-flex justify-content-between">
                                        <span>পছন্দের ভাষা:</span>
                                        <strong class="text-dark">\${customer.language || 'Hindi (हिंदी)'}</strong>
                                    </div>
                                    <div class="d-flex justify-content-between">
                                        <span>সার্ভিস জোন / হাব:</span>
                                        <strong class="text-dark">\${customer.zone || 'Sealdah Station - College St'}</strong>
                                    </div>
                                    <div class="d-flex justify-content-between">
                                        <span>পেমেন্ট পদ্ধতি:</span>
                                        <span class="badge bg-light text-dark border">\${customer.preferred_payment || 'Cash'}</span>
                                    </div>
                                    <div class="d-flex justify-content-between">
                                        <span>রেজিস্ট্রেশন:</span>
                                        <span class="text-success fw-semibold"><i class="bi bi-check-circle-fill me-1"></i>Mobile OTP Verified</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- RIGHT COLUMN: STREAMLINED COMPLETE RIDE HISTORY (8 COLS) -->
                    <div class="col-lg-8 col-md-7">
                        <div class="card border-0 shadow-sm rounded-3 bg-white h-100 overflow-hidden">
                            <div class="card-header bg-white py-2.5 px-3 border-bottom d-flex align-items-center justify-content-between flex-wrap gap-2">
                                <div class="d-flex align-items-center gap-2">
                                    <i class="bi bi-clock-history text-primary fs-6"></i>
                                    <h6 class="fw-bold mb-0">একনজরে রাইড হিস্ট্রি (Ride History)</h6>
                                    <span class="badge bg-primary bg-opacity-10 text-primary border border-primary border-opacity-25 px-2 py-0.5 rounded-pill" style="font-size: 0.7rem;">
                                        \${rides.length} Recorded Trips
                                    </span>
                                </div>
                                <span class="badge bg-light text-muted border" style="font-size: 0.72rem;">
                                    <i class="bi bi-lightning-charge-fill text-warning me-1"></i>Eco-Friendly E-Rickshaw Rides
                                </span>
                            </div>

                            <div class="p-3" style="max-height: 480px; overflow-y: auto;">
                                \${rides.length > 0 ? \`
                                    <div class="d-flex flex-column gap-2.5">
                                        \${rides.map((r, idx) => \`
                                            <div class="p-3 rounded-3 border bg-light bg-opacity-50 hover-shadow transition-all">
                                                <!-- Top Row: Booking Code, Date, Status -->
                                                <div class="d-flex align-items-center justify-content-between flex-wrap gap-2 border-bottom pb-2 mb-2">
                                                    <div class="d-flex align-items-center gap-2">
                                                        <span class="badge bg-white text-primary border font-monospace fw-bold px-2 py-1" style="font-size:0.75rem;">
                                                            #\${r.booking_code}
                                                        </span>
                                                        <span class="text-muted small" style="font-size:0.75rem;">
                                                            <i class="bi bi-calendar3 me-1"></i>\${r.date}
                                                        </span>
                                                    </div>
                                                    <div class="d-flex align-items-center gap-2">
                                                        <span class="badge bg-success bg-opacity-10 text-success border border-success border-opacity-25 py-0.5 px-2" style="font-size:0.72rem;">
                                                            <i class="bi bi-check-circle-fill me-1"></i>\${r.status === 'completed' ? 'Completed' : r.status}
                                                        </span>
                                                        <span class="badge bg-light text-dark border fw-bold" style="font-size:0.75rem;">
                                                            ₹\${parseFloat(r.fare).toFixed(2)}
                                                        </span>
                                                    </div>
                                                </div>

                                                <!-- Middle Row: Route Flow (Pickup to Drop) -->
                                                <div class="row g-2 align-items-center mb-2">
                                                    <div class="col-sm-5">
                                                        <div class="small text-truncate" title="\${r.pickup}">
                                                            <i class="bi bi-geo-alt-fill text-success me-1"></i>
                                                            <strong class="text-dark">\${r.pickup}</strong>
                                                        </div>
                                                    </div>
                                                    <div class="col-sm-2 text-center text-muted small" style="font-size:0.7rem;">
                                                        <span class="badge bg-white text-secondary border px-1.5 py-0.5">\${r.distance_km} km ➔</span>
                                                    </div>
                                                    <div class="col-sm-5">
                                                        <div class="small text-truncate" title="\${r.drop}">
                                                            <i class="bi bi-flag-fill text-danger me-1"></i>
                                                            <strong class="text-dark">\${r.drop}</strong>
                                                        </div>
                                                    </div>
                                                </div>

                                                <!-- Bottom Row: Driver, Vehicle, Payment & Passenger Review -->
                                                <div class="p-2 rounded bg-white border d-flex align-items-center justify-content-between flex-wrap gap-2 text-muted" style="font-size:0.74rem;">
                                                    <div class="d-flex align-items-center gap-2 flex-wrap">
                                                        <span><i class="bi bi-person-fill text-primary me-0.5"></i> চালক: <strong class="text-dark">\${r.driver}</strong></span>
                                                        <span>&bull;</span>
                                                        <span><span class="badge bg-light text-dark border font-monospace" style="font-size:0.68rem;">🛺 \${r.vehicle}</span></span>
                                                        <span>&bull;</span>
                                                        <span><span class="badge bg-success bg-opacity-10 text-success border border-success border-opacity-25 py-0 px-1.5" style="font-size:0.68rem;">\${r.payment_mode} (\${r.payment_status || 'Paid'})</span></span>
                                                    </div>
                                                    <div>
                                                        <span class="text-warning fw-bold"><i class="bi bi-star-fill me-0.5"></i>\${r.rating || '5.0 ★'}</span>
                                                        \${r.review ? \`<span class="text-dark ms-1 fst-italic">"\${r.review}"</span>\` : ''}
                                                    </div>
                                                </div>
                                            </div>
                                        \`).join('')}
                                    </div>
                                \` : \`
                                    <div class="text-center py-5 text-muted">
                                        <i class="bi bi-inbox fs-3 d-block mb-1"></i>
                                        কোনো রাইড রেকর্ড পাওয়া যায়নি।
                                    </div>
                                \`}
                            </div>
                        </div>
                    </div>
                </div>
            \`;

            const modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('customerDetailsModal'));
            if (currentAdminLang === 'bn') setTimeout(() => translateAdminDom('bn', document.getElementById('customerDetailsModal')), 50);
            if (modal) modal.show();
        }

        `;

content = content.substring(0, startIdx) + newViewCustomerDetails + content.substring(endIdx);
fs.writeFileSync('G:/oitoto/admin/index.html', content, 'utf8');
console.log('admin/index.html successfully updated with At-A-Glance Customer Profile modal!');
