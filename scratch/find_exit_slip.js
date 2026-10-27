const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

content.split('\n').forEach((l, i) => {
    if (l.includes('Exit Slip') || l.includes('exitSlip') || l.includes('deletedAccountDetailModal')) {
        console.log(i + 1, l.trim());
    }
});
