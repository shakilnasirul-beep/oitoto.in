const fs = require('fs');
const html = fs.readFileSync('G:/oitoto/admin/index.html', 'utf8');

console.log('Has INITIAL_SEED_DRIVERS_DATA:', html.includes('INITIAL_SEED_DRIVERS_DATA'));
console.log('Has let globalDriversData = [:', html.includes('let globalDriversData = ['));
console.log('Index of let globalDriversData = [:', html.indexOf('let globalDriversData = ['));
