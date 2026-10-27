const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const idx = content.indexOf('id="deletedAccountsTable"');
const tableStart = content.lastIndexOf('<table', idx);
const tableEnd = content.indexOf('</table>', idx);
console.log(content.substring(tableStart, tableEnd + 8));
