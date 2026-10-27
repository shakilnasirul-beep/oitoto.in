const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const startMarker = '<!-- RC papers button -->';
const startIdx = content.indexOf(startMarker);
console.log(content.substring(startIdx, startIdx + 800));
