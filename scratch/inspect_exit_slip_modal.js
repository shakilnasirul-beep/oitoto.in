const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const marker = 'id="deletedAccountDetailModal"';
const idx = content.indexOf(marker);
console.log(content.substring(idx - 40, idx + 800));
