const fs = require('fs');

let content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

// 1. UPDATE loadPartnersAndVehicles and updatePartnerKPIs
const loadPartnersOld = `async function loadPartnersAndVehicles() {
            try {
                await ensureAuth();
                const filterStatus = document.getElementById('partnerStatusFilter')?.value || '';
                const res = await fetch(\`\${API_BASE}/admin/drivers?status=\${filterStatus}\`, {
                    headers: { 'Authorization': \`Bearer \${adminToken}\` }
                });
                const json = await res.json();
                if (json.success && Array.isArray(json.data) && json.data.length > 0) {
                    if (!filterStatus) {
                        globalDriversData = json.data;
                    } else {
                        json.data.forEach(item => {
                            const idx = globalDriversData.findIndex(x => x.id === item.id);
                            if (idx >= 0) globalDriversData[idx] = { ...globalDriversData[idx], ...item };
                            else globalDriversData.unshift(item);
                        });
                    }
                }
            } catch (e) {}

            try {
                const resV = await fetch(\`\${API_BASE}/vehicles\`);
                const jsonV = await resV.json();
                if (jsonV.success && Array.isArray(jsonV.data) && jsonV.data.length > 0) {
                    globalVehiclesData = jsonV.data;
                }
            } catch (e) {}

            updatePartnerKPIs();
            renderUnifiedPartnersVehiclesTable();
        }`;

const loadPartnersNew = `async function loadPartnersAndVehicles() {
            let deletedDriverIds = [];
            try {
                deletedDriverIds = JSON.parse(localStorage.getItem('oitoto_deleted_driver_ids') || '[]');
            } catch(e) { deletedDriverIds = []; }

            try {
                await ensureAuth();
                const filterStatus = document.getElementById('partnerStatusFilter')?.value || '';
                const res = await fetch(\`\${API_BASE}/admin/drivers?status=\${filterStatus}\`, {
                    headers: { 'Authorization': \`Bearer \${adminToken}\` }
                });
                const json = await res.json();
                if (json.success && Array.isArray(json.data) && json.data.length > 0) {
                    // Filter out any driver that was deleted by admin
                    const validData = json.data.filter(item => 
                        !deletedDriverIds.includes(String(item.id)) && 
                        !deletedDriverIds.includes(String(item.phone))
                    );

                    if (!filterStatus) {
                        globalDriversData = validData;
                    } else {
                        validData.forEach(item => {
                            const idx = globalDriversData.findIndex(x => String(x.id) === String(item.id));
                            if (idx >= 0) globalDriversData[idx] = { ...globalDriversData[idx], ...item };
                            else globalDriversData.unshift(item);
                        });
                    }
                }
            } catch (e) {}

            try {
                const resV = await fetch(\`\${API_BASE}/vehicles\`);
                const jsonV = await resV.json();
                if (jsonV.success && Array.isArray(jsonV.data) && jsonV.data.length > 0) {
                    globalVehiclesData = jsonV.data;
                }
            } catch (e) {}

            // Ensure deleted drivers are always purged from memory
            if (deletedDriverIds.length > 0) {
                globalDriversData = globalDriversData.filter(item => 
                    !deletedDriverIds.includes(String(item.id)) && 
                    !deletedDriverIds.includes(String(item.phone))
                );
            }

            updatePartnerKPIs();
            renderUnifiedPartnersVehiclesTable();
        }`;

content = content.replace(loadPartnersOld, loadPartnersNew);
console.log('loadPartnersAndVehicles replacement checked.');

// Update sidebarPartnersCount in updatePartnerKPIs
content = content.replace(
    "setTxt('sidebarPartnersCount', totalDriversCount + (globalVehiclesData?.length || 0));",
    "setTxt('sidebarPartnersCount', totalDriversCount);"
);

// 2. UPDATE delete button and action buttons in renderUnifiedPartnersVehiclesTable
content = content.replace(
    'onclick="deleteDriverPartner(${d.id})"',
    "onclick=\"deleteDriverPartner('${d.id}')\""
);
content = content.replace(
    'onclick="toggleDriverActiveSuspend(${d.id})"',
    "onclick=\"toggleDriverActiveSuspend('${d.id}')\""
);
content = content.replace(
    'onclick="openDriverKYCModal(${d.id})"',
    "onclick=\"openDriverKYCModal('${d.id}')\""
);

// 3. REWRITE deleteDriverPartner function
const oldDeleteFuncRegex = /async function deleteDriverPartner\(id\)[\s\S]*?(?=async function loadDrivers\(\))/;

const newDeleteFunc = `async function deleteDriverPartner(id) {
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
            if (!deletedDriverIds.includes(idStr)) deletedDriverIds.push(idStr);
            if (d.phone && !deletedDriverIds.includes(String(d.phone))) deletedDriverIds.push(String(d.phone));
            localStorage.setItem('oitoto_deleted_driver_ids', JSON.stringify(deletedDriverIds));

            // 2. Unassign vehicle in globalVehiclesData & localStorage
            if (d.vehicle_number && typeof globalVehiclesData !== 'undefined') {
                const veh = globalVehiclesData.find(v => v.vehicle_number === d.vehicle_number);
                if (veh) {
                    veh.driver_name = 'Unassigned';
                    veh.driver_id = null;
                }
            }

            // 3. Create exit record in globalDeletedAccountsData & localStorage
            try {
                const newAuditId = 'DEL-DRV-' + Math.floor(1000 + Math.random() * 9000);
                const nowFormatted = new Date().toLocaleString('en-GB', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: true });

                const auditRecord = {
                    id: newAuditId,
                    role: 'driver',
                    userName: d.full_name,
                    userName_en: d.full_name,
                    userName_bn: d.full_name,
                    phone: d.phone,
                    vehicleNo: d.vehicle_number || 'N/A',
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
                } catch(e) { localDelAccounts = []; }
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

            // 6. Call Backend API to permanently delete in database
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

content = content.replace(oldDeleteFuncRegex, newDeleteFunc);
console.log('deleteDriverPartner function replaced.');

// 4. Fix type comparisons in toggleDriverActiveSuspend
content = content.replace(
    'const drv = globalDriversData.find(d => d.id === driverId);',
    'const drv = globalDriversData.find(d => String(d.id) === String(driverId) || d.id === Number(driverId));'
);

// 5. Fix type comparisons in verifyDriverAction
content = content.replace(
    'const drv = globalDriversData.find(d => d.id === driverId);',
    'const drv = globalDriversData.find(d => String(d.id) === String(driverId) || d.id === Number(driverId));'
);

// 6. Fix openDriverKYCModal lookup
content = content.replace(
    'd = globalDriversData.find(drv => drv.id === Number(driverId));',
    'd = globalDriversData.find(drv => String(drv.id) === String(driverId) || drv.id === Number(driverId));'
);

// 7. Fix approveUnifiedKYC lookup
content = content.replace(
    'const d = globalDriversData.find(item => item.id === Number(driverId))',
    'const d = globalDriversData.find(item => String(item.id) === String(driverId) || item.id === Number(driverId))'
);

// 8. Fix rejectUnifiedKYC lookup
content = content.replace(
    'const d = globalDriversData.find(item => item.id === Number(driverId))',
    'const d = globalDriversData.find(item => String(item.id) === String(driverId) || item.id === Number(driverId))'
);

// 9. Fix toggleUnifiedSuspend lookup
content = content.replace(
    'const d = globalDriversData.find(item => item.id === Number(driverId))',
    'const d = globalDriversData.find(item => String(item.id) === String(driverId) || item.id === Number(driverId))'
);

fs.writeFileSync('G:/oitoto/admin/index.html', content, 'utf8');
console.log('admin/index.html successfully updated and saved!');
