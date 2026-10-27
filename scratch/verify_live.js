const http = require('http');

http.get('http://oitoto.gt.tc/admin/index.html', (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
        console.log('HTTP Status:', res.statusCode);
        console.log('Downloaded length:', data.length);
        console.log('Includes Partner & Vehicle Unified KYC:', data.includes('Partner & Vehicle Unified KYC'));
        console.log('Includes vehiclePhotoLightboxModal:', data.includes('vehiclePhotoLightboxModal'));
        console.log('Includes approveUnifiedKYC:', data.includes('approveUnifiedKYC'));
        console.log('Includes Ratul Sarkar:', data.includes('Ratul Sarkar'));
        console.log('Includes Pradip Saha:', data.includes('Pradip Saha'));
        console.log('Includes 3-Angle Vehicle Inspection Photos:', data.includes('Vehicle 3-Angle Inspection Photos'));
    });
}).on('error', (err) => {
    console.error('Fetch error:', err.message);
});
