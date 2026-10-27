const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const startMarker = 'function loadPartnersAndVehicles()';
const startIdx = content.indexOf(startMarker);
console.log(content.substring(startIdx, startIdx + 3000));
