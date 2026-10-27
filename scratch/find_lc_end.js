const fs = require('fs');
const html = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const sIdx = html.indexOf('async function loadCustomers()');
console.log(html.substring(sIdx + 4100, sIdx + 5000));
