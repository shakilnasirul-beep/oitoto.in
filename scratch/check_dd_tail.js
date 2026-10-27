const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const ddIdx = content.indexOf('function deleteDriverPartner(');
console.log(content.substring(ddIdx + 5200, ddIdx + 6200));
