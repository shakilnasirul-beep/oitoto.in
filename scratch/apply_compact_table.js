const fs = require('fs');

let html = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

// 1. Add scoped CSS
const cssNeedle = `.btn-view-slip:hover {
            background: #BE123C;
            color: #FFFFFF;
            border-color: #BE123C;
            transform: translateY(-1.5px);
            box-shadow: 0 4px 12px rgba(190, 18, 60, 0.25);
        }`;

const newCss = `.btn-view-slip:hover {
            background: #BE123C;
            color: #FFFFFF;
            border-color: #BE123C;
            transform: translateY(-1.5px);
            box-shadow: 0 4px 12px rgba(190, 18, 60, 0.25);
        }

        /* Compact At-a-Glance Deleted Accounts Table */
        #tab-deletedAccounts .table-custom {
            table-layout: fixed !important;
            width: 100% !important;
        }
        #tab-deletedAccounts .table-custom th {
            padding: 8px 8px !important;
            font-size: 0.69rem !important;
            white-space: normal !important;
            vertical-align: middle !important;
            letter-spacing: 0.2px !important;
        }
        #tab-deletedAccounts .table-custom td {
            padding: 7px 8px !important;
            font-size: 0.74rem !important;
            vertical-align: middle !important;
        }
        #tab-deletedAccounts .table-responsive {
            overflow-x: auto;
        }
        @media (min-width: 992px) {
            #tab-deletedAccounts .table-responsive {
                overflow-x: hidden !important;
            }
        }`;

if (!html.includes(cssNeedle)) {
    console.error('Could not find cssNeedle!');
    process.exit(1);
}
html = html.replace(cssNeedle, newCss);

// 2. Replace the HTML table structure
const targetTable = `<table class="table table-custom table-hover mb-0 align-middle">
                            <thead>
                                <tr>
                                    <th style="width: 140px;"><i class="bi bi-hash me-1"></i> Audit ID & Date</th>
                                    <th style="width: 115px;"><i class="bi bi-person-badge me-1"></i> Role</th>
                                    <th style="width: 180px;"><i class="bi bi-person-circle me-1"></i> User & Phone</th>
                                    <th style="min-width: 220px;"><i class="bi bi-chat-left-quote-fill me-1 text-danger"></i> Mandatory Reason & Feedback</th>
                                    <th style="width: 130px;"><i class="bi bi-activity me-1"></i> Past Trips</th>
                                    <th style="width: 135px;"><i class="bi bi-shield-check me-1 text-success"></i> 2FA SMS Verification</th>
                                    <th style="width: 95px;" class="text-end"><i class="bi bi-receipt me-1"></i> Action</th>
                                </tr>
                            </thead>
                            <tbody id="deletedAccountsTable">
                                <tr><td colspan="7" class="text-center py-4 text-muted">Loading audit logs...</td></tr>
                            </tbody>
                        </table>`;

const newTable = `<table class="table table-custom table-hover mb-0 align-middle w-100" style="table-layout: fixed;">
                            <thead id="deletedAccountsThead">
                                <tr>
                                    <th style="width: 15%;"><i class="bi bi-hash me-1"></i> Audit & Role</th>
                                    <th style="width: 23%;"><i class="bi bi-person-circle me-1"></i> User, Vehicle & Hub</th>
                                    <th style="width: 28%;"><i class="bi bi-chat-left-quote-fill me-1 text-danger"></i> Mandatory Reason & Feedback</th>
                                    <th style="width: 22%;"><i class="bi bi-activity me-1"></i> Lifetime Activity & 2FA</th>
                                    <th style="width: 12%;" class="text-end"><i class="bi bi-receipt me-1"></i> Action</th>
                                </tr>
                            </thead>
                            <tbody id="deletedAccountsTable">
                                <tr><td colspan="5" class="text-center py-4 text-muted">Loading audit logs...</td></tr>
                            </tbody>
                        </table>`;

if (!html.includes(targetTable)) {
    console.error('Could not find targetTable!');
    process.exit(1);
}
html = html.replace(targetTable, newTable);

// 3. Replace renderDeletedAccountsTable function
const sIdx = html.indexOf('function renderDeletedAccountsTable(items) {');
const eIdx = html.indexOf('function escapeDeletedHtml(str) {');

if (sIdx === -1 || eIdx === -1) {
    console.error('Could not find renderDeletedAccountsTable indices!');
    process.exit(1);
}

const newRenderFunc = `function renderDeletedAccountsTable(items) {
            const tbody = document.getElementById('deletedAccountsTable');
            if (!tbody) return;

            const isBn = currentAdminLang === 'bn';

            const thead = document.getElementById('deletedAccountsThead');
            if (thead) {
                thead.innerHTML = \`
                    <tr>
                        <th style="width: 15%;"><i class="bi bi-hash me-1"></i> \${isBn ? 'অডিট ও রোল' : 'Audit & Role'}</th>
                        <th style="width: 23%;"><i class="bi bi-person-circle me-1"></i> \${isBn ? 'ব্যবহারকারী ও হাব' : 'User, Vehicle & Hub'}</th>
                        <th style="width: 28%;"><i class="bi bi-chat-left-quote-fill me-1 text-danger"></i> \${isBn ? 'কারণ ও মন্তব্য' : 'Mandatory Reason & Feedback'}</th>
                        <th style="width: 22%;"><i class="bi bi-activity me-1"></i> \${isBn ? 'অ্যাক্টিভিটি ও নিরাপত্তা' : 'Lifetime Activity & 2FA'}</th>
                        <th style="width: 12%;" class="text-end"><i class="bi bi-receipt me-1"></i> \${isBn ? 'অ্যাকশন' : 'Action'}</th>
                    </tr>
                \`;
            }

            if (items.length === 0) {
                tbody.innerHTML = \`
                    <tr>
                        <td colspan="5" class="text-center py-5">
                            <div class="py-4">
                                <div style="width: 64px; height: 64px; border-radius: 50%; background: #FEE2E2; color: #DC2626; display: inline-flex; align-items: center; justify-content: center; font-size: 1.8rem; margin-bottom: 12px;">
                                    <i class="bi bi-funnel"></i>
                                </div>
                                <h6 class="fw-bold text-dark mb-1">\${isBn ? 'কোনো অডিট রেকর্ড পাওয়া যায়নি' : 'No deleted account records found'}</h6>
                                <p class="text-muted small mb-3">\${isBn ? 'বর্তমান ফিল্টারের সাথে কোনো রেকর্ড মেলেনি।' : 'No audit logs match current filter or search criteria.'}</p>
                                <button class="btn btn-sm btn-outline-danger" onclick="setRoleTab('all'); setReasonFilter('all'); clearDelSearch();">
                                    <i class="bi bi-arrow-repeat me-1"></i> \${isBn ? 'সব ফিল্টার রিসেট করুন' : 'Reset All Filters'}
                                </button>
                            </div>
                        </td>
                    </tr>
                \`;
                return;
            }

            tbody.innerHTML = items.map(r => {
                const isDriver = r.role === 'driver';
                const roleBadge = isDriver
                    ? \`<span class="badge bg-warning bg-opacity-10 text-dark border border-warning border-opacity-50 px-1.5 py-0.5 rounded-pill" style="font-size:0.65rem;"><i class="bi bi-ev-front-fill text-warning me-0.5"></i>\${isBn ? 'চালক' : 'Driver'}</span>\`
                    : \`<span class="badge bg-primary bg-opacity-10 text-primary border border-primary border-opacity-25 px-1.5 py-0.5 rounded-pill" style="font-size:0.65rem;"><i class="bi bi-person-walking me-0.5"></i>\${isBn ? 'যাত্রী' : 'Passenger'}</span>\`;

                const displayName = isBn ? (r.userName_bn || r.userName) : (r.userName_en || r.userName);
                const displayReason = isBn ? (r.reasonText_bn || r.reasonText) : (r.reasonText_en || r.reasonText);
                const displayRemarks = isBn ? (r.remarks_bn || r.remarks) : (r.remarks_en || r.remarks);
                const displayZone = isBn ? (r.zone_bn || r.zone) : (r.zone_en || r.zone);
                const initials = r.initials || getUserInitials(r.userName_en || r.userName);
                const avatarClass = isDriver ? 'driver' : 'passenger';

                const vehicleRow = isDriver && r.vehicleNo && r.vehicleNo !== 'N/A (Passenger)'
                    ? \`<div class="mt-0.5 text-truncate"><span class="badge bg-light text-dark border font-monospace px-1 py-0.5" style="font-size:0.63rem;"><i class="bi bi-truck-front-fill text-warning me-0.5"></i>\${escapeDeletedHtml(r.vehicleNo)}</span></div>\`
                    : '';

                const zoneRow = displayZone
                    ? \`<div class="text-muted text-truncate mt-0.5" style="font-size:0.65rem;" title="\${escapeDeletedHtml(displayZone)}"><i class="bi bi-geo-alt-fill text-danger me-0.5"></i>\${escapeDeletedHtml(displayZone)}</div>\`
                    : '';

                return \`
                    <tr class="align-middle">
                        <!-- 1. Audit ID, Role & Date (15%) -->
                        <td style="padding: 6px 8px;">
                            <div class="d-flex align-items-center gap-1 flex-wrap mb-1">
                                <span class="badge bg-danger bg-opacity-10 text-danger border border-danger border-opacity-25 font-monospace px-1.5 py-0.5" style="font-size:0.67rem;">
                                    \${escapeDeletedHtml(r.id)}
                                </span>
                                \${roleBadge}
                            </div>
                            <div class="text-muted d-flex align-items-center gap-1" style="font-size:0.65rem; line-height: 1.2;">
                                <i class="bi bi-clock-history"></i> <span class="text-truncate">\${escapeDeletedHtml(r.deletedAtFormatted || r.deletedAt || '')}</span>
                            </div>
                        </td>

                        <!-- 2. User & Vehicle/Hub (23%) -->
                        <td style="padding: 6px 8px;">
                            <div class="d-flex align-items-start gap-1.5">
                                <div class="audit-avatar \${avatarClass}" style="width: 28px; height: 28px; font-size: 0.72rem; flex-shrink: 0;">
                                    \${initials}
                                </div>
                                <div style="min-width: 0; flex: 1;">
                                    <div class="fw-bold text-dark text-truncate" style="font-size: 0.77rem;" title="\${escapeDeletedHtml(displayName)}">
                                        \${escapeDeletedHtml(displayName)}
                                    </div>
                                    <div class="font-monospace text-secondary text-truncate" style="font-size: 0.67rem;">
                                        <i class="bi bi-telephone-fill text-muted" style="font-size:0.58rem;"></i> \${escapeDeletedHtml(r.phone)}
                                    </div>
                                    \${vehicleRow}
                                    \${zoneRow}
                                </div>
                            </div>
                        </td>

                        <!-- 3. Mandatory Reason & Feedback (28%) -->
                        <td style="padding: 6px 8px;">
                            <div class="audit-reason-bubble py-1 px-2" style="background: #FFF1F2; border-left: 3px solid #E11D48; border-radius: 6px; margin-bottom: 0;">
                                <div class="d-flex align-items-center gap-1 text-danger fw-bold text-truncate" style="font-size: 0.72rem;" title="\${escapeDeletedHtml(displayReason || 'Reason specified')}">
                                    <i class="bi bi-exclamation-triangle-fill flex-shrink-0" style="font-size: 0.66rem;"></i>
                                    <span class="text-truncate">\${escapeDeletedHtml(displayReason || 'Reason specified')}</span>
                                </div>
                                <div class="text-secondary fst-italic mt-0.5" style="font-size: 0.67rem; line-height: 1.25; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;" title="\${escapeDeletedHtml(displayRemarks || '')}">
                                    <i class="bi bi-quote text-danger opacity-50"></i> \${escapeDeletedHtml(displayRemarks || (isBn ? 'কোনো অতিরিক্ত মন্তব্য নেই' : 'No additional remarks entered'))}
                                </div>
                            </div>
                        </td>

                        <!-- 4. Lifetime Activity & 2FA (22%) -->
                        <td style="padding: 6px 8px;">
                            <div class="d-flex align-items-center gap-1 flex-wrap mb-1">
                                <span class="badge bg-light text-dark border px-1.5 py-0.5" style="font-size: 0.64rem;">
                                    <i class="bi bi-check2-circle text-primary me-0.5"></i><strong>\${r.lifetimeTrips || 0}</strong> \${isBn ? 'ট্রিপ' : 'trips'}
                                </span>
                                <span class="badge bg-success bg-opacity-10 text-success border border-success border-opacity-25 px-1.5 py-0.5 font-monospace" style="font-size:0.64rem;">
                                    \${escapeDeletedHtml(r.lifetimeValue || r.lifetimeSpends || r.lifetimeEarnings || 'N/A')}
                                </span>
                                <span class="text-warning fw-bold" style="font-size:0.65rem;">
                                    ★ \${escapeDeletedHtml(String(r.avgRating || '5.0').replace('★','').trim())}
                                </span>
                            </div>
                            <div class="d-flex align-items-center gap-1 flex-wrap">
                                <span class="badge bg-success text-white px-1.5 py-0.5 rounded-pill" style="font-size: 0.62rem;">
                                    <i class="bi bi-patch-check-fill me-0.5"></i>SMS OTP
                                </span>
                                <span class="text-muted font-monospace text-truncate" style="font-size: 0.62rem; max-width: 105px;" title="\${escapeDeletedHtml(r.ipAddress || 'IP Verified')}">
                                    <i class="bi bi-broadcast text-secondary me-0.5"></i>\${escapeDeletedHtml(r.ipAddress || 'Verified')}
                                </span>
                            </div>
                        </td>

                        <!-- 5. Action Buttons (12%) -->
                        <td class="text-end" style="padding: 6px 8px;">
                            <div class="d-flex flex-column gap-1 align-items-stretch" style="min-width: 82px; max-width: 100px; margin-left: auto;">
                                <button class="btn btn-sm btn-success py-0.5 px-1.5 shadow-xs fw-semibold d-inline-flex align-items-center justify-content-center text-nowrap" style="font-size: 0.69rem; border-radius: 5px;" onclick="restoreDeletedAccount('\${r.id}')" title="\${isBn ? 'অ্যাকাউন্ট পুনরুদ্ধার করুন' : 'Restore Account'}">
                                    <i class="bi bi-arrow-counterclockwise me-1"></i>
                                    <span>\${isBn ? 'রিস্টোর' : 'Restore'}</span>
                                </button>
                                <button class="btn-view-slip py-0.5 px-1.5 shadow-xs d-inline-flex align-items-center justify-content-center text-nowrap" style="font-size: 0.69rem; border-radius: 5px;" onclick="viewDeletedAccountSlip('\${r.id}')" title="View Official Digital Exit Slip">
                                    <i class="bi bi-receipt-cutoff me-1"></i>
                                    <span>\${isBn ? 'এক্সিট স্লিপ' : 'Exit Slip'}</span>
                                </button>
                            </div>
                        </td>
                    </tr>
                \`;
            }).join('');
        }

        `;

html = html.substring(0, sIdx) + newRenderFunc + html.substring(eIdx);

fs.writeFileSync('G:/oitoto/admin/index.html', html, 'utf8');
console.log('Successfully applied compact table to G:/oitoto/admin/index.html!');
