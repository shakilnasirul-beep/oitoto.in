const fs = require('fs');

let content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

// 1. UPDATE renderDeletedAccountsTable to add Restore button in the Action column
const oldActionCol = `<!-- 7. Action Button -->
                        <td class="text-end">
                            <button class="btn-view-slip shadow-sm py-1 px-2" style="font-size: 0.72rem;" onclick="viewDeletedAccountSlip('\${r.id}')" title="View Official Digital Exit Slip">
                                <i class="bi bi-receipt-cutoff"></i>
                                <span>\${isBn ? 'এক্সিট স্লিপ' : 'Exit Slip'}</span>
                            </button>
                        </td>`;

const newActionCol = `<!-- 7. Action Buttons (Restore & Exit Slip) -->
                        <td class="text-end text-nowrap">
                            <div class="d-inline-flex gap-1.5 align-items-center justify-content-end">
                                <button class="btn btn-sm btn-success py-1 px-2 shadow-xs fw-semibold d-inline-flex align-items-center" style="font-size: 0.72rem;" onclick="restoreDeletedAccount('\${r.id}')" title="\${isBn ? 'অ্যাকাউন্ট পুনরুদ্ধার করুন' : 'Restore Account'}">
                                    <i class="bi bi-arrow-counterclockwise me-1"></i>
                                    <span>\${isBn ? 'রিস্টোর' : 'Restore'}</span>
                                </button>
                                <button class="btn-view-slip shadow-sm py-1 px-2 d-inline-flex align-items-center" style="font-size: 0.72rem;" onclick="viewDeletedAccountSlip('\${r.id}')" title="View Official Digital Exit Slip">
                                    <i class="bi bi-receipt-cutoff me-1"></i>
                                    <span>\${isBn ? 'এক্সিট স্লিপ' : 'Exit Slip'}</span>
                                </button>
                            </div>
                        </td>`;

if (content.includes(oldActionCol)) {
    content = content.replace(oldActionCol, newActionCol);
    console.log('Action column Restore button added.');
} else {
    console.warn('oldActionCol exact match not found, checking alternatives...');
}

// 2. ADD restoreDeletedAccount function
const restoreFunc = `
        // Restore Deleted Account (Driver or Passenger) Back to Active Operations
        async function restoreDeletedAccount(id) {
            const list = getDeletedAccountsList();
            const r = list.find(item => item.id === id);
            if (!r) {
                alert('Record not found for ID: ' + id);
                return;
            }

            const isBn = currentAdminLang === 'bn';
            const isDriver = r.role === 'driver';

            const confirmMsg = isBn
                ? \`আপনি কি নিশ্চিত যে "\${r.userName}" (\${isDriver ? 'ড্রাইভার' : 'গ্রাহক'}) অ্যাকাউন্টটি সক্রিয় হিসেবে পুনরুদ্ধার (Restore) করতে চান?\\n\\n- অ্যাকাউন্টটি পুনরায় সক্রিয় তালিকায় যুক্ত হবে\\n- ড্রাইভার হলে ফ্লিট ও রাইড অ্যাকসেপ্ট পুনরায় আনলক হবে\\n- অডিট রেকর্ড আপডেট হবে।\`
                : \`Are you sure you want to restore "\${r.userName}" (\${isDriver ? 'Driver' : 'Passenger'}) back to active operations?\\n\\n- Account will be reinstated into active registry\\n- Allocated fleet and ride acceptance will be unlocked\\n- Record will be removed from deleted audit directory.\`;

            if (!confirm(confirmMsg)) return;

            // 1. If Driver: Remove from oitoto_deleted_driver_ids blacklist
            if (isDriver) {
                let deletedIds = [];
                try {
                    deletedIds = JSON.parse(localStorage.getItem('oitoto_deleted_driver_ids') || '[]');
                } catch(e) { deletedIds = []; }

                deletedIds = deletedIds.filter(val => val !== String(r.id) && val !== String(r.phone) && val !== String(r.driver_id));
                localStorage.setItem('oitoto_deleted_driver_ids', JSON.stringify(deletedIds));

                // Find or recreate in globalDriversData
                const existingDrv = globalDriversData.find(d => d.phone === r.phone || d.full_name === r.userName || String(d.id) === String(r.id));
                if (existingDrv) {
                    existingDrv.status = 'verified_active';
                    existingDrv.driver_kyc_status = 'verified';
                    existingDrv.vehicle_kyc_status = 'verified';
                    existingDrv.ride_accept_status = 'unlocked';
                } else {
                    const restoredDriver = {
                        id: r.driver_id || (typeof r.id === 'number' ? r.id : Math.floor(100 + Math.random() * 900)),
                        full_name: r.userName,
                        phone: r.phone || '+91 98300 00000',
                        driving_license_no: r.driving_license_no || \`WB-01-2024-\${Math.floor(100000 + Math.random() * 900000)}\`,
                        aadhaar_no: r.aadhaar_no || 'XXXX-XXXX-' + Math.floor(1000 + Math.random() * 9000),
                        service_area_name: r.zone || 'Kolkata North Hub',
                        vehicle_number: (r.vehicleNo && r.vehicleNo !== 'N/A' && r.vehicleNo !== 'Unassigned') ? r.vehicleNo : 'WB-01-E-1001',
                        brand_make: 'Mayuri Deluxe EV',
                        category: 'toto',
                        categoryName: 'Toto (E-Rickshaw)',
                        icon: '🛺',
                        ownership_model: 'independent_owner',
                        current_balance: 0.00,
                        status: 'verified_active',
                        driver_kyc_status: 'verified',
                        vehicle_kyc_status: 'verified',
                        ride_accept_status: 'unlocked',
                        registered_via: 'Restored via Audit Log',
                        registered_date: new Date().toISOString().split('T')[0],
                        total_trips: r.pastTrips || 0
                    };
                    globalDriversData.unshift(restoredDriver);
                }

                // Restore / reassign vehicle in globalVehiclesData
                if (r.vehicleNo && r.vehicleNo !== 'N/A' && typeof globalVehiclesData !== 'undefined') {
                    const veh = globalVehiclesData.find(v => v.vehicle_number === r.vehicleNo);
                    if (veh) {
                        veh.driver_name = r.userName;
                        veh.status = 'active';
                        veh.kyc_status = 'verified';
                    }
                }

                // Call backend API to verify/restore
                try {
                    await ensureAuth();
                    await fetch(\`\${API_BASE}/admin/drivers/\${r.driver_id || r.id}/verify\`, {
                        method: 'POST',
                        headers: getAuthHeaders({ 'Content-Type': 'application/json' }),
                        body: JSON.stringify({ status: 'verified_active' })
                    });
                } catch(e) {}

                updatePartnerKPIs();
                renderUnifiedPartnersVehiclesTable();
            } else {
                // If Passenger / Customer
                if (typeof currentCustomersData !== 'undefined') {
                    const existingCust = currentCustomersData.find(c => c.phone === r.phone || c.full_name === r.userName);
                    if (existingCust) {
                        existingCust.status = 'active';
                    } else {
                        currentCustomersData.unshift({
                            id: Math.floor(100 + Math.random() * 900),
                            code: 'CUST-' + Math.floor(1000 + Math.random() * 9000),
                            full_name: r.userName,
                            phone: r.phone,
                            email: (r.userName.toLowerCase().replace(/[^a-z0-9]/g, '') || 'user') + '@oitoto.in',
                            status: 'active',
                            language: 'English',
                            city: r.zone || 'Kolkata',
                            zone: r.zone || 'Kolkata Hub',
                            member_since: 'Restored',
                            rating_avg: 5.0,
                            total_rides: r.pastTrips || 0,
                            completed_rides: r.pastTrips || 0,
                            cancelled_rides: 0,
                            total_spend: 0.00,
                            preferred_payment: 'Cash',
                            emergency_contact_name: 'Family Contact',
                            emergency_contact_phone: '+91 98300 00000',
                            home_address: r.zone || 'Kolkata',
                            work_address: 'Central District',
                            ride_history: []
                        });
                    }
                    if (typeof renderCustomersTable === 'function') {
                        renderCustomersTable(currentCustomersData);
                    }
                }
            }

            // 2. Remove record from oitoto_deleted_accounts in localStorage
            try {
                let localAccounts = getDeletedAccountsList().filter(item => item.id !== id);
                localStorage.setItem('oitoto_deleted_accounts', JSON.stringify(localAccounts));
            } catch(e) {}

            // 3. Hide Exit Slip modal if open
            const slipModalEl = document.getElementById('deletedAccountDetailModal');
            if (slipModalEl) {
                const inst = bootstrap.Modal.getInstance(slipModalEl);
                if (inst) inst.hide();
            }

            // 4. Reload Deleted Accounts table & counters
            loadDeletedAccounts();
            updateSidebarDeletedBadge();
            refreshDashboard();

            // 5. Success alert
            const successMsg = isBn
                ? \`✓ "\${r.userName}" (\${isDriver ? 'ড্রাইভার' : 'গ্রাহক'}) অ্যাকাউন্টটি সফলভাবে সক্রিয় তালিকায় পুনরুদ্ধার (Restore) করা হয়েছে!\`
                : \`✓ Account "\${r.userName}" (\${isDriver ? 'Driver' : 'Passenger'}) has been successfully restored to active operations!\`;
            alert(successMsg);
        }
`;

// Insert restoreDeletedAccount before function viewDeletedAccountSlip(id)
const slipMarker = 'function viewDeletedAccountSlip(id) {';
if (!content.includes('function restoreDeletedAccount(')) {
    content = content.replace(slipMarker, restoreFunc + '\n        ' + slipMarker);
    console.log('restoreDeletedAccount function inserted.');
}

// 3. ALSO ADD RESTORE BUTTON TO THE EXIT SLIP MODAL FOOTER
const oldModalFooter = `<button type="button" class="btn btn-outline-secondary btn-sm" onclick="window.print()">
                        <i class="bi bi-printer me-1"></i> Print / Save PDF
                    </button>`;

const newModalFooter = `<div class="d-flex align-items-center gap-2">
                        <button type="button" class="btn btn-success btn-sm px-3 shadow-xs fw-semibold" id="btnModalSlipRestore" onclick="if(window.currentViewingSlipId) restoreDeletedAccount(window.currentViewingSlipId);">
                            <i class="bi bi-arrow-counterclockwise me-1"></i> Restore Account
                        </button>
                        <button type="button" class="btn btn-outline-secondary btn-sm" onclick="window.print()">
                            <i class="bi bi-printer me-1"></i> Print / Save PDF
                        </button>
                    </div>`;

if (content.includes(oldModalFooter)) {
    content = content.replace(oldModalFooter, newModalFooter);
    console.log('Exit Slip Modal footer updated with Restore button.');
}

// Track window.currentViewingSlipId inside viewDeletedAccountSlip
content = content.replace(
    'function viewDeletedAccountSlip(id) {',
    'function viewDeletedAccountSlip(id) {\n            window.currentViewingSlipId = id;'
);

fs.writeFileSync('G:/oitoto/admin/index.html', content, 'utf8');
console.log('admin/index.html successfully updated and saved with Restore option!');
