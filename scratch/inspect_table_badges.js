const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const startMarker = '<!-- 3. Documents & KYC Papers (Driver + Vehicle) -->';
const startIdx = content.indexOf(startMarker);
console.log(content.substring(startIdx, startIdx + 1200));
