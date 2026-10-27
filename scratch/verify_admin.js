const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

console.log('File length:', content.length);
console.log('Includes driverKYCModal:', content.includes('id="driverKYCModal"'));
console.log('Includes vehiclePhotoLightboxModal:', content.includes('id="vehiclePhotoLightboxModal"'));
console.log('Includes approveUnifiedKYC:', content.includes('function approveUnifiedKYC'));
console.log('Includes openPhotoLightbox:', content.includes('function openPhotoLightbox'));
console.log('Includes Ratul Sarkar:', content.includes('Ratul Sarkar'));
console.log('Includes Pradip Saha:', content.includes('Pradip Saha'));

// Extract the main JS script block and syntax check it
const scriptMatch = content.match(/<script>([\s\S]*?)<\/script>/g);
console.log('Total script tags:', scriptMatch ? scriptMatch.length : 0);

if (scriptMatch) {
    const mainScript = scriptMatch[scriptMatch.length - 1].replace(/<\/?script>/g, '');
    try {
        new Function(mainScript);
        console.log('✅ JS syntax in main script tag is 100% VALID!');
    } catch(err) {
        console.error('❌ JS syntax error:', err.message);
    }
}
