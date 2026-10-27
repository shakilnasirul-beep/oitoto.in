const fs = require('fs');

let html = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

// 1. Update globalDriversData initialization
const seedDriversNeedle = `let globalDriversData = [
            { 
                id: 7, 
                full_name: 'Ratul Sarkar',`;

const newSeedDrivers = `function cleanAdminPhone(p) {
            if (!p) return '';
            return String(p).replace(/\\D/g, '').slice(-10);
        }

        const INITIAL_SEED_DRIVERS_DATA = [
            { 
                id: 7, 
                full_name: 'Ratul Sarkar',`;

if (!html.includes(seedDriversNeedle)) {
    console.error('Could not find seedDriversNeedle!');
    process.exit(1);
}
html = html.replace(seedDriversNeedle, newSeedDrivers);

const closingDriversNeedle = `total_trips: 118 
            }
        ];

        let globalVehiclesData = [`;

const newClosingDrivers = `total_trips: 118 
            }
        ];

        let globalDriversData = INITIAL_SEED_DRIVERS_DATA.map(d => ({ ...d }));

        let globalVehiclesData = [`;

if (!html.includes(closingDriversNeedle)) {
    console.error('Could not find closingDriversNeedle!');
    process.exit(1);
}
html = html.replace(closingDriversNeedle, newClosingDrivers);
console.log('Step 1 complete');

// 2. Update loadPartnersAndVehicles
const lpStart = 'async function loadPartnersAndVehicles() {';
const lpEnd = 'function updatePartnerKPIs() {';
const lpStartIdx = html.indexOf(lpStart);
const lpEndIdx = html.indexOf(lpEnd);

const newLoadPartners = `async function loadPartnersAndVehicles() {
            let deletedDriverIds = [];
            try {
                deletedDriverIds = JSON.parse(localStorage.getItem('oitoto_deleted_driver_ids') || '[]');
            } catch(e) { deletedDriverIds = []; }

            let customVehicles = [];
            try {
                customVehicles = JSON.parse(localStorage.getItem('oitoto_custom_vehicles') || '[]');
            } catch(e) {}

            let apiDrivers = [];
            try {
                await ensureAuth();
                const filterStatus = document.getElementById('partnerStatusFilter')?.value || '';
                const res = await fetch(\`\${API_BASE}/admin/drivers?status=\${filterStatus}\`, {
                    headers: { 'Authorization': \`Bearer \${adminToken}\` }
                });
                const json = await res.json();
                if (json.success && Array.isArray(json.data) && json.data.length > 0) {
                    apiDrivers = json.data;
                }
            } catch (e) {}

            // Start with fresh copy of initial seed drivers
            let mergedDrivers = INITIAL_SEED_DRIVERS_DATA.map(d => ({ ...d }));

            // Merge API drivers if any
            apiDrivers.forEach(apiD => {
                const pClean = cleanAdminPhone(apiD.phone);
                const idx = mergedDrivers.findIndex(d => 
                    String(d.id) === String(apiD.id) || 
                    (pClean && cleanAdminPhone(d.phone) === pClean)
                );
                if (idx >= 0) {
                    mergedDrivers[idx] = { ...mergedDrivers[idx], ...apiD };
                } else {
                    mergedDrivers.push(apiD);
                }
            });

            // Merge persistent restored drivers from localStorage
            let restoredDrivers = [];
            try {
                restoredDrivers = JSON.parse(localStorage.getItem('oitoto_restored_drivers') || '[]');
            } catch(e) {}

            restoredDrivers.forEach(rd => {
                const pClean = cleanAdminPhone(rd.phone);
                const idx = mergedDrivers.findIndex(d => 
                    String(d.id) === String(rd.id) || 
                    d.full_name === rd.full_name || 
                    (pClean && cleanAdminPhone(d.phone) === pClean)
                );
                if (idx >= 0) {
                    mergedDrivers[idx] = { 
                        ...mergedDrivers[idx], 
                        ...rd, 
                        status: 'verified_active', 
                        driver_kyc_status: 'verified', 
                        vehicle_kyc_status: 'verified', 
                        ride_accept_status: 'unlocked' 
                    };
                } else {
                    mergedDrivers.unshift(rd);
                }
            });

            // Fetch vehicles if available
            try {
                const resV = await fetch(\`\${API_BASE}/vehicles\`);
                const jsonV = await resV.json();
                if (jsonV.success && Array.isArray(jsonV.data) && jsonV.data.length > 0) {
                    globalVehiclesData = jsonV.data;
                }
            } catch (e) {}

            // Merge custom vehicles
            if (customVehicles.length > 0) {
                customVehicles.forEach(cv => {
                    const idx = globalVehiclesData.findIndex(v => v.vehicle_number === cv.vehicle_number);
                    if (idx >= 0) {
                        globalVehiclesData[idx] = { ...globalVehiclesData[idx], ...cv };
                    } else {
                        globalVehiclesData.unshift(cv);
                    }
                });
            }

            // Purge deleted drivers based on blacklist
            if (deletedDriverIds.length > 0) {
                mergedDrivers = mergedDrivers.filter(item => {
                    const pClean = cleanAdminPhone(item.phone);
                    const isDel = deletedDriverIds.some(dId => {
                        const s = String(dId);
                        return s === String(item.id) || (pClean && cleanAdminPhone(s) === pClean);
                    });
                    return !isDel;
                });
            }

            globalDriversData = mergedDrivers;

            updatePartnerKPIs();
            renderUnifiedPartnersVehiclesTable();
        }

        `;

html = html.substring(0, lpStartIdx) + newLoadPartners + html.substring(lpEndIdx);
console.log('Step 2 complete');

// 3. Update deleteDriverPartner
const ddStart = 'function deleteDriverPartner(id) {';
const ddEnd = 'async function loadDrivers() {';
const ddStartIdx = html.indexOf(ddStart);
const ddEndIdx = html.indexOf(ddEnd);

const newDeleteDriverPartner = `async function deleteDriverPartner(id) {
            if (!id && id !== 0) return;
            const d = globalDriversData.find(drv => String(drv.id) === String(id) || drv.id === Number(id) || drv.phone === id);
            if (!d) return;

            const isBn = currentAdminLang === 'bn';
            const confirmMsg = isBn 
                ? \`আপনি কি নিশ্চিত যে পার্টনার "\${d.full_name}" কে স্থায়ীভাবে মুছে ফেলতে চান?\\n\\n- ড্রাইভার প্রোফাইল মুছে ফেলা হবে\\n- বরাদ্দকৃত গাড়ি (\${d.vehicle_number || 'কোনো গাড়ি নেই'}) আনঅ্যাসাইন হবে\\n- অডিট রেকর্ড "Deleted Accounts Audit"-এ সংরক্ষিত হবে।\`
                : \`Are you sure you want to permanently delete partner "\${d.full_name}"?\\n\\n- Driver profile will be permanently removed\\n- Allocated vehicle (\${d.vehicle_number || 'None'}) will be unassigned\\n- An exit audit record will be preserved in "Deleted Accounts Audit".\`;

            if (!confirm(confirmMsg)) return;

            // 1. Blacklist ID & Phone in persistent localStorage so it NEVER reappears on refresh
            let deletedDriverIds = [];
            try {
                deletedDriverIds = JSON.parse(localStorage.getItem('oitoto_deleted_driver_ids') || '[]');
            } catch(e) { deletedDriverIds = []; }

            const idStr = String(d.id);
            const pClean = cleanAdminPhone(d.phone);
            if (!deletedDriverIds.includes(idStr)) deletedDriverIds.push(idStr);
            if (d.phone && !deletedDriverIds.includes(String(d.phone))) deletedDriverIds.push(String(d.phone));
            if (pClean && !deletedDriverIds.includes(pClean)) deletedDriverIds.push(pClean);
            localStorage.setItem('oitoto_deleted_driver_ids', JSON.stringify(deletedDriverIds));

            // Remove from restored drivers if present
            try {
                let restoredDrivers = JSON.parse(localStorage.getItem('oitoto_restored_drivers') || '[]');
                restoredDrivers = restoredDrivers.filter(rd => 
                    String(rd.id) !== idStr && 
                    rd.full_name !== d.full_name && 
                    cleanAdminPhone(rd.phone) !== pClean
                );
                localStorage.setItem('oitoto_restored_drivers', JSON.stringify(restoredDrivers));
            } catch(e) {}

            // 2. Unassign vehicle in globalVehiclesData & localStorage
            if (d.vehicle_number && typeof globalVehiclesData !== 'undefined') {
                const veh = globalVehiclesData.find(v => v.vehicle_number === d.vehicle_number);
                if (veh) {
                    veh.driver_name = 'Unassigned';
                    veh.driver_id = null;
                }
                try {
                    let customVehicles = JSON.parse(localStorage.getItem('oitoto_custom_vehicles') || '[]');
                    const cv = customVehicles.find(v => v.vehicle_number === d.vehicle_number);
                    if (cv) {
                        cv.driver_name = 'Unassigned';
                        cv.driver_id = null;
                        localStorage.setItem('oitoto_custom_vehicles', JSON.stringify(customVehicles));
                    }
                } catch(e) {}
            }

            // 3. Create exit record in globalDeletedAccountsData & localStorage with driver_id
            try {
                const newAuditId = 'DEL-DRV-' + Math.floor(1000 + Math.random() * 9000);
                const nowFormatted = new Date().toLocaleString('en-GB', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: true });

                const auditRecord = {
                    id: newAuditId,
                    driver_id: d.id,
                    role: 'driver',
                    userName: d.full_name,
                    userName_en: d.full_name,
                    userName_bn: d.full_name,
                    phone: d.phone,
                    vehicleNo: d.vehicle_number || 'N/A',
                    brand_make: d.brand_make || 'Mayuri Pro 1000 EV',
                    driving_license_no: d.driving_license_no || '',
                    aadhaar_no: d.aadhaar_no || '',
                    reasonCode: 'ADMIN_REMOVAL',
                    reasonText: 'Admin Removed Partner / Fleet Exit',
                    reasonText_en: 'Admin Removed Partner / Fleet Exit',
                    reasonText_bn: 'অ্যাডমিন কর্তৃক পার্টনার অপসারণ / ফ্লিট এক্সিট',
                    remarks: \`Partner account permanently removed by Super Admin. Allocated vehicle \${d.vehicle_number || 'N/A'} unassigned.\`,
                    remarks_en: \`Partner account permanently removed by Super Admin. Allocated vehicle \${d.vehicle_number || 'N/A'} unassigned.\`,
                    remarks_bn: \`সুপার অ্যাডমিন কর্তৃক অ্যাকাউন্ট মুছে ফেলা হয়েছে। গাড়ি \${d.vehicle_number || 'N/A'} আনঅ্যাসাইন করা হয়েছে।\`,
                    zone: d.service_area_name || 'Kolkata Hub',
                    zone_en: d.service_area_name || 'Kolkata Hub',
                    zone_bn: d.service_area_name || 'Kolkata Hub',
                    deletedAt: new Date().toISOString(),
                    deletedAtFormatted: nowFormatted,
                    otpVerified: true,
                    verificationMethod: 'ADMIN_PANEL_OVERRIDE',
                    ipAddress: 'Admin Portal (Super Administrator)'
                };

                if (typeof globalDeletedAccountsData !== 'undefined') {
                    globalDeletedAccountsData.unshift(auditRecord);
                }
                let localDelAccounts = [];
                try {
                    localDelAccounts = JSON.parse(localStorage.getItem('oitoto_deleted_accounts') || '[]');
                } catch(e) {}
                localDelAccounts.unshift(auditRecord);
                localStorage.setItem('oitoto_deleted_accounts', JSON.stringify(localDelAccounts));

                const sidebarDeletedEl = document.getElementById('sidebarDeletedCount');
                if (sidebarDeletedEl && typeof globalDeletedAccountsData !== 'undefined') {
                    sidebarDeletedEl.textContent = globalDeletedAccountsData.length;
                }
            } catch(e) {}

            // 4. Remove from globalDriversData immediately in memory
            globalDriversData = globalDriversData.filter(drv => 
                String(drv.id) !== idStr && 
                drv.phone !== d.phone
            );

            // 5. Update UI immediately!
            updatePartnerKPIs();
            renderUnifiedPartnersVehiclesTable();
            refreshDashboard();

            // 6. Call Backend API
            try {
                await ensureAuth();
                let res = await fetch(\`\${API_BASE}/admin/drivers/\${d.id}\`, {
                    method: 'DELETE',
                    headers: getAuthHeaders()
                });
                if (!res.ok) {
                    await fetch(\`\${API_BASE}/admin/drivers/\${d.id}/delete\`, {
                        method: 'POST',
                        headers: getAuthHeaders()
                    });
                }
            } catch(err) {
                console.warn('Backend delete sync note:', err);
            }

            const successMsg = isBn
                ? \`✓ পার্টনার "\${d.full_name}" সফলভাবে মুছে ফেলা হয়েছে এবং এক্সিট অডিটে যুক্ত করা হয়েছে।\`
                : \`✓ Partner "\${d.full_name}" deleted successfully and logged in Exit Audit.\`;
            alert(successMsg);
        }

        `;

html = html.substring(0, ddStartIdx) + newDeleteDriverPartner + html.substring(ddEndIdx);
console.log('Step 3 complete');

// 4. Update loadCustomers
const lcStart = 'async function loadCustomers() {';
const lcEnd = 'function renderCustomersTable(list) {';
const lcStartIdx = html.indexOf(lcStart);
const lcEndIdx = html.indexOf(lcEnd);

const newLoadCustomers = `async function loadCustomers() {
            currentCustomersData = SEED_CUSTOMERS.map(c => ({ ...c }));

            try {
                await ensureAuth();
                const res = await fetch(\`\${API_BASE}/admin/customers\`, {
                    headers: { 'Authorization': \`Bearer \${adminToken}\` }
                });
                const json = await res.json();
                if (json.success && Array.isArray(json.data) && json.data.length > 0) {
                    const apiCusts = json.data.map((c, idx) => {
                        const local = SEED_CUSTOMERS.find(s => s.phone === c.phone || s.id === c.id) || {};
                        return {
                            id: c.id,
                            code: \`CUST-\${1000 + c.id}\`,
                            full_name: c.full_name || local.full_name,
                            phone: c.phone || local.phone,
                            email: c.email || local.email,
                            status: c.status || local.status || 'active',
                            language: c.language === 'bn' ? 'Bengali (বাংলা)' : (c.language === 'hi' ? 'Hindi (हिंदी)' : 'English'),
                            city: local.city || 'Kolkata North',
                            zone: local.zone || 'Metropolitan Feeder',
                            member_since: local.member_since || '2026',
                            rating_avg: parseFloat(c.rating_avg || local.rating_avg || 4.9).toFixed(2),
                            total_rides: parseInt(c.total_rides || local.total_rides || 0),
                            completed_rides: parseInt(c.total_rides || local.completed_rides || 0),
                            cancelled_rides: local.cancelled_rides || 0,
                            total_spend: parseFloat(c.total_spend || local.total_spend || 0),
                            preferred_payment: local.preferred_payment || 'UPI',
                            emergency_contact_name: c.emergency_contact_name || local.emergency_contact_name || 'N/A',
                            emergency_contact_phone: c.emergency_contact_phone || local.emergency_contact_phone || 'N/A',
                            home_address: c.home_address || local.home_address || 'Kolkata, WB',
                            home_coords: local.home_coords || '22.5726, 88.3639',
                            work_address: c.work_address || local.work_address || 'Kolkata, WB',
                            work_coords: local.work_coords || '22.5670, 88.3710',
                            avatar_bg: local.avatar_bg || '#10B981',
                            ride_history: local.ride_history || []
                        };
                    });
                    if (apiCusts.length > 0) currentCustomersData = apiCusts;
                }
            } catch (e) {}

            // Merge persistent restored customers from localStorage
            let restoredCustomers = [];
            try {
                restoredCustomers = JSON.parse(localStorage.getItem('oitoto_restored_customers') || '[]');
            } catch(e) {}
            restoredCustomers.forEach(rc => {
                const rcClean = cleanAdminPhone(rc.phone);
                const idx = currentCustomersData.findIndex(c => 
                    c.full_name === rc.full_name || 
                    (rcClean && cleanAdminPhone(c.phone) === rcClean)
                );
                if (idx >= 0) {
                    currentCustomersData[idx] = { ...currentCustomersData[idx], ...rc, status: 'active' };
                } else {
                    currentCustomersData.unshift(rc);
                }
            });

            const totalCust = currentCustomersData.length;
            const totalRides = currentCustomersData.reduce((acc, c) => acc + (c.total_rides || 0), 0);
            const totalSpend = currentCustomersData.reduce((acc, c) => acc + (c.total_spend || 0), 0);
            const avgRating = (currentCustomersData.reduce((acc, c) => acc + parseFloat(c.rating_avg || 5.0), 0) / (totalCust || 1)).toFixed(2);

            const elTotal = document.getElementById('custMetricTotal');
            if (elTotal) elTotal.textContent = totalCust;
            const elRides = document.getElementById('custMetricRides');
            if (elRides) elRides.textContent = totalRides;
            const elSpend = document.getElementById('custMetricSpend');
            if (elSpend) elSpend.textContent = \`₹\${totalSpend.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}\`;
            const elRating = document.getElementById('custMetricRating');
            if (elRating) elRating.textContent = \`\${avgRating} ★\`;
            const elBadge = document.getElementById('custTotalBadge');
            if (elBadge) elBadge.textContent = \`\${totalCust} Riders\`;
            const elSidebarBadge = document.getElementById('sidebarCustomersCount');
            if (elSidebarBadge) elSidebarBadge.textContent = totalCust;

            renderCustomersTable(currentCustomersData);
        }

        `;

html = html.substring(0, lcStartIdx) + newLoadCustomers + html.substring(lcEndIdx);
console.log('Step 4 complete');

// 5. Update restoreDeletedAccount
const resStart = 'async function restoreDeletedAccount(id) {';
const resEnd = 'function viewDeletedAccountSlip(id) {';
const resStartIdx = html.indexOf(resStart);
const resEndIdx = html.indexOf(resEnd);

const newRestoreFunc = `async function restoreDeletedAccount(id) {
            const list = getDeletedAccountsList();
            const r = list.find(item => item.id === id);
            if (!r) {
                alert('Record not found for ID: ' + id);
                return;
            }

            const isBn = currentAdminLang === 'bn';
            const isDriver = r.role === 'driver';

            const confirmMsg = isBn
                ? \`আপনি কি নিশ্চিত যে "\${r.userName}" (\${isDriver ? 'ড্রাইভার' : 'গ্রাহক'}) অ্যাকাউন্টটি পুনরুদ্ধার (Restore) করে সক্রিয় করতে চান?\\n\\n- অ্যাকাউন্টটি পুনরায় সক্রিয় তালিকায় ফিরে যাবে\\n- ড্রাইভার হলে ফ্লিট ও রাইড গ্রহণ আনলক হবে\\n- অডিট হিস্ট্রি থেকে মুছে ফেলা হবে।\`
                : \`Are you sure you want to restore "\${r.userName}" (\${isDriver ? 'Driver' : 'Passenger'}) back to active operations?\\n\\n- Account will be reinstated into active registry\\n- Allocated fleet and ride acceptance will be unlocked\\n- Record will be removed from deleted audit directory.\`;

            if (!confirm(confirmMsg)) return;

            if (isDriver) {
                const pClean = cleanAdminPhone(r.phone);
                const seedMatch = INITIAL_SEED_DRIVERS_DATA.find(s => 
                    s.full_name === r.userName || 
                    (s.phone && cleanAdminPhone(s.phone) === pClean)
                );
                const matchedId = seedMatch ? String(seedMatch.id) : (r.driver_id ? String(r.driver_id) : null);

                // 1. Un-blacklist completely from oitoto_deleted_driver_ids
                let deletedDriverIds = [];
                try {
                    deletedDriverIds = JSON.parse(localStorage.getItem('oitoto_deleted_driver_ids') || '[]');
                } catch(e) { deletedDriverIds = []; }

                deletedDriverIds = deletedDriverIds.filter(val => {
                    const valStr = String(val);
                    if (valStr === String(r.id)) return false;
                    if (r.driver_id && valStr === String(r.driver_id)) return false;
                    if (matchedId && valStr === matchedId) return false;
                    if (pClean && cleanAdminPhone(valStr) === pClean) return false;
                    if (r.phone && valStr === String(r.phone)) return false;
                    return true;
                });
                localStorage.setItem('oitoto_deleted_driver_ids', JSON.stringify(deletedDriverIds));

                // 2. Prepare restored driver object
                const numericId = matchedId ? Number(matchedId) : (r.driver_id ? Number(r.driver_id) : Math.floor(100 + Math.random() * 900));
                const restoredDriver = {
                    id: numericId,
                    full_name: r.userName,
                    driving_license_no: (seedMatch && seedMatch.driving_license_no) || r.driving_license_no || \`WB-01-2023-\${Math.floor(100000 + Math.random() * 900000)}\`,
                    aadhaar_no: (seedMatch && seedMatch.aadhaar_no) || r.aadhaar_no || 'XXXX-XXXX-' + Math.floor(1000 + Math.random() * 9000),
                    phone: r.phone || '+91 98300 00000',
                    service_area_name: r.zone || (seedMatch && seedMatch.service_area_name) || 'Kolkata Hub',
                    vehicle_number: (r.vehicleNo && r.vehicleNo !== 'N/A' && r.vehicleNo !== 'N/A (Passenger)') ? r.vehicleNo : (seedMatch && seedMatch.vehicle_number ? seedMatch.vehicle_number : 'WB-01-E-1007'),
                    brand_make: (seedMatch && seedMatch.brand_make) || 'Mayuri Pro 1000 EV',
                    category: (seedMatch && seedMatch.category) || 'toto',
                    categoryName: (seedMatch && seedMatch.categoryName) || 'Toto (E-Rickshaw)',
                    icon: (seedMatch && seedMatch.icon) || '🛺',
                    ownership_model: (seedMatch && seedMatch.ownership_model) || 'independent_owner',
                    current_balance: 0.00,
                    status: 'verified_active',
                    driver_kyc_status: 'verified',
                    vehicle_kyc_status: 'verified',
                    ride_accept_status: 'unlocked',
                    registered_via: 'Restored via Audit Log',
                    registered_date: new Date().toISOString().split('T')[0],
                    total_trips: parseInt(r.lifetimeTrips || r.pastTrips || 0)
                };

                // 3. Persist in localStorage 'oitoto_restored_drivers'
                let restoredDrivers = [];
                try {
                    restoredDrivers = JSON.parse(localStorage.getItem('oitoto_restored_drivers') || '[]');
                } catch(e) { restoredDrivers = []; }

                restoredDrivers = restoredDrivers.filter(d => 
                    String(d.id) !== String(numericId) && 
                    d.full_name !== r.userName && 
                    cleanAdminPhone(d.phone) !== pClean
                );
                restoredDrivers.unshift(restoredDriver);
                localStorage.setItem('oitoto_restored_drivers', JSON.stringify(restoredDrivers));

                // 4. Update memory & UI
                const existingIdx = globalDriversData.findIndex(d => 
                    String(d.id) === String(numericId) || 
                    d.full_name === r.userName || 
                    cleanAdminPhone(d.phone) === pClean
                );
                if (existingIdx >= 0) {
                    globalDriversData[existingIdx] = { ...globalDriversData[existingIdx], ...restoredDriver };
                } else {
                    globalDriversData.unshift(restoredDriver);
                }

                // 5. Restore vehicle allocation
                if (restoredDriver.vehicle_number && restoredDriver.vehicle_number !== 'N/A') {
                    let customVehicles = [];
                    try {
                        customVehicles = JSON.parse(localStorage.getItem('oitoto_custom_vehicles') || '[]');
                    } catch(e) {}
                    let veh = globalVehiclesData.find(v => v.vehicle_number === restoredDriver.vehicle_number);
                    if (veh) {
                        veh.driver_name = restoredDriver.full_name;
                        veh.driver_id = restoredDriver.id;
                        veh.status = 'active';
                        veh.kyc_status = 'verified';
                    } else {
                        veh = {
                            vehicle_number: restoredDriver.vehicle_number,
                            brand_make: restoredDriver.brand_make || 'Mayuri Deluxe EV',
                            category: restoredDriver.category || 'toto',
                            category_name: restoredDriver.categoryName || 'Toto (E-Rickshaw)',
                            icon: restoredDriver.icon || '🛺',
                            model_year: '2024',
                            ownership_type: 'independent_owner',
                            driver_name: restoredDriver.full_name,
                            driver_id: restoredDriver.id,
                            battery_type: 'Lithium-ion (60V 100Ah)',
                            status: 'active',
                            kyc_status: 'verified'
                        };
                        globalVehiclesData.unshift(veh);
                    }
                    customVehicles = customVehicles.filter(v => v.vehicle_number !== restoredDriver.vehicle_number);
                    customVehicles.push(veh);
                    localStorage.setItem('oitoto_custom_vehicles', JSON.stringify(customVehicles));
                }

                // Notify backend API
                try {
                    ensureAuth().then(() => {
                        fetch(\`\${API_BASE}/admin/drivers/\${numericId}/verify\`, {
                            method: 'POST',
                            headers: getAuthHeaders({ 'Content-Type': 'application/json' }),
                            body: JSON.stringify({ status: 'verified_active' })
                        }).catch(() => {});
                    });
                } catch(e) {}

                updatePartnerKPIs();
                renderUnifiedPartnersVehiclesTable();

            } else {
                // Passenger / Customer restoration
                const pClean = cleanAdminPhone(r.phone);
                const restoredCust = {
                    id: Math.floor(100 + Math.random() * 900),
                    code: 'CUST-' + Math.floor(1000 + Math.random() * 9000),
                    full_name: r.userName,
                    phone: r.phone || '+91 98700 01111',
                    email: (r.userName.toLowerCase().replace(/[^a-z0-9]/g, '') || 'user') + '@oitoto.in',
                    status: 'active',
                    language: 'Bengali (বাংলা)',
                    city: r.zone || 'Kolkata',
                    zone: r.zone || 'Kolkata Hub',
                    member_since: 'Member (Restored)',
                    rating_avg: 5.0,
                    total_rides: parseInt(r.lifetimeTrips || r.pastTrips || 12),
                    completed_rides: parseInt(r.lifetimeTrips || r.pastTrips || 12),
                    cancelled_rides: 0,
                    total_spend: parseFloat(String(r.lifetimeValue || '250').replace(/[^0-9.]/g, '') || 250),
                    preferred_payment: 'UPI',
                    emergency_contact_name: 'Family Contact',
                    emergency_contact_phone: '+91 98700 00000',
                    home_address: r.zone || 'Kolkata, WB',
                    work_address: 'Central District',
                    ride_history: []
                };

                let restoredCustomers = [];
                try {
                    restoredCustomers = JSON.parse(localStorage.getItem('oitoto_restored_customers') || '[]');
                } catch(e) {}
                restoredCustomers = restoredCustomers.filter(c => 
                    c.full_name !== r.userName && 
                    cleanAdminPhone(c.phone) !== pClean
                );
                restoredCustomers.unshift(restoredCust);
                localStorage.setItem('oitoto_restored_customers', JSON.stringify(restoredCustomers));

                if (typeof currentCustomersData !== 'undefined') {
                    const idx = currentCustomersData.findIndex(c => 
                        c.full_name === r.userName || 
                        cleanAdminPhone(c.phone) === pClean
                    );
                    if (idx >= 0) {
                        currentCustomersData[idx] = { ...currentCustomersData[idx], ...restoredCust, status: 'active' };
                    } else {
                        currentCustomersData.unshift(restoredCust);
                    }
                    if (typeof renderCustomersTable === 'function') {
                        renderCustomersTable(currentCustomersData);
                    }
                }
            }

            // Remove record from oitoto_deleted_accounts in localStorage
            try {
                let localAccounts = getDeletedAccountsList().filter(item => item.id !== id);
                localStorage.setItem('oitoto_deleted_accounts', JSON.stringify(localAccounts));
            } catch(e) {}

            // Hide Exit Slip modal if open
            const slipModalEl = document.getElementById('deletedAccountDetailModal');
            if (slipModalEl) {
                const inst = bootstrap.Modal.getInstance(slipModalEl);
                if (inst) inst.hide();
            }

            // Reload Deleted Accounts table & counters
            loadDeletedAccounts();
            updateSidebarDeletedBadge();
            refreshDashboard();

            const targetTab = isDriver ? 'partnersVehicles' : 'customers';
            const targetName = isDriver ? (isBn ? 'Partners & Vehicles' : 'Partners & Vehicles') : (isBn ? 'Customers' : 'Customers');

            alert(isBn 
                ? \`✓ "\${r.userName}" অ্যাকাউন্টটি সফলভাবে পুনরুদ্ধার করা হয়েছে এবং "\${targetName}" তালিকায় যুক্ত হয়েছে!\` 
                : \`✓ "\${r.userName}" has been successfully restored and reinstated in "\${targetName}"!\`
            );

            // Automatically switch and navigate directly to the restored tab!
            switchTab(targetTab);
            window.location.hash = targetTab;
        }

        `;

html = html.substring(0, resStartIdx) + newRestoreFunc + html.substring(resEndIdx);
console.log('Step 5 complete');

fs.writeFileSync('G:/oitoto/admin/index.html', html, 'utf8');
console.log('SUCCESS: All 5 steps applied to G:/oitoto/admin/index.html!');
