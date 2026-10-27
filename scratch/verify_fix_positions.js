const fs = require('fs');

const html = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const sIdx = html.indexOf('let globalDriversData = [');
const eIdx = html.indexOf('let globalVehiclesData = [');
console.log('sIdx:', sIdx, 'eIdx:', eIdx);
console.log(html.substring(sIdx, sIdx + 100));
console.log(html.substring(eIdx - 50, eIdx + 50));
