const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const startMarker = '<!-- MODAL: DRIVER FULL KYC & ONBOARDING INSPECTION -->';
const endMarker = '<!-- MODAL: DELETED ACCOUNT EXIT AUDIT SLIP -->';

const startIdx = content.indexOf(startMarker);
const endIdx = content.indexOf(endMarker);

console.log('startIdx:', startIdx, 'endIdx:', endIdx);
if (startIdx !== -1 && endIdx !== -1) {
    console.log(content.substring(startIdx, endIdx));
} else {
    console.log('Markers not found');
}
