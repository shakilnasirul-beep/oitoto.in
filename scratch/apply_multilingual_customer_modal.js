const fs = require('fs');

let content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

// 1. UPDATE MODAL CONTAINER HTML (Add subtitle, print, note, and close btn IDs)
const oldModalContainer = `<!-- MODAL: CUSTOMER PROFILE & COMPREHENSIVE RIDE HISTORY -->
    <div class="modal fade" id="customerDetailsModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-xl">
            <div class="modal-content border-0 shadow-lg" style="border-radius: 16px; overflow: hidden;">
                <div class="modal-header bg-dark text-white py-2.5 px-4 d-flex justify-content-between align-items-center">
                    <div class="d-flex align-items-center gap-2">
                        <span class="badge bg-success p-2 rounded-circle"><i class="bi bi-person-fill text-white fs-6"></i></span>
                        <div>
                            <h5 class="modal-title fw-bold mb-0 text-white" id="customerModalTitle">Customer Full Profile & Ride History</h5>
                            <small class="text-white-50" style="font-size: 0.72rem;">Oi Toto! Pan-India E-Rickshaw Passenger Lifetime Record</small>
                        </div>
                    </div>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-light py-1 px-2.5" onclick="printCustomerSlip()" title="Print Profile">
                            <i class="bi bi-printer me-1"></i> Print / PDF
                        </button>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                </div>
                <div class="modal-body p-4" id="customerDetailsModalBody" style="background-color: #F8FAFC; max-height: 80vh; overflow-y: auto;">
                    <!-- Dynamically populated by viewCustomerDetails(id) -->
                </div>
                <div class="modal-footer bg-white border-top py-2 px-4 d-flex justify-content-between">
                    <div class="d-flex align-items-center gap-2 text-muted small" style="font-size: 0.76rem;">
                        <i class="bi bi-shield-check text-success fs-6"></i>
                        <span>Secure OTP verified platform history &bull; All booking tracking stored in digital ledger</span>
                    </div>
                    <button type="button" class="btn btn-secondary btn-sm px-4" data-bs-dismiss="modal">Close Profile</button>
                </div>
            </div>
        </div>
    </div>`;

const newModalContainer = `<!-- MODAL: CUSTOMER PROFILE & COMPREHENSIVE RIDE HISTORY -->
    <div class="modal fade" id="customerDetailsModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered modal-xl">
            <div class="modal-content border-0 shadow-lg" style="border-radius: 16px; overflow: hidden;">
                <div class="modal-header bg-dark text-white py-2.5 px-4 d-flex justify-content-between align-items-center">
                    <div class="d-flex align-items-center gap-2.5">
                        <span class="badge bg-primary p-2 rounded-circle"><i class="bi bi-person-badge-fill text-white fs-6"></i></span>
                        <div>
                            <h5 class="modal-title fw-bold mb-0 text-white" id="customerModalTitle">Customer Profile & Ride History</h5>
                            <small class="text-white-50" id="customerModalSubtitle" style="font-size: 0.72rem;">Oi Toto! Pan-India E-Rickshaw Passenger Lifetime Record</small>
                        </div>
                    </div>
                    <div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-sm btn-outline-light py-1 px-2.5" onclick="printCustomerSlip()" title="Print Profile">
                            <i class="bi bi-printer me-1"></i> <span id="customerModalPrintBtn">Print / PDF</span>
                        </button>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                </div>
                <div class="modal-body p-4" id="customerDetailsModalBody" style="background-color: #F8FAFC; max-height: 80vh; overflow-y: auto;">
                    <!-- Dynamically populated by viewCustomerDetails(id) -->
                </div>
                <div class="modal-footer bg-white border-top py-2 px-4 d-flex justify-content-between">
                    <div class="d-flex align-items-center gap-2 text-muted small" style="font-size: 0.76rem;">
                        <i class="bi bi-shield-check text-success fs-6"></i>
                        <span id="customerModalFooterNote">Secure OTP verified platform history &bull; All booking tracking stored in digital ledger</span>
                    </div>
                    <button type="button" class="btn btn-secondary btn-sm px-4" id="customerModalCloseBtn" data-bs-dismiss="modal">Close Profile</button>
                </div>
            </div>
        </div>
    </div>`;

content = content.replace(oldModalContainer, newModalContainer);
console.log('Customer modal container replaced.');

// 2. UPDATE setAdminLanguage to re-render customer modal if open
const setLangOld = `            setTimeout(() => {
                translateAdminDom(lang);
            if (typeof applyServiceZoneLanguage === 'function') {
                applyServiceZoneLanguage(lang);
            }
            }, 60);`;

const setLangNew = `            // Immediately refresh open modals when language changes in header
            if (typeof currentViewingCustomerId !== 'undefined' && currentViewingCustomerId) {
                const modalEl = document.getElementById('customerDetailsModal');
                if (modalEl && modalEl.classList.contains('show')) {
                    viewCustomerDetails(currentViewingCustomerId);
                }
            }
            if (typeof currentViewingDriverId !== 'undefined' && currentViewingDriverId) {
                const modalEl = document.getElementById('driverKYCModal');
                if (modalEl && modalEl.classList.contains('show')) {
                    openDriverKYCModal(currentViewingDriverId);
                }
            }

            setTimeout(() => {
                translateAdminDom(lang);
                if (typeof applyServiceZoneLanguage === 'function') {
                    applyServiceZoneLanguage(lang);
                }
            }, 60);`;

content = content.replace(setLangOld, setLangNew);
console.log('setAdminLanguage updated with modal refresh.');

// 3. REWRITE viewCustomerDetails WITH COMPLETE I18N SUPPORT (DEFAULT ENGLISH)
const startMarker = 'function viewCustomerDetails(customerId) {';
const endMarker = 'function toggleCustomerStatus(customerId) {';

const startIdx = content.indexOf(startMarker);
const endIdx = content.indexOf(endMarker);

if (startIdx === -1 || endIdx === -1) {
    console.error('viewCustomerDetails markers not found!');
    process.exit(1);
}

const customerI18nAndFunction = `// =========================================================================
        // CUSTOMER PROFILE & COMPREHENSIVE RIDE HISTORY (MULTILINGUAL AT-A-GLANCE)
        // =========================================================================
        let currentViewingCustomerId = null;

        const CUST_I18N = {
            en: {
                modalTitleSuffix: 'Customer Profile & Ride History',
                subTitle: 'Oi Toto! Pan-India E-Rickshaw Passenger Lifetime Record',
                verifiedRider: 'Verified Rider',
                active: 'Active',
                suspended: 'Suspended',
                whatsapp: 'WhatsApp',
                call: 'Call Passenger',
                suspend: 'Suspend Account',
                reactivate: 'Reactivate',
                memberSince: 'Member Since',
                totalRides: 'Total Rides',
                trips: 'Trips',
                completedRate: '100% Completed',
                cancelledSuffix: 'Cancelled',
                totalSpent: 'Total Spent',
                method: 'Method',
                passengerRating: 'Passenger Rating',
                trustedRider: 'Trusted Rider',
                emergencySos: 'Emergency Contact (SOS)',
                savedPlaces: 'Saved Frequent Places',
                gpsTracked: 'GPS Tracked',
                home: 'Home',
                work: 'Work / Office',
                safetyTitle: 'Safety & Emergency SOS Contact',
                sosConfigured: 'SOS Configured',
                sosNote: 'If passenger triggers SOS during ride, live SMS & GPS tracking link is dispatched to this contact.',
                preferencesTitle: 'Language & Preferences',
                prefLanguage: 'Preferred Language',
                serviceZone: 'Service Zone / Hub',
                paymentMethod: 'Payment Method',
                registration: 'Registration',
                mobileOtpVerified: 'Mobile OTP Verified',
                rideHistoryTitle: 'Complete Ride History',
                recordedTrips: 'Recorded Trips',
                ecoBadge: 'Eco-Friendly E-Rickshaw Rides',
                driver: 'Driver',
                paid: 'Paid',
                noRides: 'No ride records found.',
                footerNote: 'Secure OTP verified platform history • All booking tracking stored in digital ledger',
                closeBtn: 'Close Profile',
                printBtn: 'Print / PDF'
            },
            bn: {
                modalTitleSuffix: 'একনজরে প্রোফাইল ও রাইড হিস্ট্রি',
                subTitle: 'Oi Toto! প্যান-ইন্ডিয়া ই-রিকশা যাত্রী আজীবন রেকর্ড',
                verifiedRider: 'ভেরিফায়েড যাত্রী',
                active: 'সক্রিয়',
                suspended: 'স্থগিত',
                whatsapp: 'হোয়াটসঅ্যাপ',
                call: 'যাত্রীকে কল করুন',
                suspend: 'অ্যাকাউন্ট স্থগিত করুন',
                reactivate: 'পুনরায় সক্রিয় করুন',
                memberSince: 'নিবন্ধন তারিখ',
                totalRides: 'মোট রাইড',
                trips: 'ট্রিপ',
                completedRate: '১০০% সম্পন্ন',
                cancelledSuffix: 'বাতিল',
                totalSpent: 'মোট খরচ',
                method: 'পদ্ধতি',
                passengerRating: 'যাত্রী রেটিং',
                trustedRider: 'বিশ্বস্ত যাত্রী',
                emergencySos: 'জরুরি যোগাযোগ (SOS)',
                savedPlaces: 'সেভড ঘনঘন রুট',
                gpsTracked: 'জিপিএস ট্র্যাকিং',
                home: 'বাসা',
                work: 'অফিস / কর্মক্ষেত্র',
                safetyTitle: 'নিরাপত্তা ও জরুরি এসওএস কনটাক্ট',
                sosConfigured: 'এসওএস সক্রিয়',
                sosNote: 'জরুরি সময়ে যাত্রী SOS বাটন চাপলে স্বয়ংক্রিয়ভাবে লাইভ জিপিএস ট্র্যাকিং ও এসএমএস এই নম্বরে পাঠানো হয়।',
                preferencesTitle: 'ভাষা ও পছন্দসমূহ',
                prefLanguage: 'পছন্দের ভাষা',
                serviceZone: 'সার্ভিস জোন / হাব',
                paymentMethod: 'পেমেন্ট মাধ্যম',
                registration: 'রেজিস্ট্রেশন',
                mobileOtpVerified: 'মোবাইল ওটিপি ভেরিফাইড',
                rideHistoryTitle: 'একনজরে সম্পূর্ণ রাইড হিস্ট্রি',
                recordedTrips: 'নথিভুক্ত ট্রিপ',
                ecoBadge: 'পরিবেশ-বান্ধব ই-রিকশা রাইড',
                driver: 'চালক',
                paid: 'পরিশোধিত',
                noRides: 'কোনো রাইড রেকর্ড পাওয়া যায়নি।',
                footerNote: 'সুরক্ষিত ওটিপি যাচাইকৃত প্ল্যাটফর্ম হিস্ট্রি • সকল বুকিং ডিজিটাল লেজারে সংরক্ষিত',
                closeBtn: 'প্রোফাইল বন্ধ করুন',
                printBtn: 'প্রিন্ট / পিডিএফ'
            },
            hi: {
                modalTitleSuffix: 'ग्राहक प्रोफ़ाइल एवं राइड इतिहास',
                subTitle: 'Oi Toto! अखिल भारतीय ई-रिक्शा यात्री आजीवन रिकॉर्ड',
                verifiedRider: 'सत्यापित राइडर',
                active: 'सक्रिय',
                suspended: 'निलंबित',
                whatsapp: 'व्हाट्सएप',
                call: 'यात्री को कॉल करें',
                suspend: 'खाता निलंबित करें',
                reactivate: 'पुनः सक्रिय करें',
                memberSince: 'सदस्यता तिथि',
                totalRides: 'कुल राइड्स',
                trips: 'ट्रिप्स',
                completedRate: '100% पूर्ण',
                cancelledSuffix: 'रद्द',
                totalSpent: 'कुल खर्च',
                method: 'विधि',
                passengerRating: 'यात्री रेटिंग',
                trustedRider: 'विश्वसनीय यात्री',
                emergencySos: 'आपातकालीन संपर्क (SOS)',
                savedPlaces: 'सहेजे गए स्थान',
                gpsTracked: 'जीपीएस ट्रैक किया गया',
                home: 'घर',
                work: 'कार्यालय / काम',
                safetyTitle: 'सुरक्षा एवं आपातकालीन एसओएस',
                sosConfigured: 'एसओएस सक्रिय',
                sosNote: 'सवारी के दौरान एसओएस दबाने पर इस नंबर पर लाइव जीपीएस और एसएमएस तुरंत भेजा जाता है।',
                preferencesTitle: 'भाषा एवं प्राथमिकताएं',
                prefLanguage: 'पसंदीदा भाषा',
                serviceZone: 'सेवा क्षेत्र / हब',
                paymentMethod: 'भुगतान विधि',
                registration: 'पंजीकरण',
                mobileOtpVerified: 'मोबाइल ओटीपी सत्यापित',
                rideHistoryTitle: 'पूर्ण राइड इतिहास',
                recordedTrips: 'रिकॉर्डेड ट्रिप्स',
                ecoBadge: 'पर्यावरण-अनुकूल ई-रिक्शा राइड्स',
                driver: 'चालक',
                paid: 'भुगतान किया गया',
                noRides: 'कोई राइड रिकॉर्ड नहीं मिला।',
                footerNote: 'सुरक्षित ओटीपी सत्यापित रिकॉर्ड • सभी बुकिंग डिजिटल लेज़र में सुरक्षित',
                closeBtn: 'प्रोफ़ाइल बंद करें',
                printBtn: 'प्रिंट / पीडीएफ'
            }
        };

        function viewCustomerDetails(customerId) {
            currentViewingCustomerId = customerId;
            const customer = currentCustomersData.find(c => c.id == customerId) || SEED_CUSTOMERS.find(s => s.id == customerId);
            if (!customer) {
                alert("Customer profile not found.");
                return;
            }

            // Detect current language - Default is English ('en')
            const lang = (typeof currentAdminLang === 'string' && CUST_I18N[currentAdminLang]) ? currentAdminLang : 'en';
            const t = CUST_I18N[lang];

            const titleEl = document.getElementById('customerModalTitle');
            if (titleEl) {
                titleEl.textContent = \`\${customer.full_name} — \${t.modalTitleSuffix}\`;
            }

            const subEl = document.getElementById('customerModalSubtitle');
            if (subEl) {
                subEl.textContent = \`\${t.subTitle} • \${customer.code} • \${customer.city || 'Kolkata'}\`;
            }

            const printBtnEl = document.getElementById('customerModalPrintBtn');
            if (printBtnEl) printBtnEl.textContent = t.printBtn;

            const footerNoteEl = document.getElementById('customerModalFooterNote');
            if (footerNoteEl) footerNoteEl.textContent = t.footerNote;

            const closeBtnEl = document.getElementById('customerModalCloseBtn');
            if (closeBtnEl) closeBtnEl.textContent = t.closeBtn;

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
                                        <i class="bi bi-patch-check-fill me-1"></i>\${t.verifiedRider}
                                    </span>
                                    <span class="badge bg-secondary bg-opacity-10 text-secondary border font-monospace py-0.5 px-2" style="font-size:0.72rem;">
                                        \${customer.code}
                                    </span>
                                    <span class="badge \${customer.status === 'active' ? 'bg-success' : 'bg-danger'} py-0.5 px-2" style="font-size:0.72rem;">
                                        \${customer.status === 'active' ? t.active : t.suspended}
                                    </span>
                                </div>
                                <div class="d-flex align-items-center gap-2 text-muted small mt-1 flex-wrap" style="font-size:0.78rem;">
                                    <span><i class="bi bi-telephone-fill text-success me-1"></i><a href="tel:\${customer.phone}" class="text-decoration-none text-dark fw-semibold">\${customer.phone}</a></span>
                                    <span>&bull;</span>
                                    <span><i class="bi bi-envelope-fill text-primary me-1"></i><a href="mailto:\${customer.email}" class="text-decoration-none text-dark">\${customer.email}</a></span>
                                    <span>&bull;</span>
                                    <span><i class="bi bi-geo-alt-fill text-danger me-1"></i>\${customer.zone || customer.city || 'Kolkata'}</span>
                                    <span>&bull;</span>
                                    <span><i class="bi bi-calendar-check me-1"></i>\${t.memberSince}: <strong>\${customer.member_since}</strong></span>
                                </div>
                            </div>
                        </div>

                        <div class="d-flex align-items-center gap-1.5 flex-wrap">
                            <a href="https://wa.me/\${(customer.phone || '').replace(/[^0-9]/g, '')}" target="_blank" class="btn btn-sm btn-outline-success py-1 px-2.5" style="font-size:0.78rem;">
                                <i class="bi bi-whatsapp me-1"></i> \${t.whatsapp}
                            </a>
                            <a href="tel:\${customer.phone}" class="btn btn-sm btn-outline-primary py-1 px-2.5" style="font-size:0.78rem;">
                                <i class="bi bi-telephone me-1"></i> \${t.call}
                            </a>
                            <button class="btn btn-sm \${customer.status === 'active' ? 'btn-outline-danger' : 'btn-outline-success'} py-1 px-2.5" style="font-size:0.78rem;" onclick="toggleCustomerStatus(\${customer.id})">
                                <i class="bi \${customer.status === 'active' ? 'bi-pause-circle' : 'bi-play-circle'} me-1"></i> \${customer.status === 'active' ? t.suspend : t.reactivate}
                            </button>
                        </div>
                    </div>
                </div>

                <!-- 2. COMPACT 4 KEY PERFORMANCE METRIC CARDS (AT-A-GLANCE SUMMARY) -->
                <div class="row g-2.5 mb-3">
                    <!-- Total Completed Rides -->
                    <div class="col-6 col-md-3">
                        <div class="p-2.5 bg-white rounded-3 border shadow-xs h-100 d-flex align-items-center gap-2.5">
                            <div class="p-2.5 bg-primary bg-opacity-10 text-primary rounded-circle">
                                <i class="bi bi-ev-front-fill fs-5"></i>
                            </div>
                            <div>
                                <small class="text-muted d-block" style="font-size:0.72rem;">\${t.totalRides} (\${t.trips})</small>
                                <div class="fw-bold text-dark fs-6">\${customer.completed_rides || customer.total_rides} \${t.trips}</div>
                                <small class="text-success fw-semibold" style="font-size:0.68rem;"><i class="bi bi-check-circle me-0.5"></i>\${customer.cancelled_rides ? customer.cancelled_rides + ' ' + t.cancelledSuffix : t.completedRate}</small>
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
                                <small class="text-muted d-block" style="font-size:0.72rem;">\${t.totalSpent}</small>
                                <div class="fw-bold text-dark fs-6">₹\${parseFloat(customer.total_spend || 0).toFixed(2)}</div>
                                <small class="text-muted" style="font-size:0.68rem;">\${t.method}: \${customer.preferred_payment || 'Cash'}</small>
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
                                <small class="text-muted d-block" style="font-size:0.72rem;">\${t.passengerRating}</small>
                                <div class="fw-bold text-dark fs-6">\${customer.rating_avg ? customer.rating_avg + ' ★' : '4.88 ★'}</div>
                                <small class="text-success fw-semibold" style="font-size:0.68rem;">\${t.trustedRider}</small>
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
                                <small class="text-muted d-block" style="font-size:0.72rem;">\${t.emergencySos}</small>
                                <div class="fw-bold text-dark text-truncate" style="font-size:0.8rem; max-width:140px;" title="\${customer.emergency_contact_name}">\${customer.emergency_contact_name || 'Sunita Verma'}</div>
                                <small class="text-danger fw-semibold" style="font-size:0.68rem;"><a href="tel:\${customer.emergency_contact_phone}" class="text-danger text-decoration-none">\${customer.emergency_contact_phone}</a></small>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 3. TWO-COLUMN BALANCED MASTER GRID (AT-A-GLANCE DOSSIER & RIDE HISTORY) -->
                <div class="row g-3">
                    <!-- LEFT COLUMN: PASSENGER DOSSIER & SAVED PLACES (4 COLS) -->
                    <div class="col-lg-4 col-md-5">
                        <div class="d-flex flex-column gap-3">
                            <!-- Saved Places Card -->
                            <div class="card border-0 shadow-sm rounded-3 bg-white p-3">
                                <div class="d-flex align-items-center justify-content-between border-bottom pb-2 mb-2.5">
                                    <h6 class="fw-bold text-dark mb-0 small">
                                        <i class="bi bi-geo-alt-fill text-success me-1.5"></i>\${t.savedPlaces}
                                    </h6>
                                    <span class="badge bg-light text-dark border" style="font-size:0.65rem;">\${t.gpsTracked}</span>
                                </div>
                                <div class="d-flex flex-column gap-2">
                                    <!-- Home -->
                                    <div class="p-2 rounded-2 bg-light border">
                                        <div class="d-flex align-items-center justify-content-between">
                                            <strong class="text-primary small"><i class="bi bi-house-door-fill me-1"></i>\${t.home}</strong>
                                            <small class="text-muted font-monospace" style="font-size:0.65rem;">\${customer.home_coords || '22.5681, 88.3704'}</small>
                                        </div>
                                        <div class="small text-dark fw-semibold mt-0.5" title="\${customer.home_address}">
                                            \${customer.home_address || 'Sealdah Station North Gate, Kolkata'}
                                        </div>
                                    </div>
                                    <!-- Work -->
                                    <div class="p-2 rounded-2 bg-light border">
                                        <div class="d-flex align-items-center justify-content-between">
                                            <strong class="text-warning text-dark small"><i class="bi bi-briefcase-fill me-1 text-warning"></i>\${t.work}</strong>
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
                                        <i class="bi bi-shield-lock-fill text-danger me-1.5"></i>\${t.safetyTitle}
                                    </h6>
                                    <span class="badge bg-danger bg-opacity-10 text-danger border border-danger border-opacity-25" style="font-size:0.65rem;">\${t.sosConfigured}</span>
                                </div>
                                <div class="p-2 rounded-2 bg-light border">
                                    <div class="fw-bold text-dark small">\${customer.emergency_contact_name || 'Sunita Verma (Mother)'}</div>
                                    <div class="d-flex align-items-center justify-content-between mt-1">
                                        <span class="text-muted small"><i class="bi bi-telephone-outbound text-primary me-1"></i>\${customer.emergency_contact_phone || '+91 98700 08888'}</span>
                                        <a href="tel:\${customer.emergency_contact_phone}" class="btn btn-xs btn-outline-danger py-0 px-2" style="font-size:0.7rem;">
                                            <i class="bi bi-telephone-fill"></i> \${lang === 'bn' ? 'কল' : (lang === 'hi' ? 'कॉल' : 'Call')}
                                        </a>
                                    </div>
                                </div>
                                <small class="text-muted d-block mt-2" style="font-size: 0.72rem; line-height: 1.35;">
                                    <i class="bi bi-info-circle text-primary me-1"></i>\${t.sosNote}
                                </small>
                            </div>

                            <!-- Customer Preferences Card -->
                            <div class="card border-0 shadow-sm rounded-3 bg-white p-3">
                                <h6 class="fw-bold text-dark mb-2.5 small border-bottom pb-2">
                                    <i class="bi bi-sliders text-primary me-1.5"></i>\${t.preferencesTitle}
                                </h6>
                                <div class="small d-flex flex-column gap-1.5 text-muted" style="font-size:0.75rem;">
                                    <div class="d-flex justify-content-between">
                                        <span>\${t.prefLanguage}:</span>
                                        <strong class="text-dark">\${customer.language || 'English'}</strong>
                                    </div>
                                    <div class="d-flex justify-content-between">
                                        <span>\${t.serviceZone}:</span>
                                        <strong class="text-dark">\${customer.zone || 'Sealdah Station - College St'}</strong>
                                    </div>
                                    <div class="d-flex justify-content-between">
                                        <span>\${t.paymentMethod}:</span>
                                        <span class="badge bg-light text-dark border">\${customer.preferred_payment || 'Cash'}</span>
                                    </div>
                                    <div class="d-flex justify-content-between">
                                        <span>\${t.registration}:</span>
                                        <span class="text-success fw-semibold"><i class="bi bi-check-circle-fill me-1"></i>\${t.mobileOtpVerified}</span>
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
                                    <h6 class="fw-bold mb-0">\${t.rideHistoryTitle}</h6>
                                    <span class="badge bg-primary bg-opacity-10 text-primary border border-primary border-opacity-25 px-2 py-0.5 rounded-pill" style="font-size: 0.7rem;">
                                        \${rides.length} \${t.recordedTrips}
                                    </span>
                                </div>
                                <span class="badge bg-light text-muted border" style="font-size: 0.72rem;">
                                    <i class="bi bi-lightning-charge-fill text-warning me-1"></i>\${t.ecoBadge}
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
                                                            <i class="bi bi-check-circle-fill me-1"></i>\${r.status === 'completed' ? t.completed : r.status}
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
                                                        <span><i class="bi bi-person-fill text-primary me-0.5"></i> \${t.driver}: <strong class="text-dark">\${r.driver}</strong></span>
                                                        <span>&bull;</span>
                                                        <span><span class="badge bg-light text-dark border font-monospace" style="font-size:0.68rem;">🛺 \${r.vehicle}</span></span>
                                                        <span>&bull;</span>
                                                        <span><span class="badge bg-success bg-opacity-10 text-success border border-success border-opacity-25 py-0 px-1.5" style="font-size:0.68rem;">\${r.payment_mode} (\${r.payment_status || t.paid})</span></span>
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
                                        \${t.noRides}
                                    </div>
                                \`}
                            </div>
                        </div>
                    </div>
                </div>
            \`;

            const modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('customerDetailsModal'));
            if (modal) modal.show();
        }

        `;

content = content.substring(0, startIdx) + customerI18nAndFunction + content.substring(endIdx);
fs.writeFileSync('G:/oitoto/admin/index.html', content, 'utf8');
console.log('admin/index.html successfully updated with Multilingual (Default English) Customer Modal!');
