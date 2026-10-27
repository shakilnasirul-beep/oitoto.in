const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const startMarker = '// Open Driver KYC Inspection & Onboarding Modal';
const endMarker = 'async function submitNewVehicle(e)';

const startIdx = content.indexOf(startMarker);
const endIdx = content.indexOf(endMarker);

console.log('startIdx:', startIdx, 'endIdx:', endIdx);
if (startIdx !== -1 && endIdx !== -1) {
    console.log('Length of JS block to replace/upgrade:', endIdx - startIdx);
    console.log('First 500 chars:\n', content.substring(startIdx, startIdx + 500));
    console.log('Last 500 chars:\n', content.substring(endIdx - 500, endIdx));
} else {
    console.log('Markers not found');
}
