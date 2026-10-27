const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const startMarker = 'function viewCustomerDetails(customerId) {';
const startIdx = content.indexOf(startMarker);
const endMarker = 'function toggleCustomerStatus(customerId) {';
const endIdx = content.indexOf(endMarker);

console.log('startIdx:', startIdx, 'endIdx:', endIdx);
console.log('Current length:', endIdx - startIdx);
console.log(content.substring(startIdx, startIdx + 500));
