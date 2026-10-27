const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const startMarker = '<!-- 7. Actions -->';
const startIdx = content.indexOf(startMarker);
console.log(content.substring(startIdx, startIdx + 2000));
