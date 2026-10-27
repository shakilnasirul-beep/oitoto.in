const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const sIdx = content.indexOf('const SEED_CUSTOMERS = [');
const eIdx = content.indexOf('];', sIdx);
console.log(content.substring(sIdx, eIdx + 2));
