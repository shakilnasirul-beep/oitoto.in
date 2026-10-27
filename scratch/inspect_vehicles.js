const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const sIdx = content.indexOf('async function loadPartnersAndVehicles()');
console.log(content.substring(sIdx, sIdx + 1200));
