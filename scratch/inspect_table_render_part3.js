const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const startMarker = 'statusBadge = `<span class="badge bg-danger';
const startIdx = content.indexOf(startMarker);
console.log(content.substring(startIdx, startIdx + 3000));
