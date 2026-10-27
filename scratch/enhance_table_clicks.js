const fs = require('fs');

let content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

// Update column 1 to make full_name clickable
content = content.replace(
    '<div class="fw-bold text-dark text-nowrap" style="font-size:0.84rem;">${d.full_name}</div>',
    '<div class="fw-bold text-dark text-nowrap" style="font-size:0.84rem; cursor:pointer;" onclick="openDriverKYCModal(${d.id})" title="Click to view full KYC & Onboarding profile">${d.full_name}</div>'
);

// Update column 2 to make vehicle_number clickable
content = content.replace(
    '<span class="fw-bold font-monospace text-primary" style="font-size:0.83rem;">${d.icon || \'🛺\'} ${d.vehicle_number}</span>',
    '<span class="fw-bold font-monospace text-primary" style="font-size:0.83rem; cursor:pointer;" onclick="openVehicleKYCModal(\'${d.vehicle_number}\')" title="Click to view Vehicle & Partner KYC">${d.icon || \'🛺\'} ${d.vehicle_number}</span>'
);

// Update column 3 td to be clickable
content = content.replace(
    '<!-- 3. Documents & KYC Papers (Driver + Vehicle) -->\n                        <td class="text-nowrap py-2">',
    '<!-- 3. Documents & KYC Papers (Driver + Vehicle) -->\n                        <td class="text-nowrap py-2" style="cursor:pointer;" onclick="openDriverKYCModal(${d.id})" title="Click to audit Partner & Vehicle KYC documents and photos">'
);

fs.writeFileSync('G:/oitoto/admin/index.html', content, 'utf8');
console.log('Table click targets successfully enhanced!');
