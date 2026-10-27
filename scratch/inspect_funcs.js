const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const startMarker = '// Open Driver KYC Inspection & Onboarding Modal';
const endMarker = 'async function submitNewVehicle(e)';

const startIdx = content.indexOf(startMarker);
const endIdx = content.indexOf(endMarker);

const block = content.substring(startIdx, endIdx);
const funcMatches = block.match(/(?:function|async function)\s+([a-zA-Z0-9_]+)/g);
console.log('Functions in this block:', funcMatches);
