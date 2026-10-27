const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const needle = 'Partners & Vehicles Master Registry';
const idx = content.indexOf(needle);
if (idx !== -1) {
    console.log(content.substring(idx + 1000, idx + 2500));
}
