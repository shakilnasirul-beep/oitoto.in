const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const startMarker = '<!-- 2. Vehicle & Category -->';
const startIdx = content.indexOf(startMarker);
console.log(content.substring(startIdx, startIdx + 2500));
