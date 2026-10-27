const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const startMarker = '<td class="text-end text-nowrap py-2">';
const startIdx = content.indexOf(startMarker);
console.log(content.substring(startIdx, startIdx + 1200));
