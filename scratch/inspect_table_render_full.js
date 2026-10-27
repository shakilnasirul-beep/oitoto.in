const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const startMarker = 'function renderUnifiedPartnersVehiclesTable()';
const startIdx = content.indexOf(startMarker);
const endIdx = content.indexOf('function openDriverKYCModal');
console.log(content.substring(startIdx, endIdx));
