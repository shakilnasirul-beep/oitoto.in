const fs = require('fs');
const content = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

const startMarker = 'let globalDriversData = [';
const endMarker = 'let globalVehiclesData = [';
const endVehMarker = 'async function loadPartnersAndVehicles()';

const startDrivers = content.indexOf(startMarker);
const endDrivers = content.indexOf(endMarker);
const endVehicles = content.indexOf(endVehMarker);

console.log('startDrivers:', startDrivers, 'endDrivers:', endDrivers, 'endVehicles:', endVehicles);
console.log('--- Current Drivers snippet ---');
console.log(content.substring(startDrivers, startDrivers + 400));
console.log('--- Current Vehicles snippet ---');
console.log(content.substring(endDrivers, endDrivers + 400));
