const fs = require('fs');

const html = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const needle = '.btn-view-slip:hover';
const idx = html.indexOf(needle);
console.log(html.substring(idx, idx + 400));
