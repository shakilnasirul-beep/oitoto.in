const fs = require('fs');

let content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

// Check renderDeletedAccountsTable action column
const actionColIdx = content.indexOf('<!-- 7. Action Button -->');
console.log('Action column found at:', actionColIdx);
console.log(content.substring(actionColIdx, actionColIdx + 500));
